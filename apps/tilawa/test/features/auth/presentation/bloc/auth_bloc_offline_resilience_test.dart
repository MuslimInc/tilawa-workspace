import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/application/account_deletion_flow_tracker.dart';
import 'package:tilawa/features/auth/data/services/google_sign_in_session_tracker.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';
import 'package:tilawa/features/auth/domain/entities/auth_error_key.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/await_auth_restoration_use_case.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../support/map_backed_shared_preferences_async.dart';

import 'auth_bloc_test.mocks.dart';

/// Offline-first contract for the auth session.
///
/// Once a user has signed in, the app must treat the locally persisted
/// session as authoritative: opening the app on a weak, dead, captive
/// (exhausted data plan), or airplane-mode network must restore the
/// authenticated state immediately and must never fabricate a logout.
/// The only thing allowed to demote the session is a definitive server
/// verdict (stale device with multi-device off) for the *current* session.
void main() {
  late AuthBloc authBloc;
  late MockSignInWithGoogleUseCase mockSignInWithGoogleUseCase;
  late MockSignInWithEmailUseCase mockSignInWithEmailUseCase;
  late MockRegisterWithEmailUseCase mockRegisterWithEmailUseCase;
  late MockSignOut mockSignOut;
  late MockDeleteAccount mockDeleteAccount;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
  late MockGetCurrentLanguageUseCase mockGetCurrentLanguageUseCase;
  late MockSyncUserLanguagePreferenceUseCase mockSyncUserLanguagePreference;
  late AccountDeletionFlowTracker accountDeletionFlowTracker;
  late GoogleSignInSessionTracker signInSessionTracker;
  late MockAwaitAuthRestorationUseCase mockAwaitAuthRestoration;
  late MockGetPersistedAuthenticatedUserUseCase mockGetPersistedUser;
  late MapBackedSharedPreferencesAsync revokePrefs;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<Either<Failure, String>>(
      const Right(LanguageConfig.defaultLanguageCode),
    );
  });

  final tUser = UserEntity(
    id: 'user-a',
    email: 'a@example.com',
    displayName: 'User A',
    createdAt: DateTime.utc(2023),
  );
  final tOtherUser = UserEntity(
    id: 'user-b',
    email: 'b@example.com',
    displayName: 'User B',
    createdAt: DateTime.utc(2024),
  );
  // Id-only placeholder shape produced by GetPersistedAuthenticatedUserUseCase.
  final tPersistedHint = UserEntity(
    id: 'user-a',
    email: '',
    displayName: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  AuthBloc buildAuthBloc({bool multiDeviceLoginEnabled = false}) {
    return AuthBloc(
      mockSignInWithGoogleUseCase,
      mockSignInWithEmailUseCase,
      mockRegisterWithEmailUseCase,
      mockSignOut,
      mockDeleteAccount,
      mockGetCurrentUserUseCase,
      mockSyncDeviceTokenUseCase,
      mockGetCurrentLanguageUseCase,
      mockSyncUserLanguagePreference,
      accountDeletionFlowTracker,
      signInSessionTracker,
      mockAwaitAuthRestoration,
      mockGetPersistedUser,
      multiDeviceLoginEnabled: () => multiDeviceLoginEnabled,
    );
  }

  setUp(() {
    revokePrefs = MapBackedSharedPreferencesAsync();
    PendingSessionRevokeStore.setPrefsFactoryForTesting(
      () => revokePrefs.prefs,
    );
    mockSignInWithGoogleUseCase = MockSignInWithGoogleUseCase();
    mockSignInWithEmailUseCase = MockSignInWithEmailUseCase();
    mockRegisterWithEmailUseCase = MockRegisterWithEmailUseCase();
    mockSignOut = MockSignOut();
    mockDeleteAccount = MockDeleteAccount();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockSyncDeviceTokenUseCase = MockSyncDeviceTokenUseCase();
    mockGetCurrentLanguageUseCase = MockGetCurrentLanguageUseCase();
    mockSyncUserLanguagePreference = MockSyncUserLanguagePreferenceUseCase();
    accountDeletionFlowTracker = AccountDeletionFlowTracker();
    signInSessionTracker = GoogleSignInSessionTracker();
    signInSessionTracker.markFinished();
    mockAwaitAuthRestoration = MockAwaitAuthRestorationUseCase();
    mockGetPersistedUser = MockGetPersistedAuthenticatedUserUseCase();
    when(mockGetPersistedUser()).thenAnswer((_) async => null);
    when(
      mockAwaitAuthRestoration(sessionUser: anyNamed('sessionUser')),
    ).thenAnswer((_) async => AuthRestorationOutcome.unauthenticated);
    when(
      mockGetCurrentLanguageUseCase(),
    ).thenAnswer((_) async => const Right(LanguageConfig.defaultLanguageCode));
    when(mockSyncUserLanguagePreference(any)).thenAnswer((_) async {});
    when(
      mockSyncDeviceTokenUseCase(any),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockSyncDeviceTokenUseCase.registerExplicitSignIn(any),
    ).thenAnswer((_) async => const Right(null));

    authBloc = buildAuthBloc();
  });

  tearDown(() {
    PendingSessionRevokeStore.setPrefsFactoryForTesting(null);
    signInSessionTracker.markFinished();
    authBloc.close();
  });

  group('AuthBloc offline resilience', () {
    group('airplane mode / dead network on cold start', () {
      blocTest<AuthBloc, AuthState>(
        'authenticates from the persisted hint when Firebase restoration '
        'never surfaces a user (no network to refresh tokens)',
        build: () {
          when(mockGetPersistedUser()).thenAnswer((_) async => tPersistedHint);
          when(mockGetCurrentUserUseCase()).thenReturn(null);
          when(
            mockAwaitAuthRestoration(sessionUser: anyNamed('sessionUser')),
          ).thenAnswer((_) async => AuthRestorationOutcome.pendingUnresolved);
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        wait: const Duration(milliseconds: 10),
        expect: () => [AuthState.authenticated(user: tPersistedHint)],
        verify: (_) {
          verifyNever(
            mockSignOut(skipServerTokenClear: anyNamed('skipServerTokenClear')),
          );
        },
      );

      blocTest<AuthBloc, AuthState>(
        'keeps the disk-restored Firebase session when device sync fails '
        'with a network error',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(mockSyncDeviceTokenUseCase(tUser.id)).thenAnswer(
            (_) async => Left(Failure.networkError('unreachable')),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        wait: const Duration(milliseconds: 10),
        expect: () => [AuthState.authenticated(user: tUser)],
        verify: (_) {
          verifyNever(
            mockSignOut(skipServerTokenClear: anyNamed('skipServerTokenClear')),
          );
        },
      );

      blocTest<AuthBloc, AuthState>(
        'stays authenticated when device sync throws instead of returning '
        'a failure (SDK-level exception on a broken connection)',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(
            mockSyncDeviceTokenUseCase(tUser.id),
          ).thenAnswer((_) async => throw Exception('socket closed'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        wait: const Duration(milliseconds: 10),
        expect: () => [AuthState.authenticated(user: tUser)],
        verify: (_) {
          verifyNever(
            mockSignOut(skipServerTokenClear: anyNamed('skipServerTokenClear')),
          );
        },
      );

      blocTest<AuthBloc, AuthState>(
        'fresh install with no session resolves to [unauthenticated] '
        'without ever touching the network',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        expect: () => [const AuthState.unauthenticated()],
        verify: (_) {
          verifyNever(mockSyncDeviceTokenUseCase(any));
        },
      );
    });

    group('captive / hung network (exhausted data plan)', () {
      blocTest<AuthBloc, AuthState>(
        'emits [authenticated] immediately while device sync hangs forever',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(mockSyncDeviceTokenUseCase(tUser.id)).thenAnswer(
            (_) => Completer<Either<Failure, void>>().future,
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        expect: () => [AuthState.authenticated(user: tUser)],
        verify: (_) {
          verifyNever(
            mockSignOut(skipServerTokenClear: anyNamed('skipServerTokenClear')),
          );
        },
      );

      test(
        'a slow sync that eventually succeeds causes no extra state changes',
        () async {
          final syncCompleter = Completer<Either<Failure, void>>();
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(
            mockSyncDeviceTokenUseCase(tUser.id),
          ).thenAnswer((_) => syncCompleter.future);

          final List<AuthState> states = <AuthState>[];
          final subscription = authBloc.stream.listen(states.add);

          authBloc.add(const CheckAuthStatusEvent());
          await Future<void>.delayed(Duration.zero);
          expect(authBloc.state, AuthState.authenticated(user: tUser));

          syncCompleter.complete(const Right(null));
          await Future<void>.delayed(const Duration(milliseconds: 10));

          expect(states, [AuthState.authenticated(user: tUser)]);
          await subscription.cancel();
        },
      );

      blocTest<AuthBloc, AuthState>(
        'language preference failure never affects the session',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(mockGetCurrentLanguageUseCase()).thenAnswer(
            (_) async => Left(Failure.networkError('unreachable')),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        wait: const Duration(milliseconds: 10),
        expect: () => [AuthState.authenticated(user: tUser)],
      );
    });

    group('local storage failures must never strand or log out', () {
      blocTest<AuthBloc, AuthState>(
        'falls back to the live Firebase user when reading the persisted '
        'hint throws',
        build: () {
          when(mockGetPersistedUser()).thenThrow(Exception('prefs corrupt'));
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        wait: const Duration(milliseconds: 10),
        expect: () => [AuthState.authenticated(user: tUser)],
      );

      blocTest<AuthBloc, AuthState>(
        'still authenticates when awaiting restoration throws',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(
            mockAwaitAuthRestoration(sessionUser: anyNamed('sessionUser')),
          ).thenThrow(StateError('stream disposed'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        wait: const Duration(milliseconds: 10),
        expect: () => [AuthState.authenticated(user: tUser)],
      );
    });

    group('late server verdicts against a changed session', () {
      test(
        'a stale verdict arriving after an interactive re-sign-in must not '
        'sign out the new session',
        () async {
          final staleCompleter = Completer<Either<Failure, void>>();
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(
            mockSyncDeviceTokenUseCase(tUser.id),
          ).thenAnswer((_) => staleCompleter.future);
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) async => AuthResult.success(user: tOtherUser));

          authBloc.add(const CheckAuthStatusEvent());
          await Future<void>.delayed(Duration.zero);
          expect(authBloc.state, AuthState.authenticated(user: tUser));

          authBloc.add(const SignInWithGoogleEvent());
          await Future<void>.delayed(Duration.zero);
          expect(authBloc.state, AuthState.authenticated(user: tOtherUser));

          staleCompleter.complete(
            const Left(PermissionFailure(AuthErrorKey.staleDeviceRejected)),
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));

          expect(authBloc.state, AuthState.authenticated(user: tOtherUser));
          verifyNever(
            mockSignOut(skipServerTokenClear: anyNamed('skipServerTokenClear')),
          );
        },
      );

      test(
        'a stale verdict arriving after a manual sign-out is ignored',
        () async {
          final staleCompleter = Completer<Either<Failure, void>>();
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(
            mockSyncDeviceTokenUseCase(tUser.id),
          ).thenAnswer((_) => staleCompleter.future);
          when(mockSignOut()).thenAnswer((_) async => const Right(null));

          authBloc.add(const CheckAuthStatusEvent());
          await Future<void>.delayed(Duration.zero);
          expect(authBloc.state, AuthState.authenticated(user: tUser));

          authBloc.add(const SignOutEvent());
          await Future<void>.delayed(Duration.zero);
          expect(authBloc.state, const AuthState.unauthenticated());

          staleCompleter.complete(
            const Left(PermissionFailure(AuthErrorKey.staleDeviceRejected)),
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));

          expect(authBloc.state, const AuthState.unauthenticated());
          verifyNever(mockSignOut(skipServerTokenClear: true));
        },
      );
    });
  });
}
