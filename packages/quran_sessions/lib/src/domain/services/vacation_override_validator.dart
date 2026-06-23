import '../entities/availability_override.dart';

/// Validates vacation (unavailable) date ranges against existing overrides.
///
/// Pure domain logic — no UI, no repository, no localisation.
class VacationOverrideValidator {
  const VacationOverrideValidator();

  static const field = 'vacation';
  static const overlapsExistingCode = 'overlaps_existing';

  /// Whether [endDate] is on or after [startDate] (calendar-day comparison).
  bool hasValidDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = _normalize(startDate);
    final end = _normalize(endDate);
    return !end.isBefore(start);
  }

  /// First calendar day in `[startDate, endDate]` that already has an
  /// unavailable override, or `null` when the range is clear.
  DateTime? findFirstOverlappingVacationDay({
    required DateTime startDate,
    required DateTime endDate,
    required List<AvailabilityOverride> existingOverrides,
  }) {
    if (!hasValidDateRange(startDate: startDate, endDate: endDate)) {
      return null;
    }

    final blockedDates = {
      for (final override in existingOverrides)
        if (override.type == OverrideType.unavailable) override.dateKey,
    };

    var day = _normalize(startDate);
    final last = _normalize(endDate);
    while (!day.isAfter(last)) {
      if (blockedDates.contains(_dateKey(day))) return day;
      day = day.add(const Duration(days: 1));
    }
    return null;
  }

  /// Builds one unavailable override per calendar day in `[startDate, endDate]`.
  List<AvailabilityOverride> expandVacationRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final overrides = <AvailabilityOverride>[];
    var day = _normalize(startDate);
    final last = _normalize(endDate);

    while (!day.isAfter(last)) {
      overrides.add(
        AvailabilityOverride(
          date: day,
          type: OverrideType.unavailable,
          reason: 'vacation',
        ),
      );
      day = day.add(const Duration(days: 1));
    }
    return overrides;
  }

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
