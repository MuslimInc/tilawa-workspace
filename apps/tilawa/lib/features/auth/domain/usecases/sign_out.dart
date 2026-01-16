import 'package:injectable/injectable.dart';
import '../repositories/auth_repository.dart';

@injectable
class SignOut {
  SignOut(this._repository);
  final AuthRepository _repository;

  Future<void> call() async {
    await _repository.signOut();
  }
}
