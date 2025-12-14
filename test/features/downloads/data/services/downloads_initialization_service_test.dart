import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/data/services/download_notification_service.dart';
import 'package:muzakri/features/downloads/data/services/downloads_initialization_service.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';

import 'downloads_initialization_service_test.mocks.dart';

@GenerateMocks([DownloadsRepository, DownloadNotificationService])
void main() {
  late DownloadsInitializationService service;
  late MockDownloadsRepository mockRepository;
  late MockDownloadNotificationService mockNotificationService;

  setUp(() {
    mockRepository = MockDownloadsRepository();
    mockNotificationService = MockDownloadNotificationService();

    // Stub initialize to do nothing
    when(mockNotificationService.initialize()).thenAnswer((_) async {
      return;
    });

    service = DownloadsInitializationService(
      mockRepository,
      mockNotificationService,
    );
  });

  group('DownloadsInitializationService', () {
    test('initialize calls dependencies correctly', () async {
      // Arrange
      when(mockRepository.resumePendingDownloads()).thenAnswer((_) async {});

      // Act
      await service.initialize();

      // Assert
      verify(mockNotificationService.initialize()).called(1);
      verify(mockRepository.resumePendingDownloads()).called(1);
    });

    test('initialize catches and logs errors gracefully', () async {
      // Arrange
      when(
        mockRepository.resumePendingDownloads(),
      ).thenThrow(Exception('Test error'));

      // Act - should not throw
      await service.initialize();

      // Assert
      verify(mockNotificationService.initialize()).called(1);
      verify(mockRepository.resumePendingDownloads()).called(1);
      // Test passes if no exception is thrown
    });

    test(
      'initialize completes successfully when repository succeeds',
      () async {
        // Arrange
        when(mockRepository.resumePendingDownloads()).thenAnswer((_) async {});

        // Act & Assert - should complete without errors
        await expectLater(service.initialize(), completes);
      },
    );
  });
}
