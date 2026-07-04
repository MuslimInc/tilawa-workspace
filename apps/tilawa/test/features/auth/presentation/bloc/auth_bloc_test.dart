import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/application/account_deletion_flow_tracker.dart';
import 'package:tilawa/features/auth/data/services/google_sign_in_session_tracker.dart';
import 'package:tilawa/features/auth/domain/entities/auth_error_key.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/email_auth_failure_key.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_draft.dart';
import 'package:tilawa/features/auth/domain/entities/register_with_email_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/delete_account.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/register_with_email_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_user_language_preference_use_case.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/localization/domain/usecases/get_current_language_use_case.dart';
import 'package:tilawa_core/config/language_config.dart';

import 'package:tilawa_core/errors/failures.dart';

import '../../../../support/map_backed_shared_preferences_async.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([
  SignInWithGoogleUseCase,
  SignInWithEmailUseCase,
  RegisterWithEmailUseCase,
  SignOut,
  DeleteAccount,
  GetCurrentUserUseCase,
  SyncDeviceTokenUseCase,
  GetCurrentLanguageUseCase,
  SyncUserLanguagePreferenceUseCase,
])
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
  late MapBackedSharedPreferencesAsync defaultRevokePrefs;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<Either<Failure, String>>(
      Right(LanguageConfig.defaultLanguageCode),
    );
  });

  final tUser = UserEntity(
    id: '1',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime.utc(2023),
  );

  setUp(() {
    defaultRevokePrefs = MapBackedSharedPreferencesAsync();
    PendingSessionRevokeStore.setPrefsFactoryForTesting(
      () => defaultRevokePrefs.prefs,
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

    when(
      mockGetCurrentLanguageUseCase(),
    ).thenAnswer((_) async => Right(LanguageConfig.defaultLanguageCode));
    when(
      mockSyncUserLanguagePreference(any),
    ).thenAnswer((_) async {});
    when(mockSyncDeviceTokenUseCase(any)).thenAnswer(
      (_) async => const Right(null),
    );
    when(mockSyncDeviceTokenUseCase.registerExplicitSignIn(any)).thenAnswer(
      (_) async => const Right(null),
    );

    authBloc = AuthBloc(
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
    );
  });

  tearDown(() {
    PendingSessionRevokeStore.setPrefsFactoryForTesting(null);
    signInSessionTracker.markFinished();
    authBloc.close();
    reset(mockSignInWithGoogleUseCase);
    reset(mockSignOut);
    reset(mockDeleteAccount);
    reset(mockGetCurrentUserUseCase);
    reset(mockSyncDeviceTokenUseCase);
    reset(mockGetCurrentLanguageUseCase);
    reset(mockSyncUserLanguagePreference);
  });

  group('AuthBloc', () {
    test('initial state is AuthState.initial', () {
      expect(authBloc.state, const AuthState.initial());
    });

    group('CheckAuthStatusEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [unauthenticated] when passive sync confirms stale device',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(mockSyncDeviceTokenUseCase(tUser.id)).thenAnswer(
            (_) async => const Left(
              PermissionFailure(AuthErrorKey.staleDeviceRejected),
            ),
          );
          when(
            mockSignOut(skipServerTokenClear: true),
          ).thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        expect: () => [const AuthState.unauthenticated()],
        verify: (_) {
          verify(mockSignOut(skipServerTokenClear: true)).called(1);
          verifyNever(mockGetCurrentLanguageUseCase());
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [authenticated] when user is logged in',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        expect: () => [AuthState.authenticated(user: tUser)],
        verify: (_) {
          verify(mockGetCurrentUserUseCase()).called(1);
          verify(mockSyncDeviceTokenUseCase(tUser.id)).called(1);
          verify(mockGetCurrentLanguageUseCase()).called(1);
          verify(
            mockSyncUserLanguagePreference(LanguageConfig.defaultLanguageCode),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'keeps user authenticated when passive sync fails without stale proof',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(mockSyncDeviceTokenUseCase(tUser.id)).thenAnswer(
            (_) async => Left(Failure.networkError('offline')),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        expect: () => [AuthState.authenticated(user: tUser)],
        verify: (_) {
          verifyNever(
            mockSignOut(
              skipServerTokenClear: anyNamed('skipServerTokenClear'),
            ),
          );
        },
      );

      blocTest<AuthBloc, AuthState>(
        'ignores CheckAuthStatus while interactive sign-in is loading',
        build: () {
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) => Completer<AuthResult>().future);
          return authBloc;
        },
        act: (bloc) async {
          bloc.add(const SignInWithGoogleEvent());
          await Future<void>.delayed(Duration.zero);
          bloc.add(const CheckAuthStatusEvent());
        },
        expect: () => [const AuthState.loading()],
        verify: (_) {
          verifyNever(mockGetCurrentUserUseCase());
        },
      );

      blocTest<AuthBloc, AuthState>(
        'keeps in-memory authenticated user when live Firebase user is missing',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(null);
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: tUser),
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        expect: () => <AuthState>[],
        verify: (bloc) {
          expect(bloc.state, AuthState.authenticated(user: tUser));
          verify(mockSyncDeviceTokenUseCase(tUser.id)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [unauthenticated] when user is NOT logged in',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
        expect: () => [const AuthState.unauthenticated()],
        verify: (_) {
          verify(mockGetCurrentUserUseCase()).called(1);
          verifyNever(mockSyncDeviceTokenUseCase(any));
        },
      );
    });

    group('SignInWithGoogleEvent', () {
      late MapBackedSharedPreferencesAsync revokePrefs;

      blocTest<AuthBloc, AuthState>(
        'clears stale pending session revoke flag at sign-in start',
        build: () {
          revokePrefs = MapBackedSharedPreferencesAsync({
            PendingSessionRevokeStore.key: true,
          });
          PendingSessionRevokeStore.setPrefsFactoryForTesting(
            () => revokePrefs.prefs,
          );
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) async => const AuthResult.cancelled());
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithGoogleEvent()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          expect(
            revokePrefs.store.containsKey(PendingSessionRevokeStore.key),
            isFalse,
          );
          expect(signInSessionTracker.inFlight, isFalse);
        },
        tearDown: () {
          PendingSessionRevokeStore.setPrefsFactoryForTesting(null);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when device registration fails after Google success',
        build: () {
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) async => AuthResult.success(user: tUser));
          when(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(tUser.id),
          ).thenAnswer(
            (_) async => Left(
              Failure.serverError(AuthErrorKey.deviceRegistrationFailed),
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithGoogleEvent()),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(user: tUser),
        ],
        verify: (_) async {
          verify(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(tUser.id),
          ).called(1);
          verifyNever(
            mockSignOut(
              skipServerTokenClear: anyNamed('skipServerTokenClear'),
            ),
          );
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when sign in is successful and syncs token',
        build: () {
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) async => AuthResult.success(user: tUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithGoogleEvent()),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(user: tUser),
        ],
        verify: (_) async {
          verify(mockSignInWithGoogleUseCase()).called(1);
          verify(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(tUser.id),
          ).called(1);
          verify(mockGetCurrentLanguageUseCase()).called(1);
          verify(
            mockSyncUserLanguagePreference(LanguageConfig.defaultLanguageCode),
          ).called(1);
        },
      );

      test(
        'keeps session inFlight until explicit device registration completes',
        () async {
          final registrationCompleter = Completer<Either<Failure, void>>();
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) async => AuthResult.success(user: tUser));
          when(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(tUser.id),
          ).thenAnswer((_) => registrationCompleter.future);

          authBloc.add(const SignInWithGoogleEvent());
          await Future<void>.delayed(Duration.zero);

          expect(authBloc.state, AuthState.authenticated(user: tUser));
          expect(signInSessionTracker.inFlight, isTrue);

          registrationCompleter.complete(const Right(null));
          await Future<void>.delayed(Duration.zero);

          expect(signInSessionTracker.inFlight, isFalse);
        },
      );

      test(
        'stays authenticated when explicit registration returns stale',
        () async {
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) async => AuthResult.success(user: tUser));
          when(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(tUser.id),
          ).thenAnswer(
            (_) async => const Left(
              PermissionFailure(AuthErrorKey.staleDeviceRejected),
            ),
          );

          authBloc.add(const SignInWithGoogleEvent());
          await Future<void>.delayed(Duration.zero);

          expect(authBloc.state, AuthState.authenticated(user: tUser));
          verify(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(tUser.id),
          ).called(1);
          verifyNever(
            mockSignOut(
              skipServerTokenClear: anyNamed('skipServerTokenClear'),
            ),
          );
        },
      );

      late Completer<Either<Failure, void>> registrationCompleter;

      blocTest<AuthBloc, AuthState>(
        'ignores stale background registration after sign-out',
        build: () {
          registrationCompleter = Completer<Either<Failure, void>>();
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) async => AuthResult.success(user: tUser));
          when(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(tUser.id),
          ).thenAnswer((_) => registrationCompleter.future);
          when(mockSignOut()).thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        act: (bloc) async {
          bloc.add(const SignInWithGoogleEvent());
          await Future<void>.delayed(Duration.zero);
          bloc.add(const SignOutEvent());
          registrationCompleter.complete(
            const Left(
              PermissionFailure(AuthErrorKey.staleDeviceRejected),
            ),
          );
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(user: tUser),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(mockSignOut()).called(1);
          verifyNever(mockSignOut(skipServerTokenClear: true));
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when sign in fails',
        build: () {
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) async => const AuthResult.failure(message: 'Error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithGoogleEvent()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error(message: 'Error'),
        ],
        verify: (_) {
          verify(mockSignInWithGoogleUseCase()).called(1);
          verifyNever(mockSyncDeviceTokenUseCase(any));
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when sign in fails with code and details',
        build: () {
          when(mockSignInWithGoogleUseCase()).thenAnswer(
            (_) async => const AuthResult.failure(
              message: 'Login failed',
              code: '204',
              details: 'GetCredentialProviderConfigurationException: …',
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithGoogleEvent()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error(message: 'Login failed'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when sign in throws',
        build: () {
          when(
            mockSignInWithGoogleUseCase(),
          ).thenThrow(Exception('network'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithGoogleEvent()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error(message: EmailAuthFailureKey.generic),
        ],
        verify: (_) {
          expect(signInSessionTracker.inFlight, isFalse);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] when sign in is cancelled',
        build: () {
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) async => const AuthResult.cancelled());
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithGoogleEvent()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(mockSignInWithGoogleUseCase()).called(1);
          verifyNever(mockSyncDeviceTokenUseCase(any));
        },
      );

      blocTest<AuthBloc, AuthState>(
        'returns to authenticated when sign in is cancelled mid-session',
        seed: () => AuthState.authenticated(user: tUser),
        build: () {
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) async => const AuthResult.cancelled());
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInWithGoogleEvent()),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(user: tUser),
        ],
        verify: (_) {
          verify(mockSignInWithGoogleUseCase()).called(1);
          verifyNever(mockSyncDeviceTokenUseCase(any));
        },
      );
    });

    group('SessionInvalidatedEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [unauthenticated] after remote session revocation',
        seed: () => AuthState.authenticated(user: tUser),
        build: () => authBloc,
        act: (bloc) => bloc.add(const SessionInvalidatedEvent()),
        expect: () => [const AuthState.unauthenticated()],
      );
    });

    group('SignOutEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [unauthenticated] when sign out works',
        build: () {
          when(mockSignOut()).thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignOutEvent()),
        expect: () => [const AuthState.unauthenticated()],
        verify: (_) {
          verify(mockSignOut()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [error] when sign out is blocked by server action guard',
        build: () {
          when(mockSignOut()).thenAnswer(
            (_) async => const Left(
              ServerActionFailure.offline(),
            ),
          );
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: tUser),
        act: (bloc) => bloc.add(const SignOutEvent()),
        expect: () => const [
          AuthState.error(message: ServerActionFailureKey.offline),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'still emits [unauthenticated] when sign out throws',
        build: () {
          when(mockSignOut()).thenThrow(Exception('network'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignOutEvent()),
        expect: () => [const AuthState.unauthenticated()],
      );
    });

    group('DeleteAccountEvent', () {
      blocTest<AuthBloc, AuthState>(
        'passes cached session user to delete use case',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(null);
          when(
            mockDeleteAccount(sessionUser: tUser),
          ).thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: tUser),
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => [const AuthState.unauthenticated()],
        verify: (_) {
          verify(mockDeleteAccount(sessionUser: tUser)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [unauthenticated] when delete succeeds',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(
            mockDeleteAccount(sessionUser: anyNamed('sessionUser')),
          ).thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: tUser),
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => [const AuthState.unauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'returns to authenticated when delete is cancelled',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(
            mockDeleteAccount(sessionUser: anyNamed('sessionUser')),
          ).thenAnswer(
            (_) async => const Left(UserCancelledFailure()),
          );
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: tUser),
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => <AuthState>[],
        verify: (_) {
          expect(authBloc.state, AuthState.authenticated(user: tUser));
          expect(accountDeletionFlowTracker.deletionInProgress, isFalse);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [unauthenticated] when delete is cancelled but no user '
        'was signed in',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(null);
          when(
            mockDeleteAccount(sessionUser: anyNamed('sessionUser')),
          ).thenAnswer(
            (_) async => const Left(UserCancelledFailure()),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => [const AuthState.unauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [error, authenticated] when delete fails and the '
        'user is still signed in',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(
            mockDeleteAccount(sessionUser: anyNamed('sessionUser')),
          ).thenAnswer(
            (_) async => const Left(UnexpectedFailure('boom')),
          );
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: tUser),
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => [
          const AuthState.error(message: 'boom'),
          AuthState.authenticated(user: tUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [error, authenticated] when delete fails but Firebase '
        'session is still available via cached user',
        build: () {
          int calls = 0;
          when(mockGetCurrentUserUseCase()).thenAnswer((_) {
            return calls++ == 0 ? tUser : null;
          });
          when(
            mockDeleteAccount(sessionUser: anyNamed('sessionUser')),
          ).thenAnswer(
            (_) async => const Left(UnexpectedFailure(null)),
          );
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: tUser),
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => [
          const AuthState.error(message: DeleteAccountErrorKey.failed),
          AuthState.authenticated(user: tUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [error, authenticated] when delete fails with not signed in '
        'but in-memory auth state still has a user',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(null);
          when(
            mockDeleteAccount(sessionUser: anyNamed('sessionUser')),
          ).thenAnswer(
            (_) async => const Left(
              ValidationFailure(DeleteAccountErrorKey.notSignedIn),
            ),
          );
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: tUser),
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => [
          const AuthState.error(message: DeleteAccountErrorKey.notSignedIn),
          AuthState.authenticated(user: tUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [error, unauthenticated] when delete fails and the '
        'session is gone',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(null);
          when(
            mockDeleteAccount(sessionUser: anyNamed('sessionUser')),
          ).thenAnswer(
            (_) async => const Left(UnexpectedFailure(null)),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => [
          const AuthState.error(message: DeleteAccountErrorKey.failed),
          const AuthState.unauthenticated(),
        ],
      );
    });

    group('AbortInteractiveSignInEvent', () {
      late Completer<AuthResult> signInCompleter;

      blocTest<AuthBloc, AuthState>(
        'emits [unauthenticated] when aborting an in-flight sign-in',
        build: () => authBloc,
        seed: () => const AuthState.loading(),
        act: (bloc) => bloc.add(const AbortInteractiveSignInEvent()),
        expect: () => [const AuthState.unauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'ignores a late sign-in result after abort',
        build: () {
          signInCompleter = Completer<AuthResult>();
          when(
            mockSignInWithGoogleUseCase(),
          ).thenAnswer((_) => signInCompleter.future);
          return authBloc;
        },
        act: (bloc) async {
          bloc.add(const SignInWithGoogleEvent());
          await Future<void>.delayed(Duration.zero);
          bloc.add(const AbortInteractiveSignInEvent());
          signInCompleter.complete(AuthResult.success(user: tUser));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(mockSignInWithGoogleUseCase()).called(1);
          verifyNever(mockSyncDeviceTokenUseCase(any));
        },
      );
    });

    group('SignInWithEmailEvent', () {
      test(
        'keeps CheckAuthStatus deferred until email device registration finishes',
        () async {
          final registrationCompleter = Completer<Either<Failure, void>>();
          when(
            mockSignInWithEmailUseCase(
              email: anyNamed('email'),
              password: anyNamed('password'),
            ),
          ).thenAnswer((_) async => AuthResult.success(user: tUser));
          when(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(tUser.id),
          ).thenAnswer((_) => registrationCompleter.future);

          authBloc.add(
            const SignInWithEmailEvent(
              email: 'test@example.com',
              password: 'Password1!',
            ),
          );
          await Future<void>.delayed(Duration.zero);

          expect(authBloc.state, AuthState.authenticated(user: tUser));
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

    group('RegisterWithEmailEvent', () {
      const EmailRegistrationDraft draft = EmailRegistrationDraft(
        email: 'mm@gmail.com',
        password: 'Password1!',
        confirmPassword: 'Password1!',
      );

      blocTest<AuthBloc, AuthState>(
        'emits loading then error without authenticated on duplicate email',
        build: () {
          when(
            mockRegisterWithEmailUseCase(draft: draft),
          ).thenAnswer(
            (_) async => const RegisterWithEmailResult.authFailed(
              message: EmailAuthFailureKey.emailAlreadyInUse,
              code: 'email-already-in-use',
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const RegisterWithEmailEvent(draft: draft)),
        expect: () => <AuthState>[
          const AuthState.loading(),
          const AuthState.error(
            message: EmailAuthFailureKey.emailAlreadyInUse,
          ),
        ],
        verify: (_) {
          verify(mockRegisterWithEmailUseCase(draft: draft)).called(1);
          verifyNever(mockSyncDeviceTokenUseCase.registerExplicitSignIn(any));
        },
      );
    });
  });
}
