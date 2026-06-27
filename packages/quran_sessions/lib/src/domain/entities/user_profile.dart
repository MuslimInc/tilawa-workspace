import 'package:equatable/equatable.dart';

// ── Enumerations ──────────────────────────────────────────────────────────────

/// System access roles — orthogonal to marketplace capability.
///
/// `teacher` is NOT a role. Teacher capability is represented by an approved
/// [TeacherProfile] + an [TeacherApplication] in the `approved` state.
/// See ADR-003 and [TeacherApplication].
enum UserRole { student, admin, moderator }

enum UserGender { male, female }

enum UserAgeGroup { child, adult }

/// Student learning goals captured during profile completion (Qutor parity).
enum StudentLearningGoal { recitation, hifz, tajweed, arabic }

/// Goals offered in profile completion — order matches UI.
const List<StudentLearningGoal> kStudentLearningGoalOptions = [
  StudentLearningGoal.recitation,
  StudentLearningGoal.hifz,
  StudentLearningGoal.tajweed,
  StudentLearningGoal.arabic,
];

enum AccountStatus { active, underReview, suspended, blocked }

enum AccountRestrictionReason {
  falseIdentity,
  policyViolation,
  safetyConcern,
  abuseReport,
  repeatedNoShow,
  adminDecision,
}

// ── UserProfile entity ────────────────────────────────────────────────────────

/// The application-level profile for a user within the Quran Sessions feature.
///
/// [role] is a system-access role — student, admin, or moderator.
/// Teacher capability is a separate verified profile — see [TeacherApplication].
/// [gender] and [dateOfBirth] are nullable until the user completes setup.
/// - [countryCode] + [cityId] are required before booking; they drive
///   market config resolution (pricing, teacher availability, currency).
/// - [guardianId] is set when a parent/guardian account manages this profile
///   (applies to child students).
class UserProfile extends Equatable {
  const UserProfile({
    required this.userId,
    required this.role,
    required this.accountStatus,
    this.displayName,
    this.gender,
    this.dateOfBirth,
    this.countryCode,
    this.countryName,
    this.cityId,
    this.cityName,
    this.currencyCode,
    this.timezone,
    this.guardianId,
    this.guardianChildBookingApprovedAt,
    this.restrictionReason,
    this.learningGoals = const [],
  });

  final String userId;
  final UserRole role;
  final AccountStatus accountStatus;
  final String? displayName;
  final UserGender? gender;
  final DateTime? dateOfBirth;

  /// ISO 3166-1 alpha-2 market country code, e.g. 'EG'.
  /// Required before booking — used to resolve market pricing and rules.
  final String? countryCode;

  /// Display name for [countryCode], e.g. 'مصر'.
  final String? countryName;

  /// Machine ID of the student's city within [countryCode], e.g. 'cairo'.
  final String? cityId;

  /// Display name of the city, e.g. 'القاهرة'.
  final String? cityName;

  /// ISO 4217 currency code resolved from the market config, e.g. 'EGP'.
  /// Stored for display without an extra market config fetch.
  final String? currencyCode;

  /// IANA timezone resolved from the city config, e.g. 'Africa/Cairo'.
  final String? timezone;

  /// ID of the guardian/parent user, if this is a child's profile.
  final String? guardianId;

  /// Set when a linked guardian approves Quran Sessions bookings for a child.
  final DateTime? guardianChildBookingApprovedAt;

  /// Populated when [accountStatus] is [AccountStatus.suspended] or
  /// [AccountStatus.blocked].
  final AccountRestrictionReason? restrictionReason;

  /// Optional learning goals — not required for booking eligibility.
  final List<StudentLearningGoal> learningGoals;

  // ── Computed ────────────────────────────────────────────────────────────────

  /// True when all mandatory fields required before booking are filled.
  ///
  /// Requires: gender, dateOfBirth, countryCode, cityId.
  bool get isComplete =>
      gender != null &&
      dateOfBirth != null &&
      countryCode != null &&
      cityId != null;

  /// Fields still missing for profile completion (machine-readable).
  List<String> get missingFields => [
    if (gender == null) 'gender',
    if (dateOfBirth == null) 'dateOfBirth',
    if (countryCode == null) 'countryCode',
    if (cityId == null) 'cityId',
  ];

  /// Derives age group from [dateOfBirth] and the global [childAgeThreshold].
  ///
  /// A null DOB is treated as adult (safe default — no child restriction).
  /// Age is calculated using calendar years: the birthday must have passed in
  /// the current year for the year to be counted.  This avoids the ±1 error
  /// produced by the naive `inDays ~/ 365` approximation near leap-year
  /// boundaries.  Age == threshold is classified as adult.
  UserAgeGroup ageGroup(int childAgeThreshold) {
    final dob = dateOfBirth;
    if (dob == null) return UserAgeGroup.adult;
    final today = DateTime.now();
    final age = _calendarAge(dob, today);
    return age < childAgeThreshold ? UserAgeGroup.child : UserAgeGroup.adult;
  }

  static int _calendarAge(DateTime dob, DateTime today) {
    var age = today.year - dob.year;
    final birthdayPassedThisYear =
        today.month > dob.month ||
        (today.month == dob.month && today.day >= dob.day);
    if (!birthdayPassedThisYear) age--;
    return age;
  }

  bool get isActive => accountStatus == AccountStatus.active;

  UserProfile copyWith({
    UserRole? role,
    AccountStatus? accountStatus,
    String? displayName,
    UserGender? gender,
    DateTime? dateOfBirth,
    String? countryCode,
    String? countryName,
    String? cityId,
    String? cityName,
    String? currencyCode,
    String? timezone,
    String? guardianId,
    DateTime? guardianChildBookingApprovedAt,
    AccountRestrictionReason? restrictionReason,
    List<StudentLearningGoal>? learningGoals,
  }) => UserProfile(
    userId: userId,
    role: role ?? this.role,
    accountStatus: accountStatus ?? this.accountStatus,
    displayName: displayName ?? this.displayName,
    gender: gender ?? this.gender,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    countryCode: countryCode ?? this.countryCode,
    countryName: countryName ?? this.countryName,
    cityId: cityId ?? this.cityId,
    cityName: cityName ?? this.cityName,
    currencyCode: currencyCode ?? this.currencyCode,
    timezone: timezone ?? this.timezone,
    guardianId: guardianId ?? this.guardianId,
    guardianChildBookingApprovedAt:
        guardianChildBookingApprovedAt ?? this.guardianChildBookingApprovedAt,
    restrictionReason: restrictionReason ?? this.restrictionReason,
    learningGoals: learningGoals ?? this.learningGoals,
  );

  @override
  List<Object?> get props => [
    userId,
    role,
    accountStatus,
    displayName,
    gender,
    dateOfBirth,
    countryCode,
    countryName,
    cityId,
    cityName,
    currencyCode,
    timezone,
    guardianId,
    guardianChildBookingApprovedAt,
    restrictionReason,
    learningGoals,
  ];
}
