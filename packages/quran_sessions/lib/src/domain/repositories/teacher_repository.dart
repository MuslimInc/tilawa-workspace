import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_teacher.dart';
import '../entities/session_review.dart';
import '../entities/teacher_availability.dart';
import '../failures/quran_sessions_failure.dart';

/// Read-side repository for teacher data.
/// All write paths go through [BookingRepository].
abstract interface class TeacherRepository {
  /// Returns a paginated list of verified teachers.
  ///
  /// [specialization] — optional filter (e.g. 'hifz').
  /// [language]       — optional BCP-47 tag filter.
  /// [cursor]         — opaque pagination token; null for first page.
  Future<Either<QuranSessionsFailure, TeacherPage>> getTeachers({
    String? specialization,
    String? language,
    String? cursor,
  });

  Future<Either<QuranSessionsFailure, QuranTeacher>> getTeacherById(
    String teacherId,
  );

  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>>
  getAvailableSlots(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  });

  Future<Either<QuranSessionsFailure, List<SessionReview>>> getTeacherReviews(
    String teacherId, {
    String? cursor,
  });
}

class TeacherPage {
  const TeacherPage({
    required this.teachers,
    required this.nextCursor,
  });

  final List<QuranTeacher> teachers;
  final String? nextCursor;
}
