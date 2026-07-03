class SessionPolicyDto {
  const SessionPolicyDto({
    required this.childAgeThreshold,
    required this.minimumStudentAgeYears,
    required this.minimumTeacherAgeYears,
    required this.globalAllowMaleTeacherFemaleStudent,
    required this.globalAllowFemaleTeacherMaleStudent,
    required this.videoCallAllowedForChildren,
    required this.recordingEnabled,
    this.quranTutorBookingMode,
  });

  final int childAgeThreshold;
  final int minimumStudentAgeYears;
  final int minimumTeacherAgeYears;
  final bool globalAllowMaleTeacherFemaleStudent;
  final bool globalAllowFemaleTeacherMaleStudent;
  final bool videoCallAllowedForChildren;
  final bool recordingEnabled;
  final String? quranTutorBookingMode;
}

class TeacherEligibilityPolicyDto {
  const TeacherEligibilityPolicyDto({
    required this.allowedStudentGender,
    required this.canTeachChildren,
  });

  final String allowedStudentGender;
  final bool canTeachChildren;
}
