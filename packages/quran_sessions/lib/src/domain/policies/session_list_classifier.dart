import '../entities/quran_session.dart';
import '../entities/session_lifecycle_status.dart';

/// Shared rules for which sessions belong in upcoming vs cancelled vs past lists.
abstract final class SessionListClassifier {
  /// Teacher dashboard "Upcoming sessions" — actionable / joinable lifecycle only.
  static bool isTeacherDashboardUpcoming(QuranSession session) {
    return isActionableUpcomingLifecycle(session.effectiveLifecycleStatus);
  }

  /// Student "Upcoming" tab — same actionable lifecycle set as teacher dashboard.
  static bool isStudentUpcoming(QuranSession session) {
    return isActionableUpcomingLifecycle(session.effectiveLifecycleStatus);
  }

  /// True when lifecycle is active and the session may still be joined or managed.
  static bool isActionableUpcomingLifecycle(SessionLifecycleStatus status) {
    return switch (status) {
      SessionLifecycleStatus.scheduled ||
      SessionLifecycleStatus.confirmed ||
      SessionLifecycleStatus.inProgress ||
      SessionLifecycleStatus.rescheduled => true,
      _ => false,
    };
  }

  /// Cancelled, rejected, completed, missed, expired, and other inactive terminals.
  static bool isCancelledOrInactive(QuranSession session) {
    if (isCancelledSession(session)) return true;
    return isInactiveTerminalLifecycle(session.effectiveLifecycleStatus);
  }

  /// Matches student My Sessions "Cancelled" tab membership.
  static bool isCancelledSession(QuranSession session) {
    if (session.effectiveLifecycleStatus.isCancelled) return true;
    return switch (session.status) {
      QuranSessionStatus.cancelledByStudent ||
      QuranSessionStatus.cancelledByTeacher => true,
      _ => false,
    };
  }

  static bool isInactiveTerminalLifecycle(SessionLifecycleStatus status) {
    if (status.isCancelled) return true;
    return switch (status) {
      SessionLifecycleStatus.rejectedByTutor ||
      SessionLifecycleStatus.completed ||
      SessionLifecycleStatus.expired ||
      SessionLifecycleStatus.teacherNoShow ||
      SessionLifecycleStatus.studentNoShow ||
      SessionLifecycleStatus.bothNoShow ||
      SessionLifecycleStatus.incomplete ||
      SessionLifecycleStatus.disputed ||
      SessionLifecycleStatus.compensated ||
      SessionLifecycleStatus.refunded => true,
      _ => false,
    };
  }
}
