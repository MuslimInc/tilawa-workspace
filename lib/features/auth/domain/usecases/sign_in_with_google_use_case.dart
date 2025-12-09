import 'package:injectable/injectable.dart';
import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

@Singleton()
class SignInWithGoogleUseCase {
  SignInWithGoogleUseCase(this._repository);
  final AuthRepository _repository;

  Future<AuthResult> call() async {
    return _repository.signInWithGoogle();
  }
}
