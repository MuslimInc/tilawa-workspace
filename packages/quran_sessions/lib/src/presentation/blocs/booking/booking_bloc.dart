import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_teacher_availability_usecase.dart';
import '../../../domain/usecases/submit_session_booking_usecase.dart';
import '../../../domain/usecases/validate_booking_eligibility_usecase.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({
    required this._getAvailability,
    required this._submitBooking,
    required this._validateEligibility,
  }) : super(const BookingInitial()) {
    on<BookingScreenOpened>(_onScreenOpened, transformer: restartable());
    on<BookingEligibilityRetried>(
      _onEligibilityRetried,
      transformer: restartable(),
    );
    on<SlotSelected>(_onSlotSelected, transformer: sequential());
    on<CallTypeSelected>(_onCallTypeSelected, transformer: sequential());
    on<BookingSubmitted>(_onSubmitted, transformer: droppable());
  }

  final GetTeacherAvailabilityUseCase _getAvailability;
  final SubmitSessionBookingUseCase _submitBooking;
  final ValidateBookingEligibilityUseCase _validateEligibility;

  Future<void> _onScreenOpened(
    BookingScreenOpened event,
    Emitter<BookingState> emit,
  ) => _checkEligibilityThenLoadSlots(
    teacherId: event.teacherId,
    studentId: event.studentId,
    from: event.from,
    to: event.to,
    emit: emit,
  );

  Future<void> _onEligibilityRetried(
    BookingEligibilityRetried event,
    Emitter<BookingState> emit,
  ) => _checkEligibilityThenLoadSlots(
    teacherId: event.teacherId,
    studentId: event.studentId,
    from: event.from,
    to: event.to,
    emit: emit,
  );

  Future<void> _checkEligibilityThenLoadSlots({
    required String teacherId,
    required String studentId,
    required DateTime from,
    required DateTime to,
    required Emitter<BookingState> emit,
  }) async {
    emit(const BookingEligibilityChecking());

    final eligibility = await _validateEligibility(
      teacherId: teacherId,
      studentId: studentId,
    );

    if (eligibility.isLeft()) {
      eligibility.fold((f) => emit(BookingFailure(f)), (_) {});
      return;
    }

    emit(const BookingSlotsLoading());

    final result = await _getAvailability(teacherId, from: from, to: to);

    result.fold(
      (failure) => emit(BookingFailure(failure)),
      (slots) => emit(
        BookingSelecting(
          teacherId: teacherId,
          availableSlots: slots.where((s) => !s.isBooked).toList(),
        ),
      ),
    );
  }

  void _onSlotSelected(SlotSelected event, Emitter<BookingState> emit) {
    final current = state;
    if (current is! BookingSelecting) return;
    emit(current.copyWith(selectedSlot: event.slot));
  }

  void _onCallTypeSelected(CallTypeSelected event, Emitter<BookingState> emit) {
    final current = state;
    if (current is! BookingSelecting) return;
    emit(current.copyWith(selectedCallType: event.callType));
  }

  Future<void> _onSubmitted(
    BookingSubmitted event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingSubmitting());

    final result = await _submitBooking(
      teacherId: event.teacherId,
      slotId: event.slotId,
      callType: event.callType,
      paymentReference: event.paymentReference,
      studentNote: event.note,
    );

    result.fold(
      (failure) => emit(BookingFailure(failure)),
      (booking) => emit(BookingSuccess(booking)),
    );
  }
}
