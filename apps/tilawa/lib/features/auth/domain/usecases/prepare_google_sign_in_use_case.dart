import '../repositories/auth_repository.dart';

/// Warms Google account selection before navigating to [LoginScreen].
class PrepareGoogleSignInUseCase {
  PrepareGoogleSignInUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() {
    return _authRepository.prepareGoogleSignIn();
  }
}
