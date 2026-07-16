import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../premium/domain/usecases/check_feature_access_use_case_test.mocks.dart';
import '../../helpers/auth_mock_helper.mocks.dart';
import '../../../../support/fake_network_info.dart';

void main() {
  late SignOut useCase;
  late MockAuthRepository mockAuthRepository;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
  late MockPremiumRepository mockPremiumRepository;
  late MockTokenSyncCache mockTokenSyncCache;
  late FakeNetworkInfo networkInfo;

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
    mockTokenSyncCache = MockTokenSyncCache();
    networkInfo = FakeNetworkInfo();
    useCase = SignOut(
      mockAuthRepository,
      mockSyncDeviceTokenUseCase,
      mockPremiumRepository,
      mockTokenSyncCache,
      ServerActionGuard(networkInfo),
    );
    when(mockTokenSyncCache.clearSession()).thenAnswer((_) async {
      return;
    });
  });

  tearDown(() async {
    await networkInfo.dispose();
  });

  test(
    'remote revoke skips server token clear so new device token is preserved',
    () async {
      when(mockAuthRepository.currentUser).thenReturn(tUser);
      when(mockPremiumRepository.clearPremiumStatus()).thenAnswer((_) async {
        return;
      });
      when(mockAuthRepository.signOut()).thenAnswer((_) async {
        return;
      });

      final Either<Failure, void> result = await useCase(
        skipServerTokenClear: true,
      );

      expect(result.isRight(), isTrue);
      verifyNever(mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any));
      verifyInOrder([
        mockTokenSyncCache.clearSession(),
        mockPremiumRepository.clearPremiumStatus(),
        mockAuthRepository.signOut(),
      ]);
    },
  );

  test('should revoke token, clear premium cache, and sign out', () async {
    when(mockAuthRepository.currentUser).thenReturn(tUser);
    when(
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(tUser.id),
    ).thenAnswer((_) async {
      return;
    });
    when(mockPremiumRepository.clearPremiumStatus()).thenAnswer((_) async {
      return;
    });
    when(mockAuthRepository.signOut()).thenAnswer((_) async {
      return;
    });

    final Either<Failure, void> result = await useCase();

    expect(result.isRight(), isTrue);
    verifyInOrder([
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(tUser.id),
      mockTokenSyncCache.clearSession(),
      mockPremiumRepository.clearPremiumStatus(),
      mockAuthRepository.signOut(),
    ]);
  });

  test(
    'should still clear premium cache and sign out without a current user',
    () async {
      when(mockAuthRepository.currentUser).thenReturn(null);
      when(mockPremiumRepository.clearPremiumStatus()).thenAnswer((_) async {
        return;
      });
      when(mockAuthRepository.signOut()).thenAnswer((_) async {
        return;
      });

      final Either<Failure, void> result = await useCase();

      expect(result.isRight(), isTrue);
      verifyNever(mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any));
      verify(mockTokenSyncCache.clearSession()).called(1);
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
      when(mockPremiumRepository.clearPremiumStatus()).thenAnswer((_) async {
        return;
      });
      when(mockAuthRepository.signOut()).thenAnswer((_) async {
        return;
      });

      final Either<Failure, void> result = await useCase();

      expect(result.isRight(), isTrue);
      verify(mockTokenSyncCache.clearSession()).called(1);
      verify(mockPremiumRepository.clearPremiumStatus()).called(1);
      verify(mockAuthRepository.signOut()).called(1);
    },
  );

  test('blocks logout without calling repositories when offline', () async {
    networkInfo.connected = false;
    when(mockAuthRepository.currentUser).thenReturn(tUser);

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ServerActionFailure>());
      expect(failure.message, ServerActionFailureKey.offline);
    }, (_) => fail('expected left'));
    verifyNever(mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any));
    verifyNever(mockTokenSyncCache.clearSession());
    verifyNever(mockPremiumRepository.clearPremiumStatus());
    verifyNever(mockAuthRepository.signOut());
  });
}
