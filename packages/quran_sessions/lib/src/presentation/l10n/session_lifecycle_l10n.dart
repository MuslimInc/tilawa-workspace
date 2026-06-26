import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';

import '../../domain/entities/session_lifecycle_status.dart';
import '../../domain/value_objects/session_action.dart';

/// Localised labels for session lifecycle enums (presentation layer).
extension SessionLifecycleStatusL10n on SessionLifecycleStatus {
  String localizedLabel(QuranSessionsLocalizations l10n) => switch (this) {
    SessionLifecycleStatus.draft => l10n.sessionLifecycleDraft,
    SessionLifecycleStatus.pendingPayment =>
      l10n.sessionLifecyclePendingPayment,
    SessionLifecycleStatus.pendingTutorApproval =>
      l10n.sessionLifecyclePendingTutorApproval,
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

/// Localised labels for session timeline actions.
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
    SessionAction.expireTutorApproval => l10n.sessionActionExpireTutorApproval,
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
