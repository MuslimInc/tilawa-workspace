import 'package:equatable/equatable.dart';

import '../../../domain/policies/session_mode_policy.dart';
import '../../../domain/entities/quran_booking.dart';
import '../../../domain/entities/session_booking_outcome.dart';
import '../../../domain/entities/manual_payment_price.dart';
import '../../../domain/entities/session_call_type.dart';
import '../../../domain/entities/session_price.dart';
import '../../../domain/entities/session_pricing_type.dart';
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

/// Eligibility is being validated before slot loading starts.
final class BookingEligibilityChecking extends BookingState {
  const BookingEligibilityChecking();
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
    this.selectedCallType = SessionCallType.voiceCall,
    this.teacherExternalMeetingUrl,
    this.pricingType,
    this.sessionPrice,
    this.manualPaymentPrice,
  });

  final String teacherId;
  final List<TeacherAvailability> availableSlots;
  final TeacherAvailability? selectedSlot;
  final SessionCallType selectedCallType;
  final String? teacherExternalMeetingUrl;
  final SessionPricingType? pricingType;
  final SessionPrice? sessionPrice;

  /// Presentation-only manual/off-app price (Egypt pilot). When set the booking
  /// screen shows a paid-session notice instead of the free price summary.
  final ManualPaymentPrice? manualPaymentPrice;

  bool get hasExternalMeetingUrl =>
      SessionModePolicy.hasExternalMeetingUrl(teacherExternalMeetingUrl);

  bool get canSubmit => selectedSlot != null;

  @override
  List<Object?> get props => [
    teacherId,
    availableSlots,
    selectedSlot,
    selectedCallType,
    teacherExternalMeetingUrl,
    pricingType,
    sessionPrice,
    manualPaymentPrice,
  ];

  BookingSelecting copyWith({
    List<TeacherAvailability>? availableSlots,
    TeacherAvailability? selectedSlot,
    SessionCallType? selectedCallType,
    String? teacherExternalMeetingUrl,
    SessionPricingType? pricingType,
    SessionPrice? sessionPrice,
    ManualPaymentPrice? manualPaymentPrice,
  }) => BookingSelecting(
    teacherId: teacherId,
    availableSlots: availableSlots ?? this.availableSlots,
    selectedSlot: selectedSlot ?? this.selectedSlot,
    selectedCallType: selectedCallType ?? this.selectedCallType,
    teacherExternalMeetingUrl:
        teacherExternalMeetingUrl ?? this.teacherExternalMeetingUrl,
    pricingType: pricingType ?? this.pricingType,
    sessionPrice: sessionPrice ?? this.sessionPrice,
    manualPaymentPrice: manualPaymentPrice ?? this.manualPaymentPrice,
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

/// Paid booking created server-side; awaiting sandbox/PSP confirmation.
final class BookingPaymentRequired extends BookingState {
  const BookingPaymentRequired(
    this.outcome, {
    this.pricingType,
    this.sessionPrice,
  });

  final SessionBookingOutcome outcome;
  final SessionPricingType? pricingType;
  final SessionPrice? sessionPrice;

  @override
  List<Object?> get props => [outcome, pricingType, sessionPrice];
}

final class BookingFailure extends BookingState {
  const BookingFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
