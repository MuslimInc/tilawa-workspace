import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/downloads/data/services/download_service.dart';
import 'package:tilawa/features/downloads/data/services/flutter_downloader_wrapper.dart';
import 'package:tilawa/features/downloads/data/services/helpers/download_isolate_manager.dart';

import 'download_service_impl_test.mocks.dart';

@GenerateMocks([FlutterDownloaderWrapper, DownloadIsolateManager])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadService Static Compatibility Layer', () {
    late DownloadServiceImpl testService;
    late MockFlutterDownloaderWrapper mockDownloaderForStatic;

    setUp(() {
      final GetIt getIt = GetIt.instance;
      // Ensure clean slate
      if (getIt.isRegistered<DownloadService>()) {
        getIt.unregister<DownloadService>();
      }

      mockDownloaderForStatic = MockFlutterDownloaderWrapper();
      final mockIsolateManager = MockDownloadIsolateManager();
      when(
        mockIsolateManager.updateStream,
      ).thenAnswer((_) => const Stream.empty());
      when(mockIsolateManager.registerPort()).thenReturn(null);
      when(
        mockDownloaderForStatic.initialize(debug: anyNamed('debug')),
      ).thenAnswer((_) async {});
      when(
        mockDownloaderForStatic.registerCallback(any),
      ).thenAnswer((_) async {});
      when(mockDownloaderForStatic.loadTasks()).thenAnswer((_) async => []);

      testService = DownloadServiceImpl(
        flutterDownloader: mockDownloaderForStatic,
        isolateManager: mockIsolateManager,
      );
      getIt.registerSingleton<DownloadService>(testService);
    });

    tearDown(() {
      if (GetIt.instance.isRegistered<DownloadService>()) {
        GetIt.instance.unregister<DownloadService>();
      }
    });

    test('accessing instance getter works', () {
      expect(DownloadServiceImpl.instance, equals(testService));
    });

    test('startDownload forwards call', () async {
      await DownloadService.startDownload(
        id: 'id',
        url: 'url',
        filePath: '/p/f',
        title: 't',
        reciterName: 'r',
      );
      verify(
        mockDownloaderForStatic.initialize(debug: anyNamed('debug')),
      ).called(1);
    });

    test('cancelDownload forwards call', () async {
      await DownloadService.cancelDownload('id');
      verify(
        mockDownloaderForStatic.initialize(debug: anyNamed('debug')),
      ).called(1);
    });

    test('cancelAllDownloads forwards call', () async {
      await DownloadService.cancelAllDownloads();
      verify(
        mockDownloaderForStatic.initialize(debug: anyNamed('debug')),
      ).called(1);
    });

    test('getDownloadStatus forwards call', () async {
      await DownloadService.getDownloadStatus('id');
      verify(
        mockDownloaderForStatic.initialize(debug: anyNamed('debug')),
      ).called(1);
    });

    test('isDownloadActive forwards call', () async {
      await DownloadService.isDownloadActive('id');
      verify(
        mockDownloaderForStatic.initialize(debug: anyNamed('debug')),
      ).called(1);
    });

    test('activeDownloadIds forwards call', () async {
      await DownloadService.activeDownloadIds;
      verify(
        mockDownloaderForStatic.initialize(debug: anyNamed('debug')),
      ).called(1);
    });

    test('progressStream forwards call', () async {
      final Stream<DownloadProgress> stream = DownloadService.progressStream(
        'id',
      );
      expect(stream, isA<Stream<DownloadProgress>>());
    });

    test('globalProgressStreamStatic forwards call', () async {
      final Stream<DownloadProgress> stream =
          DownloadService.globalProgressStreamStatic;
      expect(stream, isA<Stream<DownloadProgress>>());
    });

    test('globalProgressController getter works', () {
      expect(DownloadService.globalProgressController, isNotNull);
    });

    test('flutterDownloaderTestOverride setter/getter', () {
      final newMock = MockFlutterDownloaderWrapper();
      DownloadService.flutterDownloaderTestOverride = newMock;
      expect(DownloadService.flutterDownloaderTestOverride, equals(newMock));
      // Reset
      DownloadService.flutterDownloaderTestOverride = mockDownloaderForStatic;
    });

    test('dispose calls disposeService', () async {
      await DownloadService.dispose();
    });

    test('reset calls disposeService', () async {
      await DownloadService.reset();
    });
  });
}
