import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/data/services/batch_download_manager.dart';
import 'package:muzakri/features/downloads/data/services/download_notification_service.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';

import 'batch_download_manager_test.mocks.dart';

@GenerateMocks([DownloadService, DownloadNotificationService])
void main() {
  late BatchDownloadManager manager;
  late MockDownloadService mockDownloadService;
  late MockDownloadNotificationService mockNotificationService;
  late StreamController<DownloadProgress> progressController;

  setUp(() {
    mockDownloadService = MockDownloadService();
    mockNotificationService = MockDownloadNotificationService();
    progressController = StreamController<DownloadProgress>.broadcast();

    // Setup default mock behavior
    when(
      mockDownloadService.globalProgressStream,
    ).thenAnswer((_) => progressController.stream);
    when(
      mockNotificationService.showBatchDownloadProgress(
        batchId: anyNamed('batchId'),
        title: anyNamed('title'),
        progress: anyNamed('progress'),
        completedCount: anyNamed('completedCount'),
        totalCount: anyNamed('totalCount'),
        status: anyNamed('status'),
      ),
    ).thenAnswer((_) async => Future.value());
    when(
      mockNotificationService.cancelNotification(any),
    ).thenAnswer((_) async => Future.value());

    manager = BatchDownloadManager(
      mockDownloadService,
      mockNotificationService,
    );
  });

  tearDown(() {
    progressController.close();
  });

  group('BatchDownloadManager - startBatch', () {
    test('should create batch and show initial notification', () {
      // Arrange
      const batchId = 'batch-1';
      const title = 'Downloading Al-Sudais';
      final downloadIds = ['id1', 'id2', 'id3'];

      // Act
      manager.startBatch(
        batchId: batchId,
        title: title,
        downloadIds: downloadIds,
      );

      // Assert
      verify(
        mockNotificationService.showBatchDownloadProgress(
          batchId: batchId,
          title: title,
          progress: 0,
          completedCount: 0,
          totalCount: 3,
          status: DownloadStatus.downloading,
        ),
      ).called(1);
    });

    test('should do nothing when download IDs are empty', () {
      // Act
      manager.startBatch(batchId: 'batch-1', title: 'Test', downloadIds: []);

      // Assert
      verifyNever(
        mockNotificationService.showBatchDownloadProgress(
          batchId: anyNamed('batchId'),
          title: anyNamed('title'),
          progress: anyNamed('progress'),
          completedCount: anyNamed('completedCount'),
          totalCount: anyNamed('totalCount'),
          status: anyNamed('status'),
        ),
      );
    });

    test('should start listening to progress stream when batch starts', () {
      // Act
      manager.startBatch(
        batchId: 'batch-1',
        title: 'Test',
        downloadIds: ['id1'],
      );

      // Assert
      verify(mockDownloadService.globalProgressStream).called(1);
    });
  });

  group('BatchDownloadManager - cancelBatch', () {
    test('should remove batch and cancel notification', () async {
      // Arrange
      const batchId = 'batch-1';
      manager.startBatch(
        batchId: batchId,
        title: 'Test',
        downloadIds: ['id1', 'id2'],
      );

      // Act
      await manager.cancelBatch(batchId);

      // Assert
      verify(mockNotificationService.cancelNotification(batchId)).called(1);
    });

    test('should do nothing when batch ID does not exist', () async {
      // Act
      await manager.cancelBatch('non-existent');

      // Assert
      verifyNever(mockNotificationService.cancelNotification(any));
    });

    test('should cleanup subscription when last batch is cancelled', () async {
      // Arrange
      manager.startBatch(
        batchId: 'batch-1',
        title: 'Test',
        downloadIds: ['id1'],
      );

      // Act
      await manager.cancelBatch('batch-1');

      // Give time for cleanup
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify subscription is cleaned up by emitting - no handler should process
      progressController.add(
        const DownloadProgress(
          id: 'id1',
          progress: 0.5,
          downloadedSize: 500,
          fileSize: 1000,
          status: DownloadStatus.downloading,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      // Only initial notification should have been called during startBatch
      verify(
        mockNotificationService.showBatchDownloadProgress(
          batchId: anyNamed('batchId'),
          title: anyNamed('title'),
          progress: anyNamed('progress'),
          completedCount: anyNamed('completedCount'),
          totalCount: anyNamed('totalCount'),
          status: anyNamed('status'),
        ),
      ).called(1); // Only initial, no updates
    });
  });

  group('BatchDownloadManager - progress updates', () {
    test('should update notification when download progresses', () async {
      // Arrange
      const batchId = 'batch-1';
      const downloadId = 'id1';
      manager.startBatch(
        batchId: batchId,
        title: 'Test',
        downloadIds: [downloadId, 'id2'],
      );

      // Reset to clear initial notification
      clearInteractions(mockNotificationService);

      // Act
      progressController.add(
        const DownloadProgress(
          id: downloadId,
          progress: 0.5,
          downloadedSize: 500,
          fileSize: 1000,
          status: DownloadStatus.downloading,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      verify(
        mockNotificationService.showBatchDownloadProgress(
          batchId: batchId,
          title: 'Test',
          progress: 25, // 50% of 1 item out of 2 = 25%
          completedCount: 0,
          totalCount: 2,
          status: DownloadStatus.downloading,
        ),
      ).called(1);
    });

    test('should increment completed count when item completes', () async {
      // Arrange
      const batchId = 'batch-1';
      manager.startBatch(
        batchId: batchId,
        title: 'Test',
        downloadIds: ['id1', 'id2'],
      );

      clearInteractions(mockNotificationService);

      // Act
      progressController.add(
        const DownloadProgress(
          id: 'id1',
          progress: 1.0,
          downloadedSize: 1000,
          fileSize: 1000,
          status: DownloadStatus.completed,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      verify(
        mockNotificationService.showBatchDownloadProgress(
          batchId: batchId,
          title: 'Test',
          progress: 50, // 1 out of 2 items = 50%
          completedCount: 1,
          totalCount: 2,
          status: DownloadStatus.downloading,
        ),
      ).called(1);
    });

    test('should handle failed downloads', () async {
      // Arrange
      const batchId = 'batch-1';
      manager.startBatch(batchId: batchId, title: 'Test', downloadIds: ['id1']);

      clearInteractions(mockNotificationService);

      // Act
      progressController.add(
        const DownloadProgress(
          id: 'id1',
          progress: 0.5,
          downloadedSize: 500,
          fileSize: 1000,
          status: DownloadStatus.failed,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - batch shows as completed (finished) but with failed status
      verify(
        mockNotificationService.showBatchDownloadProgress(
          batchId: batchId,
          title: anyNamed('title'),
          progress: 100, // Failed counts as 100% for progress bar
          completedCount: 0,
          totalCount: 1,
          status: DownloadStatus.failed,
        ),
      ).called(1);
    });

    test('should handle cancelled downloads', () async {
      // Arrange
      const batchId = 'batch-1';
      manager.startBatch(
        batchId: batchId,
        title: 'Test',
        downloadIds: ['id1', 'id2'],
      );

      clearInteractions(mockNotificationService);

      // Act
      progressController.add(
        const DownloadProgress(
          id: 'id1',
          progress: 0.3,
          downloadedSize: 300,
          fileSize: 1000,
          status: DownloadStatus.cancelled,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      verify(
        mockNotificationService.showBatchDownloadProgress(
          batchId: batchId,
          title: anyNamed('title'),
          progress: 50, // Cancelled counts as 100% for progress
          completedCount: 0,
          totalCount: 2,
          status: DownloadStatus.downloading,
        ),
      ).called(1);
    });

    test('should remove batch from tracking when all items complete', () async {
      // Arrange
      const batchId = 'batch-1';
      manager.startBatch(
        batchId: batchId,
        title: 'Test',
        downloadIds: ['id1', 'id2'],
      );

      clearInteractions(mockNotificationService);

      // Act - complete both items
      progressController.add(
        const DownloadProgress(
          id: 'id1',
          progress: 1.0,
          downloadedSize: 1000,
          fileSize: 1000,
          status: DownloadStatus.completed,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      clearInteractions(mockNotificationService);

      progressController.add(
        const DownloadProgress(
          id: 'id2',
          progress: 1.0,
          downloadedSize: 1000,
          fileSize: 1000,
          status: DownloadStatus.completed,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - Final notification shows completed
      verify(
        mockNotificationService.showBatchDownloadProgress(
          batchId: batchId,
          title: anyNamed('title'),
          progress: 100,
          completedCount: 2,
          totalCount: 2,
          status: DownloadStatus.completed,
        ),
      ).called(1);

      // Send another progress update - should be ignored (batch removed)
      clearInteractions(mockNotificationService);
      progressController.add(
        const DownloadProgress(
          id: 'id1',
          progress: 1.0,
          downloadedSize: 1000,
          fileSize: 1000,
          status: DownloadStatus.completed,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      verifyNever(
        mockNotificationService.showBatchDownloadProgress(
          batchId: anyNamed('batchId'),
          title: anyNamed('title'),
          progress: anyNamed('progress'),
          completedCount: anyNamed('completedCount'),
          totalCount: anyNamed('totalCount'),
          status: anyNamed('status'),
        ),
      );
    });

    test('should ignore progress for items not in batch', () async {
      // Arrange
      manager.startBatch(
        batchId: 'batch-1',
        title: 'Test',
        downloadIds: ['id1'],
      );

      clearInteractions(mockNotificationService);

      // Act - send progress for different item
      progressController.add(
        const DownloadProgress(
          id: 'id-other',
          progress: 0.5,
          downloadedSize: 500,
          fileSize: 1000,
          status: DownloadStatus.downloading,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - no notification update
      verifyNever(
        mockNotificationService.showBatchDownloadProgress(
          batchId: anyNamed('batchId'),
          title: anyNamed('title'),
          progress: anyNamed('progress'),
          completedCount: anyNamed('completedCount'),
          totalCount: anyNamed('totalCount'),
          status: anyNamed('status'),
        ),
      );
    });

    test('should handle multiple batches simultaneously', () async {
      // Arrange
      manager.startBatch(
        batchId: 'batch-1',
        title: 'Batch 1',
        downloadIds: ['id1'],
      );
      manager.startBatch(
        batchId: 'batch-2',
        title: 'Batch 2',
        downloadIds: ['id2'],
      );

      clearInteractions(mockNotificationService);

      // Act - progress for batch 1
      progressController.add(
        const DownloadProgress(
          id: 'id1',
          progress: 0.5,
          downloadedSize: 500,
          fileSize: 1000,
          status: DownloadStatus.downloading,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - only batch 1 updated
      verify(
        mockNotificationService.showBatchDownloadProgress(
          batchId: 'batch-1',
          title: anyNamed('title'),
          progress: anyNamed('progress'),
          completedCount: anyNamed('completedCount'),
          totalCount: anyNamed('totalCount'),
          status: anyNamed('status'),
        ),
      ).called(1);

      verifyNever(
        mockNotificationService.showBatchDownloadProgress(
          batchId: 'batch-2',
          title: anyNamed('title'),
          progress: anyNamed('progress'),
          completedCount: anyNamed('completedCount'),
          totalCount: anyNamed('totalCount'),
          status: anyNamed('status'),
        ),
      );
    });
  });

  group('BatchDownloadManager - error handling', () {
    test('should handle stream errors gracefully', () async {
      // Arrange
      manager.startBatch(
        batchId: 'batch-1',
        title: 'Test',
        downloadIds: ['id1'],
      );

      // Act - emit error
      progressController.addError(Exception('Stream error'));

      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - manager should still be functional
      clearInteractions(mockNotificationService);

      progressController.add(
        const DownloadProgress(
          id: 'id1',
          progress: 0.5,
          downloadedSize: 500,
          fileSize: 1000,
          status: DownloadStatus.downloading,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      verify(
        mockNotificationService.showBatchDownloadProgress(
          batchId: anyNamed('batchId'),
          title: anyNamed('title'),
          progress: anyNamed('progress'),
          completedCount: anyNamed('completedCount'),
          totalCount: anyNamed('totalCount'),
          status: anyNamed('status'),
        ),
      ).called(1);
    });
  });
}
