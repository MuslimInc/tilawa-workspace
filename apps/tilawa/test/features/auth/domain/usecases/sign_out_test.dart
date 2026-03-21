import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';

import '../../helpers/auth_mock_helper.mocks.dart';

void main() {
  late SignOut useCase;
  late MockAuthRepository mockAuthRepository;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
  late MockPremiumLocalDataSource mockPremiumLocalDataSource;

  final tUser = UserEntity(
    id: 'user_123',
    email: 'user@example.com',
    displayName: 'User',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockSyncDeviceTokenUseCase = MockSyncDeviceTokenUseCase();
    mockPremiumLocalDataSource = MockPremiumLocalDataSource();
    useCase = SignOut(
      mockAuthRepository,
      mockSyncDeviceTokenUseCase,
      mockPremiumLocalDataSource,
    );
  });

  test('should revoke token, clear premium cache, and sign out', () async {
    when(mockAuthRepository.currentUser).thenReturn(tUser);
    when(
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(tUser.id),
    ).thenAnswer((_) async {});
    when(
      mockPremiumLocalDataSource.clearPremiumStatus(),
    ).thenAnswer((_) async {});
    when(mockAuthRepository.signOut()).thenAnswer((_) async {});

    await useCase();

    verifyInOrder([
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(tUser.id),
      mockPremiumLocalDataSource.clearPremiumStatus(),
      mockAuthRepository.signOut(),
    ]);
  });

  test(
    'should still clear premium cache and sign out without a current user',
    () async {
      when(mockAuthRepository.currentUser).thenReturn(null);
      when(
        mockPremiumLocalDataSource.clearPremiumStatus(),
      ).thenAnswer((_) async {});
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});

      await useCase();

      verifyNever(mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any));
      verify(mockPremiumLocalDataSource.clearPremiumStatus()).called(1);
      verify(mockAuthRepository.signOut()).called(1);
    },
  );
}
