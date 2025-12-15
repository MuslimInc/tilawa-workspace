import 'dart:convert';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/entities/reciter.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/services/navigation_service.dart';
import 'package:muzakri/features/downloads/data/services/download_notification_service.dart';
import 'package:muzakri/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:muzakri/shared/models/reciter_model.dart';

import 'download_notification_service_test.mocks.dart';

@GenerateMocks([RecitersRepository, NavigationService])
void main() {
  late DownloadNotificationService service;
  late MockRecitersRepository mockRecitersRepository;
  late MockNavigationService mockNavigationService;

  setUp(() {
    provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));
    mockRecitersRepository = MockRecitersRepository();
    mockNavigationService = MockNavigationService();
    service = DownloadNotificationService(
      mockRecitersRepository,
      mockNavigationService,
    );
    // return null by default for location to allow navigation
    when(mockNavigationService.getCurrentLocation()).thenReturn(null);
  });

  group('handleNotificationResponse', () {
    const reciterName = 'Al-Afasy';
    const reciterEntity = ReciterEntity(
      id: 1,
      name: reciterName,
      letter: 'A',
      date: '2023',
      moshaf: [],
    );

    test('should return early if payload is null', () async {
      // Arrange
      const response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
      );

      // Act
      await service.handleNotificationResponse(response);

      // Assert
      verifyZeroInteractions(mockRecitersRepository);
      verifyZeroInteractions(mockNavigationService);
    });

    test('should fetch reciter and navigate when payload is valid', () async {
      // Arrange
      final String payload = jsonEncode({'reciterName': reciterName});
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Right([reciterEntity]));

      // Stub push to satisfy the call
      when(
        mockNavigationService.push(any, extra: anyNamed('extra')),
      ).thenAnswer((_) async {});

      // Act
      await service.handleNotificationResponse(response);

      // Assert
      verify(mockRecitersRepository.getReciters()).called(1);

      const expectedReciter = Reciter(
        id: 1,
        name: reciterName,
        letter: 'A',
        date: '2023',
        moshaf: [],
      );

      // Verify navigation call
      // Capture arguments to verify details
      final List<dynamic> captured = verify(
        mockNavigationService.push(captureAny, extra: captureAnyNamed('extra')),
      ).captured;

      expect(captured[0], isA<String>()); // location string
      expect(captured[0], contains(reciterEntity.id.toString()));
      expect(captured[1], isA<Reciter>()); // extra
      expect((captured[1] as Reciter).name, equals(expectedReciter.name));
      expect((captured[1] as Reciter).name, equals(expectedReciter.name));
    });

    test('should NOT navigate if already on target route', () async {
      // Arrange
      final String payload = jsonEncode({'reciterName': reciterName});
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Right([reciterEntity]));

      // Mock current location to match target PATH only (simulating user scenario)
      // The generated targetLocation will contain query params like /reciter/1?reciter=...
      // We return /reciter/1 to verify the path comparison logic
      when(mockNavigationService.getCurrentLocation()).thenReturn('/reciter/1');

      // Act
      await service.handleNotificationResponse(response);

      // Assert
      verify(mockRecitersRepository.getReciters()).called(1);
      // Verify push is NEVER called
      verifyNever(mockNavigationService.push(any, extra: anyNamed('extra')));
    });

    test('should not navigate if reciter is not found', () async {
      // Arrange
      final String payload = jsonEncode({'reciterName': 'Unknown'});
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Right([reciterEntity]));

      // Act
      await service.handleNotificationResponse(response);

      // Assert
      verify(mockRecitersRepository.getReciters()).called(1);
      verifyZeroInteractions(mockNavigationService);
    });

    test('should not navigate if repository fails', () async {
      // Arrange
      final String payload = jsonEncode({'reciterName': reciterName});
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(
        mockRecitersRepository.getReciters(),
      ).thenAnswer((_) async => const Left(ServerFailure('Error')));

      // Act
      await service.handleNotificationResponse(response);

      // Assert
      verify(mockRecitersRepository.getReciters()).called(1);
      verifyZeroInteractions(mockNavigationService);
    });

    test('should handle json decode error gracefully', () async {
      // Arrange
      const payload = 'invalid access {'; // Invalid JSON
      const response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      // Act
      await service.handleNotificationResponse(response);

      // Assert
      // Should catch exception and log error, no calls to repo
      verifyZeroInteractions(mockRecitersRepository);
      verifyZeroInteractions(mockNavigationService);
    });
  });
}
