class GoogleSignInConfig {
  // TODO: Replace with your actual server client ID from Firebase Console
  // To get this:
  // 1. Go to Firebase Console -> Project Settings -> General
  // 2. Scroll down to "Your apps" section
  // 3. Find your web app and copy the "Web client ID"
  static const String serverClientId = 'YOUR_SERVER_CLIENT_ID_HERE';

  // For development, you can use a placeholder
  // For production, make sure to use the actual server client ID
  static const String developmentServerClientId =
      '123456789-abcdefghijklmnop.apps.googleusercontent.com';

  // Temporary fallback - this will cause an error but won't crash the app
  static String get effectiveServerClientId {
    if (serverClientId == 'YOUR_SERVER_CLIENT_ID_HERE') {
      print(
        'WARNING: Google Sign-In not configured. Please update GoogleSignInConfig.serverClientId',
      );
      return developmentServerClientId;
    }
    return serverClientId;
  }
}
