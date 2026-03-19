import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/downloads/data/models/download_progress.dart';
import 'package:tilawa/features/downloads/data/services/batch_download_manager.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';

import '../../helpers/mock_helper.mocks.dart';

// No need to redeclare mocks here if they are in mock_helper.mocks.dart
// But we need to use them from there.

void main() {
  late BatchDownloadManager manager;
  late MockDownloadServiceInterface mockDownloadService;
  late MockDownloadNotificationService mockNotificationService;
  late MockSharedPreferencesAsync mockPrefs;
  late StreamController<DownloadProgress> progressController;

  setUp(() {
    mockDownloadService = MockDownloadServiceInterface();
    mockNotificationService = MockDownloadNotificationService();
    mockPrefs = MockSharedPreferencesAsync();
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

    when(mockPrefs.getString(any)).thenAnswer((_) async => null);
    when(mockPrefs.setString(any, any)).thenAnswer((_) async => Future.value());
    when(mockPrefs.remove(any)).thenAnswer((_) async => Future.value());

    manager = BatchDownloadManager(
      mockDownloadService,
      mockNotificationService,
      mockPrefs,
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

  group('BatchDownloadManager - cancelBatchesForReciter', () {
    test('should cancel only batches for the specified reciter', () async {
      // Arrange - start batches for different reciters
      manager.startBatch(
        batchId: 'batch-1',
        title: 'Test 1',
        downloadIds: ['id1', 'id2'],
        reciterName: 'Reciter A',
      );
      manager.startBatch(
        batchId: 'batch-2',
        title: 'Test 2',
        downloadIds: ['id3', 'id4'],
        reciterName: 'Reciter B',
      );

      // Act - cancel only Reciter A's batches
      await manager.cancelBatchesForReciter('Reciter A');

      // Assert - only Reciter A's batch should be cancelled
      verify(mockNotificationService.cancelNotification('batch-1')).called(1);
      verifyNever(mockNotificationService.cancelNotification('batch-2'));
    });

    test('should do nothing when no batches for reciter', () async {
      // Arrange - start batch for different reciter
      manager.startBatch(
        batchId: 'batch-1',
        title: 'Test 1',
        downloadIds: ['id1'],
        reciterName: 'Reciter A',
      );

      // Act - try to cancel for non-existent reciter
      await manager.cancelBatchesForReciter('Reciter B');

      // Assert - no notifications cancelled
      verifyNever(mockNotificationService.cancelNotification(any));
    });

    test('should cancel multiple batches for same reciter', () async {
      // Arrange - start multiple batches for same reciter
      manager.startBatch(
        batchId: 'batch-1',
        title: 'Test 1',
        downloadIds: ['id1'],
        reciterName: 'Reciter A',
      );
      manager.startBatch(
        batchId: 'batch-2',
        title: 'Test 2',
        downloadIds: ['id2'],
        reciterName: 'Reciter A',
      );

      // Act
      await manager.cancelBatchesForReciter('Reciter A');

      // Assert - both batches should be cancelled
      verify(mockNotificationService.cancelNotification('batch-1')).called(1);
      verify(mockNotificationService.cancelNotification('batch-2')).called(1);
    });
  });

  group('BatchDownloadManager - cancelAllBatches', () {
    test('should cancel all active batches and their notifications', () async {
      // Arrange - start multiple batches
      manager.startBatch(
        batchId: 'batch-1',
        title: 'Test 1',
        downloadIds: ['id1', 'id2'],
      );
      manager.startBatch(
        batchId: 'batch-2',
        title: 'Test 2',
        downloadIds: ['id3', 'id4'],
      );

      // Act
      await manager.cancelAllBatches();

      // Assert - both batch notifications should be cancelled
      verify(mockNotificationService.cancelNotification('batch-1')).called(1);
      verify(mockNotificationService.cancelNotification('batch-2')).called(1);
    });

    test('should do nothing when no active batches', () async {
      // Act
      await manager.cancelAllBatches();

      // Assert
      verifyNever(mockNotificationService.cancelNotification(any));
    });

    test('should cleanup subscription after cancelling all batches', () async {
      // Arrange
      manager.startBatch(
        batchId: 'batch-1',
        title: 'Test',
        downloadIds: ['id1'],
      );

      // Act
      await manager.cancelAllBatches();

      // Give time for cleanup
      await Future.delayed(const Duration(milliseconds: 10));

      // Emit progress - no handler should process since all batches cancelled
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

  group('BatchDownloadManager - Persistence', () {
    test('should restore batches on initialization', () async {
      // Arrange
      final batchData = {
        'batch-1': {
          'id': 'batch-1',
          'title': 'Restored Batch',
          'item_ids': ['id1', 'id2'],
          'total_items': 2,
          'reciter_name': 'Reciter A',
        },
      };

      when(
        mockPrefs.getString('batch_downloads_data'),
      ).thenAnswer((_) async => jsonEncode(batchData));

      when(mockDownloadService.getDownloadProgress('id1')).thenAnswer(
        (_) async => const DownloadProgress(
          id: 'id1',
          progress: 1.0,
          downloadedSize: 1000,
          fileSize: 1000,
          status: DownloadStatus.completed,
        ),
      );

      when(mockDownloadService.getDownloadProgress('id2')).thenAnswer(
        (_) async => const DownloadProgress(
          id: 'id2',
          progress: 0.5,
          downloadedSize: 500,
          fileSize: 1000,
          status: DownloadStatus.downloading,
        ),
      );

      // Act
      await manager.initialize();

      // Assert
      verify(
        mockNotificationService.showBatchDownloadProgress(
          batchId: 'batch-1',
          title: 'Restored Batch',
          progress: 75, // (100 + 50) / 2
          completedCount: 1,
          totalCount: 2,
          status: DownloadStatus.downloading,
        ),
      ).called(1);
    });

    test('should persist batches when a new batch starts', () async {
      // Act
      manager.startBatch(
        batchId: 'batch-1',
        title: 'New Batch',
        downloadIds: ['id1'],
      );

      // Assert
      verify(mockPrefs.setString('batch_downloads_data', any)).called(1);
    });

    test('should persist batches when a batch is removed', () async {
      // Arrange
      manager.startBatch(
        batchId: 'batch-1',
        title: 'New Batch',
        downloadIds: ['id1'],
      );
      clearInteractions(mockPrefs);

      // Act
      await manager.cancelBatch('batch-1');

      // Assert
      verify(mockPrefs.remove('batch_downloads_data')).called(1);
    });
  });
}
