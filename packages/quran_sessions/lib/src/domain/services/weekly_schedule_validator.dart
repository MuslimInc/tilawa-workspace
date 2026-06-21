import '../entities/time_range.dart';
import '../entities/weekday.dart';
import '../entities/weekly_schedule.dart';
import '../failures/quran_sessions_failure.dart';

/// Validates a [WeeklySchedule] before it is persisted.
///
/// Pure domain logic — no UI, repository, or localisation.
class WeeklyScheduleValidator {
  const WeeklyScheduleValidator();

  static const field = 'weeklySchedule';
  static const invalidRangeCode = 'invalid_range';
  static const overlappingRangesCode = 'overlapping_ranges';
  static const noOpenDaysCode = 'no_open_days';

  /// Returns a [ValidationFailure] when [schedule] cannot be saved, or `null`.
  ValidationFailure? validate(WeeklySchedule schedule) {
    if (schedule.isEmpty) {
      return const ValidationFailure(field: field, code: noOpenDaysCode);
    }

    for (final day in Weekday.values) {
      final ranges = schedule.rangesFor(day);
      for (final range in ranges) {
        if (!range.isValid) {
          return const ValidationFailure(
            field: field,
            code: invalidRangeCode,
          );
        }
      }
      if (_hasOverlaps(ranges)) {
        return const ValidationFailure(
          field: field,
          code: overlappingRangesCode,
        );
      }
    }
    return null;
  }

  bool _hasOverlaps(List<TimeRange> ranges) {
    if (ranges.length < 2) return false;
    final sorted = [...ranges]..sort((a, b) => a.start.compareTo(b.start));
    for (var i = 0; i < sorted.length - 1; i++) {
      if (sorted[i].overlaps(sorted[i + 1])) return true;
    }
    return false;
  }
}
