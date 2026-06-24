import '../dtos/quran_session_dto.dart';

/// Paginated Firestore session query result.
typedef SessionQueryPage = ({
  List<QuranSessionDto> sessions,
  String? nextCursor,
});

abstract interface class SessionRemoteDataSource {
  Future<QuranSessionDto> getSessionById(String sessionId);

  Future<SessionQueryPage> getStudentUpcomingSessions(
    String studentId, {
    String? cursor,
    int limit = 30,
  });

  Future<SessionQueryPage> getStudentPastSessions(
    String studentId, {
    String? cursor,
    int limit = 30,
  });

  Future<List<QuranSessionDto>> getTeacherUpcomingSessions(
    String teacherId, {
    int limit = 30,
  });

  Future<QuranSessionDto> updateNotes(
    String sessionId, {
    required String notes,
  });
}
