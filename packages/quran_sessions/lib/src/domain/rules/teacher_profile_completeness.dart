import '../entities/teacher_profile.dart';
import '../entities/teacher_verification_status.dart';
import '../value_objects/teacher_public_name.dart';

/// Lifecycle of required public teacher profile fields.
enum TeacherProfileCompletenessStatus {
  incomplete,
  complete,
}

/// Central rule for marketplace profile completeness and visibility.
abstract final class TeacherProfileCompleteness {
  static TeacherProfileCompletenessStatus evaluate({
    required String userId,
    required String displayName,
    required String? publicBio,
    required List<String> teachingLanguages,
    required List<String> specializations,
    required TeacherVerificationStatus verificationStatus,
  }) {
    if (userId.trim().isEmpty) {
      return TeacherProfileCompletenessStatus.incomplete;
    }
    if (!ValidateTeacherPublicName.isValid(displayName)) {
      return TeacherProfileCompletenessStatus.incomplete;
    }
    if (publicBio == null || publicBio.trim().isEmpty) {
      return TeacherProfileCompletenessStatus.incomplete;
    }
    if (teachingLanguages.isEmpty || specializations.isEmpty) {
      return TeacherProfileCompletenessStatus.incomplete;
    }
    if (verificationStatus != TeacherVerificationStatus.verified) {
      return TeacherProfileCompletenessStatus.incomplete;
    }
    return TeacherProfileCompletenessStatus.complete;
  }

  static bool isPubliclyVisible({
    required String userId,
    required String displayName,
    required String? publicBio,
    required List<String> teachingLanguages,
    required List<String> specializations,
    required TeacherVerificationStatus verificationStatus,
    required bool isActive,
  }) =>
      isActive &&
      evaluate(
            userId: userId,
            displayName: displayName,
            publicBio: publicBio,
            teachingLanguages: teachingLanguages,
            specializations: specializations,
            verificationStatus: verificationStatus,
          ) ==
          TeacherProfileCompletenessStatus.complete;

  static TeacherProfileCompletenessStatus forProfile(TeacherProfile profile) =>
      evaluate(
        userId: profile.userId,
        displayName: profile.displayName,
        publicBio: profile.publicBio,
        teachingLanguages: profile.teachingLanguages,
        specializations: profile.specializations,
        verificationStatus: profile.verificationStatus,
      );

  static bool isProfilePubliclyVisible(TeacherProfile profile) =>
      isPubliclyVisible(
        userId: profile.userId,
        displayName: profile.displayName,
        publicBio: profile.publicBio,
        teachingLanguages: profile.teachingLanguages,
        specializations: profile.specializations,
        verificationStatus: profile.verificationStatus,
        isActive: profile.isActive,
      );

  static TeacherProfile withComputedVisibility(TeacherProfile profile) {
    final completeness = forProfile(profile);
    final visible =
        completeness == TeacherProfileCompletenessStatus.complete &&
        profile.isActive;
    if (profile.profileCompleteness == completeness &&
        profile.isPubliclyVisible == visible) {
      return profile;
    }
    return profile.copyWith(
      profileCompleteness: completeness,
      isPubliclyVisible: visible,
    );
  }
}
