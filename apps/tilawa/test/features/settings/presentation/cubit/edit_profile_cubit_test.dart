import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/data/datasources/profile_avatar_storage.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_draft.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';
import 'package:tilawa/features/settings/presentation/cubit/edit_profile_cubit.dart';

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository() : throwOnUpdate = false;

  bool throwOnUpdate;
  int updateCalls = 0;
  String? lastDisplayName;
  String? lastPhotoUrl;

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
    updateCalls += 1;
    if (throwOnUpdate) {
      throw StateError('update failed');
    }
    lastDisplayName = displayName;
    lastPhotoUrl = photoUrl;
    return UserEntity(
      id: 'user-1',
      email: 'user@example.com',
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: DateTime.utc(2025, 12),
    );
  }
}

class _FakeAvatarStorage extends Fake implements ProfileAvatarStorage {
  String? uploadedPath;
  int deleteCalls = 0;

  @override
  Future<String> upload({
    required String userId,
    required String localPath,
  }) async {
    uploadedPath = localPath;
    return 'https://example.com/users/$userId/avatar.jpg?v=1';
  }

  @override
  Future<void> delete(String userId) async {
    deleteCalls += 1;
  }
}

void main() {
  late _FakeUserRepository repository;
  late _FakeAvatarStorage avatarStorage;
  late EditProfileCubit cubit;

  final UserEntity user = UserEntity(
    id: 'user-1',
    email: 'user@example.com',
    displayName: 'Mohammad Kamel',
    photoUrl: 'https://example.com/photo.jpg',
    createdAt: DateTime.utc(2025, 12),
  );

  setUp(() {
    repository = _FakeUserRepository();
    avatarStorage = _FakeAvatarStorage();
    cubit = EditProfileCubit(repository, avatarStorage);
    cubit.init(user);
  });

  tearDown(() async {
    await cubit.close();
  });

  group('dirty tracking', () {
    test('starts clean', () {
      check(cubit.state.isDirty).isFalse();
      check(cubit.state.canSave).isFalse();
    });

    test('name change marks dirty', () {
      cubit.displayNameChanged('New Name');

      check(cubit.state.isDirty).isTrue();
      check(cubit.state.canSave).isTrue();
    });

    test('whitespace-only rename against same trimmed name stays clean', () {
      cubit.displayNameChanged('  Mohammad Kamel  ');

      check(cubit.state.isDirty).isFalse();
    });

    test('remove photo marks dirty', () {
      cubit.removePhoto();

      check(cubit.state.isDirty).isTrue();
      check(cubit.state.hasPhoto).isFalse();
      check(cubit.state.removePhoto).isTrue();
    });
  });

  group('validation', () {
    test('empty name sets nameError and stays editing', () async {
      cubit.displayNameChanged('   ');
      await cubit.save(user);

      check(cubit.state.nameError).isTrue();
      check(cubit.state.status).equals(EditProfileStatus.editing);
      check(repository.updateCalls).equals(0);
    });
  });

  group('applyPickedImagePath', () {
    test('rejects oversized files', () async {
      final Directory dir = await Directory.systemTemp.createTemp(
        'edit_profile_',
      );
      final File file = File('${dir.path}/big.jpg');
      await file.writeAsBytes(
        List<int>.filled(ProfileAvatarStorage.maxUploadBytes + 1, 1),
      );

      await cubit.applyPickedImagePath(file.path);

      check(cubit.state.status).equals(EditProfileStatus.failure);
      check(cubit.state.errorMessage).equals('avatarTooLarge');
      check(cubit.state.localImagePath).isNull();

      await dir.delete(recursive: true);
    });

    test('stages a valid local image', () async {
      final Directory dir = await Directory.systemTemp.createTemp(
        'edit_profile_',
      );
      final File file = File('${dir.path}/ok.jpg');
      await file.writeAsBytes(List<int>.filled(128, 1));

      await cubit.applyPickedImagePath(file.path);

      check(cubit.state.status).equals(EditProfileStatus.editing);
      check(cubit.state.localImagePath).equals(file.path);
      check(cubit.state.isDirty).isTrue();

      await dir.delete(recursive: true);
    });
  });

  group('save', () {
    test('no-op save succeeds without repository writes', () async {
      await cubit.save(user);

      check(cubit.state.status).equals(EditProfileStatus.success);
      check(cubit.state.savedUser).equals(user);
      check(repository.updateCalls).equals(0);
    });

    test('name change updates repository', () async {
      cubit.displayNameChanged('Updated Name');
      await cubit.save(user);

      check(repository.updateCalls).equals(1);
      check(repository.lastDisplayName).equals('Updated Name');
      check(cubit.state.status).equals(EditProfileStatus.success);
      check(cubit.state.savedUser?.displayName).equals('Updated Name');
    });

    test('remove managed photo deletes storage then clears url', () async {
      final UserEntity managed = user.copyWith(
        photoUrl:
            'https://firebasestorage.googleapis.com/v0/b/x/o/users%2Fuser-1%2Favatar.jpg?alt=media',
      );
      cubit.init(managed);
      cubit.removePhoto();
      await cubit.save(managed);

      check(avatarStorage.deleteCalls).equals(1);
      check(repository.lastPhotoUrl).isNull();
      check(cubit.state.status).equals(EditProfileStatus.success);
    });

    test('repository failure emits saveFailed', () async {
      repository.throwOnUpdate = true;
      cubit.displayNameChanged('Updated Name');
      await cubit.save(user);

      check(cubit.state.status).equals(EditProfileStatus.failure);
      check(cubit.state.errorMessage).equals('saveFailed');
      check(cubit.state.canSave).isTrue();
    });
  });
}
