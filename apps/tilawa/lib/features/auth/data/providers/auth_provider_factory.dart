import 'package:credential_manager/credential_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/auth/core/auth_config.dart';

import '../../domain/providers/auth_provider_interface.dart';
import '../services/credential_manager_initializer.dart';
import 'credential_manager_auth_provider.dart';
import 'google_auth_provider_impl.dart';

@LazySingleton()
class AuthProviderFactory {
  AuthProviderFactory(
    this._firebaseAuth,
    this._googleSignIn,
    this._credentialManager,
    this._credentialManagerInitializer,
  );
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final CredentialManager _credentialManager;
  final CredentialManagerInitializer _credentialManagerInitializer;

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
        _credentialManagerInitializer,
      ),
    };
  }
}
