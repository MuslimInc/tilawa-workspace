import 'package:tilawa/features/auth/domain/entities/email_registration_draft.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_user_language_preference_use_case.dart';

class NoopUserRepository implements UserRepository {
  @override
  Future<void> deleteUserData(String userId) async {}

  @override
  Future<void> saveUserData(
    UserEntity user, {
    String? authProvider,
    bool? profileCompleted,
  }) async {}

  @override
  Future<void> ensureQuranSessionsProfileShell(String userId) async {}

  @override
  Future<void> saveCompleteEmailRegistration({
    required UserEntity user,
    required EmailRegistrationDraft draft,
  }) async {}

  @override
  Future<void> syncLanguagePreference(String languageCode) async {}

  @override
  Future<UserEntity> updateAccountProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    return UserEntity(
      id: 'noop',
      email: '',
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

SyncUserLanguagePreferenceUseCase noopSyncUserLanguagePreferenceUseCase() {
  return SyncUserLanguagePreferenceUseCase(NoopUserRepository());
}
