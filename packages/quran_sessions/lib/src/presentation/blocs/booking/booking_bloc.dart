import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/create_booking_usecase.dart';
import '../../../domain/usecases/get_teacher_availability_usecase.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({
    required this._getAvailability,
    required this._createBooking,
  }) : super(const BookingInitial()) {
    on<BookingScreenOpened>(_onScreenOpened, transformer: restartable());
    on<SlotSelected>(_onSlotSelected, transformer: sequential());
    on<CallTypeSelected>(_onCallTypeSelected, transformer: sequential());
    on<BookingSubmitted>(_onSubmitted, transformer: droppable());
  }

  final GetTeacherAvailabilityUseCase _getAvailability;
  final CreateBookingUseCase _createBooking;

  Future<void> _onScreenOpened(
    BookingScreenOpened event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingSlotsLoading());

    final result = await _getAvailability(
      event.teacherId,
      from: event.from,
      to: event.to,
    );

    result.fold(
      (failure) => emit(BookingFailure(failure)),
      (slots) => emit(
        BookingSelecting(
          teacherId: event.teacherId,
          availableSlots: slots.where((s) => !s.isBooked).toList(),
        ),
      ),
    );
  }

  void _onSlotSelected(
    SlotSelected event,
    Emitter<BookingState> emit,
  ) {
    final current = state;
    if (current is! BookingSelecting) return;
    emit(current.copyWith(selectedSlot: event.slot));
  }

  void _onCallTypeSelected(
    CallTypeSelected event,
    Emitter<BookingState> emit,
  ) {
    final current = state;
    if (current is! BookingSelecting) return;
    emit(current.copyWith(selectedCallType: event.callType));
  }

  Future<void> _onSubmitted(
    BookingSubmitted event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingSubmitting());

    final result = await _createBooking(
      teacherId: event.teacherId,
      slotId: event.slotId,
      requestedCallTypeId: event.callType.name,
      paymentReference: event.paymentReference,
      studentNote: event.note,
    );

    result.fold(
      (failure) => emit(BookingFailure(failure)),
      (booking) => emit(BookingSuccess(booking)),
    );
  }
}
