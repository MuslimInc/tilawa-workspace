import 'package:injectable/injectable.dart';

import '../repositories/auth_repository.dart';

/// Warms Google account selection before navigating to [LoginScreen].
@injectable
class PrepareGoogleSignInUseCase {
  PrepareGoogleSignInUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() => _authRepository.prepareGoogleSignIn();
}
