import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/providers/auth_provider_interface.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_provider_factory.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(AuthProviderFactory authProviderFactory)
    : _authProvider = authProviderFactory.createAuthProvider();
  final AuthProviderInterface _authProvider;

  @override
  Stream<UserEntity?> get authStateChanges => _authProvider.authStateChanges;

  @override
  Future<AuthResult> signInWithGoogle() {
    return _authProvider.signIn();
  }

  @override
  Future<void> signOut() async {
    await _authProvider.signOut();
  }

  @override
  UserEntity? get currentUser => _authProvider.currentUser;
}
