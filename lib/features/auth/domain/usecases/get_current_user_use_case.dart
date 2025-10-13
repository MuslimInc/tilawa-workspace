import 'package:injectable/injectable.dart';
import 'package:muzakri/features/auth/domain/entities/user.dart';
import 'package:muzakri/features/auth/domain/repositories/auth_repository.dart';

@Singleton()
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  User? call() {
    return _repository.currentUser;
  }
}
