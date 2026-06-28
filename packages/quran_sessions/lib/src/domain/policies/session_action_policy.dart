import '../entities/session_lifecycle_status.dart';

/// Which post-booking actions are available on session detail for a lifecycle state.
abstract final class SessionActionPolicy {
  static bool canJoin(SessionLifecycleStatus status) => status.canJoinSession;

  static bool canReportConcern(SessionLifecycleStatus status) => true;

  static bool canOpenDispute(SessionLifecycleStatus status) =>
      status.canOpenDispute;

  /// Show helper copy explaining dispute eligibility on cancelled sessions.
  static bool showCancelledDisputeHelper(SessionLifecycleStatus status) =>
      status.isCancelled && status.canOpenDispute;
}
