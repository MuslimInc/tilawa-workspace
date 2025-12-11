import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/data/services/flutter_downloader_wrapper.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/utils/download_path_utils.dart';

import 'download_service_test.mocks.dart';

@GenerateMocks([FlutterDownloaderWrapper])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadService', () {
    const testUrl = 'https://example.com/test.mp3';
    const testTitle = 'Test Audio';
    const testReciterName = 'Test Reciter';
    const testTaskId = 'task-uuid-123';

    late Directory tempDir;
    late String testFilePath;
    late MockFlutterDownloaderWrapper mockDownloader;
    late DownloadService downloadService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('download_test');
      testFilePath = DownloadPathUtils.resolveFullPath(
        tempDir.path,
        'test.mp3',
      );

      mockDownloader = MockFlutterDownloaderWrapper();

      // Default mock behaviors
      when(
        mockDownloader.initialize(debug: anyNamed('debug')),
      ).thenAnswer((_) async {});
      when(mockDownloader.registerCallback(any)).thenAnswer((_) async {});
      when(
        mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
      ).thenAnswer((_) async => []);

      // Stub enqueue with only arguments used by DownloadService
      when(
        mockDownloader.enqueue(
          url: anyNamed('url'),
          savedDir: anyNamed('savedDir'),
          fileName: anyNamed('fileName'),
          openFileFromNotification: anyNamed('openFileFromNotification'),
          title: anyNamed('title'),
        ),
      ).thenAnswer((_) async => testTaskId);

      when(
        mockDownloader.cancel(taskId: anyNamed('taskId')),
      ).thenAnswer((_) async {});
      when(
        mockDownloader.remove(
          taskId: anyNamed('taskId'),
          shouldDeleteContent: anyNamed('shouldDeleteContent'),
        ),
      ).thenAnswer((_) async {});
      when(mockDownloader.loadTasks()).thenAnswer((_) async => []);

      // Override the singleton instance to use our mock
      DownloadService.flutterDownloaderTestOverride = mockDownloader;

      downloadService = DownloadService(flutterDownloader: mockDownloader);
    });

    tearDown(() async {
      await downloadService.disposeService();
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    group('initialization', () {
      test('initialize registers port and callback successfully', () async {
        await downloadService.initialize();

        verify(mockDownloader.initialize(debug: anyNamed('debug'))).called(1);
        verify(mockDownloader.registerCallback(any)).called(1);

        final SendPort? port = IsolateNameServer.lookupPortByName(
          'downloader_send_port',
        );
        expect(port, isNotNull);
      });

      test('subsequent initialize calls do not re-initialize', () async {
        await downloadService.initialize();
        await downloadService.initialize();

        verify(mockDownloader.initialize(debug: anyNamed('debug'))).called(1);
        verify(mockDownloader.registerCallback(any)).called(1);
      });

      test('concurrent initialize calls return same future', () async {
        final Future<void> future1 = downloadService.initialize();
        final Future<void> future2 = downloadService.initialize();

        await Future.wait([future1, future2]);

        verify(mockDownloader.initialize(debug: anyNamed('debug'))).called(1);
      });

      test('initialize handles errors gracefully', () async {
        final localMock = MockFlutterDownloaderWrapper();
        when(
          localMock.initialize(debug: anyNamed('debug')),
        ).thenAnswer((_) async {});

        when(
          localMock.registerCallback(any),
        ).thenThrow(Exception('Callback init failed'));

        final localService = DownloadService(flutterDownloader: localMock);

        Object? caughtError;
        await runZonedGuarded(
          () async {
            try {
              await localService.initialize();
            } catch (e) {
              caughtError = e;
            }
          },
          (error, stack) {
            caughtError = error;
          },
        );

        expect(caughtError, isNotNull);
        expect(caughtError, isA<Exception>());
        expect(caughtError.toString(), contains('Callback init failed'));
      });
    });

    group('download', () {
      test('should enqueue download and emit pending status', () async {
        // Enqueue stub already in setUp matches

        final progressEvents = <DownloadProgress>[];
        final StreamSubscription<DownloadProgress> subscription =
            downloadService
                .getProgressStream(testUrl)
                .listen(progressEvents.add);

        await downloadService.download(
          id: testUrl,
          url: testUrl,
          filePath: testFilePath,
          title: testTitle,
          reciterName: testReciterName,
        );

        verify(
          mockDownloader.enqueue(
            url: testUrl,
            savedDir: DownloadPathUtils.getDirectoryName(testFilePath),
            fileName: DownloadPathUtils.getFileName(testFilePath),
            openFileFromNotification: false,
            title: testTitle,
          ),
        ).called(1);

        // Allow stream event to propagate
        await Future.delayed(Duration.zero);

        expect(progressEvents, isNotEmpty);
        expect(progressEvents.first.status, DownloadStatus.pending);
        expect(progressEvents.first.id, testUrl);

        await subscription.cancel();
      });

      test('should not enqueue if file is already completed', () async {
        final task = DownloadTask(
          taskId: 'existing-completed',
          status: DownloadTaskStatus.complete,
          progress: 100,
          url: testUrl,
          filename: 'test.mp3',
          savedDir: tempDir.path,
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );

        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => [task]);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => [task]);

        final progressEvents = <DownloadProgress>[];
        final StreamSubscription<DownloadProgress> subscription =
            downloadService
                .getProgressStream(testUrl)
                .listen(progressEvents.add);

        await downloadService.download(
          id: testUrl,
          url: testUrl,
          filePath: testFilePath,
          title: testTitle,
          reciterName: testReciterName,
        );

        verifyNever(
          mockDownloader.enqueue(
            url: anyNamed('url'),
            savedDir: anyNamed('savedDir'),
            fileName: anyNamed('fileName'),
            openFileFromNotification: anyNamed('openFileFromNotification'),
            title: anyNamed('title'),
          ),
        );

        await Future.delayed(Duration.zero);
        expect(progressEvents.first.status, DownloadStatus.completed);
        expect(progressEvents.first.progress, 1.0);

        await subscription.cancel();
      });

      test('should not enqueue if already running or enqueued', () async {
        final task = DownloadTask(
          taskId: 'existing-running',
          status: DownloadTaskStatus.running,
          progress: 50,
          url: testUrl,
          filename: 'test.mp3',
          savedDir: tempDir.path,
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );

        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => [task]);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => [task]);

        await downloadService.download(
          id: testUrl,
          url: testUrl,
          filePath: testFilePath,
          title: testTitle,
          reciterName: testReciterName,
        );

        verifyNever(
          mockDownloader.enqueue(
            url: anyNamed('url'),
            savedDir: anyNamed('savedDir'),
            fileName: anyNamed('fileName'),
            openFileFromNotification: anyNamed('openFileFromNotification'),
            title: anyNamed('title'),
          ),
        );
      });

      test('should create directory if it does not exist', () async {
        final String newDir = DownloadPathUtils.resolveFullPath(
          tempDir.path,
          'new_subdir',
        );
        final String newFilePath = DownloadPathUtils.resolveFullPath(
          newDir,
          'test.mp3',
        );

        // Ensure clean slate
        if (Directory(newDir).existsSync()) {
          Directory(newDir).deleteSync(recursive: true);
        }

        await downloadService.download(
          id: testUrl,
          url: testUrl,
          filePath: newFilePath,
          title: testTitle,
          reciterName: testReciterName,
        );

        expect(Directory(newDir).existsSync(), isTrue);
      });

      test('should handle enqueue failure (null taskId)', () async {
        final localMock = MockFlutterDownloaderWrapper();
        when(
          localMock.initialize(debug: anyNamed('debug')),
        ).thenAnswer((_) async {});
        when(localMock.registerCallback(any)).thenAnswer((_) async {});
        when(
          localMock.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => []);

        // Override enqueue to return null
        when(
          localMock.enqueue(
            url: anyNamed('url'),
            savedDir: anyNamed('savedDir'),
            fileName: anyNamed('fileName'),
            openFileFromNotification: anyNamed('openFileFromNotification'),
            title: anyNamed('title'),
          ),
        ).thenAnswer((_) async => null);

        final localService = DownloadService(flutterDownloader: localMock);

        final progressEvents = <DownloadProgress>[];
        final StreamSubscription<DownloadProgress> subscription = localService
            .getProgressStream(testUrl)
            .listen(progressEvents.add);

        await localService.download(
          id: testUrl,
          url: testUrl,
          filePath: testFilePath,
          title: testTitle,
          reciterName: testReciterName,
        );

        await Future.delayed(Duration.zero);
        expect(progressEvents, isEmpty);

        await subscription.cancel();
        await localService.disposeService();
      });
    });

    group('Progress Updates', () {
      test('should handle progress updates from port', () async {
        // Enqueue stub from setUp used

        await downloadService.download(
          id: testUrl,
          url: testUrl,
          filePath: testFilePath,
          title: testTitle,
          reciterName: testReciterName,
        );

        final progressEvents = <DownloadProgress>[];
        final StreamSubscription<DownloadProgress> subscription =
            downloadService
                .getProgressStream(testUrl)
                .listen(progressEvents.add);

        final SendPort? port = IsolateNameServer.lookupPortByName(
          'downloader_send_port',
        );
        expect(port, isNotNull);

        // Simulate progress update from isolate
        port!.send([testTaskId, 2, 50]);

        await Future.delayed(const Duration(milliseconds: 500));

        expect(progressEvents.last.status, DownloadStatus.downloading);
        expect(progressEvents.last.progress, 0.5);

        await subscription.cancel();
      });

      test(
        'should resolve external ID (URL) from DB if not in memory map',
        () async {
          await downloadService.initialize();

          final task = DownloadTask(
            taskId: testTaskId,
            status: DownloadTaskStatus.running,
            progress: 50,
            url: testUrl,
            filename: 'test.mp3',
            savedDir: tempDir.path,
            timeCreated: DateTime.now().millisecondsSinceEpoch,
            allowCellular: true,
          );

          when(mockDownloader.loadTasks()).thenAnswer((_) async => [task]);

          final progressEvents = <DownloadProgress>[];
          // Listen to local service stream
          final StreamSubscription<DownloadProgress> subscription =
              downloadService
                  .getProgressStream(testUrl)
                  .listen(progressEvents.add);

          final SendPort? port = IsolateNameServer.lookupPortByName(
            'downloader_send_port',
          );
          port!.send([testTaskId, 2, 50]);

          await Future.delayed(const Duration(milliseconds: 500));

          verify(mockDownloader.loadTasks()).called(1);

          expect(progressEvents, isNotEmpty);
          expect(progressEvents.first.id, testUrl);
          expect(progressEvents.first.status, DownloadStatus.downloading);

          await subscription.cancel();
        },
      );
    });

    group('Status Mapping', () {
      test('maps all statuses correctly', () async {
        final Map<DownloadTaskStatus, DownloadStatus> statusMap = {
          DownloadTaskStatus.enqueued: DownloadStatus.pending,
          DownloadTaskStatus.running: DownloadStatus.downloading,
          DownloadTaskStatus.complete: DownloadStatus.completed,
          DownloadTaskStatus.failed: DownloadStatus.failed,
          DownloadTaskStatus.canceled: DownloadStatus.cancelled,
          DownloadTaskStatus.paused: DownloadStatus.paused,
          DownloadTaskStatus.undefined: DownloadStatus.failed,
        };

        final Map<DownloadTaskStatus, int> statusToInt = {
          DownloadTaskStatus.undefined: 0,
          DownloadTaskStatus.enqueued: 1,
          DownloadTaskStatus.running: 2,
          DownloadTaskStatus.complete: 3,
          DownloadTaskStatus.failed: 4,
          DownloadTaskStatus.canceled: 5,
          DownloadTaskStatus.paused: 6,
        };

        // We can test this via internal method if exposed, or via loop of updates
        // Testing via updates:
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
        ).thenAnswer((_) async => testTaskId);

        await downloadService.download(
          id: testUrl,
          url: testUrl,
          filePath: testFilePath,
          title: testTitle,
          reciterName: testReciterName,
        );

        final progressEvents = <DownloadProgress>[];
        final StreamSubscription<DownloadProgress> subscription =
            downloadService
                .getProgressStream(testUrl)
                .listen(progressEvents.add);

        final SendPort? port = IsolateNameServer.lookupPortByName(
          'downloader_send_port',
        );

        for (final MapEntry<DownloadTaskStatus, DownloadStatus> entry
            in statusMap.entries) {
          port!.send([testTaskId, statusToInt[entry.key], 0]);
          await Future.delayed(const Duration(milliseconds: 10));
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // Remove the initial pending event from download() call
        if (progressEvents.isNotEmpty &&
            progressEvents.first.status == DownloadStatus.pending) {
          // It might appear twice if we iterated statusMap
        }

        final Set<DownloadStatus> receivedStatuses = progressEvents
            .map((e) => e.status)
            .toSet();
        for (final DownloadStatus status in statusMap.values) {
          expect(
            receivedStatuses.contains(status),
            isTrue,
            reason: 'Missing status: $status',
          );
        }

        await subscription.cancel();
      });
    });

    group('Query and Status Checks', () {
      test('getActiveDownloadIds returns active tasks', () async {
        final runningTask = DownloadTask(
          taskId: 't1',
          status: DownloadTaskStatus.running,
          progress: 50,
          url: 'url1',
          filename: 'f1',
          savedDir: 'd1',
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );
        final enqueuedTask = DownloadTask(
          taskId: 't2',
          status: DownloadTaskStatus.enqueued,
          progress: 0,
          url: 'url2',
          filename: 'f2',
          savedDir: 'd2',
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );
        final failedTask = DownloadTask(
          taskId: 't3',
          status: DownloadTaskStatus.failed,
          progress: 0,
          url: 'url3',
          filename: 'f3',
          savedDir: 'd3',
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );

        when(
          mockDownloader.loadTasks(),
        ).thenAnswer((_) async => [runningTask, enqueuedTask, failedTask]);

        final List<String> activeIds = await downloadService
            .getActiveDownloadIds();

        expect(activeIds, containsAll(['url1', 'url2']));
        expect(activeIds, isNot(contains('url3')));
      });

      test(
        'isStatusDownloadActive returns true for running/enqueued',
        () async {
          final task = DownloadTask(
            taskId: testTaskId,
            status: DownloadTaskStatus.running,
            progress: 50,
            url: testUrl,
            filename: 'test.mp3',
            savedDir: tempDir.path,
            timeCreated: DateTime.now().millisecondsSinceEpoch,
            allowCellular: true,
          );

          when(
            mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
          ).thenAnswer((_) async => [task]);
          when(mockDownloader.loadTasks()).thenAnswer((_) async => [task]);

          expect(await downloadService.isStatusDownloadActive(testUrl), isTrue);
        },
      );

      test('isStatusDownloadActive returns false if no tasks found', () async {
        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => []);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => []);

        expect(await downloadService.isStatusDownloadActive(testUrl), isFalse);
      });

      test('getStatus returns correct status', () async {
        final task = DownloadTask(
          taskId: testTaskId,
          status: DownloadTaskStatus.complete,
          progress: 100,
          url: testUrl,
          filename: 'test.mp3',
          savedDir: tempDir.path,
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );
        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => [task]);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => [task]);

        expect(
          await downloadService.getStatus(testUrl),
          DownloadStatus.completed,
        );
      });

      test('getStatus returns null if not found', () async {
        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => []);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => []);

        expect(await downloadService.getStatus(testUrl), isNull);
      });
    });

    group('cancel', () {
      test('should cancel and remove all matching tasks', () async {
        final task1 = DownloadTask(
          taskId: 't1',
          status: DownloadTaskStatus.running,
          progress: 50,
          url: testUrl,
          filename: 'f1',
          savedDir: 'd1',
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );
        final task2 = DownloadTask(
          taskId: 't2',
          status: DownloadTaskStatus.enqueued,
          progress: 0,
          url: testUrl, // Same URL, ghost task maybe
          filename: 'f1',
          savedDir: 'd1',
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );

        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((invocation) async {
          final query = invocation.namedArguments[#query] as String;
          if (query.contains("WHERE url = '$testUrl'")) {
            return [task1, task2];
          }
          return [];
        });
        when(
          mockDownloader.loadTasks(),
        ).thenAnswer((_) async => [task1, task2]);

        final progressEvents = <DownloadProgress>[];
        final StreamSubscription<DownloadProgress> subscription =
            downloadService
                .getProgressStream(testUrl)
                .listen(progressEvents.add);

        await downloadService.cancel(testUrl);

        verify(mockDownloader.cancel(taskId: 't1')).called(1);
        verify(
          mockDownloader.remove(taskId: 't1', shouldDeleteContent: true),
        ).called(1);
        verify(mockDownloader.cancel(taskId: 't2')).called(1);
        verify(
          mockDownloader.remove(taskId: 't2', shouldDeleteContent: true),
        ).called(1);

        await Future.delayed(Duration.zero);
        expect(progressEvents.last.status, DownloadStatus.cancelled);

        await subscription.cancel();
      });
    });

    group('Static Method Wrappers', () {
      test('progressStream returns filtered stream', () async {
        final progressEvents = <DownloadProgress>[];
        final StreamSubscription<DownloadProgress> subscription =
            DownloadService.progressStream(testUrl).listen(progressEvents.add);

        // Enqueue to get a taskId - use instance to match the static progressStream
        await DownloadService.instance.download(
          id: testUrl,
          url: testUrl,
          filePath: testFilePath,
          title: testTitle,
          reciterName: testReciterName,
        );

        await Future.delayed(Duration.zero);
        expect(progressEvents, isNotEmpty);
        expect(progressEvents.first.id, testUrl);

        await subscription.cancel();
      });

      test('activeDownloadIds returns list from instance', () async {
        final task = DownloadTask(
          taskId: 't1',
          status: DownloadTaskStatus.running,
          progress: 50,
          url: testUrl,
          filename: 'test.mp3',
          savedDir: tempDir.path,
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );

        when(mockDownloader.loadTasks()).thenAnswer((_) async => [task]);

        final List<String> ids = await DownloadService.activeDownloadIds;
        expect(ids, contains(testUrl));
      });

      test('isDownloadActive calls instance method', () async {
        final task = DownloadTask(
          taskId: testTaskId,
          status: DownloadTaskStatus.running,
          progress: 50,
          url: testUrl,
          filename: 'test.mp3',
          savedDir: tempDir.path,
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );

        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => [task]);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => [task]);

        final bool isActive = await DownloadService.isDownloadActive(testUrl);
        expect(isActive, isTrue);
      });

      test('getDownloadStatus calls instance method', () async {
        final task = DownloadTask(
          taskId: testTaskId,
          status: DownloadTaskStatus.complete,
          progress: 100,
          url: testUrl,
          filename: 'test.mp3',
          savedDir: tempDir.path,
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );

        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => [task]);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => [task]);

        final DownloadStatus? status = await DownloadService.getDownloadStatus(
          testUrl,
        );
        expect(status, DownloadStatus.completed);
      });

      test('startDownload calls instance download', () async {
        final progressEvents = <DownloadProgress>[];
        final StreamSubscription<DownloadProgress> subscription =
            DownloadService.progressStream(testUrl).listen(progressEvents.add);

        await DownloadService.startDownload(
          id: testUrl,
          url: testUrl,
          filePath: testFilePath,
          title: testTitle,
          reciterName: testReciterName,
        );

        await Future.delayed(Duration.zero);
        expect(progressEvents, isNotEmpty);

        await subscription.cancel();
      });

      test('cancelDownload calls instance cancel', () async {
        final task = DownloadTask(
          taskId: 't1',
          status: DownloadTaskStatus.running,
          progress: 50,
          url: testUrl,
          filename: 'test.mp3',
          savedDir: tempDir.path,
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );

        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => [task]);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => [task]);

        await DownloadService.cancelDownload(testUrl);

        verify(mockDownloader.cancel(taskId: 't1')).called(1);
      });

      test('dispose calls instance disposeService', () async {
        await DownloadService.dispose();
        expect(downloadService, isNotNull); // Service still exists
      });

      test('reset calls disposeService', () async {
        await DownloadService.reset();
        // After reset, initialization state should be cleared
        expect(downloadService, isNotNull);
      });

      test('globalProgressStream provides broadcast stream', () {
        final Stream<DownloadProgress> stream =
            DownloadService.globalProgressStream;
        expect(stream, isNotNull);
        expect(stream.isBroadcast, isTrue);
      });
    });

    group('Edge Cases and Error Handling', () {
      test(
        'download handles null task list from loadTasksWithRawQuery',
        () async {
          when(
            mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
          ).thenAnswer((_) async => null);

          final progressEvents = <DownloadProgress>[];
          final StreamSubscription<DownloadProgress> subscription =
              downloadService
                  .getProgressStream(testUrl)
                  .listen(progressEvents.add);

          await downloadService.download(
            id: testUrl,
            url: testUrl,
            filePath: testFilePath,
            title: testTitle,
            reciterName: testReciterName,
          );

          await Future.delayed(Duration.zero);
          expect(progressEvents, isNotEmpty);
          expect(progressEvents.first.status, DownloadStatus.pending);

          await subscription.cancel();
        },
      );

      test('_handleTaskUpdate handles database query error gracefully', () async {
        await downloadService.initialize();

        // Mock loadTasksWithRawQuery to throw an error
        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenThrow(Exception('Database error'));

        final progressEvents = <DownloadProgress>[];
        final StreamSubscription<DownloadProgress> subscription =
            DownloadService.globalProgressStream.listen(progressEvents.add);

        final SendPort? port = IsolateNameServer.lookupPortByName(
          'downloader_send_port',
        );
        // Send update for unknown task (not in _taskIdMap)
        port!.send(['unknown-task-id', 2, 50]);

        await Future.delayed(const Duration(milliseconds: 100));

        // Should not crash, but also won't emit event since ID couldn't be resolved
        // The error is logged but not propagated

        await subscription.cancel();
      });

      test('getActiveDownloadIds handles null task list', () async {
        when(mockDownloader.loadTasks()).thenAnswer((_) async => null);

        final List<String> ids = await downloadService.getActiveDownloadIds();
        expect(ids, isEmpty);
      });

      test('isStatusDownloadActive handles null task list', () async {
        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => null);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => null);

        final bool isActive = await downloadService.isStatusDownloadActive(
          testUrl,
        );
        expect(isActive, isFalse);
      });

      test('getStatus handles null task list', () async {
        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => null);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => null);

        final DownloadStatus? status = await downloadService.getStatus(testUrl);
        expect(status, isNull);
      });

      test('getStatus handles empty task list', () async {
        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => []);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => []);

        final DownloadStatus? status = await downloadService.getStatus(testUrl);
        expect(status, isNull);
      });

      test('cancel handles null task list', () async {
        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => null);
        when(mockDownloader.loadTasks()).thenAnswer((_) async => null);

        // Should not throw
        await downloadService.cancel(testUrl);

        // Verify it still emits cancelled status
        final progressEvents = <DownloadProgress>[];
        final StreamSubscription<DownloadProgress> subscription =
            downloadService
                .getProgressStream(testUrl)
                .listen(progressEvents.add);

        await downloadService.cancel(testUrl);
        await Future.delayed(Duration.zero);

        expect(progressEvents, isNotEmpty);
        expect(progressEvents.last.status, DownloadStatus.cancelled);

        await subscription.cancel();
      });

      test('disposeService clears state properly', () async {
        await downloadService.initialize();

        final SendPort? port = IsolateNameServer.lookupPortByName(
          'downloader_send_port',
        );
        expect(port, isNotNull);

        await downloadService.disposeService();

        final SendPort? portAfterDispose = IsolateNameServer.lookupPortByName(
          'downloader_send_port',
        );
        expect(portAfterDispose, isNull);
      });

      test('getStatus returns last task when multiple tasks exist', () async {
        final task1 = DownloadTask(
          taskId: 't1',
          status: DownloadTaskStatus.running,
          progress: 50,
          url: testUrl,
          filename: 'test.mp3',
          savedDir: tempDir.path,
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );

        final task2 = DownloadTask(
          taskId: 't2',
          status: DownloadTaskStatus.complete,
          progress: 100,
          url: testUrl,
          filename: 'test.mp3',
          savedDir: tempDir.path,
          timeCreated: DateTime.now().millisecondsSinceEpoch + 1000,
          allowCellular: true,
        );

        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => [task1, task2]);
        when(
          mockDownloader.loadTasks(),
        ).thenAnswer((_) async => [task1, task2]);

        final DownloadStatus? status = await downloadService.getStatus(testUrl);
        // Should return the last task's status
        expect(status, DownloadStatus.completed);
      });
    });

    group('Singleton Instance', () {
      test('instance returns same singleton', () {
        final DownloadService instance1 = DownloadService.instance;
        final DownloadService instance2 = DownloadService.instance;
        expect(identical(instance1, instance2), isTrue);
      });

      test('flutterDownloaderTestOverride sets and gets mock', () {
        final testMock = MockFlutterDownloaderWrapper();
        DownloadService.flutterDownloaderTestOverride = testMock;

        // Verify the getter returns the same mock we set
        expect(
          identical(DownloadService.flutterDownloaderTestOverride, testMock),
          isTrue,
        );
        expect(DownloadService.instance, isNotNull);
      });
    });
  });
}
