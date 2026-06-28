import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';

import '../../domain/entities/session_audit_event.dart';
import '../../domain/entities/session_lifecycle_status.dart';
import '../../domain/services/lifecycle_status_parser.dart';
import '../../domain/value_objects/actor_role.dart';
import '../../domain/value_objects/session_action.dart';

/// Context-aware session status copy for detail screens.
extension SessionStatusDisplayL10n on SessionLifecycleStatus {
  String sessionDetailStatusLabel(
    QuranSessionsLocalizations l10n, {
    ActorRole? viewerRole,
  }) {
    return switch (this) {
      SessionLifecycleStatus.cancelledByTeacher => switch (viewerRole) {
        ActorRole.teacher => l10n.sessionStatusCancelledByTutorSelf,
        _ => l10n.sessionStatusCancelledByTutorDetail,
      },
      SessionLifecycleStatus.cancelledByStudent => switch (viewerRole) {
        ActorRole.student => l10n.sessionStatusCancelledByStudentSelf,
        _ => l10n.sessionStatusCancelledByStudentDetail,
      },
      SessionLifecycleStatus.cancelledByAdmin =>
        l10n.sessionStatusCancelledBySupportDetail,
      _ => localizedLabel(l10n),
    };
  }

  String? sessionDetailStatusDescription(QuranSessionsLocalizations l10n) {
    if (isCancelled) {
      return l10n.sessionStatusCancelledDescription;
    }
    return null;
  }
}

/// Timeline row title/subtitle — never exposes raw enum or reason codes.
extension SessionTimelinePresentationL10n on SessionAuditEvent {
  String timelineEntryTitle(QuranSessionsLocalizations l10n) {
    final fromReason = _inferStatusFromReason(reason);
    if (fromReason != null) {
      return switch (fromReason) {
        SessionLifecycleStatus.cancelledByTeacher =>
          l10n.sessionTimelineCancelledByTutor,
        SessionLifecycleStatus.cancelledByStudent =>
          l10n.sessionTimelineCancelledByStudent,
        SessionLifecycleStatus.cancelledByAdmin =>
          l10n.sessionTimelineCancelledBySupport,
        _ => action.localizedLabel(l10n),
      };
    }

    return switch (action) {
      SessionAction.confirmBooking ||
      SessionAction.confirmFreeBooking ||
      SessionAction.acceptBookingRequest =>
        l10n.sessionTimelineBookingConfirmed,
      SessionAction.cancelByTeacher => l10n.sessionTimelineCancelledByTutor,
      SessionAction.cancelByStudent => l10n.sessionTimelineCancelledByStudent,
      SessionAction.cancelByAdmin => l10n.sessionTimelineCancelledBySupport,
      _ => action.localizedLabel(l10n),
    };
  }

  String timelineEntrySubtitle(QuranSessionsLocalizations l10n) {
    final inferredStatus = _inferStatusFromReason(reason);
    if (inferredStatus != null) {
      return inferredStatus.sessionDetailStatusLabel(l10n);
    }

    if (reason != null && reason!.trim().isNotEmpty) {
      final parsed = tryParseLifecycleStatusFromRaw(reason!);
      if (parsed != null) {
        return parsed.localizedLabel(l10n);
      }
    }

    return l10n.sessionTimelineStatusTransition(
      previousStatus.localizedLabel(l10n),
      newStatus.localizedLabel(l10n),
    );
  }
}

SessionLifecycleStatus? _inferStatusFromReason(String? raw) {
  if (raw == null) return null;
  return tryParseLifecycleStatusFromRaw(raw);
}

/// Re-export lifecycle labels used by [SessionStatusDisplayL10n].
extension SessionLifecycleStatusL10n on SessionLifecycleStatus {
  String localizedLabel(QuranSessionsLocalizations l10n) => switch (this) {
    SessionLifecycleStatus.draft => l10n.sessionLifecycleDraft,
    SessionLifecycleStatus.pendingPayment =>
      l10n.sessionLifecyclePendingPayment,
    SessionLifecycleStatus.pendingTutorApproval =>
      l10n.sessionLifecycleBookingUnderReview,
    SessionLifecycleStatus.scheduled => l10n.sessionLifecycleScheduled,
    SessionLifecycleStatus.confirmed => l10n.sessionLifecycleConfirmed,
    SessionLifecycleStatus.inProgress => l10n.sessionLifecycleInProgress,
    SessionLifecycleStatus.rescheduled => l10n.sessionLifecycleRescheduled,
    SessionLifecycleStatus.cancelledByStudent =>
      l10n.sessionLifecycleCancelledByStudent,
    SessionLifecycleStatus.cancelledByTeacher =>
      l10n.sessionLifecycleCancelledByTeacher,
    SessionLifecycleStatus.cancelledByAdmin =>
      l10n.sessionLifecycleCancelledByAdmin,
    SessionLifecycleStatus.teacherNoShow => l10n.sessionLifecycleTeacherNoShow,
    SessionLifecycleStatus.studentNoShow => l10n.sessionLifecycleStudentNoShow,
    SessionLifecycleStatus.bothNoShow => l10n.sessionLifecycleBothNoShow,
    SessionLifecycleStatus.incomplete => l10n.sessionLifecycleIncomplete,
    SessionLifecycleStatus.completed => l10n.sessionLifecycleCompleted,
    SessionLifecycleStatus.disputed => l10n.sessionLifecycleDisputed,
    SessionLifecycleStatus.compensated => l10n.sessionLifecycleCompensated,
    SessionLifecycleStatus.refunded => l10n.sessionLifecycleRefunded,
    SessionLifecycleStatus.expired => l10n.sessionLifecycleExpired,
    SessionLifecycleStatus.rejectedByTutor =>
      l10n.sessionLifecycleRejectedByTutor,
  };
}

/// Localised labels for session timeline actions (fallback titles).
extension SessionActionL10n on SessionAction {
  String localizedLabel(QuranSessionsLocalizations l10n) => switch (this) {
    SessionAction.createDraft => l10n.sessionActionCreateDraft,
    SessionAction.initiatePayment => l10n.sessionActionInitiatePayment,
    SessionAction.confirmBooking => l10n.sessionActionConfirmBooking,
    SessionAction.confirmFreeBooking => l10n.sessionActionConfirmFreeBooking,
    SessionAction.submitBookingRequest =>
      l10n.sessionActionSubmitBookingRequest,
    SessionAction.acceptBookingRequest =>
      l10n.sessionActionAcceptBookingRequest,
    SessionAction.rejectBookingRequest =>
      l10n.sessionActionRejectBookingRequest,
    SessionAction.expireTutorApproval => l10n.sessionActionExpireBookingReview,
    SessionAction.acknowledgeSession => l10n.sessionActionAcknowledgeSession,
    SessionAction.startSession => l10n.sessionActionStartSession,
    SessionAction.completeSession => l10n.sessionActionCompleteSession,
    SessionAction.requestReschedule => l10n.sessionActionRequestReschedule,
    SessionAction.confirmReschedule => l10n.sessionActionConfirmReschedule,
    SessionAction.adminForceReschedule =>
      l10n.sessionActionAdminForceReschedule,
    SessionAction.cancelByStudent => l10n.sessionActionCancelByStudent,
    SessionAction.cancelByTeacher => l10n.sessionActionCancelByTeacher,
    SessionAction.cancelByAdmin => l10n.sessionActionCancelByAdmin,
    SessionAction.markTeacherNoShow => l10n.sessionActionMarkTeacherNoShow,
    SessionAction.markStudentNoShow => l10n.sessionActionMarkStudentNoShow,
    SessionAction.markBothNoShow => l10n.sessionActionMarkBothNoShow,
    SessionAction.markIncomplete => l10n.sessionActionMarkIncomplete,
    SessionAction.openDispute => l10n.sessionActionOpenDispute,
    SessionAction.issueCompensation => l10n.sessionActionIssueCompensation,
    SessionAction.issueRefund => l10n.sessionActionIssueRefund,
    SessionAction.expireReservation => l10n.sessionActionExpireReservation,
    SessionAction.rejectBooking => l10n.sessionActionRejectBooking,
  };
}

/// Localised account restriction reason (server reason code string).
String restrictionReasonLabel(QuranSessionsLocalizations l10n, String reason) =>
    switch (reason) {
      'falseIdentity' => l10n.restrictionReasonFalseIdentity,
      'policyViolation' => l10n.restrictionReasonPolicyViolation,
      'safetyConcern' => l10n.restrictionReasonSafetyConcern,
      'abuseReport' => l10n.restrictionReasonAbuseReport,
      'repeatedNoShow' => l10n.restrictionReasonRepeatedNoShow,
      'adminDecision' => l10n.restrictionReasonAdminDecision,
      _ => reason,
    };
