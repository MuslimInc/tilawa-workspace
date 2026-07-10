import 'package:equatable/equatable.dart';

import 'user_profile.dart';

// ── TeacherAllowedStudentGender ───────────────────────────────────────────────

/// Which student genders a teacher is configured to accept.
enum TeacherAllowedStudentGender {
  /// Teacher only accepts male students.
  maleOnly,

  /// Teacher only accepts female students.
  femaleOnly,

  /// Teacher accepts students of any gender (subject to global policy).
  both,
}

// ── TeacherEligibilityPolicy ──────────────────────────────────────────────────

/// Per-teacher policy that controls which students may book a session.
///
/// Stored separately from [QuranTeacher] — it is an operational configuration
/// that changes independently of the teacher's profile.
class TeacherEligibilityPolicy extends Equatable {
  const TeacherEligibilityPolicy({
    required this.allowedStudentGender,
    required this.canTeachChildren,
  });

  final TeacherAllowedStudentGender allowedStudentGender;
  final bool canTeachChildren;

  /// Fully unrestricted — accepts all genders and ages.
  static const unrestricted = TeacherEligibilityPolicy(
    allowedStudentGender: TeacherAllowedStudentGender.both,
    canTeachChildren: true,
  );

  @override
  List<Object?> get props => [allowedStudentGender, canTeachChildren];
}

// ── QuranSessionSafetyPolicy ──────────────────────────────────────────────────

/// Global admin-configured safety rules for the entire platform.
///
/// Teacher-level [TeacherEligibilityPolicy] may be more restrictive than these
/// globals but never more permissive — global rules are a ceiling.
class QuranSessionSafetyPolicy extends Equatable {
  const QuranSessionSafetyPolicy({
    this.childAgeThreshold = 14,
    this.minimumStudentAgeYears = 3,
    this.minimumTeacherAgeYears = 18,
    this.globalAllowMaleTeacherFemaleStudent = true,
    this.globalAllowFemaleTeacherMaleStudent = true,
    this.videoCallAllowedForChildren = false,
    this.recordingEnabled = false,
  });

  /// Age (years) below which a student is considered a child.
  final int childAgeThreshold;

  /// Minimum age (years) a student must be to complete their profile.
  ///
  /// Sourced from remote configuration
  /// (`quran_sessions.minimum_student_age_years`). The latest acceptable
  /// student birth date is `today - minimumStudentAgeYears`. There is no
  /// hardcoded date — changing the remote value changes the limit at runtime.
  final int minimumStudentAgeYears;

  /// Minimum age (years) a teacher must be to complete their profile.
  ///
  /// Sourced from remote configuration
  /// (`quran_sessions.minimum_teacher_age_years`). The latest acceptable
  /// teacher birth date is `today - minimumTeacherAgeYears`.
  final int minimumTeacherAgeYears;

  /// Whether any male teacher may teach a female student
  /// (can be overridden at teacher level to be more restrictive).
  final bool globalAllowMaleTeacherFemaleStudent;

  /// Whether any female teacher may teach a male student.
  final bool globalAllowFemaleTeacherMaleStudent;

  final bool videoCallAllowedForChildren;
  final bool recordingEnabled;

  static const defaultPolicy = QuranSessionSafetyPolicy();

  /// Returns true if [teacherGender] teaching [studentGender] is allowed
  /// under this global policy and the given teacher-level [teacherPolicy].
  bool isGenderCombinationAllowed({
    required UserGender teacherGender,
    required UserGender studentGender,
    required TeacherEligibilityPolicy teacherPolicy,
  }) {
    // 1. Check teacher-level allowed student genders
    switch (teacherPolicy.allowedStudentGender) {
      case TeacherAllowedStudentGender.maleOnly:
        if (studentGender != UserGender.male) return false;
      case TeacherAllowedStudentGender.femaleOnly:
        if (studentGender != UserGender.female) return false;
      case TeacherAllowedStudentGender.both:
        break; // fall through to global policy
    }

    // 2. Global policy ceiling (applies even when teacher allows both)
    if (teacherGender == UserGender.male &&
        studentGender == UserGender.female) {
      if (!globalAllowMaleTeacherFemaleStudent) return false;
    }
    if (teacherGender == UserGender.female &&
        studentGender == UserGender.male) {
      if (!globalAllowFemaleTeacherMaleStudent) return false;
    }

    return true;
  }

  @override
  List<Object?> get props => [
    childAgeThreshold,
    minimumStudentAgeYears,
    minimumTeacherAgeYears,
    globalAllowMaleTeacherFemaleStudent,
    globalAllowFemaleTeacherMaleStudent,
    videoCallAllowedForChildren,
    recordingEnabled,
  ];
}
