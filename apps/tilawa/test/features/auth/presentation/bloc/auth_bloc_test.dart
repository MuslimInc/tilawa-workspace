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
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/delete_account.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
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

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import 'auth_bloc_test.mocks.dart';

@GenerateMocks([
  SignInWithGoogleUseCase,
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
  late MockSignOut mockSignOut;
  late MockDeleteAccount mockDeleteAccount;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
  late MockGetCurrentLanguageUseCase mockGetCurrentLanguageUseCase;
  late MockSyncUserLanguagePreferenceUseCase mockSyncUserLanguagePreference;
  late AccountDeletionFlowTracker accountDeletionFlowTracker;
  late GoogleSignInSessionTracker signInSessionTracker;
  late MapBackedSharedPreferencesAsync defaultRevokePrefs;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<Either<Failure, String>>(
      Right(LanguageConfig.defaultLanguageCode),
    );
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
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
          ).thenAnswer((_) async {});
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
          await Future<void>.delayed(Duration.zero);
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
          await Future<void>.delayed(Duration.zero);
          verify(
            mockSyncDeviceTokenUseCase.registerExplicitSignIn(tUser.id),
          ).called(1);
          verify(mockGetCurrentLanguageUseCase()).called(1);
          verify(
            mockSyncUserLanguagePreference(LanguageConfig.defaultLanguageCode),
          ).called(1);
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
          const AuthState.error(message: 'Authentication failed'),
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
    });

    group('SignOutEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [unauthenticated] when sign out works',
        build: () {
          when(mockSignOut()).thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignOutEvent()),
        expect: () => [const AuthState.unauthenticated()],
        verify: (_) {
          verify(mockSignOut()).called(1);
        },
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
        'emits [loading, unauthenticated] when delete succeeds',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(
            mockDeleteAccount(),
          ).thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'returns to authenticated when delete is cancelled',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(mockDeleteAccount()).thenAnswer(
            (_) async => const Left(UserCancelledFailure()),
          );
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: tUser),
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => [
          const AuthState.loading(),
          AuthState.authenticated(user: tUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [unauthenticated] when delete is cancelled but no user '
        'was signed in',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(null);
          when(mockDeleteAccount()).thenAnswer(
            (_) async => const Left(UserCancelledFailure()),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error, authenticated] when delete fails and the '
        'user is still signed in',
        build: () {
          when(mockGetCurrentUserUseCase()).thenReturn(tUser);
          when(mockDeleteAccount()).thenAnswer(
            (_) async => const Left(UnexpectedFailure('boom')),
          );
          return authBloc;
        },
        seed: () => AuthState.authenticated(user: tUser),
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error(message: 'boom'),
          AuthState.authenticated(user: tUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error, unauthenticated] when delete fails and the '
        'session is gone',
        build: () {
          int calls = 0;
          when(mockGetCurrentUserUseCase()).thenAnswer((_) {
            // Signed in before the delete, gone afterwards.
            return calls++ == 0 ? tUser : null;
          });
          when(mockDeleteAccount()).thenAnswer(
            (_) async => const Left(UnexpectedFailure(null)),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const DeleteAccountEvent()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error(message: 'Unable to delete account'),
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

    group('hydration', () {
      test('toJson / fromJson work correctly for authenticated state', () {
        final state = AuthState.authenticated(user: tUser);
        final Map<String, dynamic>? json = authBloc.toJson(state);
        expect(json, isNotNull);
        final Map<String, dynamic> jsonData = json!;
        expect(jsonData['state'], 'authenticated');
        final userMap = jsonData['user'] as Map<String, dynamic>;
        expect(userMap['id'], tUser.id);

        final AuthState? restoredState = authBloc.fromJson(json);
        expect(restoredState, state);
      });

      test('toJson returns null for unauthenticated state', () {
        const state = AuthState.unauthenticated();
        final Map<String, dynamic>? json = authBloc.toJson(state);
        expect(json, isNull);
      });

      test('fromJson returns initial for empty/invalid json', () {
        expect(authBloc.fromJson({}), const AuthState.initial());
        expect(
          authBloc.fromJson({'state': 'invalid'}),
          const AuthState.initial(),
        );
      });

      test('fromJson returns initial on exception', () {
        final json = {'state': 'authenticated', 'user': 'invalid'};
        final AuthState? restoredState = authBloc.fromJson(json);
        expect(restoredState, const AuthState.initial());
      });
    });
  });
}
