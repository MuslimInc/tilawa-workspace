import '../../domain/entities/teacher_availability.dart';
import '../../domain/services/teacher_availability_sort.dart';

/// Local calendar day (midnight) for grouping slots in the UI.
DateTime localDayKey(DateTime instant) {
  final local = instant.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Slots grouped by local calendar day.
///
/// When [slots] are already sorted by [TeacherAvailability.startsAt] (the
/// normal path from [SlotGenerator] / availability use cases), grouping is a
/// single O(n) pass with no extra sort. Unsorted input pays one O(n log n) sort.
///
/// [days] is earliest-first; each day's slots are chronological.
({List<DateTime> days, Map<DateTime, List<TeacherAvailability>> byDay})
groupTeacherAvailabilityByLocalDay(List<TeacherAvailability> slots) {
  if (slots.isEmpty) {
    return (days: const <DateTime>[], byDay: const {});
  }

  final List<TeacherAvailability> ordered =
      isTeacherAvailabilitySortedByStart(
        slots,
      )
      ? slots
      : (List<TeacherAvailability>.from(slots)
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt)));

  final byDay = <DateTime, List<TeacherAvailability>>{};
  final days = <DateTime>[];

  for (final slot in ordered) {
    final day = localDayKey(slot.startsAt);
    final bucket = byDay[day];
    if (bucket == null) {
      byDay[day] = <TeacherAvailability>[slot];
      days.add(day);
      continue;
    }
    bucket.add(slot);
  }

  return (days: days, byDay: byDay);
}
