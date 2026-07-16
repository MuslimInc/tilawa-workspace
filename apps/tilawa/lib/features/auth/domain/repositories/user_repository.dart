import '../entities/email_registration_draft.dart';
import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<void> saveUserData(
    UserEntity user, {
    String? authProvider,
    bool? profileCompleted,
  });

  /// Ensures `users/{uid}.quranSessionsProfile` exists with incomplete shell.
  Future<void> ensureQuranSessionsProfileShell(String userId);

  /// Writes general app profile + incomplete Quran Sessions shell after email registration.
  Future<void> saveCompleteEmailRegistration({
    required UserEntity user,
    required EmailRegistrationDraft draft,
  });

  /// Writes `languageCode` on the signed-in user's Firestore document.
  Future<void> syncLanguagePreference(String languageCode);

  /// Updates Auth + Firestore identity for the signed-in user.
  ///
  /// Pass [photoUrl] `null` to clear the profile picture.
  Future<UserEntity> updateAccountProfile({
    required String displayName,
    String? photoUrl,
  });

  /// Removes the user document and known subcollections from Firestore.
  Future<void> deleteUserData(String userId);
}
