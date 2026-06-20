import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/boundaries/scheduling/cancellation_policy.dart';

void main() {
  const policy = StandardCancellationPolicy();

  group('StandardCancellationPolicy', () {
    test('full refund when cancelled more than 24 h before session', () {
      final sessionStart = DateTime.now().add(const Duration(hours: 48));
      final cancelledAt = DateTime.now();

      check(
        policy.refundFraction(
          sessionStartsAt: sessionStart,
          cancelledAt: cancelledAt,
        ),
      ).equals(1.0);
    });

    test('no refund when cancelled within 24 h of session', () {
      final sessionStart = DateTime.now().add(const Duration(hours: 12));
      final cancelledAt = DateTime.now();

      check(
        policy.refundFraction(
          sessionStartsAt: sessionStart,
          cancelledAt: cancelledAt,
        ),
      ).equals(0.0);
    });

    test('no refund at exactly 24 h boundary', () {
      final sessionStart = DateTime.now().add(const Duration(hours: 24));
      final cancelledAt = DateTime.now().add(const Duration(minutes: 1));

      check(
        policy.refundFraction(
          sessionStartsAt: sessionStart,
          cancelledAt: cancelledAt,
        ),
      ).equals(0.0);
    });
  });
}
