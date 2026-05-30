import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/delete_account.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:tilawa_core/errors/failures.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import 'auth_bloc_test.mocks.dart';

@GenerateMocks([
  SignInWithGoogleUseCase,
  SignOut,
  DeleteAccount,
  GetCurrentUserUseCase,
  SyncDeviceTokenUseCase,
])
void main() {
  late AuthBloc authBloc;
  late MockSignInWithGoogleUseCase mockSignInWithGoogleUseCase;
  late MockSignOut mockSignOut;
  late MockDeleteAccount mockDeleteAccount;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    provideDummy<Either<Failure, void>>(const Right(null));
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
    mockSignInWithGoogleUseCase = MockSignInWithGoogleUseCase();
    mockSignOut = MockSignOut();
    mockDeleteAccount = MockDeleteAccount();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockSyncDeviceTokenUseCase = MockSyncDeviceTokenUseCase();

    authBloc = AuthBloc(
      mockSignInWithGoogleUseCase,
      mockSignOut,
      mockDeleteAccount,
      mockGetCurrentUserUseCase,
      mockSyncDeviceTokenUseCase,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthState.initial', () {
      expect(authBloc.state, const AuthState.initial());
    });

    group('CheckAuthStatusEvent', () {
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
        verify: (_) {
          verify(mockSignInWithGoogleUseCase()).called(1);
          verify(mockSyncDeviceTokenUseCase(tUser.id)).called(1);
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
