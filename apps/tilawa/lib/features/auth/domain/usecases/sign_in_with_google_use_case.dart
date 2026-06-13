import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

@injectable
class SignInWithGoogleUseCase {
  SignInWithGoogleUseCase(
    this._authRepository,
    this._userRepository,
  );

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  Future<AuthResult> call() async {
    final AuthResult result = await _authRepository.signInWithGoogle();

    return result.maybeWhen(
      success: (user) async {
        try {
          await _userRepository.saveUserData(user);
        } catch (error, stackTrace) {
          logger.w(
            'Signed in but failed to persist user profile',
            error: error,
            stackTrace: stackTrace,
          );
        }
        return AuthResult.success(user: user);
      },
      orElse: () => result,
    );
  }
}
