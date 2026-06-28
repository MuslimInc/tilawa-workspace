class SessionCacheKey {
  const SessionCacheKey._();

  static String teacherProfileByUserId(String userId) =>
      'teacherProfileByUserId:$userId';

  static String teacherProfileById(String teacherProfileId) =>
      'teacherProfileById:$teacherProfileId';

  static String teacherSchedule(String teacherProfileId) =>
      'teacherSchedule:$teacherProfileId';

  static String teacherDashboardSessions(String teacherProfileId) =>
      'teacherDashboardSessions:$teacherProfileId';

  static String teacherAvailability(String teacherProfileId) =>
      'teacherAvailability:$teacherProfileId';

  static String sessionDetail(String sessionId) => 'sessionDetail:$sessionId';

  static String studentSessions(String studentId) =>
      'studentSessions:$studentId';
}
