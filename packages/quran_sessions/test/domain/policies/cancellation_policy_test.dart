import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('ConfigurableCancellationPolicy', () {
    test('T-C01 student early cancel gives full refund', () {
      final now = DateTime.utc(2026, 1, 1, 10);
      final policy = ConfigurableCancellationPolicy(now: () => now);
      final result = policy.evaluate(
        actor: ActorRole.student,
        sessionStartsAt: now.add(const Duration(hours: 48)),
        pricingType: SessionPricingType.fixedPerSession,
      );

      result.fold(
        (_) => fail('expected Right'),
        (decision) => check(decision.refundFraction).equals(1),
      );
    });

    test('T-C03 student cancel exactly 24h still full refund', () {
      final now = DateTime.utc(2026, 1, 1, 10);
      final policy = ConfigurableCancellationPolicy(now: () => now);
      final result = policy.evaluate(
        actor: ActorRole.student,
        sessionStartsAt: now.add(const Duration(hours: 24)),
        pricingType: SessionPricingType.fixedPerSession,
      );

      result.fold(
        (_) => fail('expected Right'),
        (decision) => check(decision.refundFraction).equals(1),
      );
    });

    test('T-C06 student cancel inside min notice blocked', () {
      final now = DateTime.utc(2026, 1, 1, 10);
      final policy = ConfigurableCancellationPolicy(now: () => now);
      final result = policy.evaluate(
        actor: ActorRole.student,
        sessionStartsAt: now.add(const Duration(minutes: 30)),
        pricingType: SessionPricingType.fixedPerSession,
      );

      result.fold(
        (failure) => check(failure).isA<PolicyViolationFailure>(),
        (_) => fail('expected Left'),
      );
    });

    test('T-C07 market override late refund fraction applied', () {
      final now = DateTime.utc(2026, 1, 1, 10);
      final policy = ConfigurableCancellationPolicy(
        now: () => now,
        config: const CancellationPolicyConfig(marketLateRefundFraction: 0.5),
      );
      final result = policy.evaluate(
        actor: ActorRole.student,
        sessionStartsAt: now.add(const Duration(hours: 12)),
        pricingType: SessionPricingType.fixedPerSession,
      );

      result.fold(
        (_) => fail('expected Right'),
        (decision) => check(decision.refundFraction).equals(0.5),
      );
    });
  });
}
