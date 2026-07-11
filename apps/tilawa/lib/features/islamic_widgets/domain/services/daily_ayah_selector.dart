import '../entities/curated_ayah.dart';

/// Selects a stable daily Ayah without repeating before the pool is exhausted.
class DailyAyahSelector {
  const DailyAyahSelector();

  /// Returns the selection for [localDate] and installation-specific [seed].
  ///
  /// The catalog order defines one complete rotation cycle. The seed shifts
  /// where an installation enters that cycle without changing daily stability.
  CuratedAyah select({
    required DateTime localDate,
    required int seed,
    required List<CuratedAyah> catalog,
  }) {
    if (catalog.isEmpty) {
      throw ArgumentError.value(catalog, 'catalog', 'must not be empty');
    }

    final DateTime calendarDay = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
    );
    final int dayNumber = calendarDay.millisecondsSinceEpoch ~/ _dayMs;
    final int catalogIndex = (dayNumber + seed) % catalog.length;
    return catalog[catalogIndex];
  }

  static const int _dayMs = Duration.millisecondsPerDay;
}
