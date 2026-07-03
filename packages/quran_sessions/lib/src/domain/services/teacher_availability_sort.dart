import '../entities/teacher_availability.dart';

/// Whether [slots] are already ordered earliest-first by [TeacherAvailability.startsAt].
bool isTeacherAvailabilitySortedByStart(List<TeacherAvailability> slots) {
  for (var index = 1; index < slots.length; index++) {
    final previous = slots[index - 1].startsAt;
    final current = slots[index].startsAt;
    if (current.isBefore(previous)) {
      return false;
    }
  }
  return true;
}

/// Returns [slots] sorted earliest-first by [TeacherAvailability.startsAt].
List<TeacherAvailability> sortTeacherAvailabilityByStart(
  List<TeacherAvailability> slots,
) {
  if (isTeacherAvailabilitySortedByStart(slots)) {
    return slots;
  }
  return List<TeacherAvailability>.from(slots)
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
}
