import 'package:flutter/material.dart';

import '../../domain/entities/quran_teacher.dart';
import '../models/teacher_availability_summary.dart';
import 'quran_session_teacher_compact_card.dart';

/// Compact card showing teacher avatar, name, specializations, rating, and price.
/// Used in [TeacherListScreen] and the feature home preview.
class TeacherCard extends StatelessWidget {
  const TeacherCard({
    super.key,
    required this.teacher,
    required this.onTap,
    this.availabilitySummary,
    this.onBook,
    this.onViewProfile,
  });

  final QuranTeacher teacher;
  final VoidCallback onTap;
  final TeacherAvailabilitySummary? availabilitySummary;
  final VoidCallback? onBook;
  final VoidCallback? onViewProfile;

  @override
  Widget build(BuildContext context) {
    return QuranSessionTeacherCompactCard(
      teacher: teacher,
      onTap: onTap,
      availabilitySummary: availabilitySummary,
      onBook: onBook,
      onViewProfile: onViewProfile,
    );
  }
}
