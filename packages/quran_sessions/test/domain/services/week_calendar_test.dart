import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  const calendar = WeekCalendar();
  const timezone = 'Asia/Riyadh';

  group('WeekCalendar', () {
    test('Saturday is week start for MENA default', () {
      // 2026-01-10 is Saturday in Riyadh
      final start = calendar.weekStartDate(
        DateTime(2026, 1, 10),
        Weekday.saturday,
      );
      check(start).equals(DateTime(2026, 1, 10));
    });

    test('thisWeek and nextWeek partition do not overlap', () {
      final now = DateTime.utc(2026, 1, 9, 12); // Friday UTC
      final thisWeek = calendar.thisWeek(
        now: now,
        timezone: timezone,
        weekStartDay: Weekday.saturday,
      );
      final nextWeek = calendar.nextWeek(
        now: now,
        timezone: timezone,
        weekStartDay: Weekday.saturday,
      );

      check(thisWeek.endDate.isBefore(nextWeek.startDate)).isTrue();
      check(nextWeek.startDate.difference(thisWeek.startDate).inDays).equals(7);
    });

    test('partitionSlots assigns slots to this or next week only', () {
      final now = DateTime.utc(2026, 1, 9, 12); // Friday in Riyadh
      final thisStart = DateTime.utc(
        2026,
        1,
        7,
        7,
      ); // Wed in current Sat–Fri week
      final nextStart = DateTime.utc(2026, 1, 10, 7); // Sat starting next week
      final slots = [
        TeacherAvailability(
          slotId: 'a',
          teacherId: 't1',
          startsAt: thisStart,
          endsAt: thisStart.add(const Duration(minutes: 30)),
          isBooked: false,
        ),
        TeacherAvailability(
          slotId: 'b',
          teacherId: 't1',
          startsAt: nextStart,
          endsAt: nextStart.add(const Duration(minutes: 30)),
          isBooked: false,
        ),
      ];

      final partition = calendar.partitionSlots(
        slots: slots,
        now: now,
        timezone: timezone,
        weekStartDay: Weekday.saturday,
      );

      check(partition.thisWeek.length).equals(1);
      check(partition.nextWeek.length).equals(1);
      check(partition.thisWeek.single.slotId).equals('a');
      check(partition.nextWeek.single.slotId).equals('b');
    });
  });
}
