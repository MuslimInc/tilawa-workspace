import '../../domain/entities/teacher_profile.dart';
import '../../domain/entities/teacher_verification_status.dart';
import '../../domain/entities/user_profile.dart';
import '../dtos/teacher_profile_dto.dart';

extension TeacherProfileDtoMapper on TeacherProfileDto {
  TeacherProfile toDomain() => TeacherProfile(
    id: id,
    userId: userId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    publicBio: publicBio,
    verificationStatus: _mapVerificationStatus(verificationStatus),
    teachingLanguages: teachingLanguages,
    specializations: specializations,
    averageRating: averageRating,
    reviewCount: reviewCount,
    isActive: isActive,
    allowedStudentGender: allowedStudentGender == null
        ? null
        : _mapAllowedGender(allowedStudentGender!),
    canTeachChildren: canTeachChildren,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension TeacherProfileDomainMapper on TeacherProfile {
  TeacherProfileDto toDto() => TeacherProfileDto(
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
    allowedStudentGender: allowedStudentGender?.name,
    canTeachChildren: canTeachChildren,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

TeacherVerificationStatus _mapVerificationStatus(String raw) => switch (raw) {
  'underReview' => TeacherVerificationStatus.underReview,
  'verified' => TeacherVerificationStatus.verified,
  'rejected' => TeacherVerificationStatus.rejected,
  'suspended' => TeacherVerificationStatus.suspended,
  _ => TeacherVerificationStatus.pending,
};

UserGender _mapAllowedGender(String raw) => switch (raw) {
  'female' => UserGender.female,
  _ => UserGender.male,
};
