import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/services/device_token_service.dart';
import 'package:tilawa/features/auth/data/auth_service.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa/features/notifications/presentation/services/fcm_service.dart';

import 'fcm_service_test.mocks.dart';

@GenerateMocks([AuthService, SyncDeviceTokenUseCase, DeviceTokenService, User])
void main() {
  late FCMService service;
  late MockAuthService mockAuthService;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
  late MockDeviceTokenService mockDeviceTokenService;
  late MockUser mockUser;

  setUp(() {
    mockAuthService = MockAuthService();
    mockSyncDeviceTokenUseCase = MockSyncDeviceTokenUseCase();
    mockDeviceTokenService = MockDeviceTokenService();
    mockUser = MockUser();

    when(mockUser.uid).thenReturn('user123');

    // Default stubs
    when(
      mockAuthService.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockDeviceTokenService.onTokenRefresh,
    ).thenAnswer((_) => const Stream.empty());
    when(mockAuthService.currentUser).thenReturn(null);
    when(mockSyncDeviceTokenUseCase(any)).thenAnswer((_) async {});

    service = FCMService(
      mockAuthService,
      mockSyncDeviceTokenUseCase,
      mockDeviceTokenService,
    );
  });

  group('initialize', () {
    test('should sync token when auth state changes to logged in', () async {
      // Arrange
      final userController = StreamController<User?>();
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => userController.stream);

      service.initialize();

      // Act
      userController.add(mockUser);
      await Future.delayed(Duration.zero); // Wait for stream listener

      // Assert
      verify(mockSyncDeviceTokenUseCase('user123')).called(1);

      userController.close();
    });

    test(
      'should sync token when token refreshes and user is logged in',
      () async {
        // Arrange
        final tokenController = StreamController<String>();
        when(
          mockDeviceTokenService.onTokenRefresh,
        ).thenAnswer((_) => tokenController.stream);
        when(mockAuthService.currentUser).thenReturn(mockUser);

        service.initialize();

        // Act
        tokenController.add('new_token');
        await Future.delayed(Duration.zero);

        // Assert
        verify(mockSyncDeviceTokenUseCase('user123')).called(1);

        tokenController.close();
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
        when(mockAuthService.currentUser).thenReturn(null);

        service.initialize();

        // Act
        tokenController.add('new_token');
        await Future.delayed(Duration.zero);

        // Assert
        verifyNever(mockSyncDeviceTokenUseCase(any));

        tokenController.close();
      },
    );
  });
}
