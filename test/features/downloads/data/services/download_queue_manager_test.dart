import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/data/services/download_queue_manager.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';

import 'download_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterDownloaderWrapper mockDownloader;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dqm_test');
    mockDownloader = MockFlutterDownloaderWrapper();
    DownloadService.flutterDownloaderTestOverride = mockDownloader;

    // Default stubbing
    when(
      mockDownloader.initialize(debug: anyNamed('debug')),
    ).thenAnswer((_) async {});
    when(
      mockDownloader.registerCallback(any, step: anyNamed('step')),
    ).thenAnswer((_) async {});
    when(mockDownloader.loadTasks()).thenAnswer((_) async => []);
    when(
      mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
    ).thenAnswer((_) async => []);

    DownloadQueueManager.reset();
  });

  tearDown(() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    DownloadQueueManager.instance.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
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

        // Non-existent
        expect(DownloadQueueManager.instance.getQueuePosition('999'), -1);
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
}
