import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/services/device_token_service.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa/features/notifications/presentation/services/fcm_service.dart';

import 'fcm_service_test.mocks.dart';

@GenerateMocks([AuthRepository, SyncDeviceTokenUseCase, DeviceTokenService])
void main() {
  late FCMService service;
  late MockAuthRepository mockAuthRepository;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
  late MockDeviceTokenService mockDeviceTokenService;

  final testUser = UserEntity(
    id: 'user123',
    email: 'test@test.com',
    displayName: 'Test User',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockSyncDeviceTokenUseCase = MockSyncDeviceTokenUseCase();
    mockDeviceTokenService = MockDeviceTokenService();

    // Default stubs
    when(
      mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockDeviceTokenService.onTokenRefresh,
    ).thenAnswer((_) => const Stream.empty());
    when(mockAuthRepository.currentUser).thenReturn(null);
    when(mockSyncDeviceTokenUseCase(any)).thenAnswer((_) async {});

    service = FCMService(
      mockAuthRepository,
      mockSyncDeviceTokenUseCase,
      mockDeviceTokenService,
    );
  });

  group('initialize', () {
    test('should sync token when auth state changes to logged in', () async {
      // Arrange
      final userController = StreamController<UserEntity?>();
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => userController.stream);

      service.initialize();

      // Act
      userController.add(testUser);
      await Future.delayed(Duration.zero);

      // Assert
      verify(mockSyncDeviceTokenUseCase('user123')).called(1);

      await userController.close();
    });

    test(
      'should sync token when token refreshes and user is logged in',
      () async {
        // Arrange
        final tokenController = StreamController<String>();
        when(
          mockDeviceTokenService.onTokenRefresh,
        ).thenAnswer((_) => tokenController.stream);
        when(mockAuthRepository.currentUser).thenReturn(testUser);

        service.initialize();

        // Act
        tokenController.add('new_token');
        await Future.delayed(Duration.zero);

        // Assert
        verify(mockSyncDeviceTokenUseCase('user123')).called(1);

        await tokenController.close();
      },
    );

    test(
      'should NOT sync token when token refreshes and user is NOT logged in',
      () async {
        // Arrange
        final tokenController = StreamController<String>();
        when(
          mockDeviceTokenService.onTokenRefresh,
        ).thenAnswer((_) => tokenController.stream);
        when(mockAuthRepository.currentUser).thenReturn(null);

        service.initialize();

        // Act
        tokenController.add('new_token');
        await Future.delayed(Duration.zero);

        // Assert
        verifyNever(mockSyncDeviceTokenUseCase(any));

        await tokenController.close();
      },
    );
  });
}
