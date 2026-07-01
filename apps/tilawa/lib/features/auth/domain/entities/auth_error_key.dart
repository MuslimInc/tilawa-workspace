abstract final class AuthErrorKey {
  static const String deviceRegistrationFailed = 'authDeviceRegistrationFailed';
  static const String appCheckFailed = 'authAppCheckFailed';
  static const String staleDeviceRejected = 'stale_device_rejected';
  static const String requiresExplicitSignIn = 'requires_explicit_sign_in';
}

/// Stable keys for self-service account deletion failures.
///
/// Values match [AppLocalizations] arb keys; map to user-visible copy in
/// presentation via [localizedAuthBlocErrorMessage].
abstract final class DeleteAccountErrorKey {
  static const String adminMustUseAdminPanel =
      'deleteAccountAdminMustUseAdminPanel';
  static const String walletNotEmpty = 'deleteAccountWalletNotEmpty';
  static const String activeBookingsStudent =
      'deleteAccountActiveBookingsStudent';
  static const String activeBookingsTeacher =
      'deleteAccountActiveBookingsTeacher';
  static const String alreadyPending = 'deleteAccountAlreadyPending';
  static const String serviceUnavailable = 'deleteAccountServiceUnavailable';
  static const String notSignedIn = 'deleteAccountNotSignedIn';
  static const String failed = 'deleteAccountFailed';
}
