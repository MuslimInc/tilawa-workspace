/// Stable keys for email/password auth failures.
///
/// Values match [AppLocalizations] arb keys; map in presentation via
/// [localizedEmailAuthFailureMessage].
abstract final class EmailAuthFailureKey {
  static const String invalidEmail = 'authInvalidEmail';
  static const String weakPassword = 'authWeakPassword';
  static const String passwordsDoNotMatch = 'authPasswordsDoNotMatch';
  static const String userNotFound = 'authUserNotFound';
  static const String wrongPassword = 'authWrongPassword';
  static const String emailAlreadyInUse = 'authEmailAlreadyInUse';
  static const String emailAlreadyInUseWithGoogle =
      'authEmailAlreadyInUseWithGoogle';
  static const String accountExistsWithDifferentCredential =
      'authAccountExistsWithDifferentCredential';
  static const String accountExistsUseEmailPassword =
      'authAccountExistsUseEmailPassword';
  static const String tooManyRequests = 'authTooManyRequests';
  static const String networkError = 'authNetworkError';
  static const String operationNotAllowed = 'authOperationNotAllowed';
  static const String userDisabled = 'authUserDisabled';
  static const String invalidCredential = 'authInvalidCredential';
  static const String resetEmailSent = 'authResetEmailSent';
  static const String generic = 'authErrorGenericMessage';
}
