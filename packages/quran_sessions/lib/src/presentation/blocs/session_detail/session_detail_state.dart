import 'package:equatable/equatable.dart';

import '../../../domain/entities/session_aggregate.dart';
import '../../../domain/entities/session_audit_event.dart';
import '../../../domain/entities/session_call_provider_kind.dart';
import '../../../domain/entities/pending_reschedule_request.dart';
import '../../../domain/entities/session_call_type.dart';
import '../../../domain/entities/session_lifecycle_status.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/entities/session_allowed_action.dart';
import '../../../domain/policies/platform_scheduling_policy.dart';
import '../../../domain/policies/session_join_window_policy.dart';
import '../../../domain/value_objects/actor_role.dart';
import '../../../domain/policies/session_cancel_eligibility_policy.dart';
import '../../../domain/policies/session_action_policy.dart';
import '../../session_join/session_join_ui_state.dart';

sealed class SessionDetailState extends Equatable {
  const SessionDetailState();

  @override
  List<Object?> get props => [];
}

final class SessionDetailInitial extends SessionDetailState {
  const SessionDetailInitial();
}

final class SessionDetailLoading extends SessionDetailState {
  const SessionDetailLoading();
}

final class SessionDetailSuccess extends SessionDetailState {
  const SessionDetailSuccess({
    required this.aggregate,
    required this.timeline,
    this.callType,
    this.externalMeetingJoinUrl,
    this.callProviderKind,
    this.timelineLoadFailed = false,
    this.pendingRescheduleLoadFailed = false,
    this.hasOpenedExternalMeeting = false,
    this.joinInProgress = false,
    this.joinFailure,
    this.reportInProgress = false,
    this.reportFailure,
    this.reportSubmitted = false,
    this.disputeInProgress = false,
    this.disputeFailure,
    this.disputeSubmitted = false,
    this.pendingRescheduleRequest,
    this.canRespondToReschedule = false,
    this.isAwaitingRescheduleCounterparty = false,
    this.rescheduleRespondInProgress = false,
    this.rescheduleRespondFailure,
    this.rescheduleRespondAccepted,
    this.cancellationInProgress = false,
    this.cancellationFailure,
    this.cancellationSucceeded = false,
    this.reviewInProgress = false,
    this.reviewFailure,
    this.reviewSubmitted = false,
    this.reviewCompleted = false,
    this.joinWindowPolicy = const SessionJoinWindowPolicy(),
    this.viewerRole,
  });

  final SessionAggregate aggregate;
  final List<SessionAuditEvent> timeline;
  final SessionCallType? callType;
  final String? externalMeetingJoinUrl;
  final SessionCallProviderKind? callProviderKind;
  final bool timelineLoadFailed;
  final bool pendingRescheduleLoadFailed;
  final bool hasOpenedExternalMeeting;
  final bool joinInProgress;
  final QuranSessionsFailure? joinFailure;
  final bool reportInProgress;
  final QuranSessionsFailure? reportFailure;
  final bool reportSubmitted;
  final bool disputeInProgress;
  final QuranSessionsFailure? disputeFailure;
  final bool disputeSubmitted;
  final PendingRescheduleRequest? pendingRescheduleRequest;
  final bool canRespondToReschedule;
  final bool isAwaitingRescheduleCounterparty;
  final bool rescheduleRespondInProgress;
  final QuranSessionsFailure? rescheduleRespondFailure;

  /// `true` accepted, `false` rejected, `null` not yet responded.
  final bool? rescheduleRespondAccepted;
  final bool cancellationInProgress;
  final QuranSessionsFailure? cancellationFailure;
  final bool cancellationSucceeded;
  final bool reviewInProgress;
  final QuranSessionsFailure? reviewFailure;
  final bool reviewSubmitted;
  final bool reviewCompleted;
  final SessionJoinWindowPolicy joinWindowPolicy;
  final ActorRole? viewerRole;

  SessionJoinUiState get joinUiState => resolveSessionJoinUiState(
    lifecycleStatus: aggregate.lifecycleStatus,
    startsAt: aggregate.startsAt,
    endsAt: aggregate.startsAt.add(
      const Duration(
        minutes: PlatformSchedulingPolicy.defaultSlotDurationMinutes,
      ),
    ),
    now: DateTime.now(),
    joinInProgress: joinInProgress,
    joinFailure: joinFailure,
    hasOpenedMeeting: hasOpenedExternalMeeting,
    joinWindowPolicy: joinWindowPolicy,
  );

  bool get isTeacherViewer => viewerRole == ActorRole.teacher;

  SessionAllowedActions? get _serverAllowedActions => isTeacherViewer
      ? aggregate.allowedActionsForTeacher
      : aggregate.allowedActionsForStudent;

  bool get canCancel {
    final server = _serverAllowedActions;
    if (server != null) return server.can(SessionAllowedAction.cancel);
    return canViewerCancelSession(aggregate, viewerRole);
  }

  bool get canJoin {
    final server = _serverAllowedActions;
    if (server != null) {
      return aggregate.sessionId != null &&
          server.can(SessionAllowedAction.join) &&
          !joinInProgress;
    }
    return aggregate.sessionId != null &&
        joinUiState == SessionJoinUiState.joinAvailable;
  }

  bool get canOpenDispute {
    final server = _serverAllowedActions;
    if (server != null) return server.can(SessionAllowedAction.openDispute);
    return SessionActionPolicy.canOpenDispute(aggregate.lifecycleStatus);
  }

  bool get canReportConcern {
    final server = _serverAllowedActions;
    if (server != null) return server.can(SessionAllowedAction.reportConcern);
    return SessionActionPolicy.canReportConcern(aggregate.lifecycleStatus);
  }

  bool get showCancelledDisputeHelper =>
      SessionActionPolicy.showCancelledDisputeHelper(aggregate.lifecycleStatus);

  bool get canOpenMeetingAgain =>
      externalMeetingJoinUrl != null && hasOpenedExternalMeeting;

  bool get canReview {
    if (isTeacherViewer) return false;
    final server = _serverAllowedActions;
    if (server != null) {
      return server.can(SessionAllowedAction.submitReview) && !reviewCompleted;
    }
    return aggregate.lifecycleStatus == SessionLifecycleStatus.completed &&
        !reviewCompleted;
  }

  bool get isExternalMeeting => externalMeetingJoinUrl != null;

  bool get supportsInAppMicrophoneMute =>
      callProviderKind == SessionCallProviderKind.agora ||
      callProviderKind == SessionCallProviderKind.livekit;

  /// Booked sessions lock call mode/provider (Option A — see spec 037).
  bool get showLockedAtBookingCopy =>
      aggregate.lifecycleStatus == SessionLifecycleStatus.scheduled ||
      aggregate.lifecycleStatus == SessionLifecycleStatus.confirmed;

  SessionDetailSuccess copyWith({
    SessionAggregate? aggregate,
    List<SessionAuditEvent>? timeline,
    SessionCallType? callType,
    bool clearCallType = false,
    String? externalMeetingJoinUrl,
    bool clearExternalMeetingJoinUrl = false,
    SessionCallProviderKind? callProviderKind,
    bool clearCallProviderKind = false,
    bool? timelineLoadFailed,
    bool clearTimelineLoadFailed = false,
    bool? pendingRescheduleLoadFailed,
    bool clearPendingRescheduleLoadFailed = false,
    bool? hasOpenedExternalMeeting,
    bool? joinInProgress,
    bool clearJoinInProgress = false,
    QuranSessionsFailure? joinFailure,
    bool clearJoinFailure = false,
    bool? reportInProgress,
    bool clearReportInProgress = false,
    QuranSessionsFailure? reportFailure,
    bool clearReportFailure = false,
    bool? reportSubmitted,
    bool clearReportSubmitted = false,
    bool? disputeInProgress,
    bool clearDisputeInProgress = false,
    QuranSessionsFailure? disputeFailure,
    bool clearDisputeFailure = false,
    bool? disputeSubmitted,
    bool clearDisputeSubmitted = false,
    PendingRescheduleRequest? pendingRescheduleRequest,
    bool clearPendingRescheduleRequest = false,
    bool? canRespondToReschedule,
    bool? isAwaitingRescheduleCounterparty,
    bool? rescheduleRespondInProgress,
    bool clearRescheduleRespondInProgress = false,
    QuranSessionsFailure? rescheduleRespondFailure,
    bool clearRescheduleRespondFailure = false,
    bool? rescheduleRespondAccepted,
    bool clearRescheduleRespondAccepted = false,
    bool? cancellationInProgress,
    bool clearCancellationInProgress = false,
    QuranSessionsFailure? cancellationFailure,
    bool clearCancellationFailure = false,
    bool? cancellationSucceeded,
    bool clearCancellationSucceeded = false,
    bool? reviewInProgress,
    bool clearReviewInProgress = false,
    QuranSessionsFailure? reviewFailure,
    bool clearReviewFailure = false,
    bool? reviewSubmitted,
    bool clearReviewSubmitted = false,
    bool? reviewCompleted,
    ActorRole? viewerRole,
    bool clearViewerRole = false,
  }) {
    return SessionDetailSuccess(
      aggregate: aggregate ?? this.aggregate,
      timeline: timeline ?? this.timeline,
      callType: clearCallType ? null : callType ?? this.callType,
      externalMeetingJoinUrl: clearExternalMeetingJoinUrl
          ? null
          : externalMeetingJoinUrl ?? this.externalMeetingJoinUrl,
      callProviderKind: clearCallProviderKind
          ? null
          : callProviderKind ?? this.callProviderKind,
      timelineLoadFailed: clearTimelineLoadFailed
          ? false
          : timelineLoadFailed ?? this.timelineLoadFailed,
      pendingRescheduleLoadFailed: clearPendingRescheduleLoadFailed
          ? false
          : pendingRescheduleLoadFailed ?? this.pendingRescheduleLoadFailed,
      hasOpenedExternalMeeting:
          hasOpenedExternalMeeting ?? this.hasOpenedExternalMeeting,
      joinInProgress: clearJoinInProgress
          ? false
          : joinInProgress ?? this.joinInProgress,
      joinFailure: clearJoinFailure ? null : joinFailure ?? this.joinFailure,
      reportInProgress: clearReportInProgress
          ? false
          : reportInProgress ?? this.reportInProgress,
      reportFailure: clearReportFailure
          ? null
          : reportFailure ?? this.reportFailure,
      reportSubmitted: clearReportSubmitted
          ? false
          : reportSubmitted ?? this.reportSubmitted,
      disputeInProgress: clearDisputeInProgress
          ? false
          : disputeInProgress ?? this.disputeInProgress,
      disputeFailure: clearDisputeFailure
          ? null
          : disputeFailure ?? this.disputeFailure,
      disputeSubmitted: clearDisputeSubmitted
          ? false
          : disputeSubmitted ?? this.disputeSubmitted,
      pendingRescheduleRequest: clearPendingRescheduleRequest
          ? null
          : pendingRescheduleRequest ?? this.pendingRescheduleRequest,
      canRespondToReschedule:
          canRespondToReschedule ?? this.canRespondToReschedule,
      isAwaitingRescheduleCounterparty:
          isAwaitingRescheduleCounterparty ??
          this.isAwaitingRescheduleCounterparty,
      rescheduleRespondInProgress: clearRescheduleRespondInProgress
          ? false
          : rescheduleRespondInProgress ?? this.rescheduleRespondInProgress,
      rescheduleRespondFailure: clearRescheduleRespondFailure
          ? null
          : rescheduleRespondFailure ?? this.rescheduleRespondFailure,
      rescheduleRespondAccepted: clearRescheduleRespondAccepted
          ? null
          : rescheduleRespondAccepted ?? this.rescheduleRespondAccepted,
      cancellationInProgress: clearCancellationInProgress
          ? false
          : cancellationInProgress ?? this.cancellationInProgress,
      cancellationFailure: clearCancellationFailure
          ? null
          : cancellationFailure ?? this.cancellationFailure,
      cancellationSucceeded: clearCancellationSucceeded
          ? false
          : cancellationSucceeded ?? this.cancellationSucceeded,
      reviewInProgress: clearReviewInProgress
          ? false
          : reviewInProgress ?? this.reviewInProgress,
      reviewFailure: clearReviewFailure
          ? null
          : reviewFailure ?? this.reviewFailure,
      reviewSubmitted: clearReviewSubmitted
          ? false
          : reviewSubmitted ?? this.reviewSubmitted,
      reviewCompleted: reviewCompleted ?? this.reviewCompleted,
      viewerRole: clearViewerRole ? null : viewerRole ?? this.viewerRole,
    );
  }

  @override
  List<Object?> get props => [
    aggregate,
    timeline,
    callType,
    externalMeetingJoinUrl,
    callProviderKind,
    timelineLoadFailed,
    pendingRescheduleLoadFailed,
    hasOpenedExternalMeeting,
    joinInProgress,
    joinFailure,
    reportInProgress,
    reportFailure,
    reportSubmitted,
    disputeInProgress,
    disputeFailure,
    disputeSubmitted,
    pendingRescheduleRequest,
    canRespondToReschedule,
    isAwaitingRescheduleCounterparty,
    rescheduleRespondInProgress,
    rescheduleRespondFailure,
    rescheduleRespondAccepted,
    cancellationInProgress,
    cancellationFailure,
    cancellationSucceeded,
    reviewInProgress,
    reviewFailure,
    reviewSubmitted,
    reviewCompleted,
    joinWindowPolicy,
    viewerRole,
  ];
}

final class SessionDetailFailure extends SessionDetailState {
  const SessionDetailFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
