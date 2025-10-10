import 'package:injectable/injectable.dart';
import 'package:muzakri/features/auth/domain/entities/user.dart';
import 'package:muzakri/features/auth/domain/repositories/auth_repository.dart';

@injectable
class GetCurrentUser {
  final AuthRepository _repository;

  GetCurrentUser(this._repository);

  User? call() {
    return _repository.currentUser;
  }
}
