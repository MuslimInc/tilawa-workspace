import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/gateways/email_password_auth_gateway.dart';
import '../../domain/providers/auth_provider_interface.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/google_sign_in_prepare_data_source.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    AuthProviderInterface authProvider,
    GoogleSignInPrepareDataSource googleSignInPrepare,
    EmailPasswordAuthGateway emailPasswordAuth,
  ) : _authProvider = authProvider,
      _googleSignInPrepare = googleSignInPrepare,
      _emailPasswordAuth = emailPasswordAuth;

  final AuthProviderInterface _authProvider;
  final GoogleSignInPrepareDataSource _googleSignInPrepare;
  final EmailPasswordAuthGateway _emailPasswordAuth;

  @override
  Stream<UserEntity?> get authStateChanges => _authProvider.authStateChanges;

  @override
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _emailPasswordAuth.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResult> registerWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _emailPasswordAuth.registerWithEmailPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    // Best-effort warm-up; a no-op when the login screen already ran it.
    await _googleSignInPrepare.prepare();
    // GoogleSignIn.authenticate() requires a completed initialize(). prepare()
    // swallows initialization errors, so re-check the hard requirement here.
    try {
      await _googleSignInPrepare.ensureInitialized();
    } catch (e) {
      return AuthResult.failure(
        message: 'Google Sign-In failed to initialize: $e',
        code: 'sign-in-init-failed',
      );
    }
    return _authProvider.signIn();
  }

  @override
  Future<void> prepareGoogleSignIn() {
    return _googleSignInPrepare.prepare();
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignInPrepare.ensureInitialized();
    } catch (_) {
      // Firebase sign-out must still run; the provider treats the
      // google_sign_in part of sign-out as best-effort.
    }
    await _authProvider.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    // The re-authentication path inside deleteAccount() calls
    // GoogleSignIn.authenticate(), which requires initialize() first.
    await _googleSignInPrepare.ensureInitialized();
    await _authProvider.deleteAccount();
  }

  @override
  UserEntity? get currentUser => _authProvider.currentUser;

  @override
  Future<bool> hasAdminClaim() => _authProvider.hasAdminClaim();
}
