import 'package:equatable/equatable.dart';

import '../../../domain/policies/session_mode_policy.dart';
import '../../../domain/entities/booking_block_reason.dart';
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
    this.teacherDisplayName,
    this.teacherExternalMeetingUrl,
    this.pricingType,
    this.sessionPrice,
    this.manualPaymentPrice,
    this.paymentProviderAvailable,
    this.blockReason = BookingBlockReason.none,
    this.isQuoteLoading = false,
  });

  final String teacherId;
  final List<TeacherAvailability> availableSlots;
  final TeacherAvailability? selectedSlot;
  final SessionCallType selectedCallType;
  final String? teacherDisplayName;
  final String? teacherExternalMeetingUrl;
  final SessionPricingType? pricingType;
  final SessionPrice? sessionPrice;

  /// Presentation-only manual/off-app price (Egypt pilot). When set the booking
  /// screen shows a paid-session notice instead of the free price summary.
  final ManualPaymentPrice? manualPaymentPrice;

  /// Server quote signal; null when no quote was obtained (client preview).
  final bool? paymentProviderAvailable;

  /// Typed block reason. Backend reasons are authoritative; transport-level
  /// quote failures use [BookingBlockReason.pricingQuoteUnavailable] so Flutter
  /// never derives final paid/free state from a market-only preview.
  final BookingBlockReason blockReason;

  /// True while the server pricing quote is still in flight. The screen shows
  /// the teacher + slots immediately with a dedicated price-section loading
  /// state; submit stays disabled until the quote resolves.
  final bool isQuoteLoading;

  bool get hasExternalMeetingUrl =>
      SessionModePolicy.hasExternalMeetingUrl(teacherExternalMeetingUrl);

  /// True when the booking screen must show a block banner and disable submit.
  /// Derived from [blockReason] — never inferred from loose payment booleans,
  /// so admin-disabled / pricing-missing / market-disabled /
  /// teacher-not-bookable / quote-unavailable each get distinct copy.
  bool get isPaymentBlocked => blockReason != BookingBlockReason.none;

  bool get canSubmit =>
      selectedSlot != null &&
      !isQuoteLoading &&
      blockReason == BookingBlockReason.none;

  @override
  List<Object?> get props => [
    teacherId,
    availableSlots,
    selectedSlot,
    selectedCallType,
    teacherDisplayName,
    teacherExternalMeetingUrl,
    pricingType,
    sessionPrice,
    manualPaymentPrice,
    paymentProviderAvailable,
    blockReason,
    isQuoteLoading,
  ];

  BookingSelecting copyWith({
    List<TeacherAvailability>? availableSlots,
    TeacherAvailability? selectedSlot,
    SessionCallType? selectedCallType,
    String? teacherDisplayName,
    String? teacherExternalMeetingUrl,
    SessionPricingType? pricingType,
    SessionPrice? sessionPrice,
    ManualPaymentPrice? manualPaymentPrice,
    bool? paymentProviderAvailable,
    BookingBlockReason? blockReason,
    bool? isQuoteLoading,
  }) => BookingSelecting(
    teacherId: teacherId,
    availableSlots: availableSlots ?? this.availableSlots,
    selectedSlot: selectedSlot ?? this.selectedSlot,
    selectedCallType: selectedCallType ?? this.selectedCallType,
    teacherDisplayName: teacherDisplayName ?? this.teacherDisplayName,
    teacherExternalMeetingUrl:
        teacherExternalMeetingUrl ?? this.teacherExternalMeetingUrl,
    pricingType: pricingType ?? this.pricingType,
    sessionPrice: sessionPrice ?? this.sessionPrice,
    manualPaymentPrice: manualPaymentPrice ?? this.manualPaymentPrice,
    paymentProviderAvailable:
        paymentProviderAvailable ?? this.paymentProviderAvailable,
    blockReason: blockReason ?? this.blockReason,
    isQuoteLoading: isQuoteLoading ?? this.isQuoteLoading,
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

/// Manual/off-app booking created and awaiting payment review.
final class BookingManualPaymentPending extends BookingState {
  const BookingManualPaymentPending({
    required this.booking,
    required this.paymentReference,
    required this.teacherDisplayName,
    required this.startsAt,
    this.sessionPrice,
  });

  final QuranBooking booking;
  final String paymentReference;
  final String teacherDisplayName;
  final DateTime startsAt;
  final SessionPrice? sessionPrice;

  @override
  List<Object?> get props => [
    booking,
    paymentReference,
    teacherDisplayName,
    startsAt,
    sessionPrice,
  ];
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
