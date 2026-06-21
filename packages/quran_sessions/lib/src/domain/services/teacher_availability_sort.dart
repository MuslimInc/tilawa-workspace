import '../entities/teacher_availability.dart';

/// Returns [slots] sorted earliest-first by [TeacherAvailability.startsAt].
List<TeacherAvailability> sortTeacherAvailabilityByStart(
  List<TeacherAvailability> slots,
) {
  return List<TeacherAvailability>.from(slots)
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
}
