import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('SessionInProgressTransitionPolicy', () {
    final startsAt = DateTime.utc(2026, 7, 1, 12);

    test('requires join event at or after startsAt', () {
      check(
        SessionInProgressTransitionPolicy.shouldTransitionToInProgress(
          startsAt: startsAt,
          now: startsAt,
          hasJoinEventAtOrAfterStart: false,
        ),
      ).isFalse();
    });

    test('transitions when join logged and startsAt reached', () {
      check(
        SessionInProgressTransitionPolicy.shouldTransitionToInProgress(
          startsAt: startsAt,
          now: startsAt.add(const Duration(minutes: 1)),
          hasJoinEventAtOrAfterStart: true,
        ),
      ).isTrue();
    });
  });
}
