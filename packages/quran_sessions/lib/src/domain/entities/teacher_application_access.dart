import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Platform policy for who may see teacher-application entry points.
///
/// Stored at `quran_session_platform_config/global.teacherApplicationAccess`.
/// Per-user override: `users/{uid}.quranSessionsProfile.canApplyAsTeacher`.
enum TeacherApplicationAccessMode {
  /// Nobody may start a new application (default when unset).
  none,

  /// All signed-in users may apply (subject to per-user override).
  all,

  /// Only user ids listed in [TeacherApplicationAccessPolicy.allowlistUserIds].
  allowlist,

  /// Match any non-empty rule dimension (country, role, email, phone).
  rules,
}

/// Rule dimensions evaluated when [TeacherApplicationAccessMode.rules] is active.
@immutable
class TeacherApplicationAccessRules extends Equatable {
  const TeacherApplicationAccessRules({
    this.countryCodes = const [],
    this.roles = const [],
    this.emails = const [],
    this.phones = const [],
  });

  final List<String> countryCodes;
  final List<String> roles;
  final List<String> emails;
  final List<String> phones;

  @override
  List<Object?> get props => [countryCodes, roles, emails, phones];
}

/// Remote policy document shape (backend source of truth).
@immutable
class TeacherApplicationAccessPolicy extends Equatable {
  const TeacherApplicationAccessPolicy({
    this.mode = TeacherApplicationAccessMode.none,
    this.allowlistUserIds = const [],
    this.rules = const TeacherApplicationAccessRules(),
  });

  final TeacherApplicationAccessMode mode;
  final List<String> allowlistUserIds;
  final TeacherApplicationAccessRules rules;

  @override
  List<Object?> get props => [mode, allowlistUserIds, rules];
}

/// Inputs required to resolve whether a user may see apply entry points.
@immutable
class TeacherApplicationAccessContext extends Equatable {
  const TeacherApplicationAccessContext({
    required this.userId,
    this.userEmail,
    this.userPhone,
    this.userCountryCode,
    this.userRole = 'student',
    this.userOverride,
  });

  final String userId;
  final String? userEmail;
  final String? userPhone;
  final String? userCountryCode;
  final String userRole;

  /// `true` / `false` force allow/deny; `null` follow platform policy.
  final bool? userOverride;

  @override
  List<Object?> get props => [
    userId,
    userEmail,
    userPhone,
    userCountryCode,
    userRole,
    userOverride,
  ];
}

/// Resolved entitlement for presentation (`canApplyAsTeacher == true`).
@immutable
class TeacherApplicationAccess extends Equatable {
  const TeacherApplicationAccess({required this.canApplyAsTeacher});

  final bool canApplyAsTeacher;

  @override
  List<Object?> get props => [canApplyAsTeacher];
}
