import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../boundaries/scheduling/availability_provider.dart';
import '../../../domain/entities/generated_slot.dart';
import '../../../domain/entities/quran_session.dart';
import '../../../domain/entities/teacher_availability.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/services/booked_slot_starts.dart';
import '../../../domain/services/teacher_availability_sort.dart';
import '../../../domain/usecases/block_generated_slot_usecase.dart';
import '../../../domain/usecases/cancel_session_via_server_usecase.dart';
import '../../../domain/usecases/complete_session_via_server_usecase.dart';
import '../../../domain/usecases/get_teacher_availability_usecase.dart';
import '../../../domain/usecases/get_teacher_sessions_usecase.dart';
import '../../../domain/value_objects/actor_role.dart';
import 'teacher_dashboard_event.dart';
import 'teacher_dashboard_state.dart';

/// Creates a deferred-commit timer; returned callback cancels it.
typedef CommitTimerFactory =
    void Function() Function(Duration delay, void Function() onFire);

CommitTimerFactory _defaultCommitTimerFactory = (delay, onFire) {
  final timer = Timer(delay, onFire);
  return timer.cancel;
};

class TeacherDashboardBloc
    extends Bloc<TeacherDashboardEvent, TeacherDashboardState> {
  TeacherDashboardBloc({
    required this._getTeacherSessions,
    required this._getAvailability,
    required this._blockGeneratedSlot,
    required this._availabilityProvider,
    required this._cancelSession,
    required this._completeSession,
    required this._teacherId,
    CommitTimerFactory? commitTimerFactory,
    this._commitDelay = const Duration(seconds: 5),
  }) : _commitTimerFactory = commitTimerFactory ?? _defaultCommitTimerFactory,
       super(const TeacherDashboardInitial()) {
    // Concurrency: destructive slot deletes use [sequential] — every tap is
    // processed in order; duplicate slot ids are no-oped in the handler.
    // [droppable] would drop rapid deletes; [restartable] could cancel in-flight
    // deletes and is unsafe here. Load uses [restartable] to supersede stale
    // fetches; it replaces optimistic pending deletes on completion.
    on<TeacherDashboardLoadRequested>(
      _onLoadRequested,
      transformer: restartable(),
    );
    on<AvailabilityUpdated>(_onAvailabilityUpdated, transformer: sequential());
    on<AvailabilitySlotAdded>(_onSlotAdded, transformer: sequential());
    on<AvailabilitySlotEdited>(_onSlotEdited, transformer: sequential());
    on<AvailabilitySlotRemoved>(_onSlotRemoved, transformer: sequential());
    on<AvailabilitySlotDeleteUndone>(
      _onSlotDeleteUndone,
      transformer: sequential(),
    );
    on<CommitPendingSlotDelete>(
      _onCommitPendingSlotDelete,
      transformer: sequential(),
    );
    on<TeacherSessionCancelled>(_onSessionCancelled, transformer: sequential());
    on<TeacherSessionCompleted>(_onSessionCompleted, transformer: sequential());
  }

  final GetTeacherSessionsUseCase _getTeacherSessions;
  final GetTeacherAvailabilityUseCase _getAvailability;
  final BlockGeneratedSlotUseCase _blockGeneratedSlot;
  final AvailabilityProvider _availabilityProvider;
  final CancelSessionViaServerUseCase _cancelSession;
  final CompleteSessionViaServerUseCase _completeSession;
  final String _teacherId;
  final CommitTimerFactory _commitTimerFactory;
  final Duration _commitDelay;

  static const _availabilityHorizon = Duration(days: 14);

  void _cancelPendingCommitTimers(TeacherDashboardSuccess success) {
    for (final pending in success.pendingDeletes.values) {
      pending.cancelTimer();
    }
  }

  String? _undoableAfterRemovingPending(
    TeacherDashboardSuccess current,
    String committedSlotId,
    Map<String, PendingSlotDelete> remainingPending,
  ) {
    if (current.undoableSlotId != committedSlotId) {
      return current.undoableSlotId;
    }
    if (remainingPending.isEmpty) return null;
    return remainingPending.values.last.slotId;
  }

  @override
  Future<void> close() {
    final current = state;
    if (current is TeacherDashboardSuccess) {
      for (final pending in current.pendingDeletes.values) {
        pending.cancelTimer();
        unawaited(_commitPendingSlotDelete(pending.slotId));
      }
    }
    return super.close();
  }

  Future<void> _onLoadRequested(
    TeacherDashboardLoadRequested event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final priorSuccess = state;
    var discardedPendingCount = 0;
    if (priorSuccess is TeacherDashboardSuccess) {
      discardedPendingCount = priorSuccess.pendingDeletes.length;
      _cancelPendingCommitTimers(priorSuccess);

      var availability = priorSuccess.availability;
      if (discardedPendingCount > 0) {
        availability = sortTeacherAvailabilityByStart([
          ...availability,
          ...priorSuccess.pendingDeletes.values.map((p) => p.snapshot),
        ]);
      }

      emit(
        priorSuccess.copyWith(
          availability: availability,
          pendingDeletes: const {},
          clearUndoableSlotId: true,
          isRefreshing: true,
          clearSlotFailure: true,
          clearRefreshDiscardedPendingCount: true,
        ),
      );
    } else {
      emit(const TeacherDashboardLoading());
    }

    final now = DateTime.now();

    final sessionsResult = await _getTeacherSessions(event.teacherId);
    final availResult = await _getAvailability(
      event.teacherId,
      from: now,
      to: now.add(_availabilityHorizon),
    );

    // Surface the first failure encountered.
    if (sessionsResult.isLeft()) {
      sessionsResult.fold(
        (f) => emit(TeacherDashboardFailure(f)),
        (_) {},
      );
      return;
    }
    if (availResult.isLeft()) {
      availResult.fold(
        (f) => emit(TeacherDashboardFailure(f)),
        (_) {},
      );
      return;
    }

    final sessions = sessionsResult.fold((_) => <QuranSession>[], (v) => v);
    final slots = availResult.fold((_) => <TeacherAvailability>[], (v) => v);

    if (sessions.isEmpty && slots.isEmpty) {
      emit(const TeacherDashboardEmpty());
      return;
    }

    emit(
      TeacherDashboardSuccess(
        upcomingSessions:
            sessions.where((s) => s.startsAt.isAfter(now)).toList()
              ..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
        availability: slots,
        refreshDiscardedPendingCount: discardedPendingCount > 0
            ? discardedPendingCount
            : null,
      ),
    );
  }

  Future<void> _onAvailabilityUpdated(
    AvailabilityUpdated event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    emit(current.copyWith(isUpdatingAvailability: true));

    final result = await _getAvailability(
      event.teacherId,
      from: event.from,
      to: event.to,
    );

    result.fold(
      (_) => emit(current.copyWith(isUpdatingAvailability: false)),
      (slots) => emit(
        current.copyWith(
          availability: slots,
          isUpdatingAvailability: false,
        ),
      ),
    );
  }

  Future<void> _onSlotAdded(
    AvailabilitySlotAdded event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    emit(
      current.copyWith(isUpdatingAvailability: true, clearSlotFailure: true),
    );

    final result = await _availabilityProvider.publishSlot(event.slot);

    result.fold(
      (failure) => emit(
        current.copyWith(
          isUpdatingAvailability: false,
          slotFailure: failure,
        ),
      ),
      (_) => emit(
        current.copyWith(
          availability: sortTeacherAvailabilityByStart([
            ...current.availability,
            event.slot,
          ]),
          isUpdatingAvailability: false,
          clearSlotFailure: true,
        ),
      ),
    );
  }

  Future<void> _onSlotEdited(
    AvailabilitySlotEdited event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    emit(
      current.copyWith(isUpdatingAvailability: true, clearSlotFailure: true),
    );

    // Remove the old slot then publish the replacement.
    final removeResult = await _availabilityProvider.withdrawSlot(
      event.original.slotId,
    );
    if (removeResult.isLeft()) {
      removeResult.fold(
        (f) => emit(
          current.copyWith(isUpdatingAvailability: false, slotFailure: f),
        ),
        (_) {},
      );
      return;
    }

    final addResult = await _availabilityProvider.publishSlot(event.updated);

    addResult.fold(
      (failure) => emit(
        current.copyWith(
          isUpdatingAvailability: false,
          slotFailure: failure,
        ),
      ),
      (_) {
        final updated = sortTeacherAvailabilityByStart(
          current.availability.map((s) {
            return s.slotId == event.original.slotId ? event.updated : s;
          }).toList(),
        );
        emit(
          current.copyWith(
            availability: updated,
            isUpdatingAvailability: false,
            clearSlotFailure: true,
          ),
        );
      },
    );
  }

  void _onSlotRemoved(
    AvailabilitySlotRemoved event,
    Emitter<TeacherDashboardState> emit,
  ) {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    if (current.pendingDeletes.containsKey(event.slot.slotId)) {
      return;
    }

    if (event.slot.isBooked) {
      emit(
        current.copyWith(
          slotFailure: SlotUnavailableFailure(event.slot.slotId),
        ),
      );
      return;
    }

    final isGenerated =
        GeneratedSlot.parseStartUtc(
          teacherId: event.teacherId,
          slotId: event.slot.slotId,
        ) !=
        null;

    final slotId = event.slot.slotId;
    final cancelTimer = _commitTimerFactory(_commitDelay, () {
      if (isClosed) return;
      add(CommitPendingSlotDelete(slotId: slotId));
    });

    final pending = PendingSlotDelete(
      snapshot: event.slot,
      isGenerated: isGenerated,
      teacherId: event.teacherId,
      cancelTimer: cancelTimer,
    );

    emit(
      current.copyWith(
        availability: current.availability
            .where((slot) => slot.slotId != slotId)
            .toList(),
        pendingDeletes: {...current.pendingDeletes, slotId: pending},
        undoableSlotId: slotId,
        clearSlotFailure: true,
      ),
    );
  }

  void _onSlotDeleteUndone(
    AvailabilitySlotDeleteUndone event,
    Emitter<TeacherDashboardState> emit,
  ) {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    final pending = current.pendingDeletes[event.slotId];
    if (pending == null) {
      return;
    }

    pending.cancelTimer();

    final restored = sortTeacherAvailabilityByStart([
      ...current.availability,
      pending.snapshot,
    ]);
    final pendingDeletes = Map<String, PendingSlotDelete>.from(
      current.pendingDeletes,
    )..remove(event.slotId);

    emit(
      current.copyWith(
        availability: restored,
        pendingDeletes: pendingDeletes,
        undoableSlotId: current.undoableSlotId == event.slotId
            ? null
            : current.undoableSlotId,
        clearUndoableSlotId: current.undoableSlotId == event.slotId,
        clearSlotFailure: true,
      ),
    );
  }

  Future<void> _onCommitPendingSlotDelete(
    CommitPendingSlotDelete event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final current = state;
    if (current is! TeacherDashboardSuccess ||
        !current.pendingDeletes.containsKey(event.slotId)) {
      return;
    }

    await _commitPendingSlotDelete(event.slotId, emit: emit);
  }

  Future<void> _commitPendingSlotDelete(
    String slotId, {
    Emitter<TeacherDashboardState>? emit,
  }) async {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    final pending = current.pendingDeletes[slotId];
    if (pending == null) {
      return;
    }

    final Either<QuranSessionsFailure, void> result;
    if (pending.isGenerated) {
      final booked = await _isGeneratedSlotBooked(pending);
      if (booked) {
        if (emit != null) {
          await _handleBookedAtCommit(current, pending, emit);
        }
        return;
      }
      result = await _blockGeneratedSlot(
        teacherId: pending.teacherId,
        slotStartUtc: pending.snapshot.startsAt,
        slotEndUtc: pending.snapshot.endsAt,
      );
    } else {
      result = await _availabilityProvider.withdrawSlot(
        pending.snapshot.slotId,
      );
    }

    if (emit == null) return;

    if (result.isLeft()) {
      final failure = result.fold(
        (f) => f,
        (_) => throw StateError('unreachable'),
      );
      if (failure is SlotUnavailableFailure) {
        await _handleBookedAtCommit(current, pending, emit);
      } else {
        _handleCommitFailure(current, pending, failure, emit);
      }
      return;
    }

    final pendingDeletes = Map<String, PendingSlotDelete>.from(
      current.pendingDeletes,
    )..remove(slotId);
    final nextUndoable = _undoableAfterRemovingPending(
      current,
      slotId,
      pendingDeletes,
    );
    emit(
      current.copyWith(
        pendingDeletes: pendingDeletes,
        undoableSlotId: nextUndoable,
        clearUndoableSlotId: nextUndoable == null,
        clearSlotFailure: true,
      ),
    );
  }

  Future<bool> _isGeneratedSlotBooked(PendingSlotDelete pending) async {
    final sessionsResult = await _getTeacherSessions(pending.teacherId);
    if (sessionsResult.isLeft()) return false;
    final sessions = sessionsResult.fold((_) => <QuranSession>[], (v) => v);
    final startUtc = pending.snapshot.startsAt.toUtc();
    final booked = collectBookedSlotStarts(
      sessions,
      windowStart: startUtc,
      windowEnd: startUtc.add(const Duration(seconds: 1)),
    );
    return booked.contains(startUtc);
  }

  Future<void> _handleBookedAtCommit(
    TeacherDashboardSuccess current,
    PendingSlotDelete pending,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final now = DateTime.now();
    final availResult = await _getAvailability(
      pending.teacherId,
      from: now,
      to: now.add(_availabilityHorizon),
    );

    final pendingDeletes = Map<String, PendingSlotDelete>.from(
      current.pendingDeletes,
    )..remove(pending.slotId);
    final nextUndoable = _undoableAfterRemovingPending(
      current,
      pending.slotId,
      pendingDeletes,
    );

    availResult.fold(
      (failure) => emit(
        current.copyWith(
          pendingDeletes: pendingDeletes,
          undoableSlotId: nextUndoable,
          clearUndoableSlotId: nextUndoable == null,
          slotFailure: failure,
        ),
      ),
      (slots) => emit(
        current.copyWith(
          availability: slots,
          pendingDeletes: pendingDeletes,
          undoableSlotId: nextUndoable,
          clearUndoableSlotId: nextUndoable == null,
          slotFailure: SlotUnavailableFailure(pending.snapshot.slotId),
        ),
      ),
    );
  }

  void _handleCommitFailure(
    TeacherDashboardSuccess current,
    PendingSlotDelete pending,
    QuranSessionsFailure failure,
    Emitter<TeacherDashboardState> emit,
  ) {
    final pendingDeletes = Map<String, PendingSlotDelete>.from(
      current.pendingDeletes,
    )..remove(pending.slotId);
    final nextUndoable = _undoableAfterRemovingPending(
      current,
      pending.slotId,
      pendingDeletes,
    );

    emit(
      current.copyWith(
        availability: sortTeacherAvailabilityByStart([
          ...current.availability,
          pending.snapshot,
        ]),
        pendingDeletes: pendingDeletes,
        undoableSlotId: nextUndoable,
        clearUndoableSlotId: nextUndoable == null,
        slotFailure: failure,
      ),
    );
  }

  Future<void> _onSessionCancelled(
    TeacherSessionCancelled event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    final result = await _cancelSession(
      bookingId: event.bookingId,
      actorId: _teacherId,
      actorRole: ActorRole.teacher,
      reason: event.reason,
    );

    result.fold(
      (_) => null,
      (_) {
        emit(
          current.copyWith(
            upcomingSessions: current.upcomingSessions
                .where((s) => s.bookingId != event.bookingId)
                .toList(),
          ),
        );
      },
    );
  }

  Future<void> _onSessionCompleted(
    TeacherSessionCompleted event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    await _completeSession(
      sessionId: event.sessionId,
      actorRole: ActorRole.teacher,
    );
  }
}
