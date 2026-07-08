import '../entities/quran_booking.dart';
import '../entities/session_aggregate.dart';
import '../entities/session_call_type.dart';
import '../entities/session_lifecycle_status.dart';

/// Maps lifecycle aggregates to legacy booking entities for presentation.
QuranBooking aggregateToQuranBooking(SessionAggregate aggregate) {
  return QuranBooking(
    id: aggregate.id,
    teacherId: aggregate.teacherId,
    studentId: aggregate.studentId,
    slotId: aggregate.slotId,
    requestedCallType: SessionCallType.externalMeeting,
    pricingType: aggregate.pricingType,
    status: _legacyBookingStatus(aggregate.lifecycleStatus),
    createdAt: aggregate.createdAt,
    lifecycleStatus: aggregate.lifecycleStatus,
    paymentReference: aggregate.paymentReference,
    sessionId: aggregate.sessionId,
  );
}

BookingStatus _legacyBookingStatus(SessionLifecycleStatus status) {
  return switch (status) {
    SessionLifecycleStatus.pendingPayment => BookingStatus.pending,
    SessionLifecycleStatus.scheduled ||
    SessionLifecycleStatus.confirmed ||
    SessionLifecycleStatus.rescheduled => BookingStatus.confirmed,
    SessionLifecycleStatus.cancelledByStudent ||
    SessionLifecycleStatus.cancelledByTeacher ||
    SessionLifecycleStatus.cancelledByAdmin => BookingStatus.cancelled,
    SessionLifecycleStatus.completed => BookingStatus.completed,
    SessionLifecycleStatus.refunded => BookingStatus.refunded,
    SessionLifecycleStatus.expired => BookingStatus.rejected,
    _ => BookingStatus.pending,
  };
}
