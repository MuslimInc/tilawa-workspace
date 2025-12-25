import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/downloads/data/services/download_service_impl.dart';

import 'helpers/mock_helper.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterDownloaderWrapper mockDownloader;

  setUp(() {
    mockDownloader = MockFlutterDownloaderWrapper();

    when(
      mockDownloader.initialize(debug: anyNamed('debug')),
    ).thenAnswer((_) async {});
    when(
      mockDownloader.registerCallback(any, step: anyNamed('step')),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  });

  test(
    'DownloadService activeDownloadIds returns correct tasks after restart',
    () async {
      // Arrange
      // Simulate 3 existing tasks in DB
      final existingTasks = [
        DownloadTask(
          taskId: 'uuid_1',
          url: 'url1',
          filename: 'f1',
          status: DownloadTaskStatus.running,
          timeCreated: 0,
          savedDir: '',
          progress: 50,
          allowCellular: true,
        ),
        DownloadTask(
          taskId: 'uuid_2',
          url: 'url2',
          filename: 'f2',
          status: DownloadTaskStatus.enqueued,
          timeCreated: 0,
          savedDir: '',
          progress: 0,
          allowCellular: true,
        ),
        DownloadTask(
          taskId: 'uuid_3',
          url: 'url3',
          filename: 'f3',
          status: DownloadTaskStatus.running,
          timeCreated: 0,
          savedDir: '',
          progress: 30,
          allowCellular: true,
        ),
      ];

      when(mockDownloader.loadTasks()).thenAnswer((_) async => existingTasks);

      // Need also loadTasksWithRawQuery for individual checks if used
      when(
        mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
      ).thenAnswer((invocation) async {
        final query =
            invocation.namedArguments[const Symbol('query')] as String;
        if (query.contains("url = 'url1'")) {
          return [existingTasks[0]];
        }
        if (query.contains("url = 'url2'")) {
          return [existingTasks[1]];
        }
        if (query.contains("url = 'url3'")) {
          return [existingTasks[2]];
        }
        return [];
      });

      // Act
      // Initialize service (simulating app restart with new instance)
      final service = DownloadServiceImpl(flutterDownloader: mockDownloader);

      final List<String> activeIds = await service.getActiveDownloadIds();

      // Assert
      // should contain the 3 existing URLs (ids) - filter logic in getActiveDownloadIds might exclude non-running/paused?
      // getActiveDownloadIds: where status == running || enqueued || paused
      // All 3 above map to active.
      expect(
        activeIds.length,
        3,
        reason: 'activeDownloadIds should contain the 3 existing tasks',
      );
      expect(activeIds, containsAll(['url1', 'url2', 'url3']));

      // Try to start a new download
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
      ).thenAnswer((_) async => 'uuid_4');

      await service.download(
        id: 'url4',
        url: 'url4',
        filePath: 'f4',
        title: 't4',
        reciterName: 'r4',
      );

      // Verify enqueue is called (DownloadService now delegates queue management to FlutterDownloader mostly)
      verify(
        mockDownloader.enqueue(
          url: 'url4',
          savedDir: anyNamed('savedDir'),
          fileName: anyNamed('fileName'),
          headers: anyNamed('headers'),
          showNotification: anyNamed('showNotification'),
          openFileFromNotification: false,
          requiresStorageNotLow: anyNamed('requiresStorageNotLow'),
          saveInPublicStorage: anyNamed('saveInPublicStorage'),
          title: 't4',
        ),
      ).called(1);
    },
  );
}
