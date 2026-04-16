import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image_flutter/core/di/dependency_injection.dart';
import 'package:quran_image_flutter/data/repositories/asset_verse_marker_repository.dart';
import 'package:quran_image_flutter/domain/domain.dart';
import 'package:quran_image_flutter/quran_image_page.dart';

void main() {
  late Directory tempDirectory;
  late _FakeDecodedQuranImageCache decodedCache;
  late _ReadyQuranImageCacheRepository imageCacheRepository;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await sl.reset();
    await initDependencies();

    tempDirectory = await Directory.systemTemp.createTemp(
      'quran_image_page_test_',
    );
    const transparentPixel =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a5m0AAAAASUVORK5CYII=';
    final imageBytes = base64Decode(transparentPixel);

    final linePaths = <int, String>{};
    for (var line = 1; line <= 15; line++) {
      final file = File('${tempDirectory.path}/page_1_line_$line.png');
      await file.writeAsBytes(imageBytes);
      linePaths[line] = file.path;
    }

    final headerFile = File('${tempDirectory.path}/sura_header_banner.png');
    await headerFile.writeAsBytes(imageBytes);

    decodedCache = _FakeDecodedQuranImageCache();
    imageCacheRepository = _ReadyQuranImageCacheRepository(
      linePaths: linePaths,
      headerPath: headerFile.path,
    );

    await sl.unregister<QuranImageCacheRepository>();
    sl.registerLazySingleton<QuranImageCacheRepository>(
      () => imageCacheRepository,
    );

    await sl.unregister<DecodedQuranImageCache>();
    sl.registerLazySingleton<DecodedQuranImageCache>(() => decodedCache);

    await sl.unregister<AssetVerseMarkerRepository>();
    final markerRepository = _ReadyAssetVerseMarkerRepository();
    sl.registerLazySingleton<AssetVerseMarkerRepository>(
      () => markerRepository,
    );
    await sl.unregister<VerseMarkerRepository>();
    sl.registerLazySingleton<VerseMarkerRepository>(() => markerRepository);
  });

  tearDown(() async {
    await sl.reset();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets('QuranImagePage builds synchronously without a loading surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: QuranImagePage(pageNumber: 1))),
    );

    expect(
      find.byKey(const ValueKey<String>('quran-image-page-loading-surface')),
      findsNothing,
    );
    expect(find.byType(Image).evaluate().length, greaterThanOrEqualTo(15));
  });
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
  final List<String> prewarmedLinePaths = <String>[];
  final List<String> prewarmedFilePaths = <String>[];

  @override
  void handleMemoryPressure() {}

  @override
  Future<void> prewarmFileImage(String imagePath) async {
    prewarmedFilePaths.add(imagePath);
  }

  @override
  Future<void> prewarmLineImage({
    required String imagePath,
    required int cacheWidth,
  }) async {
    prewarmedLinePaths.add(imagePath);
  }
}

class _ReadyAssetVerseMarkerRepository extends AssetVerseMarkerRepository {
  @override
  bool get isInitialized => true;

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

  @override
  Future<void> init({
    bool forceDebugSource = false,
    bool? preloadAllPages,
  }) async {}
}
