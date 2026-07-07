import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_sessions/src/domain/entities/booking_block_reason.dart';

void main() {
  group('BookingBlockReason classification', () {
    test(
      'none and pricingQuoteUnavailable are transient (row stays visible)',
      () {
        for (final reason in [
          BookingBlockReason.none,
          BookingBlockReason.pricingQuoteUnavailable,
        ]) {
          check(reason.isTransient).isTrue();
          check(reason.hidesTeacherFromList).isFalse();
        }
      },
    );

    test('durable blocks hide the teacher from the list', () {
      for (final reason in [
        BookingBlockReason.paymentProviderUnavailable,
        BookingBlockReason.bookingDisabledByAdmin,
        BookingBlockReason.pricingConfigMissing,
        BookingBlockReason.teacherNotBookable,
        BookingBlockReason.marketDisabled,
      ]) {
        check(reason.isTransient).isFalse();
        check(reason.hidesTeacherFromList).isTrue();
      }
    });

    test('every enum value is classified without gaps', () {
      for (final reason in BookingBlockReason.values) {
        check(reason.hidesTeacherFromList).equals(!reason.isTransient);
      }
    });
  });
}
