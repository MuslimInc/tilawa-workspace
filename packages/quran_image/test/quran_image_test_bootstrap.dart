import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/domain/domain.dart';

/// Shared DI + temp assets for [QuranImagePage] widget tests.
Future<Directory> bootstrapQuranImagePageTest() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await sl.reset();
  await initDependencies();

  final tempDirectory = await Directory.systemTemp.createTemp(
    'quran_image_widget_test_',
  );
  const transparentPixel =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a5m0AAAAASUVORK5CYII=';
  final imageBytes = base64Decode(transparentPixel);

  for (var line = 1; line <= 15; line++) {
    final file = File('${tempDirectory.path}/page_1_line_$line.png');
    await file.writeAsBytes(imageBytes);
  }

  final headerFile = File('${tempDirectory.path}/sura_header_banner.png');
  await headerFile.writeAsBytes(imageBytes);

  final linePaths = <int, String>{
    for (var line = 1; line <= 15; line++)
      line: '${tempDirectory.path}/page_1_line_$line.png',
  };

  final imageCacheRepository = _ReadyQuranImageCacheRepository(
    linePaths: linePaths,
    headerPath: headerFile.path,
  );

  await sl.unregister<QuranImageCacheRepository>();
  sl.registerLazySingleton<QuranImageCacheRepository>(
    () => imageCacheRepository,
  );

  await sl.unregister<DecodedQuranImageCache>();
  sl.registerLazySingleton<DecodedQuranImageCache>(
    () => _FakeDecodedQuranImageCache(),
  );

  await sl.unregister<VerseMarkerRepository>();
  sl.registerLazySingleton<VerseMarkerRepository>(
    _EmptyVerseMarkerRepository.new,
  );

  return tempDirectory;
}

Future<void> tearDownQuranImageTest(Directory? tempDirectory) async {
  await sl.reset();
  if (tempDirectory != null && tempDirectory.existsSync()) {
    await tempDirectory.delete(recursive: true);
  }
}

class _ReadyQuranImageCacheRepository implements QuranImageCacheRepository {
  const _ReadyQuranImageCacheRepository({
    required this.linePaths,
    required this.headerPath,
  });

  final Map<int, String> linePaths;
  final String headerPath;

  @override
  QuranImageCacheStatus get status => const QuranImageCacheStatus.ready();

  @override
  String? lineImageFilePath({
    required int pageNumber,
    required int oneBasedLineNumber,
  }) {
    if (pageNumber != 1) {
      return null;
    }
    return linePaths[oneBasedLineNumber];
  }

  @override
  Future<QuranImageCacheStatus> prepareCache({
    void Function(QuranImageCacheStatus status)? onProgress,
  }) async {
    const status = QuranImageCacheStatus.ready();
    onProgress?.call(status);
    return status;
  }

  @override
  String? surahHeaderBannerFilePath() => headerPath;
}

class _FakeDecodedQuranImageCache implements DecodedQuranImageCache {
  @override
  void handleMemoryPressure() {}

  @override
  Future<void> prewarmFileImage(String imagePath) async {}

  @override
  Future<void> prewarmLineImage({
    required String imagePath,
    required int cacheWidth,
  }) async {}
}

class _EmptyVerseMarkerRepository implements VerseMarkerRepository {
  @override
  void dispose() {}

  @override
  bool get isDebugMode => false;

  @override
  bool get isPreloaded => true;

  @override
  bool get isPreloading => false;

  @override
  double get preloadProgress => 1.0;

  @override
  List<VerseMarkerData> getMarkersForPage(int pageNumber) => const [];

  @override
  Future<List<VerseMarkerData>> getMarkersForPageAsync(int pageNumber) async =>
      const [];
}
