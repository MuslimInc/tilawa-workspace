import '../../domain/entities/quran_teacher.dart';
import '../models/teacher_availability_summary.dart';
import '../widgets/teacher_list_filter_bar.dart';

/// Applies client-side teacher list filters on top of repository results.
List<QuranTeacher> applyTeacherListClientFilter(
  List<QuranTeacher> teachers,
  TeacherListFilter filter,
  Map<String, TeacherAvailabilitySummary> availabilitySummaries,
) {
  return switch (filter) {
    TeacherListFilter.free =>
      teachers.where((teacher) => teacher.isFree).toList(),
    TeacherListFilter.availableToday =>
      teachers
          .where(
            (teacher) =>
                availabilitySummaries[teacher.id]?.status ==
                TeacherAvailabilityStatus.availableToday,
          )
          .toList(),
    _ => teachers,
  };
}

bool isTeacherListFilterEmptyForClientOnly(
  TeacherListFilter filter,
  List<QuranTeacher> teachers,
  Map<String, TeacherAvailabilitySummary> availabilitySummaries,
) {
  return applyTeacherListClientFilter(
    teachers,
    filter,
    availabilitySummaries,
  ).isEmpty;
}
