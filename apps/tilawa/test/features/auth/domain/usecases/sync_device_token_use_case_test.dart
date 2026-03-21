import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';

import '../../helpers/auth_mock_helper.mocks.dart';

void main() {
  late SyncDeviceTokenUseCase useCase;
  late MockUserRepository mockUserRepository;
  late MockDeviceTokenService mockDeviceTokenService;
  late MockSharedPreferencesAsync mockPrefs;

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockDeviceTokenService = MockDeviceTokenService();
    mockPrefs = MockSharedPreferencesAsync();
    useCase = SyncDeviceTokenUseCase(
      mockUserRepository,
      mockDeviceTokenService,
      mockPrefs,
    );
  });

  const tUserId = 'user_123';
  const tToken = 'fcm_token_abc';

  test(
    'should get token from service and save it to repository if it exists',
    () async {
      // Arrange
      when(mockDeviceTokenService.getToken()).thenAnswer((_) async => tToken);
      when(mockPrefs.getString(any)).thenAnswer((_) async => null);
      when(
        mockUserRepository.saveDeviceToken(any, any),
      ).thenAnswer((_) async => Future.value());
      when(mockPrefs.setString(any, any)).thenAnswer((_) async {});

      // Act
      await useCase(tUserId);

      // Assert
      verify(mockDeviceTokenService.getToken()).called(1);
      verify(mockUserRepository.saveDeviceToken(tUserId, tToken)).called(1);
      verify(mockPrefs.setString(any, any)).called(2);
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

  test(
    'should remove previous synced token when token ownership changes',
    () async {
      when(mockDeviceTokenService.getToken()).thenAnswer((_) async => tToken);
      when(mockPrefs.getString(any)).thenAnswer((invocation) async {
        final String key = invocation.positionalArguments.first as String;
        if (key.contains('fcm_token')) {
          return 'old_token';
        }
        if (key.contains('fcm_user_id')) {
          return 'old_user';
        }
        return null;
      });
      when(
        mockUserRepository.deleteDeviceToken(any, any),
      ).thenAnswer((_) async {});
      when(
        mockUserRepository.saveDeviceToken(any, any),
      ).thenAnswer((_) async {});
      when(mockPrefs.setString(any, any)).thenAnswer((_) async {});

      await useCase(tUserId);

      verify(
        mockUserRepository.deleteDeviceToken('old_user', 'old_token'),
      ).called(1);
      verify(mockUserRepository.saveDeviceToken(tUserId, tToken)).called(1);
    },
  );

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
