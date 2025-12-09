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
import 'package:path/path.dart' as path;

import 'download_service_test.mocks.dart';

@GenerateMocks([FlutterDownloaderWrapper])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadService', () {
    // const testId = 'test_download_id';
    const testUrl = 'https://example.com/test.mp3';

    late Directory tempDir;
    late String testFilePath;

    const testTitle = 'Test Audio';
    const testReciterName = 'Test Reciter';
    const testTaskId = 'task-uuid-123';

    late MockFlutterDownloaderWrapper mockDownloader;
    late DownloadService downloadService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('download_test');
      testFilePath = path.join(tempDir.path, 'test.mp3');

      mockDownloader = MockFlutterDownloaderWrapper();

      when(
        mockDownloader.initialize(debug: anyNamed('debug')),
      ).thenAnswer((_) async {});
      when(
        mockDownloader.registerCallback(any, step: anyNamed('step')),
      ).thenAnswer((_) async {});
      when(
        mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
      ).thenAnswer((_) async => []);

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

    test('initialize registers port and callback', () async {
      await downloadService.initialize();

      verify(mockDownloader.initialize(debug: anyNamed('debug'))).called(1);
      verify(
        mockDownloader.registerCallback(any, step: anyNamed('step')),
      ).called(1);

      final SendPort? port = IsolateNameServer.lookupPortByName(
        'downloader_send_port',
      );
      expect(port, isNotNull);
    });

    group('download', () {
      test('should enqueue download and emit pending status', () async {
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
            savedDir: anyNamed('savedDir'),
            fileName: anyNamed('fileName'),
            openFileFromNotification: false,
            title: testTitle,
            headers: anyNamed('headers'),
            requiresStorageNotLow: anyNamed('requiresStorageNotLow'),
            saveInPublicStorage: anyNamed('saveInPublicStorage'),
          ),
        ).called(1);

        // Wait for stream to emit
        await Future.delayed(Duration.zero);

        expect(progressEvents, isNotEmpty);
        expect(progressEvents.first.status, DownloadStatus.pending);
        expect(progressEvents.first.id, testUrl);

        await subscription.cancel();
      });

      test('should not enqueue if already active', () async {
        final task = DownloadTask(
          taskId: 'existing-task',
          status: DownloadTaskStatus.running,
          progress: 50,
          url: testUrl,
          filename: 'test.mp3',
          savedDir: '/path',
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );

        when(
          mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
        ).thenAnswer((_) async => [task]);

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
            headers: anyNamed('headers'),
            showNotification: anyNamed('showNotification'),
            openFileFromNotification: anyNamed('openFileFromNotification'),
            requiresStorageNotLow: anyNamed('requiresStorageNotLow'),
            saveInPublicStorage: anyNamed('saveInPublicStorage'),
          ),
        );
      });
    });

    group('Progress Updates', () {
      test('should handle progress updates from port', () async {
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
        expect(port, isNotNull);

        port!.send([testTaskId, 2, 50]);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(progressEvents.last.status, DownloadStatus.downloading);
        expect(progressEvents.last.progress, 0.5);

        await subscription.cancel();
      });

      test('should resolve ID from DB if not in map', () async {
        await downloadService.initialize();

        final task = DownloadTask(
          taskId: testTaskId,
          status: DownloadTaskStatus.running,
          progress: 50,
          url: testUrl,
          filename: 'test.mp3',
          savedDir: '/path',
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );

        when(
          mockDownloader.loadTasksWithRawQuery(
            query: argThat(
              contains("WHERE task_id = '$testTaskId'"),
              named: 'query',
            ),
          ),
        ).thenAnswer((_) async => [task]);

        final progressEvents = <DownloadProgress>[];
        final StreamSubscription<DownloadProgress> subscription =
            downloadService
                .getProgressStream(testUrl)
                .listen(progressEvents.add);

        final SendPort? port = IsolateNameServer.lookupPortByName(
          'downloader_send_port',
        );
        port!.send([testTaskId, 2, 50]);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(progressEvents, isNotEmpty);
        expect(progressEvents.first.id, testUrl);
        expect(progressEvents.first.status, DownloadStatus.downloading);

        await subscription.cancel();
      });
    });

    group('cancel', () {
      test('should cancel task', () async {
        final task = DownloadTask(
          taskId: testTaskId,
          status: DownloadTaskStatus.running,
          progress: 50,
          url: testUrl,
          filename: 'test.mp3',
          savedDir: '/path',
          timeCreated: DateTime.now().millisecondsSinceEpoch,
          allowCellular: true,
        );

        when(
          mockDownloader.loadTasksWithRawQuery(
            query: argThat(contains("WHERE url = '$testUrl'"), named: 'query'),
          ),
        ).thenAnswer((_) async => [task]);

        await downloadService.cancel(testUrl);

        verify(mockDownloader.cancel(taskId: testTaskId)).called(1);
      });
    });
  });
}
