import 'package:muzakri/features/auth/domain/entities/user.dart';
import 'package:muzakri/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository _repository;

  GetCurrentUser(this._repository);

  User? call() {
    return _repository.currentUser;
  }
}
