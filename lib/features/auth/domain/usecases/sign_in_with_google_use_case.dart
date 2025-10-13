import 'package:injectable/injectable.dart';
import 'package:muzakri/features/auth/domain/entities/auth_result.dart';
import 'package:muzakri/features/auth/domain/repositories/auth_repository.dart';

@Singleton()
class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  SignInWithGoogleUseCase(this._repository);

  Future<AuthResult> call() async {
    return await _repository.signInWithGoogle();
  }
}
