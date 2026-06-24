import '../../domain/entities/teacher_application_access.dart';

class TeacherApplicationAccessRulesDto {
  const TeacherApplicationAccessRulesDto({
    this.countryCodes = const [],
    this.roles = const [],
    this.emails = const [],
    this.phones = const [],
  });

  final List<String> countryCodes;
  final List<String> roles;
  final List<String> emails;
  final List<String> phones;

  TeacherApplicationAccessRules toDomain() => TeacherApplicationAccessRules(
    countryCodes: countryCodes,
    roles: roles,
    emails: emails,
    phones: phones,
  );
}

class TeacherApplicationAccessPolicyDto {
  const TeacherApplicationAccessPolicyDto({
    this.mode = 'none',
    this.allowlistUserIds = const [],
    this.rules = const TeacherApplicationAccessRulesDto(),
  });

  final String mode;
  final List<String> allowlistUserIds;
  final TeacherApplicationAccessRulesDto rules;

  TeacherApplicationAccessPolicy toDomain() => TeacherApplicationAccessPolicy(
    mode: _parseMode(mode),
    allowlistUserIds: allowlistUserIds,
    rules: rules.toDomain(),
  );

  static TeacherApplicationAccessMode _parseMode(String raw) {
    return switch (raw) {
      'all' => TeacherApplicationAccessMode.all,
      'allowlist' => TeacherApplicationAccessMode.allowlist,
      'rules' => TeacherApplicationAccessMode.rules,
      _ => TeacherApplicationAccessMode.none,
    };
  }
}

/// Raw snapshot from Firestore for a single user resolution.
class TeacherApplicationAccessSnapshotDto {
  const TeacherApplicationAccessSnapshotDto({
    required this.policy,
    this.userOverride,
    this.userEmail,
    this.userPhone,
    this.userCountryCode,
    this.userRole = 'student',
  });

  final TeacherApplicationAccessPolicyDto policy;
  final bool? userOverride;
  final String? userEmail;
  final String? userPhone;
  final String? userCountryCode;
  final String userRole;

  TeacherApplicationAccessContext toContext(String userId) {
    return TeacherApplicationAccessContext(
      userId: userId,
      userEmail: userEmail,
      userPhone: userPhone,
      userCountryCode: userCountryCode,
      userRole: userRole,
      userOverride: userOverride,
    );
  }
}
