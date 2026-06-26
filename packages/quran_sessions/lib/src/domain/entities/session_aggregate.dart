import 'package:equatable/equatable.dart';

import 'session_lifecycle_status.dart';
import 'session_pricing_type.dart';

/// Canonical booking+session aggregate used by lifecycle use cases.
class SessionAggregate extends Equatable {
  const SessionAggregate({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.slotId,
    required this.startsAt,
    required this.pricingType,
    required this.lifecycleStatus,
    required this.createdAt,
    required this.updatedAt,
    this.rescheduleCount = 0,
    this.cancellationReason,
    this.lastActionReason,
    this.rejectionReason,
    this.paymentReference,
    this.sessionId,
  });

  final String id;
  final String teacherId;
  final String studentId;
  final String slotId;
  final DateTime startsAt;
  final SessionPricingType pricingType;
  final SessionLifecycleStatus lifecycleStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int rescheduleCount;
  final String? cancellationReason;
  final String? lastActionReason;
  final String? rejectionReason;
  final String? paymentReference;

  /// Linked operational session document id (from booking).
  final String? sessionId;

  bool get isPaid => pricingType == SessionPricingType.fixedPerSession;

  SessionAggregate copyWith({
    SessionLifecycleStatus? lifecycleStatus,
    DateTime? startsAt,
    DateTime? updatedAt,
    int? rescheduleCount,
    String? cancellationReason,
    String? lastActionReason,
    String? rejectionReason,
    String? paymentReference,
    String? sessionId,
  }) {
    return SessionAggregate(
      id: id,
      teacherId: teacherId,
      studentId: studentId,
      slotId: slotId,
      startsAt: startsAt ?? this.startsAt,
      pricingType: pricingType,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      lastActionReason: lastActionReason ?? this.lastActionReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      paymentReference: paymentReference ?? this.paymentReference,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    teacherId,
    studentId,
    slotId,
    startsAt,
    pricingType,
    lifecycleStatus,
    createdAt,
    updatedAt,
    rescheduleCount,
    cancellationReason,
    lastActionReason,
    rejectionReason,
    paymentReference,
    sessionId,
  ];
}
