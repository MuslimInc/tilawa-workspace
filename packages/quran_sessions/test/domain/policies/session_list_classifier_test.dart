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
  });
}
