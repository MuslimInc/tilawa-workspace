import 'package:equatable/equatable.dart';

// ── Enumerations ──────────────────────────────────────────────────────────────

/// Lifecycle state of a teacher's application.
///
/// State machine:
///   none → draft → pending → approved → (suspended | revoked)
///   pending → rejected → (re-apply after cooldown, if permitted)
///
/// Only [approved] teachers may have an active [TeacherProfile].
/// See ADR-003 for the full lifecycle policy.
enum TeacherApplicationStatus {
  /// No application exists yet.
  none,

  /// Application started but not yet submitted.
  draft,

  /// Submitted and awaiting admin review.
  pending,

  /// Approved by an admin — a [TeacherProfile] has been created.
  approved,

  /// Rejected by an admin — teacher may re-apply after cooldown.
  rejected,

  /// Temporarily suspended — teacher cannot accept bookings.
  suspended,

  /// Permanently revoked — teacher cannot re-apply.
  revoked,
}

/// Preferred channel for admin–teacher communication.
enum PreferredContactMethod { whatsapp, phone, email }

// ── TeacherApplication entity ─────────────────────────────────────────────────

/// Private/admin-facing domain entity for a teacher's onboarding application.
///
/// **Privacy contract:** this entity must never be surfaced to student-facing
/// screens. [phoneNumber] and review metadata are sensitive fields that belong
/// only to the teacher themselves and authorized admin/moderator users.
///
/// [TeacherProfile] is the public projection created only after [status]
/// reaches [TeacherApplicationStatus.approved].
///
/// Phone number rules:
/// - Stored in E.164 format (e.g. `+201234567890`).
/// - Mandatory before [status] can advance to [TeacherApplicationStatus.pending].
/// - Format-only validation in MVP. OTP verification is deferred — see ADR-003.
class TeacherApplication extends Equatable {
  const TeacherApplication({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.phoneCountryCode,
    this.preferredContactMethod,
    this.teachingLanguages = const [],
    this.specializations = const [],
    this.bio,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  final String id;
  final String userId;
  final TeacherApplicationStatus status;

  /// E.164 phone number, e.g. `+201234567890`. Mandatory before submission.
  final String? phoneNumber;

  /// ISO 3166-1 alpha-2 country code of the phone number, e.g. `'EG'`.
  final String? phoneCountryCode;

  final PreferredContactMethod? preferredContactMethod;

  /// BCP-47 language tags, e.g. `['ar', 'en']`.
  final List<String> teachingLanguages;

  /// Domain-specific specialization keys, e.g. `['tajweed', 'hifz']`.
  final List<String> specializations;

  /// Draft/application bio. May differ from the public [TeacherProfile.publicBio].
  final String? bio;

  /// Set when status advances to [TeacherApplicationStatus.pending].
  final DateTime? submittedAt;

  /// Set when an admin approves or rejects.
  final DateTime? reviewedAt;

  /// UID of the admin who reviewed this application.
  final String? reviewedBy;

  /// Human-readable reason provided by the admin on rejection or suspension.
  final String? rejectionReason;

  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Computed ────────────────────────────────────────────────────────────────

  bool get isDraft => status == TeacherApplicationStatus.draft;
  bool get isPending => status == TeacherApplicationStatus.pending;
  bool get isApproved => status == TeacherApplicationStatus.approved;
  bool get isRejected => status == TeacherApplicationStatus.rejected;
  bool get isSuspended => status == TeacherApplicationStatus.suspended;
  bool get isRevoked => status == TeacherApplicationStatus.revoked;

  /// True if the application has a submittable phone number (format only; no OTP).
  bool get hasValidPhone {
    final p = phoneNumber;
    if (p == null || p.isEmpty) return false;
    // E.164: starts with +, 8–15 digits total.
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(p);
  }

  /// Fields still required before the application can be submitted.
  List<String> get missingSubmissionFields => [
    if (phoneNumber == null || !hasValidPhone) 'phoneNumber',
    if (teachingLanguages.isEmpty) 'teachingLanguages',
    if (specializations.isEmpty) 'specializations',
    if (bio == null || bio!.trim().isEmpty) 'bio',
  ];

  bool get isReadyToSubmit => missingSubmissionFields.isEmpty;

  TeacherApplication copyWith({
    TeacherApplicationStatus? status,
    String? phoneNumber,
    String? phoneCountryCode,
    PreferredContactMethod? preferredContactMethod,
    List<String>? teachingLanguages,
    List<String>? specializations,
    String? bio,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    DateTime? updatedAt,
  }) => TeacherApplication(
    id: id,
    userId: userId,
    status: status ?? this.status,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
    preferredContactMethod:
        preferredContactMethod ?? this.preferredContactMethod,
    teachingLanguages: teachingLanguages ?? this.teachingLanguages,
    specializations: specializations ?? this.specializations,
    bio: bio ?? this.bio,
    submittedAt: submittedAt ?? this.submittedAt,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    reviewedBy: reviewedBy ?? this.reviewedBy,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    userId,
    status,
    phoneNumber,
    phoneCountryCode,
    preferredContactMethod,
    teachingLanguages,
    specializations,
    bio,
    submittedAt,
    reviewedAt,
    reviewedBy,
    rejectionReason,
    createdAt,
    updatedAt,
  ];
}
