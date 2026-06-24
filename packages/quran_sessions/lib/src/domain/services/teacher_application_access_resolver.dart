import '../entities/teacher_application_access.dart';

/// Pure policy resolver — no I/O.
abstract final class TeacherApplicationAccessResolver {
  static bool resolve({
    required TeacherApplicationAccessPolicy policy,
    required TeacherApplicationAccessContext context,
  }) {
    final override = context.userOverride;
    if (override == true) {
      return true;
    }
    if (override == false) {
      return false;
    }

    return switch (policy.mode) {
      TeacherApplicationAccessMode.all => true,
      TeacherApplicationAccessMode.none => false,
      TeacherApplicationAccessMode.allowlist =>
        policy.allowlistUserIds.contains(context.userId),
      TeacherApplicationAccessMode.rules => _matchesRules(
        policy.rules,
        context,
      ),
    };
  }

  static bool _matchesRules(
    TeacherApplicationAccessRules rules,
    TeacherApplicationAccessContext context,
  ) {
    if (rules.countryCodes.isNotEmpty &&
        context.userCountryCode != null &&
        rules.countryCodes.contains(context.userCountryCode)) {
      return true;
    }
    if (rules.roles.isNotEmpty && rules.roles.contains(context.userRole)) {
      return true;
    }
    final email = _normalizeEmail(context.userEmail);
    if (email != null &&
        rules.emails.any((rule) => _normalizeEmail(rule) == email)) {
      return true;
    }
    final phone = _normalizePhone(context.userPhone);
    if (phone != null &&
        rules.phones.any((rule) => _normalizePhone(rule) == phone)) {
      return true;
    }
    return false;
  }

  static String? _normalizeEmail(String? value) {
    final trimmed = value?.trim().toLowerCase();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static String? _normalizePhone(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed.replaceAll(RegExp(r'[\s\-()]'), '');
  }
}
