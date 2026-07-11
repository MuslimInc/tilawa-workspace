import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/usecases/get_teacher_dashboard_usecase.dart';
import '../../../application/usecases/invalidate_quran_session_cache_usecase.dart';
import '../../../boundaries/scheduling/availability_provider.dart';
import '../../../boundaries/scheduling/friday_review_reminder_store.dart';
import '../../../domain/entities/generated_slot.dart';
import '../../../domain/entities/market_scheduling_config.dart';
import '../../../domain/entities/teacher_availability.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/mappers/quran_session_lifecycle_mapper.dart';
import '../../../domain/services/scheduling_policy_resolver.dart';
import '../../../domain/services/teacher_availability_sort.dart';
import '../../../domain/services/week_calendar.dart';
import '../../../domain/usecases/block_generated_slot_usecase.dart';
import '../../../domain/usecases/cancel_session_via_server_usecase.dart';
import '../../../domain/usecases/complete_session_via_server_usecase.dart';
import '../../../domain/usecases/get_teacher_availability_usecase.dart';
import '../../../domain/usecases/is_slot_booked_usecase.dart';
import '../../../domain/usecases/join_session_usecase.dart';
import '../../../domain/usecases/respond_to_booking_request_usecase.dart';
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
    required this._getTeacherDashboard,
    required this._invalidateCache,
    required this._isSlotBooked,
    required this._getAvailability,
    required this._blockGeneratedSlot,
    required this._availabilityProvider,
    required this._cancelSession,
    required this._respondToBookingRequest,
    required this._completeSession,
    required this._joinSession,
    required this._fridayReviewReminderStore,
    required this._teacherId,
    SchedulingPolicyResolver? schedulingPolicyResolver,
    WeekCalendar? weekCalendar,
    CommitTimerFactory? commitTimerFactory,
    DateTime Function()? now,
    Future<bool> Function()? isConnected,
    this._commitDelay = const Duration(seconds: 5),
  }) : _schedulingPolicyResolver =
           schedulingPolicyResolver ?? const SchedulingPolicyResolver(),
       _weekCalendar = weekCalendar ?? const WeekCalendar(),
       _now = now ?? DateTime.now,
       _commitTimerFactory = commitTimerFactory ?? _defaultCommitTimerFactory,
       _isConnected = isConnected ?? (() async => true),
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
    on<FridayReviewBannerDismissed>(
      _onFridayReviewBannerDismissed,
      transformer: sequential(),
    );
    on<TeacherSessionCancelled>(_onSessionCancelled, transformer: sequential());
    on<TeacherBookingRequestAccepted>(
      _onBookingRequestAccepted,
      transformer: sequential(),
    );
    on<TeacherBookingRequestRejected>(
      _onBookingRequestRejected,
      transformer: sequential(),
    );
    on<TeacherSessionCompleted>(_onSessionCompleted, transformer: sequential());
    on<TeacherDashboardSessionJoinRequested>(
      _onJoinRequested,
      transformer: sequential(),
    );
    on<TeacherDashboardJoinCompletedAcknowledged>(
      _onJoinCompletedAcknowledged,
      transformer: sequential(),
    );
  }

  final GetTeacherDashboardUseCase _getTeacherDashboard;
  final InvalidateQuranSessionCacheUseCase _invalidateCache;
  final IsSlotBookedUseCase _isSlotBooked;
  final GetTeacherAvailabilityUseCase _getAvailability;
  final BlockGeneratedSlotUseCase _blockGeneratedSlot;
  final AvailabilityProvider _availabilityProvider;
  final CancelSessionViaServerUseCase _cancelSession;
  final RespondToBookingRequestUseCase _respondToBookingRequest;
  final CompleteSessionViaServerUseCase _completeSession;
  final JoinSessionUseCase _joinSession;
  final FridayReviewReminderStore _fridayReviewReminderStore;
  final SchedulingPolicyResolver _schedulingPolicyResolver;
  final WeekCalendar _weekCalendar;
  final DateTime Function() _now;
  final String _teacherId;
  final CommitTimerFactory _commitTimerFactory;
  final Future<bool> Function() _isConnected;
  final Duration _commitDelay;

  static const _dashboardHorizonDays = 14;

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
          clearSessionCancelFailure: true,
          clearSessionCancelSucceeded: true,
          clearRefreshDiscardedPendingCount: true,
        ),
      );
    } else {
      emit(const TeacherDashboardLoading());
    }

    if (!await _isConnected()) {
      if (priorSuccess is TeacherDashboardSuccess) {
        emit(priorSuccess.copyWith(isRefreshing: false));
      } else {
        emit(const TeacherDashboardFailure(NetworkFailure()));
      }
      return;
    }

    final now = _now();

    final result = await _getTeacherDashboard(
      teacherProfileId: event.teacherId,
      now: now,
      forceRefresh: true,
    );

    if (result.isLeft()) {
      result.fold(
        (f) => emit(TeacherDashboardFailure(f)),
        (_) {},
      );
      return;
    }

    final dashboard = result.fold((_) => null, (v) => v)!;
    final profile = dashboard.profile;
    final schedulingConfig = dashboard.schedulingConfig;
    final schedule = dashboard.schedule;
    final teacherTimezone = schedule?.timezone ?? 'Asia/Riyadh';
    final marketCountryCode = profile.countryCode;
    final sessions = dashboard.upcomingSessions;
    final pendingRequests = dashboard.pendingBookingRequests;
    final slots = dashboard.availability;

    if (sessions.isEmpty && pendingRequests.isEmpty && slots.isEmpty) {
      emit(const TeacherDashboardEmpty());
      return;
    }

    final presentation = await _buildPresentation(
      teacherId: event.teacherId,
      schedulingConfig: schedulingConfig,
      teacherTimezone: teacherTimezone,
      marketCountryCode: marketCountryCode,
      availability: slots,
      pendingDeletes: const {},
      dismissedFridayReminderWeekKey: null,
      now: now,
    );

    emit(
      TeacherDashboardSuccess(
        pendingBookingRequests: pendingRequests
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
        upcomingSessions: sessions
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
        availability: slots,
        schedulingConfig: schedulingConfig,
        thisWeekAvailability: presentation.thisWeekAvailability,
        nextWeekAvailability: presentation.nextWeekAvailability,
        showFridayReviewBanner: presentation.showFridayReviewBanner,
        fridayReviewNextWeekKey: presentation.fridayReviewNextWeekKey,
        dismissedFridayReminderWeekKey:
            presentation.dismissedFridayReminderWeekKey,
        teacherTimezone: teacherTimezone,
        marketCountryCode: marketCountryCode,
        refreshDiscardedPendingCount: discardedPendingCount > 0
            ? discardedPendingCount
            : null,
      ),
    );
  }

  Future<
    ({
      List<TeacherAvailability> thisWeekAvailability,
      List<TeacherAvailability> nextWeekAvailability,
      bool showFridayReviewBanner,
      String? fridayReviewNextWeekKey,
      String? dismissedFridayReminderWeekKey,
    })
  >
  _buildPresentation({
    required String teacherId,
    required MarketSchedulingConfig schedulingConfig,
    required String teacherTimezone,
    required String? marketCountryCode,
    required List<TeacherAvailability> availability,
    required Map<String, PendingSlotDelete> pendingDeletes,
    required String? dismissedFridayReminderWeekKey,
    required DateTime now,
  }) async {
    final visibleSlots = availability
        .where((slot) => !pendingDeletes.containsKey(slot.slotId))
        .toList();
    final partition = _schedulingPolicyResolver.partitionBookableSlots(
      config: schedulingConfig,
      slots: visibleSlots,
      now: now,
      timezone: teacherTimezone,
    );

    final nextWeekKey = _schedulingPolicyResolver.nextWeekKey(
      config: schedulingConfig,
      now: now,
      timezone: teacherTimezone,
    );

    final storeDismissed = await _fridayReviewReminderStore.isDismissed(
      teacherId: teacherId,
      nextWeekKey: nextWeekKey,
    );
    final dismissedKey =
        storeDismissed || dismissedFridayReminderWeekKey == nextWeekKey
        ? nextWeekKey
        : dismissedFridayReminderWeekKey;

    final bannerDecision = _schedulingPolicyResolver.evaluateFridayBanner(
      config: schedulingConfig,
      now: now,
      timezone: teacherTimezone,
      nextWeekSlotCount: partition.nextWeek.length,
      isDismissedForNextWeek: dismissedKey == nextWeekKey,
    );

    final showBanner = bannerDecision is FridayReviewBannerVisible;
    final bannerWeekKey = showBanner ? (bannerDecision).nextWeekKey : null;

    return (
      thisWeekAvailability: partition.thisWeek,
      nextWeekAvailability: partition.nextWeek,
      showFridayReviewBanner: showBanner,
      fridayReviewNextWeekKey: bannerWeekKey,
      dismissedFridayReminderWeekKey: dismissedKey,
    );
  }

  TeacherDashboardSuccess _applyAvailability(
    TeacherDashboardSuccess current,
    List<TeacherAvailability> availability, {
    Map<String, PendingSlotDelete>? pendingDeletes,
    String? dismissedFridayReminderWeekKey,
  }) {
    final effectivePending = pendingDeletes ?? current.pendingDeletes;
    final partition = _schedulingPolicyResolver.partitionBookableSlots(
      config: current.schedulingConfig,
      slots: availability
          .where(
            (slot) => !effectivePending.containsKey(slot.slotId),
          )
          .toList(),
      now: _now(),
      timezone: current.teacherTimezone,
    );

    final nextWeekKey = _schedulingPolicyResolver.nextWeekKey(
      config: current.schedulingConfig,
      now: _now(),
      timezone: current.teacherTimezone,
    );
    final dismissedKey =
        dismissedFridayReminderWeekKey ??
        current.dismissedFridayReminderWeekKey;
    final bannerDecision = _schedulingPolicyResolver.evaluateFridayBanner(
      config: current.schedulingConfig,
      now: _now(),
      timezone: current.teacherTimezone,
      nextWeekSlotCount: partition.nextWeek.length,
      isDismissedForNextWeek: dismissedKey == nextWeekKey,
    );
    final showBanner = bannerDecision is FridayReviewBannerVisible;

    return current.copyWith(
      availability: availability,
      thisWeekAvailability: partition.thisWeek,
      nextWeekAvailability: partition.nextWeek,
      showFridayReviewBanner: showBanner,
      fridayReviewNextWeekKey: showBanner ? (bannerDecision).nextWeekKey : null,
      clearFridayReviewNextWeekKey: !showBanner,
      dismissedFridayReminderWeekKey: dismissedKey,
    );
  }

  Future<void> _onFridayReviewBannerDismissed(
    FridayReviewBannerDismissed event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    final nextWeekKey =
        current.fridayReviewNextWeekKey ??
        _schedulingPolicyResolver.nextWeekKey(
          config: current.schedulingConfig,
          now: _now(),
          timezone: current.teacherTimezone,
        );

    final until = _weekCalendar.saturdayAfterFriday(
      now: _now(),
      timezone: current.teacherTimezone,
    );
    await _fridayReviewReminderStore.dismiss(
      teacherId: event.teacherId,
      nextWeekKey: nextWeekKey,
      until: until,
    );

    emit(
      current.copyWith(
        showFridayReviewBanner: false,
        dismissedFridayReminderWeekKey: nextWeekKey,
        clearFridayReviewNextWeekKey: true,
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
        _applyAvailability(
          current.copyWith(isUpdatingAvailability: false),
          slots,
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
        _applyAvailability(
          current.copyWith(
            isUpdatingAvailability: false,
            clearSlotFailure: true,
          ),
          sortTeacherAvailabilityByStart([
            ...current.availability,
            event.slot,
          ]),
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
      event.original.teacherId,
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
          _applyAvailability(
            current.copyWith(
              isUpdatingAvailability: false,
              clearSlotFailure: true,
            ),
            updated,
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
      _applyAvailability(
        current.copyWith(
          pendingDeletes: {...current.pendingDeletes, slotId: pending},
          undoableSlotId: slotId,
          clearSlotFailure: true,
        ),
        current.availability.where((slot) => slot.slotId != slotId).toList(),
        pendingDeletes: {...current.pendingDeletes, slotId: pending},
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
      _applyAvailability(
        current.copyWith(
          pendingDeletes: pendingDeletes,
          undoableSlotId: current.undoableSlotId == event.slotId
              ? null
              : current.undoableSlotId,
          clearUndoableSlotId: current.undoableSlotId == event.slotId,
          clearSlotFailure: true,
        ),
        restored,
        pendingDeletes: pendingDeletes,
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
        pending.teacherId,
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
    final result = await _isSlotBooked(pending.snapshot.slotId);
    return result.fold((_) => false, (booked) => booked);
  }

  Future<void> _handleBookedAtCommit(
    TeacherDashboardSuccess current,
    PendingSlotDelete pending,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final now = DateTime.now();
    final horizonDays =
        current.schedulingConfig.bookingHorizonDays < _dashboardHorizonDays
        ? current.schedulingConfig.bookingHorizonDays
        : _dashboardHorizonDays;
    final availResult = await _getAvailability(
      pending.teacherId,
      from: now,
      to: now.add(Duration(days: horizonDays)),
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
        _applyAvailability(
          current.copyWith(
            pendingDeletes: pendingDeletes,
            undoableSlotId: nextUndoable,
            clearUndoableSlotId: nextUndoable == null,
            slotFailure: SlotUnavailableFailure(pending.snapshot.slotId),
          ),
          slots,
          pendingDeletes: pendingDeletes,
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
      _applyAvailability(
        current.copyWith(
          pendingDeletes: pendingDeletes,
          undoableSlotId: nextUndoable,
          clearUndoableSlotId: nextUndoable == null,
          slotFailure: failure,
        ),
        sortTeacherAvailabilityByStart([
          ...current.availability,
          pending.snapshot,
        ]),
        pendingDeletes: pendingDeletes,
      ),
    );
  }

  Future<void> _onSessionCancelled(
    TeacherSessionCancelled event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    emit(
      current.copyWith(
        sessionCancelInProgress: event.bookingId,
        clearSessionCancelFailure: true,
        clearSessionCancelSucceeded: true,
      ),
    );

    final result = await _cancelSession(
      bookingId: event.bookingId,
      actorId: _teacherId,
      actorRole: ActorRole.teacher,
      reason: event.reason,
    );

    final latest = state;
    if (latest is! TeacherDashboardSuccess) return;

    result.fold(
      (failure) => emit(
        latest.copyWith(
          clearSessionCancelInProgress: true,
          sessionCancelFailure: failure,
        ),
      ),
      (aggregate) {
        _invalidateCache.invalidateSession(
          aggregate.id,
          teacherProfileId: aggregate.teacherId,
          studentId: aggregate.studentId,
        );
        emit(
          latest.copyWith(
            clearSessionCancelInProgress: true,
            sessionCancelSucceeded: true,
            upcomingSessions: latest.upcomingSessions
                .where((s) => s.bookingId != event.bookingId)
                .toList(),
          ),
        );
      },
    );
  }

  Future<void> _onBookingRequestAccepted(
    TeacherBookingRequestAccepted event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    emit(
      current.copyWith(
        bookingRequestActionInProgress: event.bookingId,
        clearBookingRequestFailure: true,
      ),
    );

    final result = await _respondToBookingRequest(
      bookingId: event.bookingId,
      accept: true,
    );

    final latest = state;
    if (latest is! TeacherDashboardSuccess) return;

    result.fold(
      (failure) => emit(
        latest.copyWith(
          clearBookingRequestActionInProgress: true,
          bookingRequestFailure: failure,
        ),
      ),
      (aggregate) {
        _invalidateCache.invalidateSession(
          aggregate.id,
          teacherProfileId: aggregate.teacherId,
          studentId: aggregate.studentId,
        );
        final moved = latest.pendingBookingRequests
            .where((s) => s.bookingId == event.bookingId)
            .map(mapAcceptedBookingToScheduledSession)
            .toList();
        emit(
          latest.copyWith(
            clearBookingRequestActionInProgress: true,
            pendingBookingRequests: latest.pendingBookingRequests
                .where((s) => s.bookingId != event.bookingId)
                .toList(),
            upcomingSessions: [...latest.upcomingSessions, ...moved]
              ..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
          ),
        );
      },
    );
  }

  Future<void> _onBookingRequestRejected(
    TeacherBookingRequestRejected event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    emit(
      current.copyWith(
        bookingRequestActionInProgress: event.bookingId,
        clearBookingRequestFailure: true,
      ),
    );

    final result = await _respondToBookingRequest(
      bookingId: event.bookingId,
      accept: false,
      reason: event.reason,
    );

    final latest = state;
    if (latest is! TeacherDashboardSuccess) return;

    result.fold(
      (failure) => emit(
        latest.copyWith(
          clearBookingRequestActionInProgress: true,
          bookingRequestFailure: failure,
        ),
      ),
      (aggregate) {
        _invalidateCache.invalidateSession(
          aggregate.id,
          teacherProfileId: aggregate.teacherId,
          studentId: aggregate.studentId,
        );
        emit(
          latest.copyWith(
            clearBookingRequestActionInProgress: true,
            pendingBookingRequests: latest.pendingBookingRequests
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
    final result = await _completeSession(
      sessionId: event.sessionId,
      actorRole: ActorRole.teacher,
    );
    result.fold(
      (_) => null,
      (aggregate) {
        _invalidateCache.invalidateSession(
          event.sessionId,
          teacherProfileId: aggregate.teacherId,
          studentId: aggregate.studentId,
        );
      },
    );
  }

  Future<void> _onJoinRequested(
    TeacherDashboardSessionJoinRequested event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    emit(
      current.copyWith(
        clearJoinFailure: true,
        joinInProgress: event.sessionId,
      ),
    );

    final result = await _joinSession(
      sessionId: event.sessionId,
      forceTakeover: event.forceTakeover,
    );

    final after = state;
    if (after is! TeacherDashboardSuccess) return;

    result.fold(
      (failure) => emit(
        after.copyWith(
          joinFailure: failure,
          clearJoinInProgress: true,
        ),
      ),
      (_) => emit(
        after.copyWith(
          clearJoinInProgress: true,
          joinCompletedSessionId: event.sessionId,
        ),
      ),
    );
  }

  Future<void> _onJoinCompletedAcknowledged(
    TeacherDashboardJoinCompletedAcknowledged event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    emit(current.copyWith(clearJoinCompletedSessionId: true));
  }
}
