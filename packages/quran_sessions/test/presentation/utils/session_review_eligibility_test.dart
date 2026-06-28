import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('isSessionEligibleForStudentReview', () {
    test('returns true for completed lifecycle status', () {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.completed,
        startsAt: DateTime.now().subtract(const Duration(days: 2)),
        endsAt: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
      );

      check(isSessionEligibleForStudentReview(session)).isTrue();
    });

    test('returns true for past session with completed legacy status', () {
      final start = DateTime.now().subtract(const Duration(days: 2));
      final session = makeSession(
        status: QuranSessionStatus.completed,
        startsAt: start,
        endsAt: start.add(const Duration(hours: 1)),
      );

      check(isSessionEligibleForStudentReview(session)).isTrue();
    });

    test('returns false for upcoming scheduled session', () {
      final session = makeSession(
        status: QuranSessionStatus.scheduled,
        lifecycleStatus: SessionLifecycleStatus.scheduled,
      );

      check(isSessionEligibleForStudentReview(session)).isFalse();
    });
  });
}
