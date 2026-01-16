import 'package:injectable/injectable.dart';

import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

@injectable
class SignInWithGoogleUseCase {
  SignInWithGoogleUseCase(this._authRepository, this._userRepository);

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  Future<AuthResult> call() async {
    final AuthResult result = await _authRepository.signInWithGoogle();

    return result.maybeWhen(
      success: (user) async {
        try {
          await _userRepository.saveUserData(user);
          return AuthResult.success(user: user);
        } catch (e) {
          rethrow;
        }
      },
      orElse: () => result,
    );
  }
}
