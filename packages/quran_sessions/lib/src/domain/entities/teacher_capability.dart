import 'package:equatable/equatable.dart';

import 'teacher_application.dart';
import 'teacher_profile.dart';

/// Resolved teacher marketplace capability for the signed-in user.
///
/// Combines [TeacherApplication] lifecycle with [TeacherProfile] activation
/// so presentation does not re-derive rules from raw status enums.
enum TeacherCapabilityState {
  none,
  draft,
  pending,
  rejected,
  approvedIncompleteProfile,
  approvedActive,
  approvedInactive,
  suspended,
  revoked,
}

class TeacherCapability extends Equatable {
  const TeacherCapability({
    required this.state,
    this.application,
    this.profile,
  });

  final TeacherCapabilityState state;
  final TeacherApplication? application;
  final TeacherProfile? profile;

  bool get showsVerifiedTeacherBadge =>
      state == TeacherCapabilityState.approvedActive ||
      state == TeacherCapabilityState.approvedIncompleteProfile;

  /// Approved teacher entry uses [TilawaCapabilityActionCard] in Settings;
  /// verification belongs on that card, not duplicated under the avatar.
  bool get showsPremiumSettingsCapabilityCard =>
      state == TeacherCapabilityState.approvedActive ||
      state == TeacherCapabilityState.approvedIncompleteProfile;

  bool get showsVerifiedTeacherBadgeInProfileHeader =>
      showsVerifiedTeacherBadge && !showsPremiumSettingsCapabilityCard;

  bool get canAccessTeacherDashboard =>
      state == TeacherCapabilityState.approvedActive;

  bool get shouldCompleteTeacherProfile =>
      state == TeacherCapabilityState.approvedIncompleteProfile;

  bool get canStartOrContinueApply =>
      state == TeacherCapabilityState.none ||
      state == TeacherCapabilityState.draft ||
      (state == TeacherCapabilityState.rejected &&
          (application?.canStartOrContinueApply ?? false));

  bool get shouldShowApplicationStatus =>
      state == TeacherCapabilityState.pending ||
      state == TeacherCapabilityState.rejected ||
      state == TeacherCapabilityState.approvedInactive ||
      state == TeacherCapabilityState.suspended ||
      state == TeacherCapabilityState.revoked;

  @override
  List<Object?> get props => [state, application, profile];
}

/// Pure domain mapper from application + optional profile to [TeacherCapability].
abstract final class TeacherCapabilityResolver {
  static TeacherCapability resolve({
    TeacherApplication? application,
    TeacherProfile? profile,
  }) {
    if (application == null) {
      return const TeacherCapability(state: TeacherCapabilityState.none);
    }

    final status = application.status;
    if (status == TeacherApplicationStatus.draft) {
      return TeacherCapability(
        state: TeacherCapabilityState.draft,
        application: application,
      );
    }
    if (status == TeacherApplicationStatus.pending) {
      return TeacherCapability(
        state: TeacherCapabilityState.pending,
        application: application,
      );
    }
    if (status == TeacherApplicationStatus.rejected) {
      return TeacherCapability(
        state: TeacherCapabilityState.rejected,
        application: application,
      );
    }
    if (status == TeacherApplicationStatus.suspended) {
      return TeacherCapability(
        state: TeacherCapabilityState.suspended,
        application: application,
        profile: profile,
      );
    }
    if (status == TeacherApplicationStatus.revoked) {
      return TeacherCapability(
        state: TeacherCapabilityState.revoked,
        application: application,
        profile: profile,
      );
    }

    if (status == TeacherApplicationStatus.approved) {
      final teacherProfile = profile;
      if (teacherProfile == null ||
          !teacherProfile.isPublicProfileFieldsComplete) {
        return TeacherCapability(
          state: TeacherCapabilityState.approvedIncompleteProfile,
          application: application,
          profile: teacherProfile,
        );
      }
      if (teacherProfile.isPublicProfileComplete) {
        return TeacherCapability(
          state: TeacherCapabilityState.approvedActive,
          application: application,
          profile: teacherProfile,
        );
      }
      return TeacherCapability(
        state: TeacherCapabilityState.approvedInactive,
        application: application,
        profile: teacherProfile,
      );
    }

    return const TeacherCapability(state: TeacherCapabilityState.none);
  }
}
