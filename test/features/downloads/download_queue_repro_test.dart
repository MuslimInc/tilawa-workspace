import 'dart:io';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/data/services/download_queue_manager.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';

import 'data/services/download_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterDownloaderWrapper mockDownloader;

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dqm_test');
    mockDownloader = MockFlutterDownloaderWrapper();
    DownloadService.flutterDownloaderTestOverride = mockDownloader;

    // Setup Service basics
    when(
      mockDownloader.initialize(debug: anyNamed('debug')),
    ).thenAnswer((_) async {});
    when(
      mockDownloader.registerCallback(any, step: anyNamed('step')),
    ).thenAnswer((_) async {});

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

      enqueuedTasks.add(
        DownloadTask(
          taskId: taskId,
          status: DownloadTaskStatus.enqueued,
          progress: 0,
          url: url,
          filename:
              invocation.namedArguments[const Symbol('fileName')] as String?,
          savedDir:
              invocation.namedArguments[const Symbol('savedDir')] as String,
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        ),
      );
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

    // Reset DQM
    DownloadQueueManager.reset();
  });

  tearDown(() async {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    DownloadQueueManager.instance.dispose();
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
    await DownloadQueueManager.instance.initialize();

    for (var i = 1; i <= 5; i++) {
      final filePath = '${tempDir.path}/$i.mp3';
      await DownloadQueueManager.instance.enqueue(
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
      DownloadQueueManager.instance.queueLength,
      3,
      reason: 'DQM queue should hold 3 tasks',
    );

    expect(
      DownloadQueueManager.instance.activeDownloadsCount,
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
