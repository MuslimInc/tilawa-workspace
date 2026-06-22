import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('ConfigurableReschedulePolicy', () {
    test('T-R01 first reschedule above notice allowed', () {
      final now = DateTime.utc(2026, 1, 1, 10);
      final policy = ConfigurableReschedulePolicy(now: () => now);
      final result = policy.validate(
        startsAt: now.add(const Duration(hours: 30)),
        currentRescheduleCount: 0,
      );
      check(result.isRight()).isTrue();
    });

    test('T-R02 second reschedule blocked', () {
      final now = DateTime.utc(2026, 1, 1, 10);
      final policy = ConfigurableReschedulePolicy(now: () => now);
      final result = policy.validate(
        startsAt: now.add(const Duration(hours: 30)),
        currentRescheduleCount: 1,
      );
      check(result.isLeft()).isTrue();
    });

    test('T-R03 reschedule inside 24h blocked', () {
      final now = DateTime.utc(2026, 1, 1, 10);
      final policy = ConfigurableReschedulePolicy(now: () => now);
      final result = policy.validate(
        startsAt: now.add(const Duration(hours: 12)),
        currentRescheduleCount: 0,
      );
      result.fold(
        (failure) => check(failure).isA<PolicyViolationFailure>(),
        (_) => fail('expected Left'),
      );
    });
  });
}
