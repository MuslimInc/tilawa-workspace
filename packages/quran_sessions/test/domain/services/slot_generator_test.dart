import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

/// Generation-shape tests use a permissive policy so the window is never the
/// thing under test; notice/horizon are exercised explicitly below.
const _openPolicy = SchedulingPolicy(minNoticeMinutes: 0, maxHorizonDays: 1000);

const _generator = SlotGenerator();

TimeRange _range(int sh, int sm, int eh, int em) =>
    TimeRange(start: LocalTime(sh, sm), end: LocalTime(eh, em));

WeeklySchedule _schedule({
  String timezone = 'Africa/Cairo',
  SlotDuration duration = SlotDuration.thirty,
  required Map<Weekday, List<TimeRange>> rules,
  SchedulingPolicy policy = _openPolicy,
}) => WeeklySchedule(
  teacherId: 'teacher_1',
  timezone: timezone,
  slotDuration: duration,
  rules: rules,
  policy: policy,
);

List<GeneratedSlot> _generate(
  WeeklySchedule schedule, {
  List<AvailabilityOverride> overrides = const [],
  Set<DateTime> booked = const {},
  required DateTime from,
  required DateTime to,
  required DateTime now,
}) => _generator.generate(
  schedule: schedule,
  overrides: overrides,
  bookedStartsUtc: booked,
  windowStart: from,
  windowEnd: to,
  now: now,
);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  // 2026-01-10 is a Saturday; January keeps Cairo on standard time (+02:00),
  // so 09:00 Cairo == 07:00 UTC with no DST ambiguity.
  final satFrom = DateTime.utc(2026, 1, 10);
  final satTo = DateTime.utc(2026, 1, 11);
  final wayBefore = DateTime.utc(2025, 1, 1);

  group('SlotGenerator — basic generation', () {
    test('one range, 30-min duration → contiguous half-hour slots', () {
      final slots = _generate(
        _schedule(
          rules: {
            Weekday.saturday: [_range(9, 0, 12, 0)],
          },
        ),
        from: satFrom,
        to: satTo,
        now: wayBefore,
      );

      check(slots).length.equals(6); // 9:00 … 11:30
      check(
        slots.first.startUtc.toIso8601String(),
      ).equals('2026-01-10T07:00:00.000Z'); // 09:00 Cairo
      check(
        slots.first.endUtc.toIso8601String(),
      ).equals('2026-01-10T07:30:00.000Z');
      check(
        slots.last.startUtc.toIso8601String(),
      ).equals('2026-01-10T09:30:00.000Z'); // 11:30 Cairo
    });

    test('multiple ranges per day are both generated', () {
      final slots = _generate(
        _schedule(
          duration: SlotDuration.sixty,
          rules: {
            Weekday.saturday: [_range(9, 0, 12, 0), _range(17, 0, 21, 0)],
          },
        ),
        from: satFrom,
        to: satTo,
        now: wayBefore,
      );

      check(slots).length.equals(7); // 3 morning + 4 evening
    });

    test('closed day generates nothing', () {
      final slots = _generate(
        _schedule(
          rules: {
            Weekday.saturday: [_range(9, 0, 12, 0)],
            Weekday.monday: const [],
          },
        ),
        from: DateTime.utc(2026, 1, 12), // Monday
        to: DateTime.utc(2026, 1, 13),
        now: wayBefore,
      );

      check(slots).isEmpty();
    });

    test('45-min duration packs slots and never overruns the range', () {
      final slots = _generate(
        _schedule(
          duration: SlotDuration.fortyFive,
          rules: {
            Weekday.saturday: [_range(9, 0, 12, 0)],
          },
        ),
        from: satFrom,
        to: satTo,
        now: wayBefore,
      );

      // 09:00, 09:45, 10:30, 11:15 (ends 12:00) → 4 slots.
      check(slots).length.equals(4);
      check(
        slots.last.endUtc.toIso8601String(),
      ).equals('2026-01-10T10:00:00.000Z'); // 12:00 Cairo
    });

    test('overlapping ranges are merged, not double-counted', () {
      final slots = _generate(
        _schedule(
          rules: {
            Weekday.saturday: [_range(9, 0, 11, 0), _range(10, 0, 12, 0)],
          },
        ),
        from: satFrom,
        to: satTo,
        now: wayBefore,
      );

      check(slots).length.equals(6); // merged 09:00–12:00, not 8
    });

    test('invalid ranges (start >= end) are ignored', () {
      final slots = _generate(
        _schedule(
          rules: {
            Weekday.saturday: [_range(12, 0, 9, 0)],
          },
        ),
        from: satFrom,
        to: satTo,
        now: wayBefore,
      );

      check(slots).isEmpty();
    });
  });

  group('SlotGenerator — overrides', () {
    test('unavailable override blanks a day the weekly rule would open', () {
      final slots = _generate(
        _schedule(
          rules: {
            Weekday.saturday: [_range(9, 0, 12, 0)],
          },
        ),
        overrides: [
          AvailabilityOverride(
            date: DateTime(2026, 1, 10),
            type: OverrideType.unavailable,
            reason: 'vacation',
          ),
        ],
        from: satFrom,
        to: satTo,
        now: wayBefore,
      );

      check(slots).isEmpty();
    });

    test('custom override opens a normally-closed day (temporary hours)', () {
      // Friday is closed in the weekly rule; the override adds 18:00–21:00.
      final slots = _generate(
        _schedule(
          duration: SlotDuration.sixty,
          rules: {Weekday.friday: const []},
        ),
        overrides: [
          AvailabilityOverride(
            date: DateTime(2026, 1, 9), // Friday
            type: OverrideType.custom,
            intervals: [_range(18, 0, 21, 0)],
          ),
        ],
        from: DateTime.utc(2026, 1, 9),
        to: DateTime.utc(2026, 1, 10),
        now: wayBefore,
      );

      check(slots).length.equals(3); // 18:00, 19:00, 20:00
    });
  });

  group('SlotGenerator — bookings & policy', () {
    test('a booked start instant is excluded', () {
      final booked = DateTime.utc(2026, 1, 10, 7, 30); // 09:30 Cairo
      final slots = _generate(
        _schedule(
          rules: {
            Weekday.saturday: [_range(9, 0, 12, 0)],
          },
        ),
        booked: {booked},
        from: satFrom,
        to: satTo,
        now: wayBefore,
      );

      check(slots).length.equals(5);
      check(
        slots.map((s) => s.startUtc.toIso8601String()),
      ).not((it) => it.contains('2026-01-10T07:30:00.000Z'));
    });

    test('minimum notice drops slots starting too soon', () {
      // now = 08:00 Cairo (06:00 UTC); 2h notice → earliest 08:00 UTC.
      final slots = _generate(
        _schedule(
          rules: {
            Weekday.saturday: [_range(9, 0, 12, 0)],
          },
          policy: const SchedulingPolicy(
            minNoticeMinutes: 120,
            maxHorizonDays: 1000,
          ),
        ),
        from: satFrom,
        to: satTo,
        now: DateTime.utc(2026, 1, 10, 6), // 08:00 Cairo
      );

      check(slots).length.equals(4); // 07:00 & 07:30 UTC dropped
      check(
        slots.first.startUtc.toIso8601String(),
      ).equals('2026-01-10T08:00:00.000Z');
    });

    test('booking horizon caps how far ahead slots are generated', () {
      final slots = _generate(
        _schedule(
          rules: {
            Weekday.saturday: [_range(9, 0, 10, 0)],
            Weekday.sunday: [_range(9, 0, 10, 0)],
          },
          policy: const SchedulingPolicy(
            minNoticeMinutes: 0,
            maxHorizonDays: 1,
          ),
        ),
        from: satFrom,
        to: DateTime.utc(2026, 1, 20),
        now: DateTime.utc(2026, 1, 10), // horizon ends 2026-01-11 00:00 UTC
      );

      // Only Saturday's slots fall inside the 1-day horizon.
      check(slots).length.equals(2);
      check(
        slots.every((s) => s.startUtc.isBefore(DateTime.utc(2026, 1, 11))),
      ).isTrue();
    });
  });

  group('SlotGenerator — timezone correctness', () {
    test('DST spring-forward gap instants are skipped (America/New_York)', () {
      // 2024-03-10: clocks jump 02:00 → 03:00 EDT, so 02:00 and 02:30 do not
      // exist. A 01:00–04:00 range at 30-min would yield 6 slots without DST.
      final slots = _generate(
        _schedule(
          timezone: 'America/New_York',
          rules: {
            Weekday.sunday: [_range(1, 0, 4, 0)],
          },
        ),
        from: DateTime.utc(2024, 3, 9),
        to: DateTime.utc(2024, 3, 12),
        now: DateTime.utc(2024, 1, 1),
      );

      // 02:00 & 02:30 local never exist, and 03:00/03:30 EDT collapse onto the
      // same UTC instants 01:00/01:30 EST would project to under no-DST. The
      // result is 4 contiguous slots (vs 6 without a spring-forward).
      check(slots).length.equals(4);
      check(
        slots.map((s) => s.startUtc.toIso8601String()).toList(),
      ).deepEquals([
        '2024-03-10T06:00:00.000Z', // 01:00 EST
        '2024-03-10T06:30:00.000Z', // 01:30 EST
        '2024-03-10T07:00:00.000Z', // 03:00 EDT (02:00 EST is the same instant)
        '2024-03-10T07:30:00.000Z', // 03:30 EDT
      ]);
    });

    test('no-DST zone keeps a stable offset (Asia/Riyadh +03:00)', () {
      final slots = _generate(
        _schedule(
          timezone: 'Asia/Riyadh',
          rules: {
            Weekday.saturday: [_range(9, 0, 10, 0)],
          },
        ),
        from: satFrom,
        to: satTo,
        now: wayBefore,
      );

      check(slots).length.equals(2);
      check(
        slots.first.startUtc.toIso8601String(),
      ).equals('2026-01-10T06:00:00.000Z'); // 09:00 Riyadh = 06:00 UTC
    });
  });

  group('GeneratedSlot.deterministicId', () {
    test('same teacher + instant always yields the same id', () {
      final id1 = GeneratedSlot.deterministicId(
        'teacher_1',
        DateTime.utc(2026, 1, 10, 7),
      );
      final id2 = GeneratedSlot.deterministicId(
        'teacher_1',
        DateTime.utc(2026, 1, 10, 7).toLocal(),
      );
      check(id1).equals('teacher_1_20260110T0700Z');
      check(id2).equals(id1); // local vs UTC input normalises identically
    });
  });
}
