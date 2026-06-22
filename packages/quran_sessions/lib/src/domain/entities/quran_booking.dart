import 'package:equatable/equatable.dart';

import 'legacy_status_lifecycle_mapper.dart';
import 'session_call_type.dart';
import 'session_lifecycle_status.dart';
import 'session_pricing_type.dart';

/// Lifecycle of a booking request.
enum BookingStatus {
  pending,
  confirmed,
  rejected,
  cancelled,
  completed,
  refunded,
}

/// A student's request to book a session with a teacher.
class QuranBooking extends Equatable {
  const QuranBooking({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.slotId,
    required this.requestedCallType,
    required this.pricingType,
    required this.status,
    required this.createdAt,
    this.lifecycleStatus,
    this.amountPaidUsd,
    this.paymentReference,
    this.sessionId,
    this.studentNote,
  });

  final String id;
  final String teacherId;
  final String studentId;
  final String slotId;
  final SessionCallType requestedCallType;
  final SessionPricingType pricingType;
  final BookingStatus status;
  final DateTime createdAt;
  final SessionLifecycleStatus? lifecycleStatus;

  /// Null for free sessions.
  final double? amountPaidUsd;

  /// Opaque reference from the payment provider — package never inspects this.
  final String? paymentReference;

  /// Set once the session is created from a confirmed booking.
  final String? sessionId;

  final String? studentNote;

  /// Canonical lifecycle status with backwards-compatible fallback.
  SessionLifecycleStatus get effectiveLifecycleStatus =>
      lifecycleStatus ?? status.toLifecycleStatus();

  @override
  List<Object?> get props => [
    id,
    teacherId,
    studentId,
    slotId,
    requestedCallType,
    pricingType,
    status,
    createdAt,
    lifecycleStatus,
    amountPaidUsd,
    paymentReference,
    sessionId,
    studentNote,
  ];
}
