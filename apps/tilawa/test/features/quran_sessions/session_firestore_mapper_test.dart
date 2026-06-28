import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'package:tilawa/features/quran_sessions/data/firebase/session_firestore_mapper.dart';

void main() {
  test('parseLifecycleStatus reads snake_case Firestore values', () {
    check(
      parseLifecycleStatus('pending_payment'),
    ).equals(SessionLifecycleStatus.pendingPayment);
    check(
      parseLifecycleStatus('teacher_no_show'),
    ).equals(SessionLifecycleStatus.teacherNoShow);
    check(
      parseLifecycleStatus('cancelled_by_student'),
    ).equals(SessionLifecycleStatus.cancelledByStudent);
  });

  test(
    'mapSessionDocToAggregate resolves stale lifecycle from legacy status',
    () {
      final aggregate = mapSessionDocToAggregate('oYSyETGrSlsdBw0ZEzfG', {
        'teacherId': 'teacher-1',
        'studentId': 'student-1',
        'startsAt': Timestamp.fromDate(DateTime.utc(2026, 7, 1, 9)),
        'status': 'cancelled',
        'cancelledByRole': 'teacher',
        'lifecycleStatus': 'scheduled',
      });

      check(aggregate.id).equals('oYSyETGrSlsdBw0ZEzfG');
      check(aggregate.sessionId).equals('oYSyETGrSlsdBw0ZEzfG');
      check(
        aggregate.lifecycleStatus,
      ).equals(SessionLifecycleStatus.cancelledByTeacher);
      check(
        SessionListClassifier.isTeacherDashboardUpcoming(
          QuranSession(
            id: aggregate.sessionId!,
            bookingId: aggregate.id,
            teacherId: aggregate.teacherId,
            studentId: aggregate.studentId,
            startsAt: aggregate.startsAt,
            endsAt: aggregate.startsAt.add(const Duration(minutes: 30)),
            callType: SessionCallType.videoCall,
            status: QuranSessionStatus.cancelledByTeacher,
            lifecycleStatus: aggregate.lifecycleStatus,
          ),
        ),
      ).isFalse();
    },
  );
}
