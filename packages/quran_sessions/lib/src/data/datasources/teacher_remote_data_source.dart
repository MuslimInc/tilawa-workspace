import '../dtos/quran_teacher_dto.dart';
import '../dtos/session_review_dto.dart';
import '../dtos/teacher_availability_dto.dart';

/// Contract for the network layer that fetches teacher data.
///
/// Implementations may use Dio, http, GraphQL, or Firebase — none of which
/// are imported here.
abstract interface class TeacherRemoteDataSource {
  Future<({List<QuranTeacherDto> teachers, String? nextCursor})> getTeachers({
    String? specialization,
    String? language,
    String? cursor,
  });

  Future<QuranTeacherDto> getTeacherById(String teacherId);

  Future<List<TeacherAvailabilityDto>> getAvailableSlots(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  });

  Future<List<SessionReviewDto>> getTeacherReviews(
    String teacherId, {
    String? cursor,
  });
}
