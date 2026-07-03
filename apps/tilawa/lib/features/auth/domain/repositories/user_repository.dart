import '../../domain/entities/email_registration_draft.dart';
import '../../domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<void> saveUserData(UserEntity user);

  /// Ensures `users/{uid}.quranSessionsProfile` exists with incomplete shell.
  Future<void> ensureQuranSessionsProfileShell(String userId);

  /// Writes merged user + completed Quran Sessions profile after registration.
  Future<void> saveCompleteEmailRegistration({
    required UserEntity user,
    required EmailRegistrationDraft draft,
  });

  /// Writes `languageCode` on the signed-in user's Firestore document.
  Future<void> syncLanguagePreference(String languageCode);

  /// Removes the user document and known subcollections from Firestore.
  Future<void> deleteUserData(String userId);
}
