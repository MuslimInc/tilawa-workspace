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

import 'download_service_impl_test.mocks.dart';

@GenerateMocks([
  FlutterDownloaderWrapper,
  DownloadFileHelper,
  DownloadStatusMapper,
  DownloadIsolateManager,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadService Stream & Edge Cases', () {
    test('download handles enqueue returning null (failure)', () async {
      // Covers lines 410, 424-426
      final localMockDownloader = MockFlutterDownloaderWrapper();
      final localMockFileHelper = MockDownloadFileHelper();
      final localMockIsolateManager = MockDownloadIsolateManager();

      when(
        localMockIsolateManager.updateStream,
      ).thenAnswer((_) => const Stream.empty());
      when(localMockIsolateManager.registerPort()).thenReturn(null);
      when(
        localMockDownloader.initialize(debug: anyNamed('debug')),
      ).thenAnswer((_) async {});
      when(localMockDownloader.registerCallback(any)).thenAnswer((_) async {});
      when(localMockFileHelper.getDirectoryName(any)).thenReturn('/path/to');
      when(localMockFileHelper.getFileName(any)).thenReturn('file.mp3');
      when(localMockFileHelper.ensureDirectoryExists(any)).thenReturn(true);
      when(localMockDownloader.loadTasks()).thenAnswer((_) async => []);

      // enqueue returns null
      when(
        localMockDownloader.enqueue(
          url: anyNamed('url'),
          savedDir: anyNamed('savedDir'),
          fileName: anyNamed('fileName'),
          openFileFromNotification: anyNamed('openFileFromNotification'),
          showNotification: anyNamed('showNotification'),
          title: anyNamed('title'),
        ),
      ).thenAnswer((_) async => null);

      final localService = DownloadServiceImpl(
        flutterDownloader: localMockDownloader,
        fileHelper: localMockFileHelper,
        statusMapper: MockDownloadStatusMapper(),
        isolateManager: localMockIsolateManager,
      );

      await localService.download(
        id: 'id',
        url: 'url',
        filePath: '/path/file.mp3',
        title: 'Title',
        reciterName: 'Reciter',
      );

      // Verify no crash, and active downloads should be empty involved
      expect(await localService.getActiveDownloadIds(), isEmpty);
      await localService.disposeService();
    });

    test('getProgressStream filters events correctly', () async {
      final localMockIsolateManager = MockDownloadIsolateManager();
      final isolateController =
          StreamController<(String, DownloadTaskStatus, int)>.broadcast();

      when(
        localMockIsolateManager.updateStream,
      ).thenAnswer((_) => isolateController.stream);
      when(localMockIsolateManager.registerPort()).thenReturn(null);

      final localMockDownloader = MockFlutterDownloaderWrapper();
      when(localMockDownloader.initialize(debug: any)).thenAnswer((_) async {});
      when(localMockDownloader.registerCallback(any)).thenAnswer((_) async {});
      when(localMockDownloader.loadTasks()).thenAnswer((_) async => []);

      final localService = DownloadServiceImpl(
        flutterDownloader: localMockDownloader,
        isolateManager: localMockIsolateManager,
      );

      await localService.initialize();

      when(localMockDownloader.loadTasks()).thenAnswer(
        (_) async => [
          DownloadTask(
            taskId: 't1',
            status: DownloadTaskStatus.running,
            url: 'url1',
            savedDir: '',
            filename: '',
            progress: 0,
            timeCreated: 0,
            allowCellular: true,
          ),
          DownloadTask(
            taskId: 't2',
            status: DownloadTaskStatus.running,
            url: 'url2',
            savedDir: '',
            filename: '',
            progress: 0,
            timeCreated: 0,
            allowCellular: true,
          ),
        ],
      );

      final Stream<DownloadProgress> stream1 = localService.getProgressStream(
        'url1',
      );
      final Stream<DownloadProgress> stream2 = localService.getProgressStream(
        'url2',
      );

      final Future<void> future1 = expectLater(
        stream1,
        emits(predicate<DownloadProgress>((p) => p.id == 'url1')),
      );

      final Future<void> future2 = expectLater(
        stream2,
        emits(predicate<DownloadProgress>((p) => p.id == 'url2')),
      );

      // Emit updates
      isolateController.add(('t1', DownloadTaskStatus.running, 10));
      isolateController.add(('t2', DownloadTaskStatus.running, 20));

      await Future.wait([future1, future2]);
      await localService.disposeService();
      await isolateController.close();
    });

    test('_handleTaskUpdate removing from active cache', () async {
      // Covers lines 298-299
      final localMockIsolateManager = MockDownloadIsolateManager();
      final isolateController =
          StreamController<(String, DownloadTaskStatus, int)>.broadcast();
      when(
        localMockIsolateManager.updateStream,
      ).thenAnswer((_) => isolateController.stream);
      when(localMockIsolateManager.registerPort()).thenReturn(null);

      final localMockDownloader = MockFlutterDownloaderWrapper();
      when(localMockDownloader.initialize(debug: any)).thenAnswer((_) async {});
      when(localMockDownloader.registerCallback(any)).thenAnswer((_) async {});

      // Setup a completed task
      when(localMockDownloader.loadTasks()).thenAnswer(
        (_) async => [
          DownloadTask(
            taskId: 't1',
            status: DownloadTaskStatus.complete,
            url: 'url1',
            savedDir: '',
            filename: '',
            progress: 100,
            timeCreated: 0,
            allowCellular: true,
          ),
        ],
      );

      final localService = DownloadServiceImpl(
        flutterDownloader: localMockDownloader,
        isolateManager: localMockIsolateManager,
      );

      await localService.initialize();

      // Initially active? logic says loadTasks populates active if run/enqueue.
      // So 'complete' won't be in active.
      expect(await localService.isStatusDownloadActive('url1'), isFalse);

      // Now send an update saying it IS running (started)
      isolateController.add(('t1', DownloadTaskStatus.running, 0));
      await Future.delayed(Duration.zero); // let event digest

      expect(await localService.isStatusDownloadActive('url1'), isTrue);

      // now send complete
      isolateController.add(('t1', DownloadTaskStatus.complete, 100));
      await Future.delayed(Duration.zero);

      expect(await localService.isStatusDownloadActive('url1'), isFalse);

      await localService.disposeService();
      await isolateController.close();
    });
  });
}
