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
    this.requiresGuardianApprovalForChildren = false,
  });

  final TeacherAllowedStudentGender allowedStudentGender;
  final bool canTeachChildren;

  /// When true, a booking for a child student emits
  /// [GuardianApprovalRequiredFailure] instead of proceeding directly.
  final bool requiresGuardianApprovalForChildren;

  /// Fully unrestricted — accepts all genders and ages.
  static const unrestricted = TeacherEligibilityPolicy(
    allowedStudentGender: TeacherAllowedStudentGender.both,
    canTeachChildren: true,
    requiresGuardianApprovalForChildren: false,
  );

  @override
  List<Object?> get props => [
    allowedStudentGender,
    canTeachChildren,
    requiresGuardianApprovalForChildren,
  ];
}

// ── QuranSessionSafetyPolicy ──────────────────────────────────────────────────

/// Global admin-configured safety rules for the entire platform.
///
/// Teacher-level [TeacherEligibilityPolicy] may be more restrictive than these
/// globals but never more permissive — global rules are a ceiling.
class QuranSessionSafetyPolicy extends Equatable {
  const QuranSessionSafetyPolicy({
    this.childAgeThreshold = 14,
    this.globalAllowMaleTeacherFemaleStudent = true,
    this.globalAllowFemaleTeacherMaleStudent = true,
    this.videoCallAllowedForChildren = false,
    this.recordingEnabled = false,
    this.requireGuardianApprovalForChildren = false,
  });

  /// Age (years) below which a student is considered a child.
  final int childAgeThreshold;

  /// Whether any male teacher may teach a female student
  /// (can be overridden at teacher level to be more restrictive).
  final bool globalAllowMaleTeacherFemaleStudent;

  /// Whether any female teacher may teach a male student.
  final bool globalAllowFemaleTeacherMaleStudent;

  final bool videoCallAllowedForChildren;
  final bool recordingEnabled;
  final bool requireGuardianApprovalForChildren;

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
    globalAllowMaleTeacherFemaleStudent,
    globalAllowFemaleTeacherMaleStudent,
    videoCallAllowedForChildren,
    recordingEnabled,
    requireGuardianApprovalForChildren,
  ];
}
