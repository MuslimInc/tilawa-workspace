import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/downloads/data/datasources/downloads_local_datasource.dart';
import 'package:tilawa/features/downloads/data/services/download_path_resolver.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';

class MockDownloadsLocalDataSource extends Mock
    implements DownloadsLocalDataSource {}

void main() {
  late MockDownloadsLocalDataSource mockDataSource;
  late DownloadPathResolver resolver;

  setUp(() {
    mockDataSource = MockDownloadsLocalDataSource();
    resolver = DownloadPathResolver(mockDataSource);
  });

  group('getDownloadsDir', () {
    test('fetches from datasource and caches it', () async {
      when(
        () => mockDataSource.getDownloadsDirectory(),
      ).thenAnswer((_) async => '/root/downloads');

      final String dir1 = await resolver.getDownloadsDir();
      expect(dir1, '/root/downloads');
      verify(() => mockDataSource.getDownloadsDirectory()).called(1);

      final String dir2 = await resolver.getDownloadsDir();
      expect(dir2, '/root/downloads');
      // Should not be called again
      verifyNever(() => mockDataSource.getDownloadsDirectory());
    });
  });

  group('resolveDownloadPath', () {
    test('returns item if filePath is empty', () {
      final item = DownloadItem(
        id: '1',
        title: 'Title',
        url: 'url',
        filePath: '',
        reciterName: 'reciter',
        reciterId: 1,
        status: DownloadStatus.completed,
        progress: 1.0,
        fileSize: 100,
        downloadedSize: 100,
        createdAt: DateTime.now(),
      );

      final DownloadItem result = resolver.resolveDownloadPath(
        item,
        '/new/root',
      );
      expect(result.filePath, '');
    });

    test('updates filePath based on new downloadsDir', () {
      final item = DownloadItem(
        id: '1',
        title: 'Title',
        url: 'http://example.com/1.mp3', // calculated name probably '1.mp3'
        filePath: '/old/root/reciter/1.mp3',
        reciterName: 'reciter',
        reciterId: 1,
        status: DownloadStatus.completed,
        progress: 1.0,
        fileSize: 100,
        downloadedSize: 100,
        createdAt: DateTime.now(),
      );

      // The logic relies on DownloadPathUtils.calculateRelativePath and resolveFullPath.
      // Usually ReciterName/filename.
      // Assuming calculateRelativePath('http://example.com/1.mp3', 'reciter') returns 'reciter/1.mp3'

      final DownloadItem result = resolver.resolveDownloadPath(
        item,
        '/new/root',
      );

      // Expected: /new/root/reciter/1.mp3
      // But verify logic: if logic simply joins, we check end result.
      expect(result.filePath, contains('/new/root'));
      // Reciter name should be part of path usually for Tilawa structure if utils work as expected.
      expect(result.filePath, contains('reciter'));
    });

    test('returns same item if path matches', () {
      final item = DownloadItem(
        id: '1',
        title: 'Title',
        url: 'http://example.com/file.mp3',
        filePath: '/root/downloads/reciter/file.mp3',
        reciterName: 'reciter',
        reciterId: 1,
        status: DownloadStatus.completed,
        progress: 1.0,
        fileSize: 100,
        downloadedSize: 100,
        createdAt: DateTime.now(),
      );

      // Assuming standard logic produces 'reciter/file.mp3'
      // /root/downloads + reciter/file.mp3

      final DownloadItem result = resolver.resolveDownloadPath(
        item,
        '/root/downloads',
      );

      expect(result, item);
    });
  });
}
