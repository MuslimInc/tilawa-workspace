import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('SessionListClassifier', () {
    test('teacher dashboard upcoming excludes tutor-cancelled sessions', () {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.cancelledByTeacher,
      );

      check(
        SessionListClassifier.isTeacherDashboardUpcoming(session),
      ).isFalse();
    });

    test('teacher dashboard upcoming excludes student-cancelled sessions', () {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.cancelledByStudent,
      );

      check(
        SessionListClassifier.isTeacherDashboardUpcoming(session),
      ).isFalse();
    });

    test('teacher dashboard upcoming excludes completed sessions', () {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.completed,
      );

      check(
        SessionListClassifier.isTeacherDashboardUpcoming(session),
      ).isFalse();
    });

    test('teacher dashboard upcoming includes scheduled sessions', () {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.scheduled,
      );

      check(SessionListClassifier.isTeacherDashboardUpcoming(session)).isTrue();
    });

    test('isCancelledSession detects legacy status field', () {
      final session = makeSession(
        status: QuranSessionStatus.cancelledByTeacher,
        lifecycleStatus: null,
      );

      check(SessionListClassifier.isCancelledSession(session)).isTrue();
    });

    test(
      'student upcoming excludes rejected expired and no-show terminals',
      () {
        const excluded = [
          SessionLifecycleStatus.rejectedByTutor,
          SessionLifecycleStatus.expired,
          SessionLifecycleStatus.teacherNoShow,
          SessionLifecycleStatus.studentNoShow,
          SessionLifecycleStatus.bothNoShow,
          SessionLifecycleStatus.pendingTutorApproval,
          SessionLifecycleStatus.pendingPayment,
        ];
        for (final status in excluded) {
          final session = makeSession(lifecycleStatus: status);
          check(SessionListClassifier.isStudentUpcoming(session)).isFalse();
        }
      },
    );

    test('student upcoming includes rescheduled and in-progress sessions', () {
      for (final status in [
        SessionLifecycleStatus.rescheduled,
        SessionLifecycleStatus.inProgress,
        SessionLifecycleStatus.confirmed,
      ]) {
        final session = makeSession(lifecycleStatus: status);
        check(SessionListClassifier.isStudentUpcoming(session)).isTrue();
      }
    });

    test('student pending includes payment and tutor approval states', () {
      for (final status in [
        SessionLifecycleStatus.pendingTutorApproval,
        SessionLifecycleStatus.pendingPayment,
      ]) {
        final session = makeSession(lifecycleStatus: status);
        check(SessionListClassifier.isStudentPending(session)).isTrue();
        check(SessionListClassifier.isStudentUpcoming(session)).isFalse();
      }
    });
  });
}
