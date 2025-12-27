import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/downloads/data/services/download_queue_manager.dart';
import 'package:tilawa/features/downloads/data/services/download_recovery_service.dart';
import 'package:tilawa/features/downloads/data/services/download_service_interface.dart';
import 'package:tilawa/features/downloads/data/services/download_validator.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';

class MockDownloadService extends Mock implements DownloadServiceInterface {}

class MockDownloadValidator extends Mock implements DownloadValidator {}

class MockDownloadQueueManager extends Mock implements DownloadQueueManager {}

void main() {
  late MockDownloadService mockDownloadService;
  late MockDownloadValidator mockValidator;
  late MockDownloadQueueManager mockQueueManager;
  late DownloadRecoveryService recoveryService;

  setUp(() {
    mockDownloadService = MockDownloadService();
    mockValidator = MockDownloadValidator();
    mockQueueManager = MockDownloadQueueManager();
    recoveryService = DownloadRecoveryService(
      mockDownloadService,
      mockValidator,
      mockQueueManager,
    );
  });

  DownloadItem createTestDownload({
    String id = '1',
    String title = 'Surah 1',
    String url = 'url',
    String filePath = 'path',
    DownloadStatus status = DownloadStatus.pending,
    double progress = 0,
    int fileSize = 100,
    DateTime? createdAt,
  }) {
    return DownloadItem(
      id: id,
      title: title,
      url: url,
      filePath: filePath,
      reciterName: 'reciter',
      reciterId: 1,
      status: status,
      progress: progress,
      fileSize: fileSize,
      downloadedSize: (fileSize * progress).round(),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  group('handleOrphanedDownload', () {
    test('re-enqueues orphaned download when status is null', () async {
      final DownloadItem download = createTestDownload();

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => null);
      when(
        () => mockQueueManager.enqueue(
          id: any(named: 'id'),
          url: any(named: 'url'),
          filePath: any(named: 'filePath'),
          title: any(named: 'title'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenAnswer((_) async {});

      final DownloadItem result = await recoveryService.handleOrphanedDownload(
        download,
        isQueued: false,
        isActive: false,
      );

      verify(
        () => mockQueueManager.enqueue(
          id: '1',
          url: 'url',
          filePath: 'path',
          title: 'Surah 1',
          reciterName: 'reciter',
          reciterId: 1,
        ),
      ).called(1);

      expect(result.status, DownloadStatus.pending);
    });

    test('handles error when checking status', () async {
      final DownloadItem download = createTestDownload();

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenThrow(Exception('Network error'));
      when(
        () => mockQueueManager.enqueue(
          id: any(named: 'id'),
          url: any(named: 'url'),
          filePath: any(named: 'filePath'),
          title: any(named: 'title'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenAnswer((_) async {});

      final DownloadItem result = await recoveryService.handleOrphanedDownload(
        download,
        isQueued: false,
        isActive: false,
      );

      // Should still re-enqueue despite error
      verify(
        () => mockQueueManager.enqueue(
          id: '1',
          url: 'url',
          filePath: 'path',
          title: 'Surah 1',
          reciterName: 'reciter',
          reciterId: 1,
        ),
      ).called(1);
      expect(result.status, DownloadStatus.pending);
    });

    test(
      'marks as completed when status is completed and file exists',
      () async {
        final DownloadItem download = createTestDownload();

        when(
          () => mockDownloadService.getStatus('url'),
        ).thenAnswer((_) async => DownloadStatus.completed);
        when(
          () => mockValidator.verifyFileExists('path'),
        ).thenAnswer((_) async => true);

        final DownloadItem result = await recoveryService
            .handleOrphanedDownload(download, isQueued: false, isActive: false);

        expect(result.status, DownloadStatus.completed);
        expect(result.progress, 1.0);
        expect(result.completedAt, isNotNull);
      },
    );

    test('tracks download when status is downloading', () async {
      final DownloadItem download = createTestDownload();

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.downloading);
      when(
        () => mockQueueManager.enqueue(
          id: any(named: 'id'),
          url: any(named: 'url'),
          filePath: any(named: 'filePath'),
          title: any(named: 'title'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenAnswer((_) async {});

      final DownloadItem result = await recoveryService.handleOrphanedDownload(
        download,
        isQueued: false,
        isActive: false,
      );

      verify(
        () => mockQueueManager.enqueue(
          id: '1',
          url: 'url',
          filePath: 'path',
          title: 'Surah 1',
          reciterName: 'reciter',
          reciterId: 1,
        ),
      ).called(1);
      expect(result.status, DownloadStatus.pending);
    });

    test('tracks download when status is pending in platform', () async {
      final DownloadItem download = createTestDownload();

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.pending);
      when(
        () => mockQueueManager.enqueue(
          id: any(named: 'id'),
          url: any(named: 'url'),
          filePath: any(named: 'filePath'),
          title: any(named: 'title'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenAnswer((_) async {});

      final DownloadItem result = await recoveryService.handleOrphanedDownload(
        download,
        isQueued: false,
        isActive: false,
      );

      verify(
        () => mockQueueManager.enqueue(
          id: '1',
          url: 'url',
          filePath: 'path',
          title: 'Surah 1',
          reciterName: 'reciter',
          reciterId: 1,
        ),
      ).called(1);
      expect(result.status, DownloadStatus.pending);
    });

    test('returns download when re-enqueue fails', () async {
      final DownloadItem download = createTestDownload();

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => null);
      when(
        () => mockQueueManager.enqueue(
          id: any(named: 'id'),
          url: any(named: 'url'),
          filePath: any(named: 'filePath'),
          title: any(named: 'title'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenThrow(Exception('Queue error'));

      final DownloadItem result = await recoveryService.handleOrphanedDownload(
        download,
        isQueued: false,
        isActive: false,
      );

      expect(result.status, DownloadStatus.pending);
    });
  });

  group('handleStuckDownload', () {
    test('returns download unchanged if not stuck', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        progress: 0.5, // Has progress, not stuck
      );

      final DownloadItem result = await recoveryService.handleStuckDownload(
        download,
      );

      expect(result.id, download.id);
      verifyNever(() => mockDownloadService.getStatus(any()));
    });

    test('returns download unchanged if stuck but not old enough', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        createdAt: DateTime.now().subtract(
          const Duration(seconds: 10),
        ), // < 30s
      );

      final DownloadItem result = await recoveryService.handleStuckDownload(
        download,
      );

      expect(result.id, download.id);
      verifyNever(() => mockDownloadService.getStatus(any()));
    });

    test('retries stuck active download', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        createdAt: DateTime.now().subtract(const Duration(seconds: 40)),
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.pending);
      when(() => mockDownloadService.cancel('url')).thenAnswer((_) async {});
      when(() => mockQueueManager.removeFromQueue('1')).thenReturn(null);
      when(
        () => mockQueueManager.enqueue(
          id: any(named: 'id'),
          url: any(named: 'url'),
          filePath: any(named: 'filePath'),
          title: any(named: 'title'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenAnswer((_) async {});

      final DownloadItem result = await recoveryService.handleStuckDownload(
        download,
      );

      verify(() => mockDownloadService.cancel('url')).called(1);
      verify(() => mockQueueManager.removeFromQueue('1')).called(1);
      expect(result.createdAt.isAfter(download.createdAt), isTrue);
    });

    test('handles MissingPluginException when getting status', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        createdAt: DateTime.now().subtract(const Duration(seconds: 40)),
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenThrow(MissingPluginException());

      final DownloadItem result = await recoveryService.handleStuckDownload(
        download,
      );

      // Returns unchanged when can't get status
      expect(result.id, download.id);
    });

    test('handles cancel error gracefully', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        createdAt: DateTime.now().subtract(const Duration(seconds: 40)),
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.pending);
      when(
        () => mockDownloadService.cancel('url'),
      ).thenThrow(Exception('Cancel error'));
      when(() => mockQueueManager.removeFromQueue('1')).thenReturn(null);
      when(
        () => mockQueueManager.enqueue(
          id: any(named: 'id'),
          url: any(named: 'url'),
          filePath: any(named: 'filePath'),
          title: any(named: 'title'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenAnswer((_) async {});

      final DownloadItem result = await recoveryService.handleStuckDownload(
        download,
      );

      // Should continue despite cancel error
      verify(() => mockQueueManager.removeFromQueue('1')).called(1);
      expect(result.createdAt.isAfter(download.createdAt), isTrue);
    });

    test('marks as failed when retry fails', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        createdAt: DateTime.now().subtract(const Duration(seconds: 40)),
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.pending);
      when(() => mockDownloadService.cancel('url')).thenAnswer((_) async {});
      when(() => mockQueueManager.removeFromQueue('1')).thenReturn(null);
      when(
        () => mockQueueManager.enqueue(
          id: any(named: 'id'),
          url: any(named: 'url'),
          filePath: any(named: 'filePath'),
          title: any(named: 'title'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenThrow(Exception('Enqueue error'));

      final DownloadItem result = await recoveryService.handleStuckDownload(
        download,
      );

      expect(result.status, DownloadStatus.failed);
    });
  });

  group('checkBackgroundStatus', () {
    test('marks completed if validated', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        progress: 0.5,
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.completed);
      when(
        () => mockValidator.verifyFileExists('path'),
      ).thenAnswer((_) async => true);
      when(
        () => mockValidator.getActualFileSize('path'),
      ).thenAnswer((_) async => 100);

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      expect(result.status, DownloadStatus.completed);
      expect(result.progress, 1.0);
    });

    test('marks failed if completed but file missing', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        progress: 0.5,
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.completed);
      when(
        () => mockValidator.verifyFileExists('path'),
      ).thenAnswer((_) async => false);

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      expect(result.status, DownloadStatus.failed);
    });

    test('handles MissingPluginException gracefully', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        progress: 0.5,
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenThrow(MissingPluginException());

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      // Returns unchanged
      expect(result.id, download.id);
    });

    test('handles generic exception when getting status', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        progress: 0.5,
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenThrow(Exception('Network error'));

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      expect(result.id, download.id);
    });

    test('updates status when downloading in background', () async {
      final DownloadItem download = createTestDownload(
        
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.downloading);

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      expect(result.status, DownloadStatus.downloading);
    });

    test('returns unchanged when already downloading status matches', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        progress: 0.5,
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.downloading);

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      expect(result.status, DownloadStatus.downloading);
      expect(result.id, download.id);
    });

    test('marks failed when download failed in background', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        progress: 0.5,
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.failed);

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      expect(result.status, DownloadStatus.failed);
    });

    test('retries stuck background download', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        createdAt: DateTime.now().subtract(const Duration(seconds: 40)),
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => null); // Not active
      when(() => mockDownloadService.cancel('url')).thenAnswer((_) async {});
      when(() => mockQueueManager.removeFromQueue('1')).thenReturn(null);
      when(
        () => mockQueueManager.enqueue(
          id: any(named: 'id'),
          url: any(named: 'url'),
          filePath: any(named: 'filePath'),
          title: any(named: 'title'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenAnswer((_) async {});

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      verify(() => mockDownloadService.cancel('url')).called(1);
      verify(() => mockQueueManager.removeFromQueue('1')).called(1);
      expect(result.createdAt.isAfter(download.createdAt), isTrue);
    });

    test('marks failed when stuck retry fails', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        createdAt: DateTime.now().subtract(const Duration(seconds: 40)),
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => null);
      when(() => mockDownloadService.cancel('url')).thenAnswer((_) async {});
      when(() => mockQueueManager.removeFromQueue('1')).thenReturn(null);
      when(
        () => mockQueueManager.enqueue(
          id: any(named: 'id'),
          url: any(named: 'url'),
          filePath: any(named: 'filePath'),
          title: any(named: 'title'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenThrow(Exception('Retry error'));

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      expect(result.status, DownloadStatus.failed);
    });

    test('marks failed when file size mismatch', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        progress: 0.5,
        fileSize: 1000,
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.completed);
      when(
        () => mockValidator.verifyFileExists('path'),
      ).thenAnswer((_) async => true);
      when(
        () => mockValidator.getActualFileSize('path'),
      ).thenAnswer((_) async => 500); // Half the expected size

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      expect(result.status, DownloadStatus.failed);
    });

    test('returns unchanged when file size verification fails', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        progress: 0.5,
        fileSize: 1000,
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.completed);
      when(
        () => mockValidator.verifyFileExists('path'),
      ).thenAnswer((_) async => true);
      when(
        () => mockValidator.getActualFileSize('path'),
      ).thenThrow(Exception('File error'));

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      // Returns unchanged on error
      expect(result.id, download.id);
      expect(result.status, DownloadStatus.downloading);
    });

    test('returns unchanged when actual file size is null', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        progress: 0.5,
        fileSize: 1000,
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.completed);
      when(
        () => mockValidator.verifyFileExists('path'),
      ).thenAnswer((_) async => true);
      when(
        () => mockValidator.getActualFileSize('path'),
      ).thenAnswer((_) async => null);

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      // Returns unchanged when can't get size
      expect(result.id, download.id);
      expect(result.status, DownloadStatus.downloading);
    });

    test('completes when fileSize is 0 (no size verification)', () async {
      final DownloadItem download = createTestDownload(
        status: DownloadStatus.downloading,
        progress: 0.5,
        fileSize: 0, // No fileSize tracking
      );

      when(
        () => mockDownloadService.getStatus('url'),
      ).thenAnswer((_) async => DownloadStatus.completed);
      when(
        () => mockValidator.verifyFileExists('path'),
      ).thenAnswer((_) async => true);

      final DownloadItem result = await recoveryService.checkBackgroundStatus(
        download,
      );

      expect(result.status, DownloadStatus.completed);
      expect(result.progress, 1.0);
      verifyNever(() => mockValidator.getActualFileSize(any()));
    });
  });
}
