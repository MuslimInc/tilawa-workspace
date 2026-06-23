import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_user_language_preference_use_case.dart';

class NoopUserRepository implements UserRepository {
  @override
  Future<void> deleteUserData(String userId) async {}

  @override
  Future<void> saveUserData(UserEntity user) async {}

  @override
  Future<void> syncLanguagePreference(String languageCode) async {}
}

SyncUserLanguagePreferenceUseCase noopSyncUserLanguagePreferenceUseCase() {
  return SyncUserLanguagePreferenceUseCase(NoopUserRepository());
}
