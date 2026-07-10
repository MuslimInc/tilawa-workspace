/// Stable keys for Google sign-in failures.
///
/// Values match [AppLocalizations] arb keys; map in presentation via
/// [localizedGoogleSignInFailureMessage].
abstract final class GoogleSignInFailureKey {
  static const String uiUnavailable = 'googleSignInFallbackBody';
  static const String notConfigured = 'googleSignInNotConfigured';
  static const String timeout = 'googleSignInTimeout';
  static const String timeoutUiHidden = 'googleSignInTimeoutUiHidden';
  static const String userMismatch = 'googleSignInUserMismatch';
  static const String offline = 'serverActionOfflineMessage';
  static const String generic = 'authErrorGenericMessage';
}
