import 'package:equatable/equatable.dart';

import '../../../domain/entities/quran_booking.dart';
import '../../../domain/entities/session_call_type.dart';
import '../../../domain/entities/teacher_availability.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

sealed class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

final class BookingInitial extends BookingState {
  const BookingInitial();
}

final class BookingSlotsLoading extends BookingState {
  const BookingSlotsLoading();
}

/// Slots loaded; user is actively selecting a slot and call type.
final class BookingSelecting extends BookingState {
  const BookingSelecting({
    required this.teacherId,
    required this.availableSlots,
    this.selectedSlot,
    this.selectedCallType = SessionCallType.externalMeeting,
  });

  final String teacherId;
  final List<TeacherAvailability> availableSlots;
  final TeacherAvailability? selectedSlot;
  final SessionCallType selectedCallType;

  bool get canSubmit => selectedSlot != null;

  @override
  List<Object?> get props => [
    teacherId,
    availableSlots,
    selectedSlot,
    selectedCallType,
  ];

  BookingSelecting copyWith({
    List<TeacherAvailability>? availableSlots,
    TeacherAvailability? selectedSlot,
    SessionCallType? selectedCallType,
  }) => BookingSelecting(
    teacherId: teacherId,
    availableSlots: availableSlots ?? this.availableSlots,
    selectedSlot: selectedSlot ?? this.selectedSlot,
    selectedCallType: selectedCallType ?? this.selectedCallType,
  );
}

/// Payment / network request in flight after the user taps confirm.
final class BookingSubmitting extends BookingState {
  const BookingSubmitting();
}

final class BookingSuccess extends BookingState {
  const BookingSuccess(this.booking);

  final QuranBooking booking;

  @override
  List<Object?> get props => [booking];
}

final class BookingFailure extends BookingState {
  const BookingFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
