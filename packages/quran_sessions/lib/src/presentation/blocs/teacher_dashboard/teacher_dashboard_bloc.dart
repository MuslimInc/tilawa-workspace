import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../boundaries/scheduling/availability_provider.dart';
import '../../../domain/entities/quran_session.dart';
import '../../../domain/entities/teacher_availability.dart';
import '../../../domain/usecases/get_teacher_availability_usecase.dart';
import '../../../domain/usecases/get_teacher_sessions_usecase.dart';
import 'teacher_dashboard_event.dart';
import 'teacher_dashboard_state.dart';

class TeacherDashboardBloc
    extends Bloc<TeacherDashboardEvent, TeacherDashboardState> {
  TeacherDashboardBloc({
    required this._getTeacherSessions,
    required this._getAvailability,
    required this._availabilityProvider,
  }) : super(const TeacherDashboardInitial()) {
    on<TeacherDashboardLoadRequested>(
      _onLoadRequested,
      transformer: restartable(),
    );
    on<AvailabilityUpdated>(_onAvailabilityUpdated, transformer: sequential());
    on<AvailabilitySlotAdded>(_onSlotAdded, transformer: sequential());
    on<AvailabilitySlotEdited>(_onSlotEdited, transformer: sequential());
    on<AvailabilitySlotRemoved>(_onSlotRemoved, transformer: sequential());
  }

  final GetTeacherSessionsUseCase _getTeacherSessions;
  final GetTeacherAvailabilityUseCase _getAvailability;
  final AvailabilityProvider _availabilityProvider;

  Future<void> _onLoadRequested(
    TeacherDashboardLoadRequested event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    emit(const TeacherDashboardLoading());

    final now = DateTime.now();

    final sessionsResult = await _getTeacherSessions(event.teacherId);
    final availResult = await _getAvailability(
      event.teacherId,
      from: now,
      to: now.add(const Duration(days: 14)),
    );

    // Surface the first failure encountered.
    if (sessionsResult.isLeft) {
      sessionsResult.fold(
        (f) => emit(TeacherDashboardFailure(f)),
        (_) {},
      );
      return;
    }
    if (availResult.isLeft) {
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
          availability: [...current.availability, event.slot],
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
    if (removeResult.isLeft) {
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
        final updated = current.availability.map((s) {
          return s.slotId == event.original.slotId ? event.updated : s;
        }).toList();
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

  Future<void> _onSlotRemoved(
    AvailabilitySlotRemoved event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    final current = state;
    if (current is! TeacherDashboardSuccess) return;

    emit(
      current.copyWith(isUpdatingAvailability: true, clearSlotFailure: true),
    );

    final result = await _availabilityProvider.withdrawSlot(event.slotId);

    result.fold(
      (failure) => emit(
        current.copyWith(
          isUpdatingAvailability: false,
          slotFailure: failure,
        ),
      ),
      (_) => emit(
        current.copyWith(
          availability: current.availability
              .where((s) => s.slotId != event.slotId)
              .toList(),
          isUpdatingAvailability: false,
          clearSlotFailure: true,
        ),
      ),
    );
  }
}
