import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';

import '../../helpers/auth_mock_helper.mocks.dart';

void main() {
  late SyncDeviceTokenUseCase useCase;
  late MockUserRepository mockUserRepository;
  late MockDeviceTokenService mockDeviceTokenService;

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockDeviceTokenService = MockDeviceTokenService();
    useCase = SyncDeviceTokenUseCase(
      mockUserRepository,
      mockDeviceTokenService,
    );
  });

  const tUserId = 'user_123';
  const tToken = 'fcm_token_abc';

  test(
    'should get token from service and save it to repository if it exists',
    () async {
      // Arrange
      when(mockDeviceTokenService.getToken()).thenAnswer((_) async => tToken);
      when(
        mockUserRepository.saveDeviceToken(any, any),
      ).thenAnswer((_) async => Future.value());

      // Act
      await useCase(tUserId);

      // Assert
      verify(mockDeviceTokenService.getToken()).called(1);
      verify(mockUserRepository.saveDeviceToken(tUserId, tToken)).called(1);
    },
  );

  test('should not call repository if token is null', () async {
    // Arrange
    when(mockDeviceTokenService.getToken()).thenAnswer((_) async => null);

    // Act
    await useCase(tUserId);

    // Assert
    verify(mockDeviceTokenService.getToken()).called(1);
    verifyNever(mockUserRepository.saveDeviceToken(any, any));
  });

  test('should fail silently if getting token throws exception', () async {
    // Arrange
    when(mockDeviceTokenService.getToken()).thenThrow(Exception('Failed'));

    // Act
    await useCase(tUserId);

    // Assert
    verify(mockDeviceTokenService.getToken()).called(1);
    verifyNever(mockUserRepository.saveDeviceToken(any, any));
  });
}
