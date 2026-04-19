class GoogleSignInConfig {
  /// The server client ID from the Google Cloud Console / Firebase Console.
  /// Used for Google Sign-In authentication.
  static const String serverClientId =
      '181575856185-2ioqgr7miir7hj7hvgcsi7qp7juo2gco.apps.googleusercontent.com';

  /// Returns the configured server client ID.
  static String get effectiveServerClientId => serverClientId;
}
