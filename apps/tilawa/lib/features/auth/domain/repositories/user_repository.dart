import '../../domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<void> saveUserData(UserEntity user);

  Future<void> saveDeviceToken(String userId, String token);

  Future<void> deleteDeviceToken(String userId, String token);

  /// Removes the user document and known subcollections from Firestore.
  Future<void> deleteUserData(String userId);
}
