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
import 'package:tilawa/features/auth/domain/entities/email_auth_failure_key.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_draft.dart';
import 'package:tilawa/features/auth/domain/entities/register_with_email_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/await_auth_restoration_use_case.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../support/map_backed_shared_preferences_async.dart';
import 'auth_bloc_test.mocks.dart';

/// Worst-case auth scenarios: races, stale cache, partial success, account swap.
void main() {
  late AuthBloc authBloc;
  late MockSignInWithGoogleUseCase mockSignInWithGoogleUseCase;
  late MockSignInWithAppleUseCase mockSignInWithAppleUseCase;
  late MockSignInWithEmailUseCase mockSignInWithEmailUseCase;
  late MockRegisterWithEmailUseCase mockRegisterWithEmailUseCase;
  late MockSignOut mockSignOut;
  late MockDeleteAccount mockDeleteAccount;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
  late MockGetCurrentLanguageUseCase mockGetCurrentLanguageUseCase;
  late MockSyncUserLanguagePreferenceUseCase mockSyncUserLanguagePreference;
  late MockAwaitAuthRestorationUseCase mockAwaitAuthRestoration;
  late MockGetPersistedAuthenticatedUserUseCase mockGetPersistedUser;
  late AccountDeletionFlowTracker accountDeletionFlowTracker;
  late GoogleSignInSessionTracker signInSessionTracker;

  final UserEntity userA = UserEntity(
    id: 'user-a',
    email: 'a@example.com',
    displayName: 'User A',
    createdAt: DateTime.utc(2024),
  );

  final UserEntity userB = UserEntity(
    id: 'user-b',
    email: 'b@example.com',
    displayName: 'User B',
    createdAt: DateTime.utc(2024, 2),
  );

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<Either<Failure, String>>(
      const Right(LanguageConfig.defaultLanguageCode),
    );
  });

  setUp(() {
    PendingSessionRevokeStore.setPrefsFactoryForTesting(
      () => MapBackedSharedPreferencesAsync().prefs,
    );
    mockSignInWithGoogleUseCase = MockSignInWithGoogleUseCase();
    mockSignInWithAppleUseCase = MockSignInWithAppleUseCase();
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
    when(mockSyncDeviceTokenUseCase(any)).thenAnswer(
      (_) async => const Right(null),
    );
    when(mockSyncDeviceTokenUseCase.registerExplicitSignIn(any)).thenAnswer(
      (_) async => const Right(null),
    );

    authBloc = AuthBloc(
      mockSignInWithGoogleUseCase,
      mockSignInWithAppleUseCase,
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
      multiDeviceLoginEnabled: () => false,
    );
  });

  tearDown(() {
    PendingSessionRevokeStore.setPrefsFactoryForTesting(null);
    signInSessionTracker.markFinished();
    authBloc.close();
  });

  group('AuthBloc worst-case scenarios', () {
    group('partial registration', () {
      const EmailRegistrationDraft draft = EmailRegistrationDraft(
        email: 'new@example.com',
        password: 'Password1!',
        confirmPassword: 'Password1!',
      );

      blocTest<AuthBloc, AuthState>(
        'authenticates when Firebase succeeds but profile persistence fails',
        build: () {
          when(mockRegisterWithEmailUseCase(draft: draft)).thenAnswer(
            (_) async => RegisterWithEmailResult.profilePersistenceFailed(
              user: userA,
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const RegisterWithEmailEvent(draft: draft)),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(user: userA),
        ],
        verify: (_) {
          verify(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(userA.id),
          ).called(1);
        },
      );
    });

    group('quick account swap', () {
      blocTest<AuthBloc, AuthState>(
        'replaces session when sign-out is followed immediately by new sign-in',
        build: () {
          when(mockSignOut()).thenAnswer((_) async => const Right(null));
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) async => AuthResult.success(user: userB));
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: userA),
        act: (bloc) async {
          bloc.add(const SignOutEvent());
          await Future<void>.delayed(Duration.zero);
          bloc.add(const SignInWithGoogleEvent());
        },
        expect: () => [
          const AuthState.unauthenticated(),
          const AuthState.loading(),
          AuthState.authenticated(user: userB),
        ],
        verify: (_) {
          verify(mockSignOut()).called(1);
          verify(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(userB.id),
          ).called(1);
          verifyNever(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(userA.id),
          );
        },
      );
    });

    group('email sign-in edge cases', () {
      blocTest<AuthBloc, AuthState>(
        'surfaces network failure without leaving user authenticated',
        build: () {
          when(
            mockSignInWithEmailUseCase(
              email: anyNamed('email'),
              password: anyNamed('password'),
            ),
          ).thenAnswer(
            (_) async => const AuthResult.failure(
              message: EmailAuthFailureKey.networkError,
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const SignInWithEmailEvent(
            email: 'a@example.com',
            password: 'Password1!',
          ),
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error(message: EmailAuthFailureKey.networkError),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'returns to unauthenticated when email sign-in is cancelled',
        build: () {
          when(
            mockSignInWithEmailUseCase(
              email: anyNamed('email'),
              password: anyNamed('password'),
            ),
          ).thenAnswer((_) async => const AuthResult.cancelled());
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const SignInWithEmailEvent(
            email: 'a@example.com',
            password: 'Password1!',
          ),
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
      );
    });

    group('app restart / cold restoration', () {
      blocTest<AuthBloc, AuthState>(
        'restores authenticated session from Firebase on CheckAuthStatus',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(userA);
          return authBloc;
        },
        seed: () => const AuthState.initial(),
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        expect: () => [AuthState.authenticated(user: userA)],
      );

      blocTest<AuthBloc, AuthState>(
        'offline startup keeps Firebase session when passive sync fails',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(userA);
          when(mockSyncDeviceTokenUseCase(userA.id)).thenAnswer(
            (_) async => Left(Failure.networkError('offline')),
          );
          return authBloc;
        },
        seed: () => const AuthState.initial(),
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        wait: const Duration(milliseconds: 10),
        expect: () => [AuthState.authenticated(user: userA)],
        verify: (_) {
          verifyNever(
            mockSignOut(skipServerTokenClear: anyNamed('skipServerTokenClear')),
          );
        },
      );

      blocTest<AuthBloc, AuthState>(
        'signs out when server rejects stale device on cold start',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(userA);
          when(mockSyncDeviceTokenUseCase(userA.id)).thenAnswer(
            (_) async => const Left(
              PermissionFailure(AuthErrorKey.staleDeviceRejected),
            ),
          );
          when(
            mockSignOut(skipServerTokenClear: true),
          ).thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: userA),
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        wait: const Duration(milliseconds: 10),
        expect: () => [const AuthState.unauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'multi-device cold start keeps user authenticated on stale passive sync',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(userA);
          when(mockSyncDeviceTokenUseCase(userA.id)).thenAnswer(
            (_) async => const Left(
              PermissionFailure(AuthErrorKey.staleDeviceRejected),
            ),
          );
          return AuthBloc(
            mockSignInWithGoogleUseCase,
            mockSignInWithAppleUseCase,
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
            multiDeviceLoginEnabled: () => true,
          );
        },
        seed: () => const AuthState.initial(),
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        wait: const Duration(milliseconds: 10),
        expect: () => [AuthState.authenticated(user: userA)],
        verify: (_) {
          verifyNever(
            mockSignOut(skipServerTokenClear: anyNamed('skipServerTokenClear')),
          );
        },
      );
    });

    group('auth state flicker', () {
      blocTest<AuthBloc, AuthState>(
        'CheckAuthStatus from initial does not emit unauthenticated first',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(userA);
          return authBloc;
        },
        seed: () => const AuthState.initial(),
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        expect: () => [AuthState.authenticated(user: userA)],
      );

      test(
        'SessionInvalidated during in-flight sign-in aborts late success',
        () async {
          final Completer<AuthResult> signInCompleter = Completer<AuthResult>();
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) => signInCompleter.future);

          authBloc.add(const SignInWithGoogleEvent());
          await Future<void>.delayed(Duration.zero);
          expect(authBloc.state, const AuthState.loading());

          authBloc.add(const SessionInvalidatedEvent());
          await Future<void>.delayed(Duration.zero);
          expect(authBloc.state, const AuthState.unauthenticated());

          signInCompleter.complete(AuthResult.success(user: userA));
          await Future<void>.delayed(Duration.zero);
          expect(authBloc.state, const AuthState.unauthenticated());
        },
      );
    });

    group('stale in-memory user', () {
      blocTest<AuthBloc, AuthState>(
        'uses in-memory user when Firebase currentUser is temporarily null',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(null);
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: userA),
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        wait: const Duration(milliseconds: 10),
        expect: () => <AuthState>[],
        verify: (bloc) {
          expect(bloc.state, AuthState.authenticated(user: userA));
          verify(mockSyncDeviceTokenUseCase(userA.id)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'drops to unauthenticated when session is invalidated remotely',
        build: () => authBloc,
        seed: () => AuthState.authenticated(user: userA),
        act: (bloc) => bloc.add(const SessionInvalidatedEvent()),
        expect: () => [const AuthState.unauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'stays unauthenticated when CheckAuthStatus finds no user after invalidation',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(null);
          return authBloc;
        },
        seed: () => const AuthState.unauthenticated(),
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        expect: () => <AuthState>[],
      );
    });

    group('slow sign-in race', () {
      test(
        'ignores CheckAuthStatus while device registration still in flight',
        () async {
          final registrationCompleter = Completer<Either<Failure, void>>();
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) async => AuthResult.success(user: userA));
          when(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(userA.id),
          ).thenAnswer((_) => registrationCompleter.future);

          authBloc.add(const SignInWithGoogleEvent());
          await Future<void>.delayed(Duration.zero);
          expect(authBloc.state, AuthState.authenticated(user: userA));
          expect(signInSessionTracker.inFlight, isTrue);

          authBloc.add(const CheckAuthStatusEvent());
          await Future<void>.delayed(Duration.zero);
          verifyNever(mockGetCurrentUserUseCase());

          registrationCompleter.complete(const Right(null));
          await Future<void>.delayed(Duration.zero);
          expect(signInSessionTracker.inFlight, isFalse);
        },
      );
    });
  });
}
