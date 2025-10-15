import 'package:credential_manager/credential_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/features/auth/core/auth_config.dart';
import 'package:muzakri/features/auth/data/providers/credential_manager_auth_provider.dart';
import 'package:muzakri/features/auth/data/providers/google_auth_provider_impl.dart';
import 'package:muzakri/features/auth/domain/providers/auth_provider_interface.dart';

@LazySingleton()
class AuthProviderFactory {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final CredentialManager _credentialManager;

  AuthProviderFactory(
    this._firebaseAuth,
    this._googleSignIn,
    this._credentialManager,
  );

  /// Creates the appropriate AuthProvider based on the configuration
  AuthProviderInterface createAuthProvider() {
    return switch (AuthConfig.providerType) {
      AuthProviderType.googleSignIn => GoogleAuthProviderImpl(
        _firebaseAuth,
        _googleSignIn,
      ),
      AuthProviderType.credentialManager => CredentialManagerAuthProvider(
        _firebaseAuth,
        _credentialManager,
      ),
    };
  }
}
