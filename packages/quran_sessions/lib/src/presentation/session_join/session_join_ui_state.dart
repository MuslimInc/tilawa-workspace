import '../../domain/entities/session_lifecycle_status.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/policies/staging_qa_join_window_bypass.dart';
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
  required DateTime endsAt,
  required DateTime now,
  required bool joinInProgress,
  required QuranSessionsFailure? joinFailure,
  required bool hasOpenedMeeting,
  SessionJoinWindowPolicy joinWindowPolicy = const SessionJoinWindowPolicy(),
  String? qaBypassUserId,
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
    endsAt: endsAt,
    now: now,
    joinWindowPolicy: joinWindowPolicy,
    qaBypassUserId: qaBypassUserId,
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
  if (joinWindowPolicy.isWithinJoinWindow(
    startsAt: startsAt,
    endsAt: endsAt,
    now: now,
    qaBypassUserId: qaBypassUserId,
  )) {
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
  required DateTime endsAt,
  required DateTime now,
  required SessionJoinWindowPolicy joinWindowPolicy,
  String? qaBypassUserId,
}) {
  if (status.isTerminal && !status.isCancelled) {
    return true;
  }
  if (!status.canJoinSession) {
    return true;
  }
  if (isQaJoinWindowBypassEligible(
    userId: qaBypassUserId,
    distribution: joinWindowPolicy.distribution,
  )) {
    return false;
  }
  return now.isAfter(endsAt);
}
