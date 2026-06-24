import 'package:equatable/equatable.dart';

import '../../../domain/entities/session_aggregate.dart';
import '../../../domain/entities/session_audit_event.dart';
import '../../../domain/entities/session_call_provider_kind.dart';
import '../../../domain/entities/pending_reschedule_request.dart';
import '../../../domain/entities/session_call_type.dart';
import '../../../domain/entities/session_lifecycle_status.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

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

  bool get canJoin =>
      aggregate.sessionId != null && aggregate.lifecycleStatus.canJoinSession;

  bool get canOpenDispute => aggregate.lifecycleStatus.canOpenDispute;

  bool get canOpenMeetingAgain =>
      externalMeetingJoinUrl != null && hasOpenedExternalMeeting;

  bool get isExternalMeeting => externalMeetingJoinUrl != null;

  bool get supportsInAppMicrophoneMute =>
      callProviderKind == SessionCallProviderKind.agora ||
      callProviderKind == SessionCallProviderKind.webrtc;

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
  ];
}

final class SessionDetailFailure extends SessionDetailState {
  const SessionDetailFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
