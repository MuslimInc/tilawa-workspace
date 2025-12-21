import 'dart:async';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/data/services/flutter_downloader_wrapper.dart';
import 'package:muzakri/features/downloads/data/services/helpers/download_file_helper.dart';
import 'package:muzakri/features/downloads/data/services/helpers/download_isolate_manager.dart';
import 'package:muzakri/features/downloads/data/services/helpers/download_status_mapper.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';

import 'download_service_impl_test.mocks.dart';

@GenerateMocks([
  FlutterDownloaderWrapper,
  DownloadFileHelper,
  DownloadStatusMapper,
  DownloadIsolateManager,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterDownloaderWrapper mockDownloader;
  late MockDownloadFileHelper mockFileHelper;
  late MockDownloadStatusMapper mockStatusMapper;
  late MockDownloadIsolateManager mockIsolateManager;
  late DownloadServiceImpl downloadService;
  late StreamController<(String, DownloadTaskStatus, int)> updateController;

  setUp(() {
    mockDownloader = MockFlutterDownloaderWrapper();
    mockFileHelper = MockDownloadFileHelper();
    mockStatusMapper = MockDownloadStatusMapper();
    mockIsolateManager = MockDownloadIsolateManager();
    updateController = StreamController.broadcast();

    // Default mock behavior
    when(
      mockIsolateManager.updateStream,
    ).thenAnswer((_) => updateController.stream);
    when(mockIsolateManager.registerPort()).thenReturn(null);
    when(mockDownloader.initialize(debug: anyNamed('debug'))).thenAnswer((
      _,
    ) async {
      return;
    });
    when(mockDownloader.registerCallback(any)).thenAnswer((_) async {
      return;
    });
    when(
      mockDownloader.loadTasks(),
    ).thenAnswer((_) async => []); // Default empty list

    // Default file helper behavior
    when(mockFileHelper.getDirectoryName(any)).thenReturn('/path/to');
    when(mockFileHelper.getFileName(any)).thenReturn('file.mp3');
    when(mockFileHelper.ensureDirectoryExists(any)).thenAnswer((_) => true);

    downloadService = DownloadServiceImpl(
      flutterDownloader: mockDownloader,
      fileHelper: mockFileHelper,
      statusMapper: mockStatusMapper,
      isolateManager: mockIsolateManager,
    );
  });

  tearDown(() {
    updateController.close();
    downloadService.disposeService();
  });

  group('DownloadServiceImpl', () {
    test('initialize calls dependencies correctly', () async {
      await downloadService.initialize();

      verify(mockDownloader.initialize(debug: anyNamed('debug'))).called(1);
      verify(mockIsolateManager.registerPort()).called(1);
      verify(mockIsolateManager.updateStream).called(1);
      verify(
        mockDownloader.registerCallback(any, step: anyNamed('step')),
      ).called(1);
    });

    test('download delegates to helpers and enqueues task', () async {
      const url = 'http://example.com/audio.mp3';
      const path = '/local/path.mp3';
      const taskId = 'task-1';

      when(
        mockDownloader.enqueue(
          url: url,
          savedDir: '/path/to',
          fileName: 'file.mp3',
          openFileFromNotification: false,
          title: 'Title',
        ),
      ).thenAnswer((_) async => taskId);

      // We need to initialize first to setup stream listeners (though download() calls initialize if needed)

      await downloadService.download(
        id: url, // using url as ID for simplicity
        url: url,
        filePath: path,
        title: 'Title',
        reciterName: 'Reciter',
      );

      // Verify helpers called
      verify(mockFileHelper.getDirectoryName(path)).called(1);
      verify(mockFileHelper.getFileName(path)).called(1);
      verify(mockFileHelper.ensureDirectoryExists('/path/to')).called(1);

      // Verify enqueue
      verify(
        mockDownloader.enqueue(
          url: url,
          savedDir: '/path/to',
          fileName: 'file.mp3',
          openFileFromNotification: false,
          title: 'Title',
        ),
      ).called(1);
    });

    test('progress stream emits updates from isolate manager', () async {
      await downloadService.initialize();

      const taskId = 'task-1';
      const url = 'http://example.com';

      // Pre-populate task ID mapping (normally done via download() or loadTasks())
      // Since _taskIdToUrlMap is private, we simulate a download to populate it or rely on tasks load fallback.
      // Easiest is to simulate download start.
      when(
        mockDownloader.enqueue(
          url: anyNamed('url'),
          savedDir: anyNamed('savedDir'),
          fileName: anyNamed('fileName'),
          openFileFromNotification: anyNamed('openFileFromNotification'),
          showNotification: anyNamed('showNotification'),
          title: anyNamed('title'),
        ),
      ).thenAnswer((_) async => taskId);

      await downloadService.download(
        id: url,
        url: url,
        filePath: '/path',
        title: 'Title',
        reciterName: 'Reciter',
      );

      // Verify initial pending status emitted
      // We can't easily check previous emissions on broadcast stream unless we listened before.

      // setup verification for mapping
      when(
        mockStatusMapper.mapTaskStatusToDownloadStatus(
          DownloadTaskStatus.running,
        ),
      ).thenReturn(DownloadStatus.downloading);

      // Set up the expectation first (but don't await yet)
      final Future<void> expectation = expectLater(
        downloadService.globalProgressStream,
        emits(
          predicate<DownloadProgress>((progress) {
            return progress.id == url &&
                progress.status == DownloadStatus.downloading &&
                progress.progress == 0.5;
          }),
        ),
      );

      // Emit update from isolate AFTER setting up expectation
      updateController.add((taskId, DownloadTaskStatus.running, 50));

      // Now wait for the expectation
      await expectation;
    });

    test('cancelAll cancels all tasks and clears active uploads', () async {
      await downloadService.initialize();

      const url1 = 'http://example.com/1';
      const url2 = 'http://example.com/2';

      // Setup active downloads
      when(mockDownloader.loadTasks()).thenAnswer(
        (_) async => [
          DownloadTask(
            taskId: 'task1',
            status: DownloadTaskStatus.running,
            url: url1,
            savedDir: '',
            filename: 'file1.mp3',
            progress: 50,
            timeCreated: 0,
            allowCellular: true,
          ),
          DownloadTask(
            taskId: 'task2',
            status: DownloadTaskStatus.enqueued,
            url: url2,
            savedDir: '',
            filename: 'file2.mp3',
            progress: 0,
            timeCreated: 0,
            allowCellular: true,
          ),
        ],
      );

      // Re-initialize to populate active cache
      downloadService.resetForTesting();
      await downloadService.initialize();

      expect(
        await downloadService.getActiveDownloadIds(),
        containsAll([url1, url2]),
      );

      // Setup cancel expectations
      when(
        mockDownloader.cancel(taskId: anyNamed('taskId')),
      ).thenAnswer((_) async {});
      when(
        mockDownloader.remove(
          taskId: anyNamed('taskId'),
          shouldDeleteContent: anyNamed('shouldDeleteContent'),
        ),
      ).thenAnswer((_) async {});

      final Future<void> expectation = expectLater(
        downloadService.globalProgressStream,
        emitsInAnyOrder([
          predicate<DownloadProgress>(
            (p) => p.id == url1 && p.status == DownloadStatus.cancelled,
          ),
          predicate<DownloadProgress>(
            (p) => p.id == url2 && p.status == DownloadStatus.cancelled,
          ),
        ]),
      );

      await downloadService.cancelAll();

      await expectation;
      expect(await downloadService.getActiveDownloadIds(), isEmpty);
      verify(mockDownloader.cancel(taskId: 'task1')).called(1);
      verify(mockDownloader.cancel(taskId: 'task2')).called(1);
    });

    test('rethrows initialization error', () async {
      final localMockDownloader = MockFlutterDownloaderWrapper();
      final localMockIsolateManager = MockDownloadIsolateManager();
      // Others can be null or simple mocks as they won't be used before error
      final localService = DownloadServiceImpl(
        flutterDownloader: localMockDownloader,
        isolateManager: localMockIsolateManager,
      );

      when(
        localMockDownloader.initialize(debug: anyNamed('debug')),
      ).thenThrow(Exception('Init failed'));

      when(localMockIsolateManager.registerPort()).thenReturn(null);

      // Call twice to ensure the internal completer's error is consumed by a listener (the second call)
      // This prevents "uncaught error" in some test environments if the completer error goes unobserved.
      final Future<void> future1 = localService.initialize();
      final Future<void> future2 = localService.initialize();

      await expectLater(future1, throwsException);
      await expectLater(future2, throwsException);
    });

    group('download edge cases', () {
      test('does nothing if task already exists and is complete', () async {
        // Create fresh isolated mocks for this test to avoid verify state leakage
        final localMockDownloader = MockFlutterDownloaderWrapper();
        final localMockFileHelper = MockDownloadFileHelper();
        final localMockStatusMapper = MockDownloadStatusMapper();
        final localMockIsolateManager = MockDownloadIsolateManager();

        // Stub basic defaults for them
        when(
          localMockIsolateManager.updateStream,
        ).thenAnswer((_) => const Stream.empty());
        when(localMockIsolateManager.registerPort()).thenReturn(null);
        when(
          localMockDownloader.initialize(debug: anyNamed('debug')),
        ).thenAnswer((_) async {
          return;
        });
        when(localMockDownloader.registerCallback(any)).thenAnswer((_) async {
          return;
        });
        when(localMockFileHelper.getDirectoryName(any)).thenReturn('/path/to');
        when(localMockFileHelper.getFileName(any)).thenReturn('file.mp3');
        when(
          localMockFileHelper.ensureDirectoryExists(any),
        ).thenAnswer((_) => true);
        when(localMockFileHelper.isFileExists(any)).thenAnswer((_) => true);

        final localService = DownloadServiceImpl(
          flutterDownloader: localMockDownloader,
          fileHelper: localMockFileHelper,
          statusMapper: localMockStatusMapper,
          isolateManager: localMockIsolateManager,
        );

        const url = 'http://example.com/audio.mp3';
        const taskId = 'task-complete';

        when(localMockDownloader.loadTasks()).thenAnswer(
          (_) async => [
            DownloadTask(
              taskId: taskId,
              status: DownloadTaskStatus.complete,
              progress: 100,
              url: url,
              filename: 'file.mp3',
              savedDir: '/path/to',
              timeCreated: 0,
              allowCellular: true,
            ),
          ],
        );

        // Should emit complete status
        final Future<void> expectation = expectLater(
          localService.globalProgressStream,
          emits(
            predicate<DownloadProgress>((progress) {
              return progress.id == url &&
                  progress.status == DownloadStatus.completed &&
                  progress.progress == 1.0;
            }),
          ),
        );

        await localService.download(
          id: url,
          url: url,
          filePath: '/path/file.mp3',
          title: 'Title',
          reciterName: 'Reciter',
        );

        // Should NOT call enqueue
        verifyNever(
          localMockDownloader.enqueue(
            url: anyNamed('url'),
            savedDir: anyNamed('savedDir'),
            fileName: anyNamed('fileName'),
            openFileFromNotification: anyNamed('openFileFromNotification'),
            title: anyNamed('title'),
          ),
        );

        await expectation;
      });

      test('does nothing if task already exists and is running', () async {
        final localMockDownloader = MockFlutterDownloaderWrapper();
        final localMockFileHelper = MockDownloadFileHelper();
        final localMockStatusMapper = MockDownloadStatusMapper();
        final localMockIsolateManager = MockDownloadIsolateManager();

        when(
          localMockIsolateManager.updateStream,
        ).thenAnswer((_) => const Stream.empty());
        when(localMockIsolateManager.registerPort()).thenReturn(null);
        when(
          localMockDownloader.initialize(debug: anyNamed('debug')),
        ).thenAnswer((_) async {
          return;
        });
        when(localMockDownloader.registerCallback(any)).thenAnswer((_) async {
          return;
        });
        when(localMockFileHelper.getDirectoryName(any)).thenReturn('/path/to');
        when(localMockFileHelper.getFileName(any)).thenReturn('file.mp3');
        when(
          localMockFileHelper.ensureDirectoryExists(any),
        ).thenAnswer((_) => true);

        final localService = DownloadServiceImpl(
          flutterDownloader: localMockDownloader,
          fileHelper: localMockFileHelper,
          statusMapper: localMockStatusMapper,
          isolateManager: localMockIsolateManager,
        );

        const url = 'http://example.com/audio.mp3';
        const taskId = 'task-running';

        when(localMockDownloader.loadTasks()).thenAnswer(
          (_) async => [
            DownloadTask(
              taskId: taskId,
              status: DownloadTaskStatus.running,
              progress: 50,
              url: url,
              filename: 'file.mp3',
              savedDir: '/path/to',
              timeCreated: 0,
              allowCellular: true,
            ),
          ],
        );

        await localService.download(
          id: url,
          url: url,
          filePath: '/path/file.mp3',
          title: 'Title',
          reciterName: 'Reciter',
        );

        verifyNever(
          localMockDownloader.enqueue(
            url: anyNamed('url'),
            savedDir: anyNamed('savedDir'),
            fileName: anyNamed('fileName'),
            openFileFromNotification: anyNamed('openFileFromNotification'),
            title: anyNamed('title'),
          ),
        );
      });

      test('aborts if directory creation fails', () async {
        final localMockDownloader = MockFlutterDownloaderWrapper();
        final localMockFileHelper = MockDownloadFileHelper();
        final localMockStatusMapper = MockDownloadStatusMapper();
        final localMockIsolateManager = MockDownloadIsolateManager();

        when(
          localMockIsolateManager.updateStream,
        ).thenAnswer((_) => const Stream.empty());
        when(localMockIsolateManager.registerPort()).thenReturn(null);
        when(
          localMockDownloader.initialize(debug: anyNamed('debug')),
        ).thenAnswer((_) async {
          return;
        });
        when(localMockDownloader.registerCallback(any)).thenAnswer((_) async {
          return;
        });
        when(localMockFileHelper.getDirectoryName(any)).thenReturn('/path/to');
        when(localMockFileHelper.getFileName(any)).thenReturn('file.mp3');

        // Simulating failure
        when(
          localMockFileHelper.ensureDirectoryExists(any),
        ).thenAnswer((_) => false);

        // Also stub loadTasks as it's called during download
        when(localMockDownloader.loadTasks()).thenAnswer((_) async => []);

        final localService = DownloadServiceImpl(
          flutterDownloader: localMockDownloader,
          fileHelper: localMockFileHelper,
          statusMapper: localMockStatusMapper,
          isolateManager: localMockIsolateManager,
        );

        await localService.download(
          id: 'id',
          url: 'url',
          filePath: '/path/file.mp3',
          title: 'Title',
          reciterName: 'Reciter',
        );

        verifyNever(
          localMockDownloader.enqueue(
            url: anyNamed('url'),
            savedDir: anyNamed('savedDir'),
            fileName: anyNamed('fileName'),
            openFileFromNotification: anyNamed('openFileFromNotification'),
            title: anyNamed('title'),
          ),
        );
      });

      test('aborts if paths are empty', () async {
        final localMockDownloader = MockFlutterDownloaderWrapper();
        final localMockFileHelper = MockDownloadFileHelper();
        final localMockStatusMapper = MockDownloadStatusMapper();
        final localMockIsolateManager = MockDownloadIsolateManager();

        when(
          localMockIsolateManager.updateStream,
        ).thenAnswer((_) => const Stream.empty());
        when(localMockIsolateManager.registerPort()).thenReturn(null);
        when(
          localMockDownloader.initialize(debug: anyNamed('debug')),
        ).thenAnswer((_) async {
          return;
        });
        when(localMockDownloader.registerCallback(any)).thenAnswer((_) async {
          return;
        });

        // Simulating empty
        when(localMockFileHelper.getDirectoryName(any)).thenReturn('');
        when(localMockFileHelper.getFileName(any)).thenReturn('file.mp3');
        // Even if directory exists, empty path should abort
        when(
          localMockFileHelper.ensureDirectoryExists(any),
        ).thenAnswer((_) => true);
        when(localMockDownloader.loadTasks()).thenAnswer((_) async => []);

        final localService = DownloadServiceImpl(
          flutterDownloader: localMockDownloader,
          fileHelper: localMockFileHelper,
          statusMapper: localMockStatusMapper,
          isolateManager: localMockIsolateManager,
        );

        await localService.download(
          id: 'id',
          url: 'url',
          filePath: '/path/file.mp3',
          title: 'Title',
          reciterName: 'Reciter',
        );

        verifyNever(
          localMockDownloader.enqueue(
            url: anyNamed('url'),
            savedDir: anyNamed('savedDir'),
            fileName: anyNamed('fileName'),
            openFileFromNotification: anyNamed('openFileFromNotification'),
            title: anyNamed('title'),
          ),
        );
      });
    });

    test('cancel cancels task and removes from queue', () async {
      final localMockDownloader = MockFlutterDownloaderWrapper();
      final localMockIsolateManager = MockDownloadIsolateManager();
      // other helpers unused for cancel, but service needs them. can pass null? no, named args. mocks fine.
      // Stub defaults
      when(
        localMockIsolateManager.updateStream,
      ).thenAnswer((_) => const Stream.empty());
      when(localMockIsolateManager.registerPort()).thenReturn(null);
      when(localMockDownloader.initialize(debug: anyNamed('debug'))).thenAnswer(
        (_) async {
          return;
        },
      );
      when(localMockDownloader.registerCallback(any)).thenAnswer((_) async {
        return;
      });

      final localService = DownloadServiceImpl(
        flutterDownloader: localMockDownloader,
        fileHelper: MockDownloadFileHelper(),
        statusMapper: MockDownloadStatusMapper(),
        isolateManager: localMockIsolateManager,
      );

      const url = 'http://example.com/audio.mp3';
      const taskId = 'task-1';

      // Simulate existing task
      when(localMockDownloader.loadTasks()).thenAnswer(
        (_) async => [
          DownloadTask(
            taskId: taskId,
            status: DownloadTaskStatus.running,
            progress: 50,
            url: url,
            filename: 'file.mp3',
            savedDir: '/path/to',
            timeCreated: 0,
            allowCellular: true,
          ),
        ],
      );

      when(localMockDownloader.cancel(taskId: taskId)).thenAnswer((_) async {
        return;
      });
      when(
        localMockDownloader.remove(taskId: taskId, shouldDeleteContent: true),
      ).thenAnswer((_) async {
        return;
      });

      await localService.cancel(url);

      verify(localMockDownloader.cancel(taskId: taskId)).called(1);
    });

    test('getStatus returns correct status', () async {
      final localMockDownloader = MockFlutterDownloaderWrapper();
      final localMockStatusMapper = MockDownloadStatusMapper();
      final localMockIsolateManager = MockDownloadIsolateManager();

      when(
        localMockIsolateManager.updateStream,
      ).thenAnswer((_) => const Stream.empty());
      when(localMockIsolateManager.registerPort()).thenReturn(null);
      when(localMockDownloader.initialize(debug: anyNamed('debug'))).thenAnswer(
        (_) async {
          return;
        },
      );
      when(localMockDownloader.registerCallback(any)).thenAnswer((_) async {
        return;
      });

      final localService = DownloadServiceImpl(
        flutterDownloader: localMockDownloader,
        fileHelper: MockDownloadFileHelper(),
        statusMapper: localMockStatusMapper,
        isolateManager: localMockIsolateManager,
      );

      const url = 'http://example.com/audio.mp3';
      const taskId = 'task-1';

      when(localMockDownloader.loadTasks()).thenAnswer(
        (_) async => [
          DownloadTask(
            taskId: taskId,
            status: DownloadTaskStatus.running,
            progress: 50,
            url: url,
            filename: 'file.mp3',
            savedDir: '/path/to',
            timeCreated: 0,
            allowCellular: true,
          ),
        ],
      );

      when(
        localMockStatusMapper.mapTaskStatusToDownloadStatus(
          DownloadTaskStatus.running,
        ),
      ).thenReturn(DownloadStatus.downloading);

      final DownloadStatus? status = await localService.getStatus(url);
      expect(status, DownloadStatus.downloading);
    });

    test('getActiveDownloadIds returns list of active urls', () async {
      final localMockDownloader = MockFlutterDownloaderWrapper();
      final localMockIsolateManager = MockDownloadIsolateManager();

      when(
        localMockIsolateManager.updateStream,
      ).thenAnswer((_) => const Stream.empty());
      when(localMockIsolateManager.registerPort()).thenReturn(null);
      when(localMockDownloader.initialize(debug: anyNamed('debug'))).thenAnswer(
        (_) async {
          return;
        },
      );
      when(localMockDownloader.registerCallback(any)).thenAnswer((_) async {
        return;
      });

      final localService = DownloadServiceImpl(
        flutterDownloader: localMockDownloader,
        fileHelper: MockDownloadFileHelper(),
        statusMapper: MockDownloadStatusMapper(),
        isolateManager: localMockIsolateManager,
      );

      when(localMockDownloader.loadTasks()).thenAnswer(
        (_) async => [
          DownloadTask(
            taskId: 't1',
            status: DownloadTaskStatus.running,
            progress: 50,
            url: 'url1',
            filename: 'f1',
            savedDir: 'd1',
            timeCreated: 0,
            allowCellular: true,
          ),
          DownloadTask(
            taskId: 't2',
            status: DownloadTaskStatus.complete,
            progress: 100,
            url: 'url2',
            filename: 'f2',
            savedDir: 'd2',
            timeCreated: 0,
            allowCellular: true,
          ),
        ],
      );

      final List<String> ids = await localService.getActiveDownloadIds();

      expect(ids, contains('url1'));
      expect(ids, isNot(contains('url2'))); // url2 is complete, so not active
    });

    test('handleTaskUpdate resolves URL from DB if map missing', () async {
      final localMockDownloader = MockFlutterDownloaderWrapper();
      final localMockStatusMapper = MockDownloadStatusMapper();
      final localMockIsolateManager = MockDownloadIsolateManager();

      final localController =
          StreamController<(String, DownloadTaskStatus, int)>.broadcast();

      when(
        localMockIsolateManager.updateStream,
      ).thenAnswer((_) => localController.stream);
      when(localMockIsolateManager.registerPort()).thenReturn(null);
      when(localMockDownloader.initialize(debug: anyNamed('debug'))).thenAnswer(
        (_) async {
          return;
        },
      );
      when(localMockDownloader.registerCallback(any)).thenAnswer((_) async {
        return;
      });

      final localService = DownloadServiceImpl(
        flutterDownloader: localMockDownloader,
        fileHelper: MockDownloadFileHelper(),
        statusMapper: localMockStatusMapper,
        isolateManager: localMockIsolateManager,
      );

      await localService.initialize();

      const taskId = 'unknown-task';
      const url = 'http://recovered.url';

      when(localMockDownloader.loadTasks()).thenAnswer(
        (_) async => [
          DownloadTask(
            taskId: taskId,
            status: DownloadTaskStatus.running,
            progress: 50,
            url: url,
            filename: 'f',
            savedDir: 'd',
            timeCreated: 0,
            allowCellular: true,
          ),
        ],
      );

      when(
        localMockStatusMapper.mapTaskStatusToDownloadStatus(
          DownloadTaskStatus.running,
        ),
      ).thenReturn(DownloadStatus.downloading);

      // Set up the expectation first (but don't await yet)
      final Future<void> expectation = expectLater(
        localService.globalProgressStream,
        emits(predicate<DownloadProgress>((p) => p.id == url)),
      );

      // Emit update from isolate AFTER setting up expectation
      localController.add((taskId, DownloadTaskStatus.running, 50));

      // Now wait for the expectation
      await expectation;

      // Cleanup
      await localController.close();
    });
  });
}
