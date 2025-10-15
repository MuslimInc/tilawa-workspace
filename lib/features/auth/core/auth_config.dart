/// Configuration for authentication providers
/// This allows easy switching between different authentication methods
enum AuthProviderType { googleSignIn, credentialManager }

class AuthConfig {
  /// The authentication provider to use
  /// Change this to switch between Google Sign-In and Credential Manager
  static const AuthProviderType providerType =
      AuthProviderType.credentialManager;

  /// Whether to use the new credential manager implementation
  static bool get useCredentialManager =>
      providerType == AuthProviderType.credentialManager;

  /// Whether to use the legacy Google Sign-In implementation
  static bool get useGoogleSignIn =>
      providerType == AuthProviderType.googleSignIn;
}
