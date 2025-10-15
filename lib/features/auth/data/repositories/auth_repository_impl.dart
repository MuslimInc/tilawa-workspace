import 'package:injectable/injectable.dart';
import 'package:muzakri/features/auth/data/providers/auth_provider_factory.dart';
import 'package:muzakri/features/auth/domain/entities/auth_result.dart';
import 'package:muzakri/features/auth/domain/entities/user_entity.dart';
import 'package:muzakri/features/auth/domain/providers/auth_provider_interface.dart';
import 'package:muzakri/features/auth/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthProviderInterface _authProvider;

  AuthRepositoryImpl(AuthProviderFactory authProviderFactory)
    : _authProvider = authProviderFactory.createAuthProvider();

  @override
  Stream<UserEntity?> get authStateChanges => _authProvider.authStateChanges;

  @override
  Future<AuthResult> signInWithGoogle() async {
    return await _authProvider.signIn();
  }

  @override
  Future<void> signOut() async {
    await _authProvider.signOut();
  }

  @override
  UserEntity? get currentUser => _authProvider.currentUser;
}
