import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_teacher_availability_usecase.dart';
import '../../../domain/usecases/request_session_reschedule_via_server_usecase.dart';
import '../../../domain/value_objects/actor_role.dart';
import 'reschedule_event.dart';
import 'reschedule_state.dart';

class RescheduleBloc extends Bloc<RescheduleEvent, RescheduleState> {
  RescheduleBloc({
    required this._getAvailability,
    required this._requestReschedule,
  }) : super(const RescheduleInitial()) {
    on<RescheduleLoadRequested>(_onLoadRequested, transformer: restartable());
    on<RescheduleSlotSelected>(_onSlotSelected, transformer: sequential());
    on<RescheduleReasonChanged>(_onReasonChanged, transformer: sequential());
    on<RescheduleSubmitted>(_onSubmitted, transformer: droppable());
  }

  final GetTeacherAvailabilityUseCase _getAvailability;
  final RequestSessionRescheduleViaServerUseCase _requestReschedule;

  Future<void> _onLoadRequested(
    RescheduleLoadRequested event,
    Emitter<RescheduleState> emit,
  ) async {
    emit(const RescheduleLoading());
    final result = await _getAvailability(
      event.teacherId,
      from: event.from,
      to: event.to,
    );
    result.fold(
      (failure) => emit(RescheduleFailure(failure)),
      (slots) => emit(
        RescheduleSelecting(
          bookingId: event.bookingId,
          teacherId: event.teacherId,
          availableSlots: slots.where((s) => !s.isBooked).toList(),
        ),
      ),
    );
  }

  void _onSlotSelected(
    RescheduleSlotSelected event,
    Emitter<RescheduleState> emit,
  ) {
    final current = state;
    if (current is! RescheduleSelecting) return;
    emit(current.copyWith(selectedSlot: event.slot));
  }

  void _onReasonChanged(
    RescheduleReasonChanged event,
    Emitter<RescheduleState> emit,
  ) {
    final current = state;
    if (current is! RescheduleSelecting) return;
    emit(current.copyWith(reason: event.reason));
  }

  Future<void> _onSubmitted(
    RescheduleSubmitted event,
    Emitter<RescheduleState> emit,
  ) async {
    final current = state;
    if (current is! RescheduleSelecting || !current.canSubmit) return;
    final slot = current.selectedSlot!;

    emit(const RescheduleSubmitting());
    final result = await _requestReschedule(
      bookingId: event.bookingId,
      newSlotId: slot.slotId,
      newStartsAt: slot.startsAt,
      reason: current.reason.trim(),
      actorRole: ActorRole.student,
    );
    result.fold(
      (failure) => emit(RescheduleFailure(failure)),
      (value) => emit(RescheduleSuccess(requestId: value.requestId)),
    );
  }
}
