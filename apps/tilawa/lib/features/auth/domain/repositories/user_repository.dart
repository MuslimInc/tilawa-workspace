import '../../domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<void> saveUserData(UserEntity user);

  /// Writes `languageCode` on the signed-in user's Firestore document.
  Future<void> syncLanguagePreference(String languageCode);

  /// Removes the user document and known subcollections from Firestore.
  Future<void> deleteUserData(String userId);
}
