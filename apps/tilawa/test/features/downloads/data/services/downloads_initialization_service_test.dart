import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/downloads/data/services/downloads_initialization_service.dart';

import '../../helpers/mock_helper.mocks.dart';

void main() {
  late DownloadsInitializationService service;
  late MockDownloadsRepository mockRepository;
  late MockDownloadNotificationService mockNotificationService;
  late MockBatchDownloadManager mockBatchDownloadManager;
  late MockDownloadQueueManager mockDownloadQueueManager;
  late MockSharedPreferencesAsync mockPrefs;

  setUp(() {
    mockRepository = MockDownloadsRepository();
    mockNotificationService = MockDownloadNotificationService();
    mockBatchDownloadManager = MockBatchDownloadManager();
    mockDownloadQueueManager = MockDownloadQueueManager();
    mockPrefs = MockSharedPreferencesAsync();

    // Stub initialize to do nothing
    when(mockNotificationService.initialize()).thenAnswer((_) async {
      return;
    });

    service = DownloadsInitializationService(
      mockRepository,
      mockNotificationService,
      mockBatchDownloadManager,
      mockDownloadQueueManager,
      mockPrefs,
    );
  });

  group('DownloadsInitializationService', () {
    test('initialize calls dependencies correctly', () async {
      // Arrange
      when(mockRepository.resumePendingDownloads()).thenAnswer((_) async {
        return;
      });

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
        when(mockRepository.resumePendingDownloads()).thenAnswer((_) async {
          return;
        });

        // Act & Assert - should complete without errors
        await expectLater(service.initialize(), completes);
      },
    );
  });
}
