import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/features/auth/data/datasources/account_deletion_remote_data_source.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/entities/auth_error_key.dart';
import 'package:tilawa/features/auth/domain/usecases/await_auth_restoration_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/delete_account.dart';
import 'package:tilawa/features/auth/domain/usecases/resolve_authenticated_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa/features/premium/domain/repositories/premium_repository.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'delete_account_test.mocks.dart';
import '../../../../support/fake_network_info.dart';

class _FakeResolveAuthenticatedUser extends ResolveAuthenticatedUserUseCase {
  _FakeResolveAuthenticatedUser(
    MockAuthRepository repository,
    this._resolvedUser,
  ) : super(repository, AwaitAuthRestorationUseCase(repository));

  final UserEntity? _resolvedUser;

  @override
  Future<UserEntity?> call({UserEntity? sessionUser}) async => _resolvedUser;
}

@GenerateMocks([
  AuthRepository,
  AccountDeletionRemoteDataSource,
  SyncDeviceTokenUseCase,
  PremiumRepository,
])
void main() {
  late DeleteAccount useCase;
  late MockAuthRepository mockAuthRepository;
  late MockAccountDeletionRemoteDataSource mockAccountDeletionRemoteDataSource;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
  late MockPremiumRepository mockPremiumRepository;
  late FakeNetworkInfo networkInfo;
  late _FakeResolveAuthenticatedUser resolveAuthenticatedUser;

  const tResult = AccountDeletionRequestResult(
    status: 'pending_deletion',
    purgeAfter: '2026-02-01T00:00:00.000Z',
  );

  final tUser = UserEntity(
    id: 'user-1',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime.utc(2024),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockAccountDeletionRemoteDataSource = MockAccountDeletionRemoteDataSource();
    mockSyncDeviceTokenUseCase = MockSyncDeviceTokenUseCase();
    mockPremiumRepository = MockPremiumRepository();
    networkInfo = FakeNetworkInfo();
    resolveAuthenticatedUser = _FakeResolveAuthenticatedUser(
      mockAuthRepository,
      tUser,
    );

    useCase = DeleteAccount(
      mockAuthRepository,
      mockAccountDeletionRemoteDataSource,
      mockSyncDeviceTokenUseCase,
      mockPremiumRepository,
      ServerActionGuard(networkInfo),
      resolveAuthenticatedUser,
    );

    when(
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any),
    ).thenAnswer((_) async {});
    when(mockPremiumRepository.clearPremiumStatus()).thenAnswer((_) async {});
    when(
      mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
        reason: anyNamed('reason'),
        confirmEmail: anyNamed('confirmEmail'),
      ),
    ).thenAnswer((_) async => tResult);
    when(mockAuthRepository.signOut()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await networkInfo.dispose();
  });

  test('returns ValidationFailure when no user is signed in', () async {
    resolveAuthenticatedUser = _FakeResolveAuthenticatedUser(
      mockAuthRepository,
      null,
    );
    useCase = DeleteAccount(
      mockAuthRepository,
      mockAccountDeletionRemoteDataSource,
      mockSyncDeviceTokenUseCase,
      mockPremiumRepository,
      ServerActionGuard(networkInfo),
      resolveAuthenticatedUser,
    );

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('expected left'),
    );
    verifyNever(
      mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
        reason: anyNamed('reason'),
        confirmEmail: anyNamed('confirmEmail'),
      ),
    );
  });

  test('requests soft-delete then signs out', () async {
    final Either<Failure, void> result = await useCase();

    expect(result.isRight(), isTrue);
    verifyInOrder([
      mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
        reason: 'Self-service account deletion from mobile app',
        confirmEmail: 'test@example.com',
      ),
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser('user-1'),
      mockPremiumRepository.clearPremiumStatus(),
      mockAuthRepository.signOut(),
    ]);
  });

  test('returns offline failure without calling remote dependencies', () async {
    networkInfo.connected = false;

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ServerActionFailure>());
      expect(failure.message, ServerActionFailureKey.offline);
    }, (_) => fail('expected left'));
    verifyNever(
      mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
        reason: anyNamed('reason'),
        confirmEmail: anyNamed('confirmEmail'),
      ),
    );
    verifyNever(mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any));
    verifyNever(mockPremiumRepository.clearPremiumStatus());
    verifyNever(mockAuthRepository.signOut());
  });

  test('uses uid confirmation when email is missing', () async {
    resolveAuthenticatedUser = _FakeResolveAuthenticatedUser(
      mockAuthRepository,
      UserEntity(
        id: 'user-1',
        email: '',
        displayName: 'Test User',
        createdAt: DateTime.utc(2024),
      ),
    );
    useCase = DeleteAccount(
      mockAuthRepository,
      mockAccountDeletionRemoteDataSource,
      mockSyncDeviceTokenUseCase,
      mockPremiumRepository,
      ServerActionGuard(networkInfo),
      resolveAuthenticatedUser,
    );

    final Either<Failure, void> result = await useCase();

    expect(result.isRight(), isTrue);
    verify(
      mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
        reason: 'Self-service account deletion from mobile app',
        confirmEmail: 'user-1',
      ),
    ).called(1);
  });

  test(
    'maps permission-denied callable errors without clearing session side effects',
    () async {
      when(
        mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
          reason: anyNamed('reason'),
          confirmEmail: anyNamed('confirmEmail'),
        ),
      ).thenThrow(
        FirebaseFunctionsException(
          code: 'permission-denied',
          message: 'Admin accounts must be deleted from the admin panel.',
        ),
      );

      final Either<Failure, void> result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<PermissionFailure>());
        expect(
          failure.message,
          DeleteAccountErrorKey.adminMustUseAdminPanel,
        );
      }, (_) => fail('expected left'));
      verifyNever(mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any));
      verifyNever(mockPremiumRepository.clearPremiumStatus());
      verifyNever(mockAuthRepository.signOut());
    },
  );

  test(
    'maps failed-precondition callable errors to ValidationFailure',
    () async {
      when(
        mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
          reason: anyNamed('reason'),
          confirmEmail: anyNamed('confirmEmail'),
        ),
      ).thenThrow(
        FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'Wallet balance is not zero',
        ),
      );

      final Either<Failure, void> result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, DeleteAccountErrorKey.walletNotEmpty);
      }, (_) => fail('expected left'));
      verifyNever(mockAuthRepository.signOut());
      verifyNever(mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any));
      verifyNever(mockPremiumRepository.clearPremiumStatus());
    },
  );

  test('maps undeployed callable not-found to ServerFailure', () async {
    when(
      mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
        reason: anyNamed('reason'),
        confirmEmail: anyNamed('confirmEmail'),
      ),
    ).thenThrow(
      FirebaseFunctionsException(
        code: 'not-found',
        message: 'NOT_FOUND',
      ),
    );

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        DeleteAccountErrorKey.serviceUnavailable,
      );
    }, (_) => fail('expected left'));
    verifyNever(mockAuthRepository.signOut());
  });

  test('maps backend target-not-found to ValidationFailure', () async {
    when(
      mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
        reason: anyNamed('reason'),
        confirmEmail: anyNamed('confirmEmail'),
      ),
    ).thenThrow(
      FirebaseFunctionsException(
        code: 'not-found',
        message: 'Target user not found.',
      ),
    );

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Target user not found.');
    }, (_) => fail('expected left'));
  });

  test('maps internal callable errors to ServerFailure', () async {
    when(
      mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
        reason: anyNamed('reason'),
        confirmEmail: anyNamed('confirmEmail'),
      ),
    ).thenThrow(
      FirebaseFunctionsException(
        code: 'internal',
        message: 'boom',
      ),
    );

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(failure.message, DeleteAccountErrorKey.failed);
    }, (_) => fail('expected left'));
  });

  test('returns UnexpectedFailure for unrecognised errors', () async {
    when(
      mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
        reason: anyNamed('reason'),
        confirmEmail: anyNamed('confirmEmail'),
      ),
    ).thenThrow(StateError('boom'));

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, contains('boom'));
    }, (_) => fail('expected left'));
  });

  test('maps unavailable callable errors to offline failure', () async {
    when(
      mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
        reason: anyNamed('reason'),
        confirmEmail: anyNamed('confirmEmail'),
      ),
    ).thenThrow(
      FirebaseFunctionsException(
        code: 'unavailable',
        message: 'Service unavailable',
      ),
    );

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ServerActionFailure>());
      expect(failure.message, ServerActionFailureKey.offline);
    }, (_) => fail('expected left'));
    verifyNever(mockAuthRepository.signOut());
  });

  test('maps unexpected network exceptions to offline failure', () async {
    when(
      mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
        reason: anyNamed('reason'),
        confirmEmail: anyNamed('confirmEmail'),
      ),
    ).thenThrow(
      Exception(
        'A network error (such as timeout, interrupted connection or '
        'unreachable host) has occurred.',
      ),
    );

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ServerActionFailure>());
      expect(failure.message, ServerActionFailureKey.offline);
    }, (_) => fail('expected left'));
    verifyNever(mockAuthRepository.signOut());
  });

  group('first-login session sync', () {
    late ResolveAuthenticatedUserUseCase resolveAuthenticatedUserUseCase;

    setUp(() {
      resolveAuthenticatedUserUseCase = ResolveAuthenticatedUserUseCase(
        mockAuthRepository,
        AwaitAuthRestorationUseCase(mockAuthRepository),
      );
      useCase = DeleteAccount(
        mockAuthRepository,
        mockAccountDeletionRemoteDataSource,
        mockSyncDeviceTokenUseCase,
        mockPremiumRepository,
        ServerActionGuard(networkInfo),
        resolveAuthenticatedUserUseCase,
      );
    });

    test(
      'does not return notSignedIn when session hint syncs after delayed null',
      () async {
        final controller = StreamController<UserEntity?>.broadcast();
        when(mockAuthRepository.currentUser).thenReturn(null);
        when(mockAuthRepository.authStateChanges).thenAnswer(
          (_) => controller.stream,
        );

        final Future<Either<Failure, void>> pending = useCase(
          sessionUser: tUser,
        );
        await Future<void>.delayed(Duration.zero);
        controller.add(null);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.add(tUser);
        await controller.close();

        final Either<Failure, void> result = await pending;

        expect(result.isRight(), isTrue);
        verify(
          mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
            reason: 'Self-service account deletion from mobile app',
            confirmEmail: 'test@example.com',
          ),
        ).called(1);
      },
    );

    test(
      'does not return notSignedIn when session hint syncs on auth stream',
      () async {
        when(mockAuthRepository.currentUser).thenReturn(null);
        when(mockAuthRepository.authStateChanges).thenAnswer(
          (_) => Stream<UserEntity?>.value(tUser),
        );

        final Either<Failure, void> result = await useCase(
          sessionUser: tUser,
        );

        expect(result.isRight(), isTrue);
        verify(
          mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
            reason: 'Self-service account deletion from mobile app',
            confirmEmail: 'test@example.com',
          ),
        ).called(1);
      },
    );

    test(
      'returns notSignedIn when session hint never syncs to Firebase',
      () async {
        when(mockAuthRepository.currentUser).thenReturn(null);
        when(mockAuthRepository.authStateChanges).thenAnswer(
          (_) => const Stream<UserEntity?>.empty(),
        );

        final Either<Failure, void> result = await useCase(sessionUser: tUser);

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, DeleteAccountErrorKey.notSignedIn);
        }, (_) => fail('expected left'));
        verifyNever(
          mockAccountDeletionRemoteDataSource.requestSelfAccountDeletion(
            reason: anyNamed('reason'),
            confirmEmail: anyNamed('confirmEmail'),
          ),
        );
      },
      timeout: Timeout(
        ResolveAuthenticatedUserUseCase.postSignInSyncTimeout +
            const Duration(seconds: 2),
      ),
    );
  });
}
