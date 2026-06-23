import '../../domain/entities/teacher_capability.dart';
import '../../../l10n/quran_sessions_localizations.dart';

/// Localized copy and navigation intent for [TeacherCapability] in Profile UI.
extension TeacherCapabilityPresentation on TeacherCapability {
  String? statusBadgeLabel(QuranSessionsLocalizations l10n) => switch (state) {
    TeacherCapabilityState.draft => l10n.teacherCapabilityStatusDraft,
    TeacherCapabilityState.pending => l10n.teacherCapabilityStatusPending,
    TeacherCapabilityState.rejected => l10n.teacherCapabilityStatusRejected,
    TeacherCapabilityState.approvedActive ||
    TeacherCapabilityState.approvedIncompleteProfile => l10n.verifiedTeacher,
    TeacherCapabilityState.suspended => l10n.teacherCapabilityStatusSuspended,
    TeacherCapabilityState.revoked => l10n.teacherCapabilityStatusRevoked,
    TeacherCapabilityState.none ||
    TeacherCapabilityState.approvedInactive => null,
  };

  String teachingSectionActionTitle(QuranSessionsLocalizations l10n) =>
      switch (state) {
        TeacherCapabilityState.none => l10n.teachingOnMemuslimApply,
        TeacherCapabilityState.draft => l10n.teachingOnMemuslimContinueDraft,
        TeacherCapabilityState.approvedActive => l10n.teacherDashboard,
        TeacherCapabilityState.approvedIncompleteProfile =>
          l10n.completeTeacherProfile,
        TeacherCapabilityState.approvedInactive =>
          routesApprovedInactiveToTeacherFlows
              ? (profile?.isPublicProfileFieldsComplete ?? false
                    ? l10n.teacherDashboard
                    : l10n.completeTeacherProfile)
              : l10n.teachingOnMemuslimViewStatus,
        TeacherCapabilityState.pending ||
        TeacherCapabilityState.rejected ||
        TeacherCapabilityState.suspended ||
        TeacherCapabilityState.revoked => l10n.teachingOnMemuslimViewStatus,
      };

  String? teachingSectionSubtitle(
    QuranSessionsLocalizations l10n,
  ) => switch (state) {
    TeacherCapabilityState.pending => l10n.teachingOnMemuslimPendingSubtitle,
    TeacherCapabilityState.approvedActive =>
      l10n.manageYourAvailabilityAndSessions,
    TeacherCapabilityState.approvedIncompleteProfile =>
      l10n.completeTeacherProfileSubtitle,
    TeacherCapabilityState.approvedInactive
        when routesApprovedInactiveToTeacherFlows =>
      profile?.isPublicProfileFieldsComplete ?? false
          ? l10n.manageYourAvailabilityAndSessions
          : l10n.completeTeacherProfileSubtitle,
    TeacherCapabilityState.rejected =>
      canStartOrContinueApply
          ? l10n.teachingOnMemuslimReapplySubtitle
          : l10n.teachingOnMemuslimRejectedSubtitle,
    TeacherCapabilityState.suspended =>
      l10n.teachingOnMemuslimSuspendedSubtitle,
    TeacherCapabilityState.revoked => l10n.teachingOnMemuslimRevokedSubtitle,
    TeacherCapabilityState.none ||
    TeacherCapabilityState.draft ||
    TeacherCapabilityState.approvedInactive => null,
  };
}

/// Where the teaching section row should navigate.
enum TeacherCapabilityNavigationTarget {
  apply,
  applicationStatus,
  completeTeacherProfile,
  teacherDashboard,
}

extension TeacherCapabilityNavigation on TeacherCapability {
  TeacherCapabilityNavigationTarget get navigationTarget => switch (state) {
    TeacherCapabilityState.none ||
    TeacherCapabilityState.draft => TeacherCapabilityNavigationTarget.apply,
    TeacherCapabilityState.approvedActive =>
      TeacherCapabilityNavigationTarget.teacherDashboard,
    TeacherCapabilityState.approvedIncompleteProfile =>
      TeacherCapabilityNavigationTarget.completeTeacherProfile,
    TeacherCapabilityState.approvedInactive =>
      routesApprovedInactiveToTeacherFlows
          ? (profile?.isPublicProfileFieldsComplete ?? false
                ? TeacherCapabilityNavigationTarget.teacherDashboard
                : TeacherCapabilityNavigationTarget.completeTeacherProfile)
          : TeacherCapabilityNavigationTarget.applicationStatus,
    TeacherCapabilityState.pending ||
    TeacherCapabilityState.rejected ||
    TeacherCapabilityState.suspended ||
    TeacherCapabilityState.revoked =>
      TeacherCapabilityNavigationTarget.applicationStatus,
  };
}
