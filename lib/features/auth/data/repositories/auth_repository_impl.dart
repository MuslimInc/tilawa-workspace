import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/providers/auth_provider_interface.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../providers/auth_provider_factory.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    AuthProviderFactory authProviderFactory,
    this._userRepository,
  ) : _authProvider = authProviderFactory.createAuthProvider();
  final AuthProviderInterface _authProvider;
  final UserRepository _userRepository;

  @override
  Stream<UserEntity?> get authStateChanges => _authProvider.authStateChanges;

  @override
  Future<AuthResult> signInWithGoogle() async {
    final AuthResult result = await _authProvider.signIn();

    return result.when(
      success: (user) async {
        await _userRepository.saveUserData(user);
        return AuthResult.success(user: user);
      },
      failure: (message, code) =>
          AuthResult.failure(message: message, code: code),
      cancelled: () => const AuthResult.cancelled(),
    );
  }

  @override
  Future<void> signOut() async {
    await _authProvider.signOut();
  }

  @override
  UserEntity? get currentUser => _authProvider.currentUser;
}
