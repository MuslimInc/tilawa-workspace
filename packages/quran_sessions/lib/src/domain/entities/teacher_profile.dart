import 'package:equatable/equatable.dart';

import '../rules/teacher_profile_completeness.dart';
import 'teacher_verification_status.dart';
import 'user_profile.dart' show UserGender;

// ── TeacherProfile entity ─────────────────────────────────────────────────────

/// Public/student-facing domain entity for an approved Quran teacher.
///
/// **Privacy contract:** this entity must never contain phone numbers, private
/// notes, admin review data, rejection reasons, or any personal contact
/// information. It is the public projection created only after a
/// [TeacherApplication] is approved.
///
/// The corresponding [TeacherApplication] remains private to the teacher and
/// authorized admin/moderator users.
class TeacherProfile extends Equatable {
  const TeacherProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.verificationStatus,
    required this.teachingLanguages,
    required this.specializations,
    required this.averageRating,
    required this.reviewCount,
    required this.isActive,
    required this.profileCompleteness,
    required this.isPubliclyVisible,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.publicBio,
    this.allowedStudentGender,
    this.canTeachChildren = true,
  });

  final String id;

  /// UID of the associated [UserProfile].
  final String userId;

  final String displayName;
  final String? avatarUrl;

  /// Public-facing bio shown on the teacher's profile screen.
  /// Must not be sourced from [TeacherApplication.bio] without explicit
  /// teacher consent — these may diverge.
  final String? publicBio;

  final TeacherVerificationStatus verificationStatus;

  /// BCP-47 language tags, e.g. `['ar', 'en', 'ur']`.
  final List<String> teachingLanguages;

  /// Domain-specific specialization keys, e.g. `['tajweed', 'hifz']`.
  final List<String> specializations;

  final double averageRating;
  final int reviewCount;

  /// False when the teacher has temporarily deactivated their profile.
  final bool isActive;

  /// Required public fields + verification status (ignores [isActive]).
  final TeacherProfileCompletenessStatus profileCompleteness;

  /// True when [profileCompleteness] is complete and [isActive] is true.
  final bool isPubliclyVisible;

  /// When non-null, only students of this gender may book.
  /// Null means no gender restriction.
  final UserGender? allowedStudentGender;

  /// Whether the teacher accepts sessions with child students.
  final bool canTeachChildren;

  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Computed ────────────────────────────────────────────────────────────────

  bool get isVerified =>
      verificationStatus == TeacherVerificationStatus.verified;

  /// Whether required public marketplace fields are present (ignores [isActive]).
  bool get isPublicProfileFieldsComplete =>
      profileCompleteness == TeacherProfileCompletenessStatus.complete;

  /// Whether all required public marketplace fields are present.
  ///
  /// Optional fields (avatar, availability, pricing) do not block completion.
  bool get isPublicProfileComplete => isPubliclyVisible;

  /// True when this teacher can accept new bookings.
  bool get canAcceptBookings =>
      isActive && isVerified && isPublicProfileComplete;

  TeacherProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? publicBio,
    TeacherVerificationStatus? verificationStatus,
    List<String>? teachingLanguages,
    List<String>? specializations,
    double? averageRating,
    int? reviewCount,
    bool? isActive,
    TeacherProfileCompletenessStatus? profileCompleteness,
    bool? isPubliclyVisible,
    UserGender? allowedStudentGender,
    bool? canTeachChildren,
    DateTime? updatedAt,
  }) => TeacherProfile(
    id: id,
    userId: userId,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    publicBio: publicBio ?? this.publicBio,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    teachingLanguages: teachingLanguages ?? this.teachingLanguages,
    specializations: specializations ?? this.specializations,
    averageRating: averageRating ?? this.averageRating,
    reviewCount: reviewCount ?? this.reviewCount,
    isActive: isActive ?? this.isActive,
    profileCompleteness: profileCompleteness ?? this.profileCompleteness,
    isPubliclyVisible: isPubliclyVisible ?? this.isPubliclyVisible,
    allowedStudentGender: allowedStudentGender ?? this.allowedStudentGender,
    canTeachChildren: canTeachChildren ?? this.canTeachChildren,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    userId,
    displayName,
    avatarUrl,
    publicBio,
    verificationStatus,
    teachingLanguages,
    specializations,
    averageRating,
    reviewCount,
    isActive,
    profileCompleteness,
    isPubliclyVisible,
    allowedStudentGender,
    canTeachChildren,
    createdAt,
    updatedAt,
  ];
}
