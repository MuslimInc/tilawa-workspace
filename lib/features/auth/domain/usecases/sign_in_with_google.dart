import 'package:injectable/injectable.dart';
import 'package:muzakri/features/auth/domain/entities/auth_result.dart';
import 'package:muzakri/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SignInWithGoogle {
  final AuthRepository _repository;

  SignInWithGoogle(this._repository);

  Future<AuthResult> call() async {
    return await _repository.signInWithGoogle();
  }
}
