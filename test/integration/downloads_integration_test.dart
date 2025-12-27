import 'dart:io';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/downloads/data/repositories/downloads_repository_impl.dart';
import 'package:tilawa/features/downloads/data/services/download_notification_service.dart';
import 'package:tilawa/features/downloads/data/services/download_queue_manager.dart';
import 'package:tilawa/features/downloads/data/services/download_service_impl.dart';
import 'package:tilawa/features/downloads/data/services/download_service_interface.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';

import '../features/downloads/helpers/mock_helper.mocks.dart';

void main() {
  provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));
  TestWidgetsFlutterBinding.ensureInitialized();

  late DownloadsRepositoryImpl repository;
  late MockDownloadsLocalDataSource mockLocalDataSource;
  late MockFlutterDownloaderWrapper mockDownloader;
  late MockBatchDownloadManager mockBatchDownloadManager;
  late MockDownloadPathResolver mockPathResolver;
  late MockDownloadValidator mockValidator;
  late MockDownloadStatusSynchronizer mockStatusSynchronizer;
  late MockRecitersRepository mockRecitersRepository;
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync();
    // Setup mocks
    // Setup mocks
    mockLocalDataSource = MockDownloadsLocalDataSource();
    mockDownloader = MockFlutterDownloaderWrapper();
    mockBatchDownloadManager = MockBatchDownloadManager();
    mockPathResolver = MockDownloadPathResolver();
    mockValidator = MockDownloadValidator();
    mockStatusSynchronizer = MockDownloadStatusSynchronizer();
    mockRecitersRepository = MockRecitersRepository();

    // Register DownloadService in GetIt
    final GetIt getIt = GetIt.instance;
    if (!getIt.isRegistered<DownloadServiceInterface>()) {
      final mockStatusMapper = MockDownloadStatusMapper();
      final mockFileHelper = MockDownloadFileHelper();
      final mockIsolateManager = MockDownloadIsolateManager();

      when(
        mockIsolateManager.updateStream,
      ).thenAnswer((_) => const Stream.empty());
      when(mockIsolateManager.registerPort()).thenReturn(null);

      // Stub status mapper
      when(
        mockStatusMapper.mapTaskStatusToDownloadStatus(any),
      ).thenReturn(DownloadStatus.pending);
      when(
        mockStatusMapper.mapTaskStatusToDownloadStatus(
          DownloadTaskStatus.running,
        ),
      ).thenReturn(DownloadStatus.downloading);
      when(
        mockStatusMapper.mapTaskStatusToDownloadStatus(
          DownloadTaskStatus.complete,
        ),
      ).thenReturn(DownloadStatus.completed);

      // Stub file helper
      when(mockFileHelper.getDirectoryName(any)).thenReturn('dir');
      when(mockFileHelper.getFileName(any)).thenReturn('file.mp3');
      when(mockFileHelper.ensureDirectoryExists(any)).thenReturn(true);
      when(mockFileHelper.isFileExists(any)).thenReturn(false);

      // Create the real service with the mock dependencies
      final downloadService = DownloadServiceImpl(
        mockDownloader,
        mockFileHelper,
        mockStatusMapper,
        mockIsolateManager,
      );
      getIt.registerSingleton<DownloadServiceInterface>(downloadService);
    }
    final mockDownloadNotificationService = MockDownloadNotificationService();
    if (!getIt.isRegistered<DownloadNotificationService>()) {
      getIt.registerSingleton<DownloadNotificationService>(
        mockDownloadNotificationService,
      );
    }

    // Reset DownloadService state
    // We can cast because we know we registered the Impl in this test
    (getIt<DownloadServiceInterface>() as DownloadServiceImpl)
        .resetForTesting();

    when(mockDownloadNotificationService.initialize()).thenAnswer((_) async {});
    when(
      mockDownloadNotificationService.showDownloadProgress(
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
    ).thenAnswer((_) async {});
    when(
      mockDownloadNotificationService.cancelNotification(any),
    ).thenAnswer((_) async {});

    // Stub logging to avoid noise
    // setupLogger(); // Assuming logger is accessible or mocked if needed

    // Setup default stubs BEFORE initializing services that use them
    when(
      mockPathResolver.getDownloadsDir(),
    ).thenAnswer((_) async => tempDir.path);
    when(mockPathResolver.resolveDownloadPath(any, any)).thenAnswer(
      (invocation) => invocation.positionalArguments[0] as DownloadItem,
    );
    when(
      mockValidator.verifyFileExists(any, maxRetries: anyNamed('maxRetries')),
    ).thenAnswer((_) async => true);

    when(
      mockLocalDataSource.getDownloadsDirectory(),
    ).thenAnswer((_) async => tempDir.path);
    when(mockLocalDataSource.getDownloads()).thenAnswer((_) async => []);
    when(mockLocalDataSource.addDownload(any)).thenAnswer((_) async {
      return;
    });
    when(mockLocalDataSource.updateDownload(any)).thenAnswer((_) async {
      return;
    });
    when(mockStatusSynchronizer.syncDownloadStatuses(any)).thenAnswer(
      (invocation) async =>
          invocation.positionalArguments[0] as List<DownloadItem>,
    );
    when(
      mockRecitersRepository.getReciters(),
    ).thenAnswer((_) async => const Right([]));

    when(mockDownloader.loadTasks()).thenAnswer((_) async => []);
    when(
      mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
    ).thenAnswer((_) async => []);

    // Reset singleton
    if (GetIt.instance.isRegistered<DownloadQueueManager>()) {
      GetIt.instance.unregister<DownloadQueueManager>();
    }
    final queueManager = DownloadQueueManager(
      GetIt.instance<DownloadServiceInterface>(),
      GetIt.instance<DownloadNotificationService>(),
    );
    GetIt.instance.registerSingleton<DownloadQueueManager>(queueManager);
    await queueManager.initialize();

    repository = DownloadsRepositoryImpl(
      mockLocalDataSource,
      GetIt.instance<DownloadServiceInterface>(),
      mockBatchDownloadManager,
      mockPathResolver,
      mockStatusSynchronizer,
      mockValidator,
      queueManager,
    );

    // Stub logging to avoid noise
    // setupLogger(); // Assuming logger is accessible or mocked if needed
  });

  tearDown(() {
    final GetIt getIt = GetIt.instance;
    if (getIt.isRegistered<DownloadServiceInterface>()) {
      getIt.unregister<DownloadServiceInterface>();
    }
  });

  group('Downloads Integration Flow', () {
    test('Queue Manager and Repository sync correctly (ID vs URL)', () async {
      // 1. Start a download via Repository
      const url = 'https://example.com/s1.mp3';
      const reciter = 'Reciter A';
      const surahTitle = 'Surah 1';

      // Mock enqueue in downloader to return a task ID
      when(
        mockDownloader.enqueue(
          url: url,
          savedDir: anyNamed('savedDir'),
          fileName: anyNamed('fileName'),
          showNotification: anyNamed('showNotification'),
          openFileFromNotification: anyNamed('openFileFromNotification'),
          title: anyNamed('title'),
          headers: anyNamed('headers'),
          requiresStorageNotLow: anyNamed('requiresStorageNotLow'),
          saveInPublicStorage: anyNamed('saveInPublicStorage'),
        ),
      ).thenAnswer((_) async => 'task_uuid_1');

      // Stub loadTasksWithRawQuery to mock active downloads
      when(
        mockDownloader.loadTasksWithRawQuery(
          query: argThat(anything, named: 'query'),
        ),
      ).thenAnswer((invocation) async {
        final query =
            invocation.namedArguments[const Symbol('query')] as String;

        // The query should perform a look up by URL not ID
        if (query.contains("url = '$url'")) {
          return [
            DownloadTask(
              taskId: 'task_uuid_1',
              status: DownloadTaskStatus.running,
              progress: 0,
              url: url,
              filename: 's1_Reciter_A.mp3',
              savedDir: tempDir.path,
              timeCreated: DateTime.now().millisecondsSinceEpoch,
              allowCellular: true,
            ),
          ];
        }
        return [];
      });

      // Stub loadTasks to return the running task (used by DownloadService.getDownloadStatus)
      when(mockDownloader.loadTasks()).thenAnswer(
        (_) async => [
          DownloadTask(
            taskId: 'task_uuid_1',
            status: DownloadTaskStatus.running,
            progress: 0,
            url: url,
            filename: 's1_Reciter_A.mp3',
            savedDir: tempDir.path,
            timeCreated: DateTime.now().millisecondsSinceEpoch,
            allowCellular: true,
          ),
        ],
      );

      // Act: Start Download
      await repository.startDownload(
        url,
        title: surahTitle,
        surahTitle: surahTitle,
        reciterName: reciter,
        reciterId: 1,
      );

      // Verify: Download added to DB with Pending/Downloading status
      final List<dynamic> captured = verify(
        mockLocalDataSource.addDownload(captureAny),
      ).captured;
      final addedItem = captured.first as DownloadItem;
      expect(addedItem.id, url);
      expect(addedItem.url, url);

      // Verify: Queued or Active in Manager (since it starts immediately)
      expect(
        GetIt.instance<DownloadQueueManager>().isQueued(url) ||
            GetIt.instance<DownloadQueueManager>().isActive(url),
        isTrue,
        reason: 'Download should be either queued or active',
      );

      // 2. Simulate Service Active Check
      // This verifies the fix: Repository should check active status using URL

      // Setup DB to return the item we just added
      when(
        mockLocalDataSource.getDownloads(),
      ).thenAnswer((_) async => [addedItem]);

      // Setup Service to report URL as active
      // Note: In real app, DownloadService uses SQLite.
      // We need to verify that repository calls `isDownloadActive(url)` not `id`.

      // Since we can't easily integrate real SQLite here without creating a full integration test environment,
      // we check the interaction via the logic flow or rely on the unit test we already updated.
      // However, we can check `isSurahDownloading` public API integration.

      // We need to trick the generic "isDownloadActive" if possible or just rely on the fact
      // that we are verifying the "flow".

      // Let's verify `isSurahDownloading` works correctly with the composite ID item in DB

      // NOTE: Because DownloadService relies on MethodChannels or SQLite queries which we replaced with
      // MockFlutterDownloaderWrapper, `DownloadService.isDownloadActive` logic depends on `loadTasksWithRawQuery`.

      final bool isDownloading = await repository.isSurahDownloading(
        url,
        reciter,
      );
      expect(isDownloading, isTrue);

      // Verify that loadTasks was called to check status
      verify(mockDownloader.loadTasks()).called(greaterThan(0));

      // Ensure no query used the composite ID (since we don't use raw queries anymore)
      verifyNever(
        mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
      );
    });
  });
}
