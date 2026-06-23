import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/availability_override.dart';
import 'package:quran_sessions/src/domain/services/vacation_override_validator.dart';

void main() {
  const validator = VacationOverrideValidator();

  group('findFirstOverlappingVacationDay', () {
    test('returns null when no existing vacations', () {
      check(
        validator.findFirstOverlappingVacationDay(
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 5),
          existingOverrides: const [],
        ),
      ).isNull();
    });

    test('returns null when range is adjacent but not overlapping', () {
      check(
        validator.findFirstOverlappingVacationDay(
          startDate: DateTime(2026, 7, 6),
          endDate: DateTime(2026, 7, 10),
          existingOverrides: [
            AvailabilityOverride(
              date: DateTime(2026, 7, 5),
              type: OverrideType.unavailable,
            ),
          ],
        ),
      ).isNull();
    });

    test('detects exact duplicate single day', () {
      check(
        validator.findFirstOverlappingVacationDay(
          startDate: DateTime(2026, 7, 5),
          endDate: DateTime(2026, 7, 5),
          existingOverrides: [
            AvailabilityOverride(
              date: DateTime(2026, 7, 5),
              type: OverrideType.unavailable,
            ),
          ],
        ),
      ).equals(DateTime(2026, 7, 5));
    });

    test('detects partial overlap at range start', () {
      check(
        validator.findFirstOverlappingVacationDay(
          startDate: DateTime(2026, 7, 4),
          endDate: DateTime(2026, 7, 8),
          existingOverrides: [
            AvailabilityOverride(
              date: DateTime(2026, 7, 6),
              type: OverrideType.unavailable,
            ),
          ],
        ),
      ).equals(DateTime(2026, 7, 6));
    });

    test('detects when proposed range is fully inside existing vacation', () {
      check(
        validator.findFirstOverlappingVacationDay(
          startDate: DateTime(2026, 7, 2),
          endDate: DateTime(2026, 7, 3),
          existingOverrides: [
            for (var day = 1; day <= 5; day++)
              AvailabilityOverride(
                date: DateTime(2026, 7, day),
                type: OverrideType.unavailable,
              ),
          ],
        ),
      ).equals(DateTime(2026, 7, 2));
    });

    test('ignores custom-hour overrides on the same dates', () {
      check(
        validator.findFirstOverlappingVacationDay(
          startDate: DateTime(2026, 7, 5),
          endDate: DateTime(2026, 7, 5),
          existingOverrides: [
            AvailabilityOverride(
              date: DateTime(2026, 7, 5),
              type: OverrideType.custom,
            ),
          ],
        ),
      ).isNull();
    });
  });

  group('hasValidDateRange', () {
    test('accepts same-day range', () {
      check(
        validator.hasValidDateRange(
          startDate: DateTime(2026, 7, 5),
          endDate: DateTime(2026, 7, 5),
        ),
      ).isTrue();
    });

    test('rejects end before start', () {
      check(
        validator.hasValidDateRange(
          startDate: DateTime(2026, 7, 10),
          endDate: DateTime(2026, 7, 5),
        ),
      ).isFalse();
    });
  });

  group('expandVacationRange', () {
    test('expands inclusive date range into daily overrides', () {
      final overrides = validator.expandVacationRange(
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 3),
      );

      check(overrides).length.equals(3);
      check(
        overrides.every((o) => o.type == OverrideType.unavailable),
      ).isTrue();
      check(overrides.map((o) => o.dateKey).toList()).deepEquals([
        '2026-07-01',
        '2026-07-02',
        '2026-07-03',
      ]);
    });
  });
}
