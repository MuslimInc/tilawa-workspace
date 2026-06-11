import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/providers/auth_provider_interface.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/google_sign_in_prepare_data_source.dart';
import '../providers/auth_provider_factory.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    AuthProviderFactory authProviderFactory,
    GoogleSignInPrepareDataSource googleSignInPrepare,
  ) : _authProvider = authProviderFactory.createAuthProvider(),
      _googleSignInPrepare = googleSignInPrepare;
  final AuthProviderInterface _authProvider;
  final GoogleSignInPrepareDataSource _googleSignInPrepare;

  @override
  Stream<UserEntity?> get authStateChanges => _authProvider.authStateChanges;

  @override
  Future<AuthResult> signInWithGoogle() {
    return _authProvider.signIn();
  }

  @override
  Future<void> prepareGoogleSignIn() {
    return _googleSignInPrepare.prepare();
  }

  @override
  Future<void> signOut() async {
    await _googleSignInPrepare.clear();
    await _authProvider.signOut();
  }

  @override
  Future<void> reauthenticateForAccountDeletion() {
    return _authProvider.reauthenticateForAccountDeletion();
  }

  @override
  Future<void> deleteAccount() async {
    await _authProvider.deleteAccount();
    await _googleSignInPrepare.clear();
  }

  @override
  UserEntity? get currentUser => _authProvider.currentUser;
}
