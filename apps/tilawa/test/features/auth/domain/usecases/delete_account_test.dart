import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/data/datasources/account_deletion_remote_data_source.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/entities/auth_error_key.dart';
import 'package:tilawa/features/auth/domain/usecases/delete_account.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa/features/premium/domain/repositories/premium_repository.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'delete_account_test.mocks.dart';

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

    useCase = DeleteAccount(
      mockAuthRepository,
      mockAccountDeletionRemoteDataSource,
      mockSyncDeviceTokenUseCase,
      mockPremiumRepository,
    );

    when(mockAuthRepository.currentUser).thenReturn(tUser);
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

  test('returns ValidationFailure when no user is signed in', () async {
    when(mockAuthRepository.currentUser).thenReturn(null);

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

  test('uses uid confirmation when email is missing', () async {
    when(mockAuthRepository.currentUser).thenReturn(
      UserEntity(
        id: 'user-1',
        email: '',
        displayName: 'Test User',
        createdAt: DateTime.utc(2024),
      ),
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
}
