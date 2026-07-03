import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('SessionJoinWindowPolicy', () {
    const policy = SessionJoinWindowPolicy();
    final startsAt = DateTime.utc(2026, 7, 1, 12);
    final endsAt = DateTime.utc(2026, 7, 1, 13);

    test('rejects join more than 15 minutes before start', () {
      final now = startsAt.subtract(const Duration(minutes: 16));
      check(
        policy.isWithinJoinWindow(startsAt: startsAt, endsAt: endsAt, now: now),
      ).isFalse();
    });

    test('allows join 15 minutes before start through endsAt', () {
      final atWindowOpen = startsAt.subtract(const Duration(minutes: 15));
      final atEnd = endsAt;
      check(
        policy.isWithinJoinWindow(
          startsAt: startsAt,
          endsAt: endsAt,
          now: atWindowOpen,
        ),
      ).isTrue();
      check(
        policy.isWithinJoinWindow(
          startsAt: startsAt,
          endsAt: endsAt,
          now: atEnd,
        ),
      ).isTrue();
    });

    test('rejects join after endsAt', () {
      final now = endsAt.add(const Duration(seconds: 1));
      check(
        policy.isWithinJoinWindow(startsAt: startsAt, endsAt: endsAt, now: now),
      ).isFalse();
    });
  });
}
