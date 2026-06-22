import 'package:quran_sessions/quran_sessions.dart';

SessionAggregate makeAggregate({
  String id = 'session_1',
  SessionLifecycleStatus status = SessionLifecycleStatus.scheduled,
  SessionPricingType pricingType = SessionPricingType.fixedPerSession,
  DateTime? startsAt,
  int rescheduleCount = 0,
  String slotId = 'slot_1',
  String? paymentReference = 'pay_1',
}) {
  final now = DateTime.utc(2026, 1, 1, 10);
  return SessionAggregate(
    id: id,
    teacherId: 'teacher_1',
    studentId: 'student_1',
    slotId: slotId,
    startsAt: startsAt ?? now.add(const Duration(days: 2)),
    pricingType: pricingType,
    lifecycleStatus: status,
    createdAt: now,
    updatedAt: now,
    rescheduleCount: rescheduleCount,
    paymentReference: paymentReference,
  );
}
