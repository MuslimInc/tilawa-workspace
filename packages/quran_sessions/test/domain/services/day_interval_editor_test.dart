import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

void main() {
  group('subtractInterval', () {
    test('splits a range around a removed slot', () {
      final remaining = subtractInterval(
        const [TimeRange(start: LocalTime(9, 0), end: LocalTime(17, 0))],
        const TimeRange(start: LocalTime(9, 0), end: LocalTime(9, 30)),
      );

      check(remaining).deepEquals(const [
        TimeRange(start: LocalTime(9, 30), end: LocalTime(17, 0)),
      ]);
    });

    test('removes a middle slot and keeps both sides', () {
      final remaining = subtractInterval(
        const [TimeRange(start: LocalTime(9, 0), end: LocalTime(12, 0))],
        const TimeRange(start: LocalTime(9, 45), end: LocalTime(10, 30)),
      );

      check(remaining).deepEquals(const [
        TimeRange(start: LocalTime(9, 0), end: LocalTime(9, 45)),
        TimeRange(start: LocalTime(10, 30), end: LocalTime(12, 0)),
      ]);
    });
  });
}
