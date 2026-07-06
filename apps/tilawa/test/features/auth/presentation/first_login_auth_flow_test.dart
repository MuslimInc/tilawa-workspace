import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/data/services/google_sign_in_session_tracker.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/services/session_revoked_notifier.dart';
import 'package:tilawa/features/auth/domain/services/token_sync_cache.dart';
import 'package:tilawa/features/auth/domain/usecases/check_session_validity_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';
import 'package:tilawa/features/auth/presentation/cubit/session_validity_cubit.dart';

import '../../../support/map_backed_shared_preferences_async.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSignOut extends Mock implements SignOut {}

class _InMemoryTokenSyncCache implements TokenSyncCache {
  int? sessionEpoch;
  String? activeDeviceId;

  @override
  Future<void> clearSession() async {
    sessionEpoch = null;
    activeDeviceId = null;
  }

  @override
  Future<void> clearSync() async {}

  @override
  Future<String?> getActiveDeviceId() async => activeDeviceId;

  @override
  Future<String?> getLastSyncedToken() async => null;

  @override
  Future<String?> getLastSyncedUserId() async => null;

  @override
  Future<int?> getSessionEpoch() async => sessionEpoch;

  @override
  Future<void> saveActiveDeviceId(String deviceId) async {
    activeDeviceId = deviceId;
  }

  @override
  Future<void> saveSessionEpoch(int epoch) async {
    sessionEpoch = epoch;
  }

  @override
  Future<void> saveSync(String token, String userId) async {}
}

void main() {
  late UserEntity testUser;
  late MockAuthRepository mockAuthRepository;
  late MockSignOut mockSignOut;
  late GoogleSignInSessionTracker signInSessionTracker;
  late _InMemoryTokenSyncCache tokenSyncCache;
  late FakeFirebaseFirestore firestore;
  late CheckSessionValidityUseCase checkSessionValidityUseCase;
  late MapBackedSharedPreferencesAsync revokePrefs;

  setUp(() {
    revokePrefs = MapBackedSharedPreferencesAsync();
    PendingSessionRevokeStore.setPrefsFactoryForTesting(
      () => revokePrefs.prefs,
    );
    testUser = UserEntity(
      id: 'user_1',
      email: 'user@example.com',
      displayName: 'User',
      createdAt: DateTime.utc(2024),
    );
    mockAuthRepository = MockAuthRepository();
    mockSignOut = MockSignOut();
    signInSessionTracker = GoogleSignInSessionTracker();
    tokenSyncCache = _InMemoryTokenSyncCache();
    firestore = FakeFirebaseFirestore();
    checkSessionValidityUseCase = CheckSessionValidityUseCase(
      firestore,
      tokenSyncCache,
    );
    when(() => mockAuthRepository.currentUser).thenReturn(testUser);
    when(
      () => mockSignOut(skipServerTokenClear: true),
    ).thenAnswer((_) async => const Right(null));
  });

  tearDown(() {
    PendingSessionRevokeStore.setPrefsFactoryForTesting(null);
  });

  SessionValidityCubit buildSessionValidityCubit() {
    return SessionValidityCubit(
      mockAuthRepository,
      checkSessionValidityUseCase,
      mockSignOut,
      SessionRevokedNotifier(),
      signInSessionTracker,
      multiDeviceLoginEnabled: () => false,
    );
  }

  group('first login auth flow', () {
    blocTest<SessionValidityCubit, SessionValidityState>(
      'resume check with empty local device cache does not revoke session',
      build: buildSessionValidityCubit,
      act: (cubit) async {
        await firestore.collection('users').doc(testUser.id).set({
          'session': {'epoch': 1, 'activeDeviceId': 'device_1'},
        });
        await cubit.checkOnResume();
      },
      expect: () => [
        const SessionValidityState(isChecking: true),
        const SessionValidityState(
          isChecking: false,
          verificationUnknown: true,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => mockSignOut(skipServerTokenClear: true),
        );
      },
    );

    blocTest<SessionValidityCubit, SessionValidityState>(
      'does not revoke when server session matches after first device registration',
      build: buildSessionValidityCubit,
      act: (cubit) async {
        await tokenSyncCache.saveActiveDeviceId('device_1');
        await tokenSyncCache.saveSessionEpoch(1);
        await firestore.collection('users').doc(testUser.id).set({
          'session': {'epoch': 1, 'activeDeviceId': 'device_1'},
        });
        await cubit.checkOnResume();
      },
      expect: () => [
        const SessionValidityState(isChecking: true),
        const SessionValidityState(isChecking: false),
      ],
      verify: (_) {
        verifyNever(
          () => mockSignOut(skipServerTokenClear: true),
        );
      },
    );

    blocTest<SessionValidityCubit, SessionValidityState>(
      'defers revoke check while Google sign-in is in flight on first login',
      build: () {
        signInSessionTracker.markStarted();
        return buildSessionValidityCubit();
      },
      act: (cubit) async {
        await firestore.collection('users').doc(testUser.id).set({
          'session': {'epoch': 99, 'activeDeviceId': 'other_device'},
        });
        await cubit.checkOnResume();
      },
      expect: () => <SessionValidityState>[],
      verify: (_) {
        verifyNever(
          () => mockSignOut(skipServerTokenClear: true),
        );
      },
    );
  });
}
