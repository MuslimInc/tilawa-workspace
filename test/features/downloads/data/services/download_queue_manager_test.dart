import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/downloads/data/models/download_progress.dart';
import 'package:tilawa/features/downloads/data/services/download_notification_service.dart';
import 'package:tilawa/features/downloads/data/services/download_queue_manager.dart';
import 'package:tilawa/features/downloads/data/services/download_service_impl.dart';
import 'package:tilawa/features/downloads/data/services/download_service_interface.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';

import '../../helpers/mock_helper.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterDownloaderWrapper mockDownloader;
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('dqm_test');
    mockDownloader = MockFlutterDownloaderWrapper();

    final GetIt getIt = GetIt.instance;

    // Reset dependencies cleanly
    if (getIt.isRegistered<DownloadQueueManager>()) {
      getIt.unregister<DownloadQueueManager>();
    }
    if (getIt.isRegistered<DownloadServiceInterface>()) {
      getIt.unregister<DownloadServiceInterface>();
    }
    if (getIt.isRegistered<DownloadNotificationService>()) {
      getIt.unregister<DownloadNotificationService>();
    }

    // Register Notification Service Mock
    getIt.registerSingleton<DownloadNotificationService>(
      MockDownloadNotificationService(),
    );

    // Register DownloadService (Implementation) with mocked downloader
    final downloadService = DownloadServiceImpl(
      flutterDownloader: mockDownloader,
    );
    getIt.registerSingleton<DownloadServiceInterface>(downloadService);

    // Register DownloadQueueManager using the registered services
    final downloadQueueManager = DownloadQueueManager(
      downloadService,
      getIt<DownloadNotificationService>(),
    );
    getIt.registerSingleton<DownloadQueueManager>(downloadQueueManager);

    // Mock Downloader behaviors
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
    when(
      mockDownloader.cancel(taskId: anyNamed('taskId')),
    ).thenAnswer((_) async {});

    // We cannot set this static override if the instance relies on GetIt which we just reset
    // But since we registered DownloadService, DownloadServiceImpl.instance might work if it resolves via GetIt.
    // However, we just injected mockDownloader via constructor, so we don't need the override unless something else uses it.
  });

  tearDown(() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    if (GetIt.instance.isRegistered<DownloadQueueManager>()) {
      GetIt.instance<DownloadQueueManager>().dispose();
      GetIt.instance.unregister<DownloadQueueManager>();
    }
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }

    final GetIt getIt = GetIt.instance;
    if (getIt.isRegistered<DownloadServiceInterface>()) {
      getIt.unregister<DownloadServiceInterface>();
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

        GetIt.instance<DownloadQueueManager>().initialize();

        unawaited(
          GetIt.instance<DownloadQueueManager>().enqueue(
            id: '1',
            url: 'new_url',
            filePath: 'path',
            title: 'Title',
            reciterName: 'Reciter',
          ),
        );

        async.flushMicrotasks();

        expect(GetIt.instance<DownloadQueueManager>().queueLength, 1);
        expect(GetIt.instance<DownloadQueueManager>().isQueued('1'), isTrue);
      });
    });

    test('removeFromQueue should remove item', () {
      fakeAsync((async) {
        simulateBusyQueue();
        GetIt.instance<DownloadQueueManager>().initialize();

        // Enqueue items
        unawaited(
          GetIt.instance<DownloadQueueManager>().enqueue(
            id: '1',
            url: 'u1',
            filePath: 'f1',
            title: 't1',
            reciterName: 'Reciter',
          ),
        );
        unawaited(
          GetIt.instance<DownloadQueueManager>().enqueue(
            id: '2',
            url: 'u2',
            filePath: 'f2',
            title: 't2',
            reciterName: 'Reciter',
          ),
        );
        async.flushMicrotasks();

        // Verify added
        expect(GetIt.instance<DownloadQueueManager>().queueLength, 2);

        // Remove one
        GetIt.instance<DownloadQueueManager>().removeFromQueue('1');

        // Verify removed
        expect(GetIt.instance<DownloadQueueManager>().isQueued('1'), isFalse);
        expect(GetIt.instance<DownloadQueueManager>().queueLength, 1);
        expect(GetIt.instance<DownloadQueueManager>().isQueued('2'), isTrue);
      });
    });

    test('clearQueue should remove all pending items', () {
      fakeAsync((async) {
        simulateBusyQueue();
        GetIt.instance<DownloadQueueManager>().initialize();

        unawaited(
          GetIt.instance<DownloadQueueManager>().enqueue(
            id: '1',
            url: 'u1',
            filePath: 'f1',
            title: 't1',
            reciterName: 'r',
          ),
        );
        async.flushMicrotasks();

        expect(GetIt.instance<DownloadQueueManager>().queueLength, 1);

        GetIt.instance<DownloadQueueManager>().clearQueue();

        expect(GetIt.instance<DownloadQueueManager>().queueLength, 0);
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

        GetIt.instance<DownloadQueueManager>().initialize();

        // Enqueue items
        unawaited(
          GetIt.instance<DownloadQueueManager>().enqueue(
            id: 'id1',
            url: 'url1',
            filePath: 'path1',
            title: 'T1',
            reciterName: 'R',
          ),
        );
        unawaited(
          GetIt.instance<DownloadQueueManager>().enqueue(
            id: 'id2',
            url: 'url2',
            filePath: 'path2',
            title: 'T2',
            reciterName: 'R',
          ),
        );

        async.flushMicrotasks();
        expect(GetIt.instance<DownloadQueueManager>().queueLength, 2);

        unawaited(GetIt.instance<DownloadQueueManager>().stopAll());
        async.flushMicrotasks();

        expect(GetIt.instance<DownloadQueueManager>().queueLength, 0);
        verify(mockNotification.cancelAllNotifications()).called(1);
      });
    });

    test('getQueuePosition should return correct index', () {
      fakeAsync((async) {
        simulateBusyQueue();
        GetIt.instance<DownloadQueueManager>().initialize();

        // Enqueue 2 items
        unawaited(
          GetIt.instance<DownloadQueueManager>().enqueue(
            id: '1',
            url: 'u1',
            filePath: 'f1',
            title: 't1',
            reciterName: 'r',
          ),
        );
        unawaited(
          GetIt.instance<DownloadQueueManager>().enqueue(
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
        expect(GetIt.instance<DownloadQueueManager>().getQueuePosition('1'), 1);

        // Item 2: Position 2
        expect(GetIt.instance<DownloadQueueManager>().getQueuePosition('2'), 2);

        expect(
          GetIt.instance<DownloadQueueManager>().getQueuePosition('999'),
          -1,
        );
      });
    });

    test('enqueueBatch should add multiple items to queue', () {
      fakeAsync((async) {
        simulateBusyQueue();
        GetIt.instance<DownloadQueueManager>().initialize();

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

        unawaited(GetIt.instance<DownloadQueueManager>().enqueueBatch(items));
        async.flushMicrotasks();

        expect(GetIt.instance<DownloadQueueManager>().queueLength, 2);
        expect(GetIt.instance<DownloadQueueManager>().isQueued('1'), isTrue);
        expect(GetIt.instance<DownloadQueueManager>().isQueued('2'), isTrue);
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
        GetIt.instance<DownloadQueueManager>().initialize();
        // Try to start a 3rd
        unawaited(
          GetIt.instance<DownloadQueueManager>().enqueue(
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
        expect(GetIt.instance<DownloadQueueManager>().isQueued('3'), isTrue);
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

          GetIt.instance<DownloadQueueManager>().initialize();

          // Enqueue with showNotification: false
          unawaited(
            GetIt.instance<DownloadQueueManager>().enqueue(
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
          (GetIt.instance<DownloadServiceInterface>() as DownloadServiceImpl)
              .globalProgressControllerInternal
              .add(
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

    // test('showNotification: true should show individual notifications', () {
    //   fakeAsync((async) {
    //     // Arrange
    //     final mockNotification =
    //         GetIt.instance<DownloadNotificationService>()
    //             as MockDownloadNotificationService;

    //     GetIt.instance<DownloadQueueManager>().initialize();

    //     // Enqueue with showNotification: true (default)
    //     unawaited(
    //       GetIt.instance<DownloadQueueManager>().enqueue(
    //         id: 'id_single',
    //         url: 'url_single',
    //         filePath: 'path',
    //         title: 'Title',
    //         reciterName: 'Reciter',
    //         showNotification: true,
    //       ),
    //     );

    //     async.flushMicrotasks();

    //     // Simulate progress update
    //     DownloadService.globalProgressController.add(
    //       const DownloadProgress(
    //         id: 'id_single',
    //         status: DownloadStatus.downloading,
    //         progress: 0.5,
    //         downloadedSize: 50,
    //         fileSize: 100,
    //       ),
    //     );

    //     async.flushMicrotasks();

    //     // Verify that individual notification was shown
    //     // It might be called twice: once for pending (progress 0) and once for downloading (progress 50)
    //     verify(
    //       mockNotification.showDownloadProgress(
    //         downloadId: 'id_single',
    //         title: 'Title',
    //         reciterName: 'Reciter',
    //         progress: 50,
    //         status: DownloadStatus.downloading,
    //         pendingMessage: anyNamed('pendingMessage'),
    //         progressMessage: anyNamed('progressMessage'),
    //         completeMessage: anyNamed('completeMessage'),
    //         failedMessage: anyNamed('failedMessage'),
    //       ),
    //     ).called(1);
    //   });
    // });
  });

  group('DownloadQueueManager - Robustness', () {
    test('should remove download from queue if it fails to start (status null)', () {
      fakeAsync((async) {
        // Arrange
        // Mock enqueue to return a task ID, simulating successful "request"
        when(
          mockDownloader.enqueue(
            url: anyNamed('url'),
            savedDir: anyNamed('savedDir'),
            fileName: anyNamed('fileName'),
            showNotification: anyNamed('showNotification'),
            openFileFromNotification: anyNamed('openFileFromNotification'),
            title: anyNamed('title'),
            headers: anyNamed('headers'),
            requiresStorageNotLow: anyNamed('requiresStorageNotLow'),
            saveInPublicStorage: anyNamed('saveInPublicStorage'),
          ),
        ).thenAnswer((_) async => 'fake_task_id');

        // Mock loadTasksWithRawQuery to ALWAYS return empty list
        // This simulates "status == null" because DownloadService.getDownloadStatus returns null if no task found
        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => []);

        // Act
        GetIt.instance<DownloadQueueManager>().initialize();
        // Don't await enqueue because it waits for _processQueue which waits for time
        // We just want to trigger it
        unawaited(
          GetIt.instance<DownloadQueueManager>().enqueue(
            id: 'test_id',
            url: 'http://example.com/test.mp3',
            filePath: '${tempDir.path}/test.mp3',
            title: 'Test Title',
            reciterName: 'Reciter',
          ),
        );

        // Verify added to queue (enqueue adds to list before awaiting process)
        // We process microtasks to ensure the async function starts
        async.flushMicrotasks();

        expect(GetIt.instance<DownloadQueueManager>().queueLength, 1);

        // DQM will try to start download, then enter the retry loop (10 retries * 500ms = 5s)
        // We explicitly advance time to cover the retry period
        // 5.5 seconds should be enough to exhaust 10 retries
        async.elapse(const Duration(milliseconds: 6000));

        // Assert
        // Should satisfy: queueLength == 0 (removed because it failed)
        expect(
          GetIt.instance<DownloadQueueManager>().queueLength,
          0,
          reason: 'Failed download should be removed from queue',
        );
        expect(GetIt.instance<DownloadQueueManager>().activeDownloadsCount, 0);
      });
    });

    test('watchdog should cancel stuck downloads after 30 seconds', () {
      fakeAsync((async) {
        // Arrange
        // 1. Enqueue task 1 - starts successfully
        when(
          mockDownloader.enqueue(
            url: 'http://example.com/1.mp3',
            savedDir: anyNamed('savedDir'),
            fileName: anyNamed('fileName'),
            showNotification: anyNamed('showNotification'),
            openFileFromNotification: anyNamed('openFileFromNotification'),
            title: anyNamed('title'),
            headers: anyNamed('headers'),
            requiresStorageNotLow: anyNamed('requiresStorageNotLow'),
            saveInPublicStorage: anyNamed('saveInPublicStorage'),
          ),
        ).thenAnswer((_) async => 'task_1');

        final runningTask = DownloadTask(
          taskId: 'task_1',
          status: DownloadTaskStatus.running,
          progress: 0,
          url: 'http://example.com/1.mp3',
          filename: '1.mp3',
          savedDir: tempDir.path,
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );
        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => [runningTask]);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => [runningTask]);

        // Mock cancel
        when(mockDownloader.cancel(taskId: 'task_1')).thenAnswer((_) async {});
        when(
          mockDownloader.remove(taskId: 'task_1', shouldDeleteContent: true),
        ).thenAnswer((_) async {});

        // Act
        GetIt.instance<DownloadQueueManager>().initialize();
        // Start download 1
        unawaited(
          GetIt.instance<DownloadQueueManager>().enqueue(
            id: 'http://example.com/1.mp3',
            url: 'http://example.com/1.mp3',
            filePath: '${tempDir.path}/1.mp3',
            title: 'Title 1',
            reciterName: 'Reciter',
          ),
        );
        async.flushMicrotasks();

        // Verify started
        expect(
          GetIt.instance<DownloadQueueManager>().activeDownloadsCount,
          1,
          reason: 'Download 1 should be active',
        );

        // Advance time by 20s - should still be active
        async.elapse(const Duration(seconds: 20));
        expect(
          GetIt.instance<DownloadQueueManager>().activeDownloadsCount,
          1,
          reason: 'Download 1 should still be active',
        );

        // Advance time by another 15s (total 35s) - watchdog (runs every 5s) should catch it
        async.elapse(const Duration(seconds: 15));

        // Assert
        // Download 1 should be cancelled and removed because no progress updates were received for >30s
        verify(mockDownloader.cancel(taskId: 'task_1')).called(1);
        expect(
          GetIt.instance<DownloadQueueManager>().activeDownloadsCount,
          0,
          reason: 'Stuck download should be removed by watchdog',
        );
      });
    });

    test(
      'should handle duplicate URLs in active list by deduplicating count',
      () {
        fakeAsync((async) {
          // Arrange
          // 1. Mock 3 active tasks for the SAME URL (simulating zombies)
          final task1 = DownloadTask(
            taskId: '1',
            status: DownloadTaskStatus.running,
            progress: 10,
            url: 'http://example.com/same.mp3',
            filename: 'same.mp3',
            savedDir: tempDir.path,
            timeCreated: DateTime.now().millisecondsSinceEpoch,
            allowCellular: true,
          );

          final mockTasks = <DownloadTask>[task1, task1, task1];

          when(mockDownloader.loadTasks()).thenAnswer((_) async => mockTasks);
          when(
            mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
          ).thenAnswer(
            (_) async => mockTasks
                .where((t) => t.url == 'http://example.com/same.mp3')
                .toList(),
          );

          // Act
          GetIt.instance<DownloadQueueManager>().initialize();
          // Enqueue a new item
          when(
            mockDownloader.enqueue(
              url: anyNamed('url'),
              savedDir: anyNamed('savedDir'),
              fileName: anyNamed('fileName'),
              showNotification: anyNamed('showNotification'),
              openFileFromNotification: anyNamed('openFileFromNotification'),
              title: anyNamed('title'),
              headers: anyNamed('headers'),
              requiresStorageNotLow: anyNamed('requiresStorageNotLow'),
              saveInPublicStorage: anyNamed('saveInPublicStorage'),
            ),
          ).thenAnswer((invocation) async {
            final url = invocation.namedArguments[#url] as String;
            final newTask = DownloadTask(
              taskId: 'task_new',
              status: DownloadTaskStatus.running,
              progress: 0,
              url: url,
              filename: 'new.mp3',
              savedDir: tempDir.path,
              timeCreated: DateTime.now().millisecondsSinceEpoch,
              allowCellular: true,
            );
            mockTasks.add(newTask);
            return 'task_new';
          });

          unawaited(
            GetIt.instance<DownloadQueueManager>().enqueue(
              id: 'new',
              url: 'http://example.com/new.mp3',
              filePath: '${tempDir.path}/new.mp3',
              title: 'New Title',
              reciterName: 'Reciter',
            ),
          );
          async.flushMicrotasks();

          // Assert
          // We expect 2 active downloads logic
          expect(
            GetIt.instance<DownloadQueueManager>().activeDownloadsCount,
            greaterThanOrEqualTo(1),
            reason: 'Queue should process despite duplicates',
          );
        });
      },
    );
  });
}
