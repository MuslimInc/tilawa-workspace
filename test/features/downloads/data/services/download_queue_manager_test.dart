import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/data/services/download_notification_service.dart';
import 'package:muzakri/features/downloads/data/services/download_queue_manager.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/data/services/flutter_downloader_wrapper.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';

import 'download_queue_manager_test.mocks.dart';

@GenerateMocks([FlutterDownloaderWrapper, DownloadNotificationService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterDownloaderWrapper mockDownloader;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dqm_test');
    mockDownloader = MockFlutterDownloaderWrapper();
    DownloadService.flutterDownloaderTestOverride = mockDownloader;

    // Register DownloadService in GetIt
    final GetIt getIt = GetIt.instance;
    if (!getIt.isRegistered<DownloadService>()) {
      getIt.registerSingleton<DownloadService>(DownloadService.instance);
    }
    if (!getIt.isRegistered<DownloadNotificationService>()) {
      getIt.registerSingleton<DownloadNotificationService>(
        MockDownloadNotificationService(),
      );
    }

    // Default stubbing
    when(mockDownloader.initialize(debug: anyNamed('debug'))).thenAnswer((
      _,
    ) async {
      return;
    });
    when(
      mockDownloader.registerCallback(any, step: anyNamed('step')),
    ).thenAnswer((_) async {
      return;
    });
    when(mockDownloader.loadTasks()).thenAnswer((_) async => []);
    when(
      mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
    ).thenAnswer((_) async => []);
    when(
      mockDownloader.enqueue(
        url: anyNamed('url'),
        savedDir: anyNamed('savedDir'),
        fileName: anyNamed('fileName'),
        headers: anyNamed('headers'),
        showNotification: anyNamed('showNotification'),
        openFileFromNotification: anyNamed('openFileFromNotification'),
        requiresStorageNotLow: anyNamed('requiresStorageNotLow'),
        saveInPublicStorage: anyNamed('saveInPublicStorage'),
        title: anyNamed('title'),
      ),
    ).thenAnswer((_) async => 'mock_task_id');

    DownloadQueueManager.reset();
    unawaited(DownloadService.reset());
  });

  tearDown(() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    DownloadQueueManager.instance.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }

    final GetIt getIt = GetIt.instance;
    if (getIt.isRegistered<DownloadService>()) {
      getIt.unregister<DownloadService>();
    }
    if (getIt.isRegistered<DownloadNotificationService>()) {
      getIt.unregister<DownloadNotificationService>();
    }
  });

  group('DownloadQueueManager - Queue Operations', () {
    // Helper to simulate busy queue
    void simulateBusyQueue() {
      final task1 = DownloadTask(
        taskId: 't1',
        status: DownloadTaskStatus.running,
        progress: 10,
        url: 'u1',
        filename: 'f1',
        savedDir: '/',
        timeCreated: 0,
        allowCellular: true,
      );
      final task2 = DownloadTask(
        taskId: 't2',
        status: DownloadTaskStatus.running,
        progress: 10,
        url: 'u2',
        filename: 'f2',
        savedDir: '/',
        timeCreated: 0,
        allowCellular: true,
      );
      when(mockDownloader.loadTasks()).thenAnswer((_) async => [task1, task2]);
      // Ensure specific queries for new items return empty so they are not seen as running
      when(
        mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
      ).thenAnswer((_) async => []);
    }

    test('enqueue should add item to queue', () {
      fakeAsync((async) {
        simulateBusyQueue();

        DownloadQueueManager.instance.initialize();

        unawaited(
          DownloadQueueManager.instance.enqueue(
            id: '1',
            url: 'new_url',
            filePath: 'path',
            title: 'Title',
            reciterName: 'Reciter',
          ),
        );

        async.flushMicrotasks();

        expect(DownloadQueueManager.instance.queueLength, 1);
        expect(DownloadQueueManager.instance.isQueued('1'), isTrue);
      });
    });

    test('removeFromQueue should remove item', () {
      fakeAsync((async) {
        simulateBusyQueue();
        DownloadQueueManager.instance.initialize();

        // Enqueue items
        unawaited(
          DownloadQueueManager.instance.enqueue(
            id: '1',
            url: 'u1',
            filePath: 'f1',
            title: 't1',
            reciterName: 'Reciter',
          ),
        );
        unawaited(
          DownloadQueueManager.instance.enqueue(
            id: '2',
            url: 'u2',
            filePath: 'f2',
            title: 't2',
            reciterName: 'Reciter',
          ),
        );
        async.flushMicrotasks();

        // Verify added
        expect(DownloadQueueManager.instance.queueLength, 2);

        // Remove one
        DownloadQueueManager.instance.removeFromQueue('1');

        // Verify removed
        expect(DownloadQueueManager.instance.isQueued('1'), isFalse);
        expect(DownloadQueueManager.instance.queueLength, 1);
        expect(DownloadQueueManager.instance.isQueued('2'), isTrue);
      });
    });

    test('clearQueue should remove all pending items', () {
      fakeAsync((async) {
        simulateBusyQueue();
        DownloadQueueManager.instance.initialize();

        unawaited(
          DownloadQueueManager.instance.enqueue(
            id: '1',
            url: 'u1',
            filePath: 'f1',
            title: 't1',
            reciterName: 'r',
          ),
        );
        async.flushMicrotasks();

        expect(DownloadQueueManager.instance.queueLength, 1);

        DownloadQueueManager.instance.clearQueue();

        expect(DownloadQueueManager.instance.queueLength, 0);
      });
    });

    test('stopAll should clear queue and cancel notifications', () {
      fakeAsync((async) {
        final mockNotification =
            GetIt.instance<DownloadNotificationService>()
                as MockDownloadNotificationService;
        when(
          mockNotification.cancelAllNotifications(),
        ).thenAnswer((_) async {});

        DownloadQueueManager.instance.initialize();

        // Enqueue items
        unawaited(
          DownloadQueueManager.instance.enqueue(
            id: 'id1',
            url: 'url1',
            filePath: 'path1',
            title: 'T1',
            reciterName: 'R',
          ),
        );
        unawaited(
          DownloadQueueManager.instance.enqueue(
            id: 'id2',
            url: 'url2',
            filePath: 'path2',
            title: 'T2',
            reciterName: 'R',
          ),
        );

        async.flushMicrotasks();
        expect(DownloadQueueManager.instance.queueLength, 2);

        unawaited(DownloadQueueManager.instance.stopAll());
        async.flushMicrotasks();

        expect(DownloadQueueManager.instance.queueLength, 0);
        verify(mockNotification.cancelAllNotifications()).called(1);
      });
    });

    test('getQueuePosition should return correct index', () {
      fakeAsync((async) {
        simulateBusyQueue();
        DownloadQueueManager.instance.initialize();

        // Enqueue 2 items
        unawaited(
          DownloadQueueManager.instance.enqueue(
            id: '1',
            url: 'u1',
            filePath: 'f1',
            title: 't1',
            reciterName: 'r',
          ),
        );
        unawaited(
          DownloadQueueManager.instance.enqueue(
            id: '2',
            url: 'u2',
            filePath: 'f2',
            title: 't2',
            reciterName: 'r',
          ),
        );
        async.flushMicrotasks();

        // Verify positions
        // Item 1: Position 1
        expect(DownloadQueueManager.instance.getQueuePosition('1'), 1);

        // Item 2: Position 2
        expect(DownloadQueueManager.instance.getQueuePosition('2'), 2);

        expect(DownloadQueueManager.instance.getQueuePosition('999'), -1);
      });
    });

    test('enqueueBatch should add multiple items to queue', () {
      fakeAsync((async) {
        simulateBusyQueue();
        DownloadQueueManager.instance.initialize();

        final List<
          ({
            String filePath,
            String id,
            int reciterId,
            String reciterName,
            String title,
            String url,
            bool showNotification,
          })
        >
        items = [
          (
            id: '1',
            url: 'u1',
            filePath: 'f1',
            title: 't1',
            reciterName: 'r',
            reciterId: 1,
            showNotification: true,
          ),
          (
            id: '2',
            url: 'u2',
            filePath: 'f2',
            title: 't2',
            reciterName: 'r',
            reciterId: 1,
            showNotification: true,
          ),
        ];

        unawaited(DownloadQueueManager.instance.enqueueBatch(items));
        async.flushMicrotasks();

        expect(DownloadQueueManager.instance.queueLength, 2);
        expect(DownloadQueueManager.instance.isQueued('1'), isTrue);
        expect(DownloadQueueManager.instance.isQueued('2'), isTrue);
      });
    });
  });

  group('DownloadQueueManager - Concurrency', () {
    test('should respect maxConcurrentDownloads', () {
      fakeAsync((async) {
        // Arrange
        // Simulate 2 running tasks
        when(mockDownloader.loadTasks()).thenAnswer(
          (_) async => [
            DownloadTask(
              taskId: 't1',
              status: DownloadTaskStatus.running,
              progress: 0,
              url: 'u1',
              filename: 'f1',
              savedDir: '/',
              timeCreated: 0,
              allowCellular: true,
            ),
            DownloadTask(
              taskId: 't2',
              status: DownloadTaskStatus.running,
              progress: 0,
              url: 'u2',
              filename: 'f2',
              savedDir: '/',
              timeCreated: 0,
              allowCellular: true,
            ),
          ],
        );
        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer(
          (_) async => [
            DownloadTask(
              taskId: 't1',
              status: DownloadTaskStatus.running,
              progress: 0,
              url: 'u1',
              filename: 'f1',
              savedDir: '/',
              timeCreated: 0,
              allowCellular: true,
            ),
          ],
        );

        // Act
        DownloadQueueManager.instance.initialize();
        // Try to start a 3rd
        unawaited(
          DownloadQueueManager.instance.enqueue(
            id: '3',
            url: 'u3',
            filePath: 'f3',
            title: 't3',
            reciterName: 'r',
          ),
        );
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));

        // Verify
        // Should NOT have called enqueue on downloader for #3
        verifyNever(
          mockDownloader.enqueue(
            url: 'u3',
            savedDir: anyNamed('savedDir'),
            fileName: anyNamed('fileName'),
            headers: anyNamed('headers'),
            showNotification: anyNamed('showNotification'),
            openFileFromNotification: anyNamed('openFileFromNotification'),
            requiresStorageNotLow: anyNamed('requiresStorageNotLow'),
            saveInPublicStorage: anyNamed('saveInPublicStorage'),
            title: anyNamed('title'),
          ),
        );

        // Should be in queue
        expect(DownloadQueueManager.instance.isQueued('3'), isTrue);
      });
    });
  });

  group('DownloadQueueManager - Notification Suppression', () {
    test(
      'showNotification: false should suppress individual notifications',
      () {
        fakeAsync((async) {
          // Arrange
          final mockNotification =
              GetIt.instance<DownloadNotificationService>()
                  as MockDownloadNotificationService;

          DownloadQueueManager.instance.initialize();

          // Enqueue with showNotification: false
          unawaited(
            DownloadQueueManager.instance.enqueue(
              id: 'id_batch',
              url: 'url_batch',
              filePath: 'path',
              title: 'Title',
              reciterName: 'Reciter',
            ),
          );

          async.flushMicrotasks();

          // Simulate progress update
          // Use the same ID as enqueued
          DownloadService.globalProgressController.add(
            const DownloadProgress(
              id: 'id_batch',
              status: DownloadStatus.downloading,
              progress: 0.5,
              downloadedSize: 50,
              fileSize: 100,
            ),
          );

          async.flushMicrotasks();

          // Verify that no individual notification was shown
          verifyNever(
            mockNotification.showDownloadProgress(
              downloadId: anyNamed('downloadId'),
              title: anyNamed('title'),
              reciterName: anyNamed('reciterName'),
              progress: anyNamed('progress'),
              status: anyNamed('status'),
              pendingMessage: anyNamed('pendingMessage'),
              progressMessage: anyNamed('progressMessage'),
              completeMessage: anyNamed('completeMessage'),
              failedMessage: anyNamed('failedMessage'),
            ),
          );
        });
      },
    );

    test('showNotification: true should show individual notifications', () {
      fakeAsync((async) {
        // Arrange
        final mockNotification =
            GetIt.instance<DownloadNotificationService>()
                as MockDownloadNotificationService;

        DownloadQueueManager.instance.initialize();

        // Enqueue with showNotification: true (default)
        unawaited(
          DownloadQueueManager.instance.enqueue(
            id: 'id_single',
            url: 'url_single',
            filePath: 'path',
            title: 'Title',
            reciterName: 'Reciter',
            showNotification: true,
          ),
        );

        async.flushMicrotasks();

        // Simulate progress update
        DownloadService.globalProgressController.add(
          const DownloadProgress(
            id: 'id_single',
            status: DownloadStatus.downloading,
            progress: 0.5,
            downloadedSize: 50,
            fileSize: 100,
          ),
        );

        async.flushMicrotasks();

        // Verify that individual notification was shown
        // It might be called twice: once for pending (progress 0) and once for downloading (progress 50)
        verify(
          mockNotification.showDownloadProgress(
            downloadId: 'id_single',
            title: 'Title',
            reciterName: 'Reciter',
            progress: 50,
            status: DownloadStatus.downloading,
            pendingMessage: anyNamed('pendingMessage'),
            progressMessage: anyNamed('progressMessage'),
            completeMessage: anyNamed('completeMessage'),
            failedMessage: anyNamed('failedMessage'),
          ),
        ).called(1);
      });
    });
  });
}
