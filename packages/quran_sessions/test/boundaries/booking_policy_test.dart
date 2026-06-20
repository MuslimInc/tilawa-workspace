import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/boundaries/scheduling/booking_policy.dart';

void main() {
  const policy = DefaultBookingPolicy();

  group('DefaultBookingPolicy', () {
    test('allows booking more than 1 hour in advance', () {
      final slotStart = DateTime.now().add(const Duration(hours: 2));

      final reason = policy.validate(
        studentId: 's1',
        teacherId: 't1',
        slotId: 'slot1',
        slotStartsAt: slotStart,
      );

      check(reason).isNull();
    });

    test('blocks booking less than 1 hour in advance', () {
      final slotStart = DateTime.now().add(const Duration(minutes: 30));

      final reason = policy.validate(
        studentId: 's1',
        teacherId: 't1',
        slotId: 'slot1',
        slotStartsAt: slotStart,
      );

      check(reason).isNotNull();
    });
  });
}
