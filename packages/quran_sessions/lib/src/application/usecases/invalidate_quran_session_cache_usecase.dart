import '../cache/quran_session_cache_store.dart';
import '../cache/session_cache_key.dart';

class InvalidateQuranSessionCacheUseCase {
  const InvalidateQuranSessionCacheUseCase(this.cacheStore);

  final QuranSessionCacheStore cacheStore;

  void invalidateSession(
    String sessionId, {
    String? teacherProfileId,
    String? studentId,
  }) {
    cacheStore.remove(SessionCacheKey.sessionDetail(sessionId));
    if (teacherProfileId != null && teacherProfileId.isNotEmpty) {
      cacheStore.remove(
        SessionCacheKey.teacherDashboardSessions(teacherProfileId),
      );
      cacheStore.remove(SessionCacheKey.teacherAvailability(teacherProfileId));
    }
    if (studentId != null && studentId.isNotEmpty) {
      cacheStore.remove(SessionCacheKey.studentSessions(studentId));
    }
  }

  void invalidateTeacher(String teacherProfileId) {
    cacheStore.remove(SessionCacheKey.teacherProfileById(teacherProfileId));
    cacheStore.remove(SessionCacheKey.teacherSchedule(teacherProfileId));
    cacheStore.remove(
      SessionCacheKey.teacherDashboardSessions(teacherProfileId),
    );
    cacheStore.remove(SessionCacheKey.teacherAvailability(teacherProfileId));
  }

  void invalidateStudent(String studentId) {
    cacheStore.remove(SessionCacheKey.studentSessions(studentId));
  }
}
