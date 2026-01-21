import '../../domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<void> saveUserData(UserEntity user);

  Future<void> saveDeviceToken(String userId, String token);
}
