import 'package:timezone/timezone.dart' as tz;

import '../entities/availability_override.dart';
import '../entities/generated_slot.dart';
import '../entities/time_range.dart';
import '../entities/weekday.dart';
import '../entities/weekly_schedule.dart';

/// Turns a [WeeklySchedule] + [AvailabilityOverride]s into concrete bookable
/// [GeneratedSlot]s for a time window.
///
/// Pure and side-effect free: no Firestore, no `BuildContext`, no `DateTime.now`
/// of its own (the caller passes [now]). This is the single place timezone and
/// DST correctness lives, so it carries the bulk of the test suite.
///
/// **Precondition:** the timezone database must be initialised before use
/// (`tz.initializeTimeZones()` / the host app's tz bootstrap). Slot generation
/// resolves [WeeklySchedule.timezone] via [tz.getLocation].
class SlotGenerator {
  const SlotGenerator();

  /// Generates every bookable slot in `[windowStart, windowEnd)`.
  ///
  /// - [bookedStartsUtc]: start instants already taken (bookings or holds);
  ///   their slots — plus any configured buffer — are excluded.
  /// - [now]: the reference instant for minimum-notice and horizon clamping.
  ///
  /// Returned slots are UTC and sorted ascending by start.
  List<GeneratedSlot> generate({
    required WeeklySchedule schedule,
    required List<AvailabilityOverride> overrides,
    required Set<DateTime> bookedStartsUtc,
    required DateTime windowStart,
    required DateTime windowEnd,
    required DateTime now,
  }) {
    final location = tz.getLocation(schedule.timezone);
    final durationMinutes = schedule.slotDuration.minutes;
    final policy = schedule.policy;

    // Clamp the requested window by minimum notice and booking horizon.
    final nowUtc = now.toUtc();
    final earliest = nowUtc.add(Duration(minutes: policy.minNoticeMinutes));
    final horizonEnd = nowUtc.add(Duration(days: policy.maxHorizonDays));

    var fromUtc = windowStart.toUtc();
    if (fromUtc.isBefore(earliest)) fromUtc = earliest;
    var toUtc = windowEnd.toUtc();
    if (toUtc.isAfter(horizonEnd)) toUtc = horizonEnd;
    if (!fromUtc.isBefore(toUtc)) return const <GeneratedSlot>[];

    // Index overrides by their calendar-date key for O(1) per-day lookup.
    final overrideByDate = <String, AvailabilityOverride>{
      for (final o in overrides) o.dateKey: o,
    };

    // Pre-compute booked intervals (with buffer) for exclusion.
    final blocked = _blockedIntervals(
      bookedStartsUtc,
      durationMinutes: durationMinutes,
      bufferBeforeMinutes: policy.bufferBeforeMinutes,
      bufferAfterMinutes: policy.bufferAfterMinutes,
    );

    final slots = <GeneratedSlot>[];

    // Iterate teacher-local calendar dates spanning the (clamped) window.
    final firstLocal = tz.TZDateTime.from(fromUtc, location);
    final lastLocal = tz.TZDateTime.from(toUtc, location);
    var day = tz.TZDateTime(
      location,
      firstLocal.year,
      firstLocal.month,
      firstLocal.day,
    );
    final lastDay = tz.TZDateTime(
      location,
      lastLocal.year,
      lastLocal.month,
      lastLocal.day,
    );

    while (!day.isAfter(lastDay)) {
      final intervals = _intervalsForDate(schedule, overrideByDate, day);
      for (final range in intervals) {
        var startMin = range.start.minutesSinceMidnight;
        final endMin = range.end.minutesSinceMidnight;
        while (startMin + durationMinutes <= endMin) {
          final hour = startMin ~/ 60;
          final minute = startMin % 60;
          final localStart = tz.TZDateTime(
            location,
            day.year,
            day.month,
            day.day,
            hour,
            minute,
          );
          // Skip non-existent local times (DST spring-forward gap): the
          // constructor rolls such a wall clock forward, so it reads back
          // differently from what we asked for.
          final existsOnClock =
              localStart.hour == hour && localStart.minute == minute;
          if (existsOnClock) {
            final startUtc = localStart.toUtc();
            final endUtc = startUtc.add(Duration(minutes: durationMinutes));
            final inWindow =
                !startUtc.isBefore(fromUtc) && startUtc.isBefore(toUtc);
            if (inWindow && !_isBlocked(startUtc, endUtc, blocked)) {
              slots.add(
                GeneratedSlot(
                  teacherId: schedule.teacherId,
                  startUtc: startUtc,
                  endUtc: endUtc,
                ),
              );
            }
          }
          startMin += durationMinutes;
        }
      }
      day = tz.TZDateTime(location, day.year, day.month, day.day + 1);
    }

    slots.sort((a, b) => a.startUtc.compareTo(b.startUtc));
    return slots;
  }

  /// Resolves the intervals in effect for a single calendar [day]:
  /// an override (unavailable → none, custom → its intervals) wins over the
  /// recurring weekly rule. The result is normalised (sorted, merged).
  List<TimeRange> _intervalsForDate(
    WeeklySchedule schedule,
    Map<String, AvailabilityOverride> overrideByDate,
    tz.TZDateTime day,
  ) {
    final key =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final override = overrideByDate[key];
    if (override != null) {
      return override.type == OverrideType.unavailable
          ? const <TimeRange>[]
          : _normalize(override.intervals);
    }
    return _normalize(schedule.rangesFor(Weekday.fromDateTime(day)));
  }

  /// Sorts intervals by start and merges any that overlap or touch, so the
  /// slot walk never double-counts an instant.
  List<TimeRange> _normalize(List<TimeRange> ranges) {
    final valid = ranges.where((r) => r.isValid).toList()
      ..sort(
        (a, b) => a.start.minutesSinceMidnight - b.start.minutesSinceMidnight,
      );
    if (valid.isEmpty) return const <TimeRange>[];

    final merged = <TimeRange>[valid.first];
    for (final range in valid.skip(1)) {
      final last = merged.last;
      if (range.start <= last.end) {
        if (range.end > last.end) {
          merged[merged.length - 1] = TimeRange(
            start: last.start,
            end: range.end,
          );
        }
      } else {
        merged.add(range);
      }
    }
    return merged;
  }

  /// Booked spans expanded by buffer, as `[startMs, endMs)` millisecond pairs.
  List<List<int>> _blockedIntervals(
    Set<DateTime> bookedStartsUtc, {
    required int durationMinutes,
    required int bufferBeforeMinutes,
    required int bufferAfterMinutes,
  }) {
    const msPerMinute = 60 * 1000;
    return bookedStartsUtc.map((start) {
      final s = start.toUtc().millisecondsSinceEpoch;
      final e = s + durationMinutes * msPerMinute;
      return <int>[
        s - bufferBeforeMinutes * msPerMinute,
        e + bufferAfterMinutes * msPerMinute,
      ];
    }).toList();
  }

  bool _isBlocked(DateTime startUtc, DateTime endUtc, List<List<int>> blocked) {
    final s = startUtc.millisecondsSinceEpoch;
    final e = endUtc.millisecondsSinceEpoch;
    for (final span in blocked) {
      if (s < span[1] && span[0] < e) return true;
    }
    return false;
  }
}
