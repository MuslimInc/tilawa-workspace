class SessionPolicyDto {
  const SessionPolicyDto({
    required this.childAgeThreshold,
    required this.minimumStudentAgeYears,
    required this.minimumTeacherAgeYears,
    required this.globalAllowMaleTeacherFemaleStudent,
    required this.globalAllowFemaleTeacherMaleStudent,
    required this.videoCallAllowedForChildren,
    required this.recordingEnabled,
    required this.requireGuardianApprovalForChildren,
    this.quranTutorBookingMode,
  });

  final int childAgeThreshold;
  final int minimumStudentAgeYears;
  final int minimumTeacherAgeYears;
  final bool globalAllowMaleTeacherFemaleStudent;
  final bool globalAllowFemaleTeacherMaleStudent;
  final bool videoCallAllowedForChildren;
  final bool recordingEnabled;
  final bool requireGuardianApprovalForChildren;
  final String? quranTutorBookingMode;
}

class TeacherEligibilityPolicyDto {
  const TeacherEligibilityPolicyDto({
    required this.allowedStudentGender,
    required this.canTeachChildren,
    required this.requiresGuardianApprovalForChildren,
  });

  final String allowedStudentGender;
  final bool canTeachChildren;
  final bool requiresGuardianApprovalForChildren;
}
