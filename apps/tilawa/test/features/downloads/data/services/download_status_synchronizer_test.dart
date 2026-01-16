import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/downloads/data/services/download_queue_manager.dart';
import 'package:tilawa/features/downloads/data/services/download_recovery_service.dart';
import 'package:tilawa/features/downloads/data/services/download_service_interface.dart';
import 'package:tilawa/features/downloads/data/services/download_status_synchronizer.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';

class MockDownloadService extends Mock implements DownloadServiceInterface {}

class MockDownloadRecoveryService extends Mock
    implements DownloadRecoveryService {}

class MockDownloadQueueManager extends Mock implements DownloadQueueManager {}

void main() {
  late MockDownloadService mockDownloadService;
  late MockDownloadRecoveryService mockDownloadRecoveryService;
  late MockDownloadQueueManager mockDownloadQueueManager;
  late DownloadStatusSynchronizer synchronizer;

  setUp(() {
    mockDownloadService = MockDownloadService();
    mockDownloadRecoveryService = MockDownloadRecoveryService();
    mockDownloadQueueManager = MockDownloadQueueManager();
    synchronizer = DownloadStatusSynchronizer(
      mockDownloadService,
      mockDownloadRecoveryService,
      mockDownloadQueueManager,
    );

    registerFallbackValue(
      DownloadItem(
        id: 'fallback',
        title: 'Surah',
        url: 'url',
        filePath: 'path',
        reciterName: 'reciter',
        reciterId: 1,
        status: DownloadStatus.pending,
        progress: 0,
        fileSize: 0,
        downloadedSize: 0,
        createdAt: DateTime.now(),
      ),
    );
  });

  DownloadItem createTestDownload({
    String id = '1',
    String url = 'url',
    DownloadStatus status = DownloadStatus.pending,
    double progress = 0,
  }) {
    return DownloadItem(
      id: id,
      title: 'Surah 1',
      url: url,
      filePath: '/path',
      reciterName: 'reciter',
      reciterId: 1,
      status: status,
      progress: progress,
      fileSize: 100,
      downloadedSize: (100 * progress).round(),
      createdAt: DateTime.now(),
    );
  }

  test('handle MissingPluginException gracefully', () async {
    when(
      () => mockDownloadService.getActiveDownloadIds(),
    ).thenThrow(MissingPluginException());

    final List<DownloadItem> result = await synchronizer.syncDownloadStatuses(
      [],
    );

    expect(result, isEmpty);
    verify(() => mockDownloadService.getActiveDownloadIds()).called(1);
  });

  test('handles generic exception when getting active downloads', () async {
    when(
      () => mockDownloadService.getActiveDownloadIds(),
    ).thenThrow(Exception('Network error'));

    final List<DownloadItem> result = await synchronizer.syncDownloadStatuses(
      [],
    );

    expect(result, isEmpty);
    verify(() => mockDownloadService.getActiveDownloadIds()).called(1);
  });

  test('handles exception when checking queue status', () async {
    when(
      () => mockDownloadService.getActiveDownloadIds(),
    ).thenAnswer((_) async => []);

    final DownloadItem download = createTestDownload();

    when(
      () => mockDownloadQueueManager.isQueued('1'),
    ).thenThrow(Exception('Queue error'));

    // Mock recovery service for orphaned download that will be called
    when(
      () => mockDownloadRecoveryService.handleOrphanedDownload(
        any(),
        isQueued: any(named: 'isQueued'),
        isActive: any(named: 'isActive'),
      ),
    ).thenAnswer((i) async => i.positionalArguments[0] as DownloadItem);

    // Should handle gracefully and continue
    final List<DownloadItem> result = await synchronizer.syncDownloadStatuses([
      download,
    ]);

    // Should still process downloads
    expect(result.length, 1);
  });

  test('syncs status for queued items', () async {
    when(
      () => mockDownloadService.getActiveDownloadIds(),
    ).thenAnswer((_) async => []);

    final DownloadItem download = createTestDownload(
      status: DownloadStatus.paused, // Should update to pending
    );

    when(() => mockDownloadQueueManager.isQueued('1')).thenReturn(true);

    final List<DownloadItem> result = await synchronizer.syncDownloadStatuses([
      download,
    ]);

    expect(result.length, 1);
    expect(result.first.status, DownloadStatus.pending);
  });

  test('syncs status for active items not already downloading', () async {
    when(
      () => mockDownloadService.getActiveDownloadIds(),
    ).thenAnswer((_) async => ['url']);

    final DownloadItem download = createTestDownload();

    when(() => mockDownloadQueueManager.isQueued('1')).thenReturn(false);

    final List<DownloadItem> result = await synchronizer.syncDownloadStatuses([
      download,
    ]);

    expect(result.length, 1);
    expect(result.first.status, DownloadStatus.downloading);
  });

  test('handles stuck download for active downloading items', () async {
    when(
      () => mockDownloadService.getActiveDownloadIds(),
    ).thenAnswer((_) async => ['url']);

    final DownloadItem download = createTestDownload(
      status: DownloadStatus.downloading, // Already downloading
    );

    when(() => mockDownloadQueueManager.isQueued('1')).thenReturn(false);
    when(
      () => mockDownloadRecoveryService.handleStuckDownload(any()),
    ).thenAnswer((i) async => i.positionalArguments[0] as DownloadItem);

    final List<DownloadItem> result = await synchronizer.syncDownloadStatuses([
      download,
    ]);

    expect(result.length, 1);
    verify(
      () => mockDownloadRecoveryService.handleStuckDownload(any()),
    ).called(1);
  });

  test('recovers orphaned pending downloads', () async {
    when(
      () => mockDownloadService.getActiveDownloadIds(),
    ).thenAnswer((_) async => []);

    final DownloadItem download = createTestDownload();

    when(() => mockDownloadQueueManager.isQueued('1')).thenReturn(false);
    when(
      () => mockDownloadRecoveryService.handleOrphanedDownload(
        any(),
        isQueued: any(named: 'isQueued'),
        isActive: any(named: 'isActive'),
      ),
    ).thenAnswer((i) async => i.positionalArguments[0] as DownloadItem);

    final List<DownloadItem> result = await synchronizer.syncDownloadStatuses([
      download,
    ]);

    expect(result.length, 1);
    verify(
      () => mockDownloadRecoveryService.handleOrphanedDownload(
        any(),
        isQueued: false,
        isActive: false,
      ),
    ).called(1);
  });

  test('checks background status for non-active downloads', () async {
    when(
      () => mockDownloadService.getActiveDownloadIds(),
    ).thenAnswer((_) async => []);

    final DownloadItem download = createTestDownload(
      status: DownloadStatus.downloading, // Downloading but not active
    );

    when(() => mockDownloadQueueManager.isQueued('1')).thenReturn(false);
    when(
      () => mockDownloadRecoveryService.checkBackgroundStatus(any()),
    ).thenAnswer((i) async => i.positionalArguments[0] as DownloadItem);

    final List<DownloadItem> result = await synchronizer.syncDownloadStatuses([
      download,
    ]);

    expect(result.length, 1);
    verify(
      () => mockDownloadRecoveryService.checkBackgroundStatus(any()),
    ).called(1);
  });

  test(
    'calls checkBackgroundStatus for pending queued download when not active',
    () async {
      when(
        () => mockDownloadService.getActiveDownloadIds(),
      ).thenAnswer((_) async => []);

      final DownloadItem download = createTestDownload();

      when(() => mockDownloadQueueManager.isQueued('1')).thenReturn(true);
      when(
        () => mockDownloadRecoveryService.checkBackgroundStatus(any()),
      ).thenAnswer((i) async => i.positionalArguments[0] as DownloadItem);

      // When queued and already pending, checkBackgroundStatus is called
      // because the download is not active
      final List<DownloadItem> result = await synchronizer.syncDownloadStatuses(
        [download],
      );

      expect(result.length, 1);
      // Status should remain pending since it's already pending and queued
      expect(result.first.status, DownloadStatus.pending);
      // checkBackgroundStatus is called because not active
      verify(
        () => mockDownloadRecoveryService.checkBackgroundStatus(any()),
      ).called(1);
    },
  );

  test('processes multiple downloads with different states', () async {
    when(
      () => mockDownloadService.getActiveDownloadIds(),
    ).thenAnswer((_) async => ['url2']);

    final DownloadItem download1 = createTestDownload(
      url: 'url1',
      status: DownloadStatus.paused,
    );
    final DownloadItem download2 = createTestDownload(id: '2', url: 'url2');
    final DownloadItem download3 = createTestDownload(
      id: '3',
      url: 'url3',
      status: DownloadStatus.downloading,
    );

    when(() => mockDownloadQueueManager.isQueued('1')).thenReturn(true);
    when(() => mockDownloadQueueManager.isQueued('2')).thenReturn(false);
    when(() => mockDownloadQueueManager.isQueued('3')).thenReturn(false);

    when(
      () => mockDownloadRecoveryService.checkBackgroundStatus(any()),
    ).thenAnswer((i) async => i.positionalArguments[0] as DownloadItem);

    final List<DownloadItem> result = await synchronizer.syncDownloadStatuses([
      download1,
      download2,
      download3,
    ]);

    expect(result.length, 3);
    // download1: queued, paused -> pending
    expect(result[0].status, DownloadStatus.pending);
    // download2: active -> downloading
    expect(result[1].status, DownloadStatus.downloading);
    // download3: not active, downloading -> checked background
    verify(
      () => mockDownloadRecoveryService.checkBackgroundStatus(any()),
    ).called(1);
  });
}
