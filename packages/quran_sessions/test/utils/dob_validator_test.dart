import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/utils/dob_validator.dart';

void main() {
  // Fixed "today" so every age boundary is deterministic regardless of the
  // real clock.
  final today = DateTime(2026, 6, 21);

  // ── Required ──────────────────────────────────────────────────────────────────

  group('DobValidator.validate — required', () {
    test('null returns DateOfBirthRequiredFailure (minAge 3)', () {
      check(
        DobValidator.validate(null, minimumAgeYears: 3, today: today),
      ).isA<DateOfBirthRequiredFailure>();
    });

    test('null returns DateOfBirthRequiredFailure (minAge 18)', () {
      check(
        DobValidator.validate(null, minimumAgeYears: 18, today: today),
      ).isA<DateOfBirthRequiredFailure>();
    });

    test('null without today param also returns required failure', () {
      check(
        DobValidator.validate(null, minimumAgeYears: 5),
      ).isA<DateOfBirthRequiredFailure>();
    });
  });

  // ── Minimum age = 3 ───────────────────────────────────────────────────────────

  group('DobValidator.validate — minimum age 3', () {
    test('exactly 3 years old today is accepted (inclusive boundary)', () {
      check(
        DobValidator.validate(
          DateTime(2023, 6, 21),
          minimumAgeYears: 3,
          today: today,
        ),
      ).isNull();
    });

    test('one day short of 3 returns DateOfBirthTooRecent', () {
      check(
        DobValidator.validate(
          DateTime(2023, 6, 22),
          minimumAgeYears: 3,
          today: today,
        ),
      ).isA<DateOfBirthTooRecentFailure>();
    });

    test('one day over 3 is accepted', () {
      check(
        DobValidator.validate(
          DateTime(2023, 6, 20),
          minimumAgeYears: 3,
          today: today,
        ),
      ).isNull();
    });

    test('much older than 3 is accepted', () {
      check(
        DobValidator.validate(
          DateTime(2000, 1, 1),
          minimumAgeYears: 3,
          today: today,
        ),
      ).isNull();
    });
  });

  // ── Minimum age = 5 ───────────────────────────────────────────────────────────

  group('DobValidator.validate — minimum age 5', () {
    test('exactly 5 years old today is accepted', () {
      check(
        DobValidator.validate(
          DateTime(2021, 6, 21),
          minimumAgeYears: 5,
          today: today,
        ),
      ).isNull();
    });

    test('one day short of 5 returns DateOfBirthTooRecent', () {
      check(
        DobValidator.validate(
          DateTime(2021, 6, 22),
          minimumAgeYears: 5,
          today: today,
        ),
      ).isA<DateOfBirthTooRecentFailure>();
    });

    test('a date valid for age 3 is rejected once the limit becomes 5', () {
      // Demonstrates the rule is config-driven: same DOB, different min age.
      final dob = DateTime(2022, 6, 21); // 4 years old on `today`
      check(
        DobValidator.validate(dob, minimumAgeYears: 3, today: today),
      ).isNull();
      check(
        DobValidator.validate(dob, minimumAgeYears: 5, today: today),
      ).isA<DateOfBirthTooRecentFailure>();
    });
  });

  // ── Minimum age = 18 ──────────────────────────────────────────────────────────

  group('DobValidator.validate — minimum age 18', () {
    test('exactly 18 years old today is accepted', () {
      check(
        DobValidator.validate(
          DateTime(2008, 6, 21),
          minimumAgeYears: 18,
          today: today,
        ),
      ).isNull();
    });

    test('one day short of 18 returns DateOfBirthTooRecent', () {
      check(
        DobValidator.validate(
          DateTime(2008, 6, 22),
          minimumAgeYears: 18,
          today: today,
        ),
      ).isA<DateOfBirthTooRecentFailure>();
    });

    test('17 years old returns DateOfBirthTooRecent', () {
      check(
        DobValidator.validate(
          DateTime(2009, 1, 1),
          minimumAgeYears: 18,
          today: today,
        ),
      ).isA<DateOfBirthTooRecentFailure>();
    });

    test('25 years old is accepted', () {
      check(
        DobValidator.validate(
          DateTime(2001, 1, 1),
          minimumAgeYears: 18,
          today: today,
        ),
      ).isNull();
    });
  });

  // ── Future dates ──────────────────────────────────────────────────────────────

  group('DobValidator.validate — future dates', () {
    test('tomorrow returns FutureDateOfBirthFailure (minAge 3)', () {
      check(
        DobValidator.validate(
          DateTime(2026, 6, 22),
          minimumAgeYears: 3,
          today: today,
        ),
      ).isA<FutureDateOfBirthFailure>();
    });

    test('far future returns FutureDateOfBirthFailure (minAge 18)', () {
      check(
        DobValidator.validate(
          DateTime(2100, 1, 1),
          minimumAgeYears: 18,
          today: today,
        ),
      ).isA<FutureDateOfBirthFailure>();
    });

    test('future takes precedence over the too-recent rule', () {
      // A future date is also "younger than min age"; future must win.
      check(
        DobValidator.validate(
          DateTime(2027, 1, 1),
          minimumAgeYears: 3,
          today: today,
        ),
      ).isA<FutureDateOfBirthFailure>();
    });
  });

  // ── Invalid (before the sanity floor) ─────────────────────────────────────────

  group('DobValidator.validate — invalid (too old)', () {
    test('1899-12-31 returns InvalidDateOfBirthFailure', () {
      check(
        DobValidator.validate(
          DateTime(1899, 12, 31),
          minimumAgeYears: 18,
          today: today,
        ),
      ).isA<InvalidDateOfBirthFailure>();
    });

    test('year 0 returns InvalidDateOfBirthFailure', () {
      check(
        DobValidator.validate(DateTime(0), minimumAgeYears: 3, today: today),
      ).isA<InvalidDateOfBirthFailure>();
    });

    test('1900-01-01 (the floor) is accepted', () {
      check(
        DobValidator.validate(
          DateTime(1900),
          minimumAgeYears: 18,
          today: today,
        ),
      ).isNull();
    });
  });

  // ── Leap years ────────────────────────────────────────────────────────────────

  group('DobValidator.validate — leap years', () {
    test('born Feb 29 2000, min age 18, is accepted', () {
      check(
        DobValidator.validate(
          DateTime(2000, 2, 29),
          minimumAgeYears: 18,
          today: today,
        ),
      ).isNull();
    });

    test('leap "today" with leap target year: Feb 29 boundary is exact', () {
      final leapToday = DateTime(2024, 2, 29);
      // min age 4 → target 2020 (also leap) → 2020-02-29 exactly.
      check(
        DobValidator.validate(
          DateTime(2020, 2, 29),
          minimumAgeYears: 4,
          today: leapToday,
        ),
      ).isNull();
    });

    test('leap "today" with non-leap target normalises Feb 29 → Mar 1', () {
      final leapToday = DateTime(2024, 2, 29);
      // min age 1 → target year 2023 (non-leap); latestBirthDate normalises to
      // 2023-03-01, so someone born 2023-03-01 is exactly at the boundary.
      check(
        DobValidator.latestBirthDate(minimumAgeYears: 1, today: leapToday),
      ).equals(DateTime(2023, 3, 1));
      check(
        DobValidator.validate(
          DateTime(2023, 3, 1),
          minimumAgeYears: 1,
          today: leapToday,
        ),
      ).isNull();
      check(
        DobValidator.validate(
          DateTime(2023, 3, 2),
          minimumAgeYears: 1,
          today: leapToday,
        ),
      ).isA<DateOfBirthTooRecentFailure>();
    });
  });

  // ── Timezone / time-component edge cases (date-only comparison) ────────────────

  group('DobValidator.validate — timezone & time components', () {
    test('UTC-constructed DOB is compared date-only', () {
      check(
        DobValidator.validate(
          DateTime.utc(2008, 6, 21),
          minimumAgeYears: 18,
          today: today,
        ),
      ).isNull();
    });

    test('late-night time on the boundary day is still accepted', () {
      // 23:59 on the exact boundary date — time must be ignored.
      check(
        DobValidator.validate(
          DateTime(2008, 6, 21, 23, 59, 59),
          minimumAgeYears: 18,
          today: today,
        ),
      ).isNull();
    });

    test('time component does not push a too-recent date into valid', () {
      // One day too young, even at 00:00 — still rejected.
      check(
        DobValidator.validate(
          DateTime(2008, 6, 22, 0, 0, 1),
          minimumAgeYears: 18,
          today: today,
        ),
      ).isA<DateOfBirthTooRecentFailure>();
    });

    test('today supplied with a time component is reduced to date-only', () {
      final todayLateNight = DateTime(2026, 6, 21, 23, 59, 59);
      // Born exactly 3 years before the date part → accepted.
      check(
        DobValidator.validate(
          DateTime(2023, 6, 21),
          minimumAgeYears: 3,
          today: todayLateNight,
        ),
      ).isNull();
    });
  });

  // ── latestBirthDate (shared picker/validator rule) ────────────────────────────

  group('DobValidator.latestBirthDate', () {
    test('minAge 3 → today minus 3 years (date-only)', () {
      check(
        DobValidator.latestBirthDate(minimumAgeYears: 3, today: today),
      ).equals(DateTime(2023, 6, 21));
    });

    test('minAge 18 → today minus 18 years', () {
      check(
        DobValidator.latestBirthDate(minimumAgeYears: 18, today: today),
      ).equals(DateTime(2008, 6, 21));
    });

    test('strips the time component from today', () {
      check(
        DobValidator.latestBirthDate(
          minimumAgeYears: 5,
          today: DateTime(2026, 6, 21, 10, 30),
        ),
      ).equals(DateTime(2021, 6, 21));
    });

    test('matches the validator boundary exactly', () {
      const minAge = 7;
      final boundary = DobValidator.latestBirthDate(
        minimumAgeYears: minAge,
        today: today,
      );
      // The boundary date is accepted; one day later is rejected.
      check(
        DobValidator.validate(boundary, minimumAgeYears: minAge, today: today),
      ).isNull();
      check(
        DobValidator.validate(
          boundary.add(const Duration(days: 1)),
          minimumAgeYears: minAge,
          today: today,
        ),
      ).isA<DateOfBirthTooRecentFailure>();
    });

    test('without today param uses real now and is never in the future', () {
      final last = DobValidator.latestBirthDate(minimumAgeYears: 3);
      check(last.isAfter(DateTime.now())).isFalse();
    });
  });

  // ── Default-today path ────────────────────────────────────────────────────────

  test('validate() without today param uses real DateTime.now()', () {
    // Born in 1990 — comfortably older than any realistic minimum age.
    check(
      DobValidator.validate(DateTime(1990, 5, 15), minimumAgeYears: 18),
    ).isNull();
  });
}
