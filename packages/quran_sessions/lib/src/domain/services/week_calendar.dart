import 'package:timezone/timezone.dart' as tz;

import '../entities/teacher_availability.dart';
import '../entities/week_availability_window.dart';
import '../entities/weekday.dart';

/// Calendar-week math for teacher-local Sat→Fri buckets.
class WeekCalendar {
  const WeekCalendar();

  /// Days elapsed since [weekStartDay] within the current week (0 = start day).
  int daysSinceWeekStart(DateTime localDate, Weekday weekStartDay) {
    final start = weekStartDay.dartWeekday;
    final current = localDate.weekday;
    return (current - start + 7) % 7;
  }

  /// Week start date (date-only) containing [localDate].
  DateTime weekStartDate(DateTime localDate, Weekday weekStartDay) {
    final normalized = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );
    final offset = daysSinceWeekStart(normalized, weekStartDay);
    return normalized.subtract(Duration(days: offset));
  }

  String weekKeyFor(DateTime localDate, Weekday weekStartDay) {
    final start = weekStartDate(localDate, weekStartDay);
    return _dateKey(start);
  }

  WeekAvailabilityWindow windowForWeekStart(
    DateTime weekStart, {
    int weekLengthDays = 7,
  }) {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(Duration(days: weekLengthDays - 1));
    return WeekAvailabilityWindow(
      weekKey: _dateKey(start),
      startDate: start,
      endDate: end,
    );
  }

  WeekAvailabilityWindow thisWeek({
    required DateTime now,
    required String timezone,
    Weekday weekStartDay = Weekday.saturday,
  }) {
    final local = _localNow(now, timezone);
    final start = weekStartDate(local, weekStartDay);
    return windowForWeekStart(start);
  }

  WeekAvailabilityWindow nextWeek({
    required DateTime now,
    required String timezone,
    Weekday weekStartDay = Weekday.saturday,
  }) {
    final local = _localNow(now, timezone);
    final start = weekStartDate(
      local,
      weekStartDay,
    ).add(const Duration(days: 7));
    return windowForWeekStart(start);
  }

  /// Splits [slots] into this-week and next-week lists (teacher-local dates).
  ({List<TeacherAvailability> thisWeek, List<TeacherAvailability> nextWeek})
  partitionSlots({
    required List<TeacherAvailability> slots,
    required DateTime now,
    required String timezone,
    Weekday weekStartDay = Weekday.saturday,
  }) {
    final thisWindow = thisWeek(
      now: now,
      timezone: timezone,
      weekStartDay: weekStartDay,
    );
    final nextWindow = nextWeek(
      now: now,
      timezone: timezone,
      weekStartDay: weekStartDay,
    );
    final location = tz.getLocation(timezone);

    final thisWeekSlots = <TeacherAvailability>[];
    final nextWeekSlots = <TeacherAvailability>[];

    for (final slot in slots) {
      final local = tz.TZDateTime.from(slot.startsAt.toUtc(), location);
      final date = DateTime(local.year, local.month, local.day);
      if (thisWindow.containsLocalDate(date)) {
        thisWeekSlots.add(slot);
      } else if (nextWindow.containsLocalDate(date)) {
        nextWeekSlots.add(slot);
      }
    }

    return (thisWeek: thisWeekSlots, nextWeek: nextWeekSlots);
  }

  bool isFriday({
    required DateTime now,
    required String timezone,
  }) {
    final local = _localNow(now, timezone);
    return local.weekday == DateTime.friday;
  }

  bool isReminderHour({
    required DateTime now,
    required String timezone,
    required int reminderLocalHour,
  }) {
    final local = _localNow(now, timezone);
    return local.hour >= reminderLocalHour;
  }

  DateTime saturdayAfterFriday({
    required DateTime now,
    required String timezone,
  }) {
    final local = _localNow(now, timezone);
    final daysUntilSaturday = (DateTime.saturday - local.weekday + 7) % 7;
    final saturday = local.add(
      Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday),
    );
    return DateTime(saturday.year, saturday.month, saturday.day);
  }

  DateTime _localNow(DateTime now, String timezone) {
    final location = tz.getLocation(timezone);
    final local = tz.TZDateTime.from(now.toUtc(), location);
    return DateTime(local.year, local.month, local.day, local.hour);
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
