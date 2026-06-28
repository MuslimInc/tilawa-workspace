import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';

import '../../../premium/domain/usecases/check_feature_access_use_case_test.mocks.dart';
import '../../helpers/auth_mock_helper.mocks.dart';

void main() {
  late SignOut useCase;
  late MockAuthRepository mockAuthRepository;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
  late MockPremiumRepository mockPremiumRepository;

  final tUser = UserEntity(
    id: 'user_123',
    email: 'user@example.com',
    displayName: 'User',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockSyncDeviceTokenUseCase = MockSyncDeviceTokenUseCase();
    mockPremiumRepository = MockPremiumRepository();
    useCase = SignOut(
      mockAuthRepository,
      mockSyncDeviceTokenUseCase,
      mockPremiumRepository,
    );
  });

  test(
    'remote revoke skips server token clear so new device token is preserved',
    () async {
      when(mockAuthRepository.currentUser).thenReturn(tUser);
      when(mockPremiumRepository.clearPremiumStatus()).thenAnswer((_) async {});
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});

      await useCase(skipServerTokenClear: true);

      verifyNever(mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any));
      verifyInOrder([
        mockPremiumRepository.clearPremiumStatus(),
        mockAuthRepository.signOut(),
      ]);
    },
  );

  test('should revoke token, clear premium cache, and sign out', () async {
    when(mockAuthRepository.currentUser).thenReturn(tUser);
    when(
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(tUser.id),
    ).thenAnswer((_) async {});
    when(mockPremiumRepository.clearPremiumStatus()).thenAnswer((_) async {});
    when(mockAuthRepository.signOut()).thenAnswer((_) async {});

    await useCase();

    verifyInOrder([
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(tUser.id),
      mockPremiumRepository.clearPremiumStatus(),
      mockAuthRepository.signOut(),
    ]);
  });

  test(
    'should still clear premium cache and sign out without a current user',
    () async {
      when(mockAuthRepository.currentUser).thenReturn(null);
      when(mockPremiumRepository.clearPremiumStatus()).thenAnswer((_) async {});
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});

      await useCase();

      verifyNever(mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any));
      verify(mockPremiumRepository.clearPremiumStatus()).called(1);
      verify(mockAuthRepository.signOut()).called(1);
    },
  );

  test(
    'should still sign out when device token removal throws',
    () async {
      when(mockAuthRepository.currentUser).thenReturn(tUser);
      when(
        mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(tUser.id),
      ).thenThrow(Exception('apns-token-not-set'));
      when(mockPremiumRepository.clearPremiumStatus()).thenAnswer((_) async {});
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});

      await useCase();

      verify(mockPremiumRepository.clearPremiumStatus()).called(1);
      verify(mockAuthRepository.signOut()).called(1);
    },
  );
}
