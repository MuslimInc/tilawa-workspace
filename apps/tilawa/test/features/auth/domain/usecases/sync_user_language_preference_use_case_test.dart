import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_draft.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_user_language_preference_use_case.dart';

class _RecordingUserRepository implements UserRepository {
  String? lastSyncedLanguageCode;

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
  Future<void> syncLanguagePreference(String languageCode) async {
    lastSyncedLanguageCode = languageCode;
  }

  @override
  Future<UserEntity> updateAccountProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    return UserEntity(
      id: 'test',
      email: '',
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

void main() {
  late _RecordingUserRepository repository;
  late SyncUserLanguagePreferenceUseCase useCase;

  setUp(() {
    repository = _RecordingUserRepository();
    useCase = SyncUserLanguagePreferenceUseCase(repository);
  });

  test('persists Arabic unchanged', () async {
    await useCase('ar');

    check(repository.lastSyncedLanguageCode).equals('ar');
  });

  test('persists English unchanged', () async {
    await useCase('en');

    check(repository.lastSyncedLanguageCode).equals('en');
  });

  test('maps unsupported locale to English', () async {
    await useCase('fr');

    check(repository.lastSyncedLanguageCode).equals('en');
  });
}
