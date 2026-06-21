import '../../domain/entities/teacher_profile.dart';
import '../../domain/entities/teacher_verification_status.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/rules/teacher_profile_completeness.dart';
import '../../domain/teacher_profile_display_name_resolver.dart';
import '../dtos/teacher_profile_dto.dart';

extension TeacherProfileDtoMapper on TeacherProfileDto {
  /// Maps DTO → domain. Empty persisted [displayName] stays empty — legacy
  /// placeholder backfill must not mark profiles marketplace-ready.
  TeacherProfile toDomain() {
    final rawDisplayName = TeacherProfileDisplayNameResolver.resolveStored(
      displayName: displayName,
    );
    final verification = _mapVerificationStatus(verificationStatus);
    final storedCompleteness = _mapCompleteness(profileCompleteness);
    final computedCompleteness = TeacherProfileCompleteness.evaluate(
      userId: userId,
      displayName: rawDisplayName,
      publicBio: publicBio,
      teachingLanguages: teachingLanguages,
      specializations: specializations,
      verificationStatus: verification,
    );
    final completeness = storedCompleteness == computedCompleteness
        ? storedCompleteness
        : computedCompleteness;
    final visible = TeacherProfileCompleteness.isPubliclyVisible(
      userId: userId,
      displayName: rawDisplayName,
      publicBio: publicBio,
      teachingLanguages: teachingLanguages,
      specializations: specializations,
      verificationStatus: verification,
      isActive: isActive,
    );

    return TeacherProfile(
      id: id,
      userId: userId,
      displayName: rawDisplayName,
      avatarUrl: avatarUrl,
      publicBio: publicBio,
      verificationStatus: verification,
      teachingLanguages: teachingLanguages,
      specializations: specializations,
      averageRating: averageRating,
      reviewCount: reviewCount,
      isActive: isActive,
      profileCompleteness: completeness,
      isPubliclyVisible: visible,
      allowedStudentGender: allowedStudentGender == null
          ? null
          : _mapAllowedGender(allowedStudentGender!),
      canTeachChildren: canTeachChildren,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension TeacherProfileDomainMapper on TeacherProfile {
  TeacherProfileDto toDto() {
    final withVisibility = TeacherProfileCompleteness.withComputedVisibility(
      this,
    );
    return TeacherProfileDto(
      id: id,
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      publicBio: publicBio,
      verificationStatus: verificationStatus.name,
      teachingLanguages: teachingLanguages,
      specializations: specializations,
      averageRating: averageRating,
      reviewCount: reviewCount,
      isActive: isActive,
      profileCompleteness: withVisibility.profileCompleteness.name,
      isPubliclyVisible: withVisibility.isPubliclyVisible,
      allowedStudentGender: allowedStudentGender?.name,
      canTeachChildren: canTeachChildren,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

TeacherProfileCompletenessStatus _mapCompleteness(String raw) => switch (raw) {
  'complete' => TeacherProfileCompletenessStatus.complete,
  _ => TeacherProfileCompletenessStatus.incomplete,
};

TeacherVerificationStatus _mapVerificationStatus(String raw) => switch (raw) {
  'underReview' => TeacherVerificationStatus.underReview,
  'verified' || 'approved' => TeacherVerificationStatus.verified,
  'rejected' => TeacherVerificationStatus.rejected,
  'suspended' => TeacherVerificationStatus.suspended,
  _ => TeacherVerificationStatus.pending,
};

UserGender _mapAllowedGender(String raw) => switch (raw) {
  'female' => UserGender.female,
  _ => UserGender.male,
};
