import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

void main() {
  const validator = WeeklyScheduleValidator();

  WeeklySchedule scheduleWith({
    Map<Weekday, List<TimeRange>>? rules,
  }) => WeeklySchedule(
    teacherId: 'teacher_1',
    timezone: 'Africa/Cairo',
    slotDuration: SlotDuration.thirty,
    rules:
        rules ??
        {
          Weekday.saturday: const [
            TimeRange(start: LocalTime(9, 0), end: LocalTime(17, 0)),
          ],
        },
  );

  group('WeeklyScheduleValidator', () {
    test('accepts a schedule with one valid open day', () {
      check(validator.validate(scheduleWith())).isNull();
    });

    test('rejects when no day is open', () {
      final failure = validator.validate(
        scheduleWith(
          rules: {for (final day in Weekday.values) day: const <TimeRange>[]},
        ),
      );

      check(failure).isA<ValidationFailure>();
      check(failure!.field).equals(WeeklyScheduleValidator.field);
      check(failure.code).equals(WeeklyScheduleValidator.noOpenDaysCode);
    });

    test('rejects invalid start/end times', () {
      final failure = validator.validate(
        scheduleWith(
          rules: {
            Weekday.monday: const [
              TimeRange(start: LocalTime(17, 0), end: LocalTime(9, 0)),
            ],
          },
        ),
      );

      check(failure).isA<ValidationFailure>();
      check(failure!.code).equals(WeeklyScheduleValidator.invalidRangeCode);
    });

    test('rejects overlapping ranges on the same day', () {
      final failure = validator.validate(
        scheduleWith(
          rules: {
            Weekday.monday: const [
              TimeRange(start: LocalTime(9, 0), end: LocalTime(12, 0)),
              TimeRange(start: LocalTime(11, 0), end: LocalTime(14, 0)),
            ],
          },
        ),
      );

      check(failure).isA<ValidationFailure>();
      check(
        failure!.code,
      ).equals(WeeklyScheduleValidator.overlappingRangesCode);
    });
  });
}
