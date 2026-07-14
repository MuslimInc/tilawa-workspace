import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/data/datasources/account_deletion_remote_data_source.dart';
import 'package:tilawa/features/auth/data/repositories/account_deletion_repository_impl.dart';
import 'package:tilawa/features/auth/domain/entities/auth_error_key.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockAccountDeletionRemoteDataSource extends Mock
    implements AccountDeletionRemoteDataSource {}

void main() {
  late AccountDeletionRepositoryImpl repository;
  late MockAccountDeletionRemoteDataSource mockRemote;

  const tResult = AccountDeletionRequestResult(
    status: 'pending_deletion',
    purgeAfter: '2026-02-01T00:00:00.000Z',
  );

  setUp(() {
    mockRemote = MockAccountDeletionRemoteDataSource();
    repository = AccountDeletionRepositoryImpl(mockRemote);
  });

  test('returns Right on successful soft-delete request', () async {
    when(
      () => mockRemote.requestSelfAccountDeletion(
        reason: any(named: 'reason'),
        confirmEmail: any(named: 'confirmEmail'),
      ),
    ).thenAnswer((_) async => tResult);

    final result = await repository.requestSelfAccountDeletion(
      reason: 'reason',
      confirmEmail: 'a@b.com',
    );

    expect(result.isRight(), isTrue);
  });

  test(
    'maps permission-denied callable errors to PermissionFailure',
    () async {
      when(
        () => mockRemote.requestSelfAccountDeletion(
          reason: any(named: 'reason'),
          confirmEmail: any(named: 'confirmEmail'),
        ),
      ).thenThrow(
        FirebaseFunctionsException(
          code: 'permission-denied',
          message: 'Admin accounts must be deleted from the admin panel.',
        ),
      );

      final result = await repository.requestSelfAccountDeletion(
        reason: 'reason',
        confirmEmail: 'a@b.com',
      );

      result.fold((failure) {
        expect(failure, isA<PermissionFailure>());
        expect(
          failure.message,
          DeleteAccountErrorKey.adminMustUseAdminPanel,
        );
      }, (_) => fail('expected left'));
    },
  );

  test(
    'maps failed-precondition callable errors to ValidationFailure',
    () async {
      when(
        () => mockRemote.requestSelfAccountDeletion(
          reason: any(named: 'reason'),
          confirmEmail: any(named: 'confirmEmail'),
        ),
      ).thenThrow(
        FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'Wallet balance is not zero',
        ),
      );

      final result = await repository.requestSelfAccountDeletion(
        reason: 'reason',
        confirmEmail: 'a@b.com',
      );

      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, DeleteAccountErrorKey.walletNotEmpty);
      }, (_) => fail('expected left'));
    },
  );

  test('maps undeployed callable not-found to ServerFailure', () async {
    when(
      () => mockRemote.requestSelfAccountDeletion(
        reason: any(named: 'reason'),
        confirmEmail: any(named: 'confirmEmail'),
      ),
    ).thenThrow(
      FirebaseFunctionsException(
        code: 'not-found',
        message: 'NOT_FOUND',
      ),
    );

    final result = await repository.requestSelfAccountDeletion(
      reason: 'reason',
      confirmEmail: 'a@b.com',
    );

    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        DeleteAccountErrorKey.serviceUnavailable,
      );
    }, (_) => fail('expected left'));
  });

  test('maps backend target-not-found to ValidationFailure', () async {
    when(
      () => mockRemote.requestSelfAccountDeletion(
        reason: any(named: 'reason'),
        confirmEmail: any(named: 'confirmEmail'),
      ),
    ).thenThrow(
      FirebaseFunctionsException(
        code: 'not-found',
        message: 'Target user not found.',
      ),
    );

    final result = await repository.requestSelfAccountDeletion(
      reason: 'reason',
      confirmEmail: 'a@b.com',
    );

    result.fold((failure) {
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Target user not found.');
    }, (_) => fail('expected left'));
  });

  test('maps internal callable errors to ServerFailure', () async {
    when(
      () => mockRemote.requestSelfAccountDeletion(
        reason: any(named: 'reason'),
        confirmEmail: any(named: 'confirmEmail'),
      ),
    ).thenThrow(
      FirebaseFunctionsException(
        code: 'internal',
        message: 'boom',
      ),
    );

    final result = await repository.requestSelfAccountDeletion(
      reason: 'reason',
      confirmEmail: 'a@b.com',
    );

    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(failure.message, DeleteAccountErrorKey.failed);
    }, (_) => fail('expected left'));
  });

  test('returns UnexpectedFailure for unrecognised errors', () async {
    when(
      () => mockRemote.requestSelfAccountDeletion(
        reason: any(named: 'reason'),
        confirmEmail: any(named: 'confirmEmail'),
      ),
    ).thenThrow(StateError('boom'));

    final result = await repository.requestSelfAccountDeletion(
      reason: 'reason',
      confirmEmail: 'a@b.com',
    );

    result.fold((failure) {
      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, contains('boom'));
    }, (_) => fail('expected left'));
  });

  test('maps unavailable callable errors to offline failure', () async {
    when(
      () => mockRemote.requestSelfAccountDeletion(
        reason: any(named: 'reason'),
        confirmEmail: any(named: 'confirmEmail'),
      ),
    ).thenThrow(
      FirebaseFunctionsException(
        code: 'unavailable',
        message: 'Service unavailable',
      ),
    );

    final result = await repository.requestSelfAccountDeletion(
      reason: 'reason',
      confirmEmail: 'a@b.com',
    );

    result.fold((failure) {
      expect(failure, isA<ServerActionFailure>());
      expect(failure.message, ServerActionFailureKey.offline);
    }, (_) => fail('expected left'));
  });

  test('maps unexpected network exceptions to offline failure', () async {
    when(
      () => mockRemote.requestSelfAccountDeletion(
        reason: any(named: 'reason'),
        confirmEmail: any(named: 'confirmEmail'),
      ),
    ).thenThrow(
      Exception(
        'A network error (such as timeout, interrupted connection or '
        'unreachable host) has occurred.',
      ),
    );

    final result = await repository.requestSelfAccountDeletion(
      reason: 'reason',
      confirmEmail: 'a@b.com',
    );

    result.fold((failure) {
      expect(failure, isA<ServerActionFailure>());
      expect(failure.message, ServerActionFailureKey.offline);
    }, (_) => fail('expected left'));
  });
}
