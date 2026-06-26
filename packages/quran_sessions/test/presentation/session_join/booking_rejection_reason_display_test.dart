import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  test('returns null for empty input', () {
    check(safeBookingRejectionReasonForDisplay(null)).isNull();
    check(safeBookingRejectionReasonForDisplay('')).isNull();
    check(safeBookingRejectionReasonForDisplay('   ')).isNull();
  });

  test('strips control characters', () {
    check(
      safeBookingRejectionReasonForDisplay('busy\u0000today'),
    ).equals('busytoday');
  });

  test('truncates over-max stored reasons for display', () {
    final long = 'a' * (tutorRejectBookingReasonMaxLength + 10);
    final displayed = safeBookingRejectionReasonForDisplay(long);
    check(displayed).isNotNull();
    check(displayed!.length).equals(tutorRejectBookingReasonMaxLength);
  });
}
