import '../dtos/quran_session_dto.dart';

abstract interface class SessionRemoteDataSource {
  Future<QuranSessionDto> getSessionById(String sessionId);
  Future<List<QuranSessionDto>> getStudentSessions(String studentId);
  Future<List<QuranSessionDto>> getTeacherSessions(String teacherId);
  Future<QuranSessionDto> updateNotes(
    String sessionId, {
    required String notes,
  });
}
