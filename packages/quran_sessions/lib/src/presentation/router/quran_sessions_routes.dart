/// Route path constants for the quran_sessions feature.
///
/// The host app wires these into its GoRouter configuration. No GoRouter
/// import belongs in this package — the app owns the router.
abstract final class QuranSessionsRoutes {
  static const home = '/sessions';
  static const teacherList = '/sessions/teachers';
  static const teacherProfile = '/sessions/teachers/:teacherId';
  static const booking = '/sessions/teachers/:teacherId/book';
  static const mySessions = '/sessions/my';
  static const teacherDashboard = '/sessions/dashboard';
  static const profileCompletion = '/sessions/profile/complete';

  // ── Teacher application flow ────────────────────────────────────────────────
  static const teacherApply = '/sessions/teacher/apply';
  static const teacherApplicationStatus = '/sessions/teacher/status';
}
