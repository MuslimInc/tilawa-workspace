import 'package:equatable/equatable.dart';

import '../../../domain/entities/session_call_type.dart';
import '../../../domain/entities/teacher_availability.dart';

sealed class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

/// Screen mounted — validate eligibility then load available slots.
final class BookingScreenOpened extends BookingEvent {
  const BookingScreenOpened({
    required this.teacherId,
    required this.studentId,
    required this.from,
    required this.to,
  });

  final String teacherId;
  final String studentId;
  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [teacherId, studentId, from, to];
}

/// Re-run eligibility check after the student completes their profile.
final class BookingEligibilityRetried extends BookingEvent {
  const BookingEligibilityRetried({
    required this.teacherId,
    required this.studentId,
    required this.from,
    required this.to,
  });

  final String teacherId;
  final String studentId;
  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [teacherId, studentId, from, to];
}

/// User taps a time slot in the picker.
final class SlotSelected extends BookingEvent {
  const SlotSelected(this.slot);

  final TeacherAvailability slot;

  @override
  List<Object?> get props => [slot];
}

/// User changes the call type toggle (external / voice / video).
final class CallTypeSelected extends BookingEvent {
  const CallTypeSelected(this.callType);

  final SessionCallType callType;

  @override
  List<Object?> get props => [callType];
}

/// User taps "Confirm Booking".
/// [paymentReference] is null for free sessions.
final class BookingSubmitted extends BookingEvent {
  const BookingSubmitted({
    required this.teacherId,
    required this.slotId,
    required this.callType,
    this.paymentReference,
    this.note,
  });

  final String teacherId;
  final String slotId;
  final SessionCallType callType;
  final String? paymentReference;
  final String? note;

  @override
  List<Object?> get props => [
    teacherId,
    slotId,
    callType,
    paymentReference,
    note,
  ];
}
