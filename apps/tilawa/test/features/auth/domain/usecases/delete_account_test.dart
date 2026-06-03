import 'package:dartz_plus/dartz_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('deletes auth account then app data when signed in', () async {
    final Either<Failure, void> result = await useCase();

    expect(result.isRight, isTrue);
    verifyInOrder([
      mockAuthRepository.deleteAccount(),
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser('user-1'),
      mockUserRepository.deleteUserData('user-1'),
      mockPremiumRepository.clearPremiumStatus(),
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
}
