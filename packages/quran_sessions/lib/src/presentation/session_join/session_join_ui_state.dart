import '../../domain/entities/session_lifecycle_status.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/policies/session_join_window_policy.dart';

/// Student-facing join availability on session detail and my sessions.
enum SessionJoinUiState {
  notStarted,
  joinAvailable,
  joining,
  joined,
  failed,
  ended,
  cancelled,
  awaitingTutorApproval,
  rejectedByTutor,
}

/// Resolves [SessionJoinUiState] from lifecycle, join window, and in-flight join.
SessionJoinUiState resolveSessionJoinUiState({
  required SessionLifecycleStatus lifecycleStatus,
  required DateTime startsAt,
  required DateTime now,
  required bool joinInProgress,
  required QuranSessionsFailure? joinFailure,
  required bool hasOpenedMeeting,
  SessionJoinWindowPolicy joinWindowPolicy = const SessionJoinWindowPolicy(),
}) {
  if (lifecycleStatus.isCancelled) {
    return SessionJoinUiState.cancelled;
  }
  if (lifecycleStatus == SessionLifecycleStatus.pendingTutorApproval) {
    return SessionJoinUiState.awaitingTutorApproval;
  }
  if (lifecycleStatus == SessionLifecycleStatus.rejectedByTutor) {
    return SessionJoinUiState.rejectedByTutor;
  }
  if (_isJoinWindowEnded(
    lifecycleStatus,
    startsAt: startsAt,
    now: now,
    joinWindowPolicy: joinWindowPolicy,
  )) {
    return SessionJoinUiState.ended;
  }
  if (joinInProgress) {
    return SessionJoinUiState.joining;
  }
  if (joinFailure != null) {
    return SessionJoinUiState.failed;
  }
  if (hasOpenedMeeting ||
      lifecycleStatus == SessionLifecycleStatus.inProgress) {
    return SessionJoinUiState.joined;
  }
  if (!lifecycleStatus.canJoinSession) {
    return SessionJoinUiState.ended;
  }
  if (joinWindowPolicy.isWithinJoinWindow(startsAt: startsAt, now: now)) {
    return SessionJoinUiState.joinAvailable;
  }
  final windowStart = startsAt.subtract(joinWindowPolicy.prefetchLeadTime);
  if (now.isBefore(windowStart)) {
    return SessionJoinUiState.notStarted;
  }
  return SessionJoinUiState.ended;
}

bool _isJoinWindowEnded(
  SessionLifecycleStatus status, {
  required DateTime startsAt,
  required DateTime now,
  required SessionJoinWindowPolicy joinWindowPolicy,
}) {
  if (status.isTerminal && !status.isCancelled) {
    return true;
  }
  if (!status.canJoinSession) {
    return true;
  }
  final windowEnd = startsAt.add(joinWindowPolicy.postStartGrace);
  return !now.isBefore(windowEnd);
}
