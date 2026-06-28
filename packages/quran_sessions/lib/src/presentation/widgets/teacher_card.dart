import 'package:flutter/material.dart';

import '../../domain/entities/quran_teacher.dart';
import '../models/teacher_availability_summary.dart';
import 'quran_session_teacher_compact_card.dart';

/// Compact card showing teacher avatar, name, specializations, rating, and price.
/// Used in [TeacherListScreen] and the feature home preview.
///
/// The whole card navigates to the teacher profile; booking starts there.
class TeacherCard extends StatelessWidget {
  const TeacherCard({
    super.key,
    required this.teacher,
    required this.onTap,
    this.availabilitySummary,
  });

  final QuranTeacher teacher;
  final VoidCallback onTap;
  final TeacherAvailabilitySummary? availabilitySummary;

  @override
  Widget build(BuildContext context) {
    return QuranSessionTeacherCompactCard(
      teacher: teacher,
      onTap: onTap,
      availabilitySummary: availabilitySummary,
    );
  }
}
