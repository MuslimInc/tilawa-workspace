import '../../domain/entities/teacher_availability.dart';
import '../../domain/services/teacher_availability_sort.dart';

/// Local calendar day (midnight) for grouping slots in the UI.
DateTime localDayKey(DateTime instant) {
  final local = instant.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Slots sorted by start time, grouped by local calendar day.
///
/// [days] is earliest-first; each day's slots are also chronological.
({List<DateTime> days, Map<DateTime, List<TeacherAvailability>> byDay})
groupTeacherAvailabilityByLocalDay(List<TeacherAvailability> slots) {
  final sorted = sortTeacherAvailabilityByStart(slots);
  final byDay = <DateTime, List<TeacherAvailability>>{};
  for (final slot in sorted) {
    final day = localDayKey(slot.startsAt);
    (byDay[day] ??= []).add(slot);
  }
  final days = byDay.keys.toList()..sort();
  return (days: days, byDay: byDay);
}
