import '../../domain/entities/session_policy.dart';
import '../dtos/session_policy_dto.dart';

extension SessionPolicyDtoMapper on SessionPolicyDto {
  QuranSessionSafetyPolicy toDomain() => QuranSessionSafetyPolicy(
    childAgeThreshold: childAgeThreshold,
    minimumStudentAgeYears: minimumStudentAgeYears,
    minimumTeacherAgeYears: minimumTeacherAgeYears,
    globalAllowMaleTeacherFemaleStudent: globalAllowMaleTeacherFemaleStudent,
    globalAllowFemaleTeacherMaleStudent: globalAllowFemaleTeacherMaleStudent,
    videoCallAllowedForChildren: videoCallAllowedForChildren,
    recordingEnabled: recordingEnabled,
    requireGuardianApprovalForChildren: requireGuardianApprovalForChildren,
  );
}

extension SessionPolicyDomainMapper on QuranSessionSafetyPolicy {
  SessionPolicyDto toDto() => SessionPolicyDto(
    childAgeThreshold: childAgeThreshold,
    minimumStudentAgeYears: minimumStudentAgeYears,
    minimumTeacherAgeYears: minimumTeacherAgeYears,
    globalAllowMaleTeacherFemaleStudent: globalAllowMaleTeacherFemaleStudent,
    globalAllowFemaleTeacherMaleStudent: globalAllowFemaleTeacherMaleStudent,
    videoCallAllowedForChildren: videoCallAllowedForChildren,
    recordingEnabled: recordingEnabled,
    requireGuardianApprovalForChildren: requireGuardianApprovalForChildren,
  );
}

extension TeacherEligibilityPolicyDtoMapper on TeacherEligibilityPolicyDto {
  TeacherEligibilityPolicy toDomain() => TeacherEligibilityPolicy(
    allowedStudentGender: _mapAllowedStudentGender(allowedStudentGender),
    canTeachChildren: canTeachChildren,
    requiresGuardianApprovalForChildren: requiresGuardianApprovalForChildren,
  );
}

extension TeacherEligibilityPolicyDomainMapper on TeacherEligibilityPolicy {
  TeacherEligibilityPolicyDto toDto() => TeacherEligibilityPolicyDto(
    allowedStudentGender: allowedStudentGender.name,
    canTeachChildren: canTeachChildren,
    requiresGuardianApprovalForChildren: requiresGuardianApprovalForChildren,
  );
}

TeacherAllowedStudentGender _mapAllowedStudentGender(String raw) =>
    switch (raw) {
      'maleOnly' => TeacherAllowedStudentGender.maleOnly,
      'femaleOnly' => TeacherAllowedStudentGender.femaleOnly,
      _ => TeacherAllowedStudentGender.both,
    };
