import '../entities/email_auth_failure_key.dart';

/// Pure validation for email/password forms.
abstract final class EmailAuthFormPolicy {
  static const int minPasswordLength = 6;

  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@[\w.-]+\.\w{2,}$',
  );

  static String? validateEmail(String email) {
    final String trimmed = email.trim();
    if (trimmed.isEmpty) {
      return EmailAuthFailureKey.invalidEmail;
    }
    if (!_emailPattern.hasMatch(trimmed)) {
      return EmailAuthFailureKey.invalidEmail;
    }
    return null;
  }

  static String? validatePassword(String password) {
    if (password.length < minPasswordLength) {
      return EmailAuthFailureKey.weakPassword;
    }
    return null;
  }

  static String? validateConfirmPassword({
    required String password,
    required String confirmPassword,
  }) {
    if (password != confirmPassword) {
      return EmailAuthFailureKey.passwordsDoNotMatch;
    }
    return null;
  }
}
