import 'dart:io';

/// Configuration for authentication providers
/// This allows easy switching between different authentication methods
enum AuthProviderType { googleSignIn, credentialManager }

class AuthConfig {
  /// The authentication provider to use
  /// Automatically selects based on platform:
  /// - iOS: Uses google_sign_in package
  /// - Android: Uses credential_manager package
  static AuthProviderType get providerType {
    if (Platform.isIOS) {
      return AuthProviderType.googleSignIn;
    } else {
      return AuthProviderType.credentialManager;
    }
  }

  /// Whether to use the new credential manager implementation
  static bool get useCredentialManager =>
      providerType == AuthProviderType.credentialManager;

  /// Whether to use the legacy Google Sign-In implementation
  static bool get useGoogleSignIn =>
      providerType == AuthProviderType.googleSignIn;
}
