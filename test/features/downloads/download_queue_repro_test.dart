import 'dart:io';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/downloads/data/services/download_notification_service.dart';
import 'package:tilawa/features/downloads/data/services/download_queue_manager.dart';
import 'package:tilawa/features/downloads/data/services/download_service_impl.dart';
import 'package:tilawa/features/downloads/data/services/download_service_interface.dart';

import 'helpers/mock_helper.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterDownloaderWrapper mockDownloader;

  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('dqm_test');
    mockDownloader = MockFlutterDownloaderWrapper();

    // Reset dependencies cleanly
    if (GetIt.I.isRegistered<DownloadQueueManager>()) {
      GetIt.I.unregister<DownloadQueueManager>();
    }
    if (GetIt.I.isRegistered<DownloadServiceInterface>()) {
      GetIt.I.unregister<DownloadServiceInterface>();
    }
    if (GetIt.I.isRegistered<DownloadNotificationService>()) {
      GetIt.I.unregister<DownloadNotificationService>();
    }

    // Register Notification Service Mock
    final mockNotification = MockDownloadNotificationService();
    GetIt.I.registerSingleton<DownloadNotificationService>(mockNotification);

    // Register DownloadService (Implementation) with mocked downloader
    final downloadService = DownloadServiceImpl(
      flutterDownloader: mockDownloader,
    );
    GetIt.I.registerSingleton<DownloadServiceInterface>(downloadService);

    // Register DownloadQueueManager using the registered services
    final downloadQueueManager = DownloadQueueManager(
      downloadService,
      mockNotification,
    );
    GetIt.I.registerSingleton<DownloadQueueManager>(downloadQueueManager);

    // Mock notification behaviors
    when(mockNotification.initialize()).thenAnswer((_) async {});
    when(
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
    ).thenAnswer((_) async {});
    when(mockNotification.cancelNotification(any)).thenAnswer((_) async {});

    // Setup Service basics
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

    // Default empty tasks
    when(mockDownloader.loadTasks()).thenAnswer((_) async => []);
    when(
      mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
    ).thenAnswer((_) async => []);

    // Track enqueued tasks by wrapper
    final List<DownloadTask> enqueuedTasks = [];

    // Mock enqueue to simulate adding to FlutterDownloader
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
      final url = invocation.namedArguments[const Symbol('url')] as String;
      final taskId = 'task_$url'; // Fake ID derived from URL for tracing

      final task = DownloadTask(
        taskId: taskId,
        status: DownloadTaskStatus.enqueued,
        progress: 0,
        url: url,
        filename:
            invocation.namedArguments[const Symbol('fileName')] as String?,
        savedDir: invocation.namedArguments[const Symbol('savedDir')] as String,
        timeCreated: DateTime.now().millisecondsSinceEpoch,
        allowCellular: true,
      );
      enqueuedTasks.add(task);
      return taskId;
    });

    // Mock loadTasksWithRawQuery to return what's "in the DB" (enqueuedTasks)
    when(
      mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
    ).thenAnswer((invocation) async {
      final query = invocation.namedArguments[const Symbol('query')] as String;

      // Very basic SQL parser simulation for the test
      if (query.contains('url =')) {
        // Extract URL (very roughly) - assumes single quotes
        final urlRegex = RegExp(r"url = '([^']+)'");
        final RegExpMatch? match = urlRegex.firstMatch(query);
        if (match != null) {
          final String? url = match.group(1);
          return enqueuedTasks.where((t) => t.url == url).toList();
        }
      }
      if (query.contains('task_id =')) {
        // Extract ID
        final idRegex = RegExp(r"task_id = '([^']+)'");
        final RegExpMatch? match = idRegex.firstMatch(query);
        if (match != null) {
          final String? id = match.group(1);
          return enqueuedTasks.where((t) => t.taskId == id).toList();
        }
      }

      return [];
    });

    when(mockDownloader.loadTasks()).thenAnswer((_) async => enqueuedTasks);
  });

  tearDown(() async {
    IsolateNameServer.removePortNameMapping('downloader_send_port');

    if (GetIt.I.isRegistered<DownloadQueueManager>()) {
      try {
        GetIt.I<DownloadQueueManager>().dispose();
      } catch (_) {}
      await GetIt.I.unregister<DownloadQueueManager>();
    }

    if (GetIt.I.isRegistered<DownloadServiceInterface>()) {
      await GetIt.I.unregister<DownloadServiceInterface>();
    }

    if (GetIt.I.isRegistered<DownloadNotificationService>()) {
      await GetIt.I.unregister<DownloadNotificationService>();
    }

    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  test('DownloadQueueManager floods DownloadService with pending tasks', () async {
    // Arrange
    // DQM limit is 2 (assumed, or strictly 2).
    // If DQM hasn't been updated, it might rely on internal counting.
    //
    // We enqueue 5 items.

    // Act
    await GetIt.I<DownloadQueueManager>().initialize();

    for (var i = 1; i <= 5; i++) {
      final filePath = '${tempDir.path}/$i.mp3';
      await GetIt.I<DownloadQueueManager>().enqueue(
        id: 'http://example.com/$i.mp3', // ID is URL in our refactor
        url: 'http://example.com/$i.mp3',
        filePath: filePath,
        title: 'Title $i',
        reciterName: 'Reciter',
      );
    }

    // Allow async processing
    await Future.delayed(const Duration(milliseconds: 100));

    // Assert
    // 1. Check DQM queue stats
    // Note: DQM uses "activeDownloadsCount" and "queueLength".
    // If DQM is working, it should hold tasks back if it thinks 2 are running.
    // Since we mocked startDownload -> enqueue -> returns taskId, DS emits "pending".
    //
    // If DQM counts "pending" as active (likely), it will stop after 2.
    // So 2 active, 3 in DQM queue.

    // Note: We need to verify what DQM considers "active".
    // If DQM listens to DS.globalProgressStream, it sees 'pending'.

    expect(
      GetIt.I<DownloadQueueManager>().queueLength,
      3,
      reason: 'DQM queue should hold 3 tasks',
    );

    expect(
      GetIt.I<DownloadQueueManager>().activeDownloadsCount,
      2,
      reason: 'DQM active count should be 2',
    );

    // 2. Mock 'enqueue' should have been called only 2 times.
    verify(
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
    ).called(2);
  });
}
