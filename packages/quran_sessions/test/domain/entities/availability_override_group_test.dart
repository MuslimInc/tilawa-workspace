import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/availability_override.dart';
import 'package:quran_sessions/src/domain/entities/availability_override_group.dart';
import 'package:quran_sessions/src/domain/entities/local_time.dart';
import 'package:quran_sessions/src/domain/entities/time_range.dart';

void main() {
  group('groupAvailabilityOverrides', () {
    test('empty list returns no groups', () {
      check(groupAvailabilityOverrides(const [])).isEmpty();
    });

    test('single day becomes one group', () {
      final groups = groupAvailabilityOverrides([
        AvailabilityOverride(
          date: DateTime(2026, 6, 24),
          type: OverrideType.unavailable,
          reason: 'vacation',
        ),
      ]);

      check(groups).length.equals(1);
      check(groups.first.isSingleDay).isTrue();
      check(groups.first.dateKeys).deepEquals(['2026-06-24']);
    });

    test('consecutive vacation days merge into one range', () {
      final groups = groupAvailabilityOverrides([
        AvailabilityOverride(
          date: DateTime(2026, 6, 24),
          type: OverrideType.unavailable,
          reason: 'vacation',
        ),
        AvailabilityOverride(
          date: DateTime(2026, 6, 25),
          type: OverrideType.unavailable,
          reason: 'vacation',
        ),
        AvailabilityOverride(
          date: DateTime(2026, 6, 26),
          type: OverrideType.unavailable,
          reason: 'vacation',
        ),
      ]);

      check(groups).length.equals(1);
      check(groups.first.isSingleDay).isFalse();
      check(groups.first.dateKeys).deepEquals([
        '2026-06-24',
        '2026-06-25',
        '2026-06-26',
      ]);
    });

    test('gap splits overrides into separate groups', () {
      final groups = groupAvailabilityOverrides([
        AvailabilityOverride(
          date: DateTime(2026, 6, 24),
          type: OverrideType.unavailable,
          reason: 'vacation',
        ),
        AvailabilityOverride(
          date: DateTime(2026, 6, 26),
          type: OverrideType.unavailable,
          reason: 'vacation',
        ),
      ]);

      check(groups).length.equals(2);
    });

    test('different types never merge', () {
      final groups = groupAvailabilityOverrides([
        AvailabilityOverride(
          date: DateTime(2026, 6, 24),
          type: OverrideType.unavailable,
        ),
        AvailabilityOverride(
          date: DateTime(2026, 6, 25),
          type: OverrideType.custom,
          intervals: const [
            TimeRange(start: LocalTime(9, 0), end: LocalTime(12, 0)),
          ],
        ),
      ]);

      check(groups).length.equals(2);
    });
  });
}
