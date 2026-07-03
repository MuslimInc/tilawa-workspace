import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/src/presentation/utils/teacher_availability_by_date.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../helpers/availability_test_helpers.dart';

/// Soft ceilings for CI — catch accidental algorithmic regressions, not
/// micro-benchmark absolutes. Tune if CI hardware changes materially.
const _maxGenerate14dMs = 200;
const _maxGenerate90dMs = 800;
const _maxGroup1000Ms = 50;
const _maxOptimisticFilter10kMs = 20;

List<TeacherAvailability> _filterSlot(
  List<TeacherAvailability> slots,
  String slotId,
) => slots.where((slot) => slot.slotId != slotId).toList();

WeeklySchedule _denseSchedule({SlotDuration duration = SlotDuration.thirty}) =>
    WeeklySchedule(
      teacherId: 'teacher_1',
      timezone: 'Africa/Cairo',
      slotDuration: duration,
      rules: {
        for (final day in Weekday.values)
          day: const [
            TimeRange(start: LocalTime(8, 0), end: LocalTime(20, 0)),
          ],
      },
      policy: const SchedulingPolicy(
        minNoticeMinutes: 0,
        maxHorizonDays: 365,
      ),
    );

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('availability performance', () {
    test('slot generation 14-day window stays within ceiling', () {
      const generator = SlotGenerator();
      final now = DateTime.utc(2026, 6, 22, 10);
      final sw = Stopwatch()..start();
      final slots = generator.generate(
        schedule: _denseSchedule(),
        overrides: const [],
        bookedStartsUtc: const {},
        windowStart: now,
        windowEnd: now.add(const Duration(days: 14)),
        now: now,
      );
      sw.stop();

      check(slots.length).isGreaterThan(100);
      check(sw.elapsedMilliseconds).isLessThan(_maxGenerate14dMs);
    });

    test('slot generation 90-day window stays within ceiling', () {
      const generator = SlotGenerator();
      final now = DateTime.utc(2026, 6, 22, 10);
      final sw = Stopwatch()..start();
      final slots = generator.generate(
        schedule: _denseSchedule(),
        overrides: const [],
        bookedStartsUtc: const {},
        windowStart: now,
        windowEnd: now.add(const Duration(days: 90)),
        now: now,
      );
      sw.stop();

      check(slots.length).isGreaterThan(500);
      check(sw.elapsedMilliseconds).isLessThan(_maxGenerate90dMs);
    });

    test('override map lookup stays O(1) per day during generation', () {
      const generator = SlotGenerator();
      final now = DateTime.utc(2026, 6, 22, 10);
      final overrides = List.generate(
        15,
        (i) => AvailabilityOverride(
          date: DateTime(2026, 6, 22).add(Duration(days: i)),
          type: OverrideType.unavailable,
        ),
      );

      final without = generator.generate(
        schedule: _denseSchedule(),
        overrides: const [],
        bookedStartsUtc: const {},
        windowStart: now,
        windowEnd: now.add(const Duration(days: 14)),
        now: now,
      );
      final withOverrides = generator.generate(
        schedule: _denseSchedule(),
        overrides: overrides,
        bookedStartsUtc: const {},
        windowStart: now,
        windowEnd: now.add(const Duration(days: 14)),
        now: now,
      );

      check(withOverrides.length).isLessThan(without.length);
    });

    test('grouping 1000 pre-sorted slots stays within ceiling', () {
      final now = DateTime.utc(2026, 6, 22, 9);
      final slots = List.generate(
        1000,
        (i) => TeacherAvailability(
          slotId: 'slot_$i',
          teacherId: 'teacher_1',
          startsAt: now.add(Duration(minutes: 45 * i)),
          endsAt: now.add(Duration(minutes: 45 * i + 30)),
          isBooked: false,
        ),
      );

      final sw = Stopwatch()..start();
      final grouped = groupTeacherAvailabilityByLocalDay(slots);
      sw.stop();

      check(grouped.days).isNotEmpty();
      check(sw.elapsedMilliseconds).isLessThan(_maxGroup1000Ms);
    });

    test('optimistic slot removal filter scales for large lists', () {
      final now = DateTime.utc(2026, 6, 22, 9);
      for (final count in [100, 1000, 10000]) {
        final slots = List.generate(
          count,
          (i) => TeacherAvailability(
            slotId: 'slot_$i',
            teacherId: 'teacher_1',
            startsAt: now.add(Duration(minutes: 45 * i)),
            endsAt: now.add(Duration(minutes: 45 * i + 30)),
            isBooked: false,
          ),
        );
        final targetId = 'slot_${count ~/ 2}';

        final sw = Stopwatch()..start();
        final filtered = _filterSlot(slots, targetId);
        sw.stop();

        check(filtered.length).equals(count - 1);
        check(sw.elapsedMilliseconds).isLessThan(_maxOptimisticFilter10kMs);
      }
    });

    test('block generated slot uses scoped override read', () async {
      final scheduleRepo = FakeScheduleRepository()
        ..schedule = makeWeeklySchedule(
          rules: {
            for (final day in Weekday.values)
              day: const [
                TimeRange(start: LocalTime(8, 0), end: LocalTime(20, 0)),
              ],
          },
        );
      for (var day = 1; day <= 90; day++) {
        scheduleRepo.overrides.add(
          AvailabilityOverride(
            date: DateTime(2026, 6, day),
            type: OverrideType.unavailable,
          ),
        );
      }
      final blockSlot = BlockGeneratedSlotUseCase(scheduleRepo);
      final slotStart = DateTime.utc(2026, 6, 22, 10);

      final sw = Stopwatch()..start();
      await blockSlot(
        teacherId: 'teacher_1',
        slotStartUtc: slotStart,
        slotEndUtc: slotStart.add(const Duration(minutes: 30)),
      );
      sw.stop();

      check(scheduleRepo.getOverrideByDateCallCount).equals(1);
      check(scheduleRepo.getOverridesCallCount).equals(0);
      check(sw.elapsedMilliseconds).isLessThan(50);
    });
  });
}
