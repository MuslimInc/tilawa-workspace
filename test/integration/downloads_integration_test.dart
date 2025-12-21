import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/data/datasources/downloads_local_datasource.dart';
import 'package:muzakri/features/downloads/data/repositories/downloads_repository_impl.dart';
import 'package:muzakri/features/downloads/data/services/batch_download_manager.dart';
import 'package:muzakri/features/downloads/data/services/download_notification_service.dart';
import 'package:muzakri/features/downloads/data/services/download_queue_manager.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';

import '../features/downloads/data/services/download_service_test.mocks.dart';
// Generate mocks
@GenerateMocks([
  DownloadsLocalDataSource,
  DownloadNotificationService,
  BatchDownloadManager,
])
import 'downloads_integration_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DownloadsRepositoryImpl repository;
  late MockDownloadsLocalDataSource mockLocalDataSource;
  late MockFlutterDownloaderWrapper mockDownloader;
  late MockBatchDownloadManager mockBatchDownloadManager;
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync();
    // Setup mocks
    // Setup mocks
    mockLocalDataSource = MockDownloadsLocalDataSource();
    mockDownloader = MockFlutterDownloaderWrapper();
    mockBatchDownloadManager = MockBatchDownloadManager();
    DownloadService.flutterDownloaderTestOverride = mockDownloader;

    // Register DownloadService in GetIt
    final GetIt getIt = GetIt.instance;
    if (!getIt.isRegistered<DownloadService>()) {
      getIt.registerSingleton<DownloadService>(DownloadService.instance);
    }
    final mockDownloadNotificationService = MockDownloadNotificationService();
    if (!getIt.isRegistered<DownloadNotificationService>()) {
      getIt.registerSingleton<DownloadNotificationService>(
        mockDownloadNotificationService,
      );
    }
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

    // Reset singleton
    DownloadQueueManager.reset();
    await DownloadQueueManager.instance.initialize();

    repository = DownloadsRepositoryImpl(
      mockLocalDataSource,
      DownloadService.instance,
      mockBatchDownloadManager,
    );

    // Default stubs
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
    when(mockDownloader.loadTasks()).thenAnswer((_) async => []);
    when(
      mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
    ).thenAnswer((_) async => []);

    // Stub logging to avoid noise
    // setupLogger(); // Assuming logger is accessible or mocked if needed
  });

  tearDown(() {
    final GetIt getIt = GetIt.instance;
    if (getIt.isRegistered<DownloadService>()) {
      getIt.unregister<DownloadService>();
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
        DownloadQueueManager.instance.isQueued(url) ||
            DownloadQueueManager.instance.isActive(url),
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
