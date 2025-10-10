import 'package:injectable/injectable.dart';
import 'package:muzakri/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SignOut {
  final AuthRepository _repository;

  SignOut(this._repository);

  Future<void> call() async {
    await _repository.signOut();
  }
}
