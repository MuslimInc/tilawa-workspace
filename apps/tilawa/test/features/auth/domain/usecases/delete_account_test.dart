import 'package:dartz_plus/dartz_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/delete_account.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa/features/premium/domain/repositories/premium_repository.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'delete_account_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  UserRepository,
  SyncDeviceTokenUseCase,
  PremiumRepository,
])
void main() {
  late DeleteAccount useCase;
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
  late MockPremiumRepository mockPremiumRepository;

  final tUser = UserEntity(
    id: 'user-1',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime.utc(2024),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();
    mockSyncDeviceTokenUseCase = MockSyncDeviceTokenUseCase();
    mockPremiumRepository = MockPremiumRepository();

    useCase = DeleteAccount(
      mockAuthRepository,
      mockUserRepository,
      mockSyncDeviceTokenUseCase,
      mockPremiumRepository,
    );

    when(mockAuthRepository.currentUser).thenReturn(tUser);
    when(
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any),
    ).thenAnswer((_) async {});
    when(mockUserRepository.deleteUserData(any)).thenAnswer((_) async {});
    when(mockPremiumRepository.clearPremiumStatus()).thenAnswer((_) async {});
    when(mockAuthRepository.deleteAccount()).thenAnswer((_) async {});
  });

  test('returns ValidationFailure when no user is signed in', () async {
    when(mockAuthRepository.currentUser).thenReturn(null);

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft, isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('expected left'),
    );
    verifyNever(mockUserRepository.deleteUserData(any));
  });

  test('deletes app data before auth account', () async {
    final Either<Failure, void> result = await useCase();

    expect(result.isRight, isTrue);
    verifyInOrder([
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser('user-1'),
      mockUserRepository.deleteUserData('user-1'),
      mockPremiumRepository.clearPremiumStatus(),
      mockAuthRepository.deleteAccount(),
    ]);
  });

  test('returns UserCancelledFailure when re-auth is cancelled', () async {
    when(mockAuthRepository.deleteAccount()).thenThrow(
      FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Google re-authentication was cancelled',
      ),
    );

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft, isTrue);
    result.fold(
      (failure) => expect(failure, isA<UserCancelledFailure>()),
      (_) => fail('expected left'),
    );
  });

  Future<Failure> failureFor(Object error) async {
    when(mockAuthRepository.deleteAccount()).thenThrow(error);
    final Either<Failure, void> result = await useCase();
    expect(result.isLeft, isTrue);
    late final Failure captured;
    result.fold((failure) => captured = failure, (_) => fail('expected left'));
    return captured;
  }

  group('FirebaseAuthException mapping', () {
    test('returns UnexpectedFailure for non-cancellation auth errors',
        () async {
      final Failure failure = await failureFor(
        FirebaseAuthException(
          code: 'network-request-failed',
          message: 'A network error occurred',
        ),
      );

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, 'A network error occurred');
    });

    test(
        'returns UnexpectedFailure when requires-recent-login is not '
        'a cancellation', () async {
      final Failure failure = await failureFor(
        FirebaseAuthException(code: 'requires-recent-login'),
      );

      expect(failure, isA<UnexpectedFailure>());
    });
  });

  group('GoogleSignInException mapping', () {
    for (final code in [
      GoogleSignInExceptionCode.canceled,
      GoogleSignInExceptionCode.interrupted,
      GoogleSignInExceptionCode.uiUnavailable,
    ]) {
      test('returns UserCancelledFailure for ${code.name}', () async {
        final Failure failure = await failureFor(
          GoogleSignInException(code: code),
        );

        expect(failure, isA<UserCancelledFailure>());
      });
    }

    test('returns UnexpectedFailure for genuine sign-in errors', () async {
      final Failure failure = await failureFor(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.providerConfigurationError,
          description: 'Missing SHA-1 fingerprint',
        ),
      );

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, 'Missing SHA-1 fingerprint');
    });

    test('falls back to the code name when description is missing', () async {
      final Failure failure = await failureFor(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
        ),
      );

      expect(failure.message, 'unknownError');
    });
  });

  group('PlatformException mapping', () {
    test('returns UserCancelledFailure for code 204', () async {
      final Failure failure = await failureFor(
        PlatformException(code: '204', message: 'Login failed'),
      );

      expect(failure, isA<UserCancelledFailure>());
    });

    test('returns UserCancelledFailure for "No credentials available"',
        () async {
      final Failure failure = await failureFor(
        PlatformException(
          code: '16',
          message: 'No credentials available on this device',
        ),
      );

      expect(failure, isA<UserCancelledFailure>());
    });

    test('returns UserCancelledFailure for "Login failed" messages',
        () async {
      final Failure failure = await failureFor(
        PlatformException(
          code: '500',
          message: 'Login failed User cancelled the selector',
        ),
      );

      expect(failure, isA<UserCancelledFailure>());
    });

    test('returns UnexpectedFailure for genuine platform errors', () async {
      final Failure failure = await failureFor(
        PlatformException(code: '500', message: 'Service unavailable'),
      );

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, 'Service unavailable');
    });
  });

  test('returns UnexpectedFailure for unrecognised errors', () async {
    final Failure failure = await failureFor(StateError('boom'));

    expect(failure, isA<UnexpectedFailure>());
    expect(failure.message, contains('boom'));
  });
}
