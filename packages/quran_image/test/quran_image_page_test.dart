import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/core/constants/surah_header_constants.dart';
import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/data/repositories/asset_verse_marker_repository.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/presentation/widgets/quran_image_content.dart';
import 'package:quran_image/quran_image_page.dart';

import 'quran_image_test_bootstrap.dart';

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

    final pageTwoLinePaths = <int, String>{};
    for (var line = 1; line <= 15; line++) {
      final file = File('${tempDirectory.path}/page_2_line_$line.png');
      await file.writeAsBytes(imageBytes);
      pageTwoLinePaths[line] = file.path;
    }

    final headerFile = File('${tempDirectory.path}/sura_header_banner.png');
    await headerFile.writeAsBytes(imageBytes);

    decodedCache = _FakeDecodedQuranImageCache();
    imageCacheRepository = _ReadyQuranImageCacheRepository(
      linePathsByPage: {1: linePaths, 2: pageTwoLinePaths},
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
      wrapQuranImageTestApp(
        const Scaffold(body: QuranImagePage(pageNumber: 1)),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('quran-image-page-loading-surface')),
      findsNothing,
    );
    expect(find.byType(Image).evaluate().length, greaterThanOrEqualTo(15));
  });

  testWidgets('QuranImagePage exposes the surah index action in the header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    var taps = 0;

    await tester.pumpWidget(
      wrapQuranImageTestApp(
        Scaffold(
          body: QuranImagePage(
            pageNumber: 1,
            onShowIndex: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Surah index'));
    await tester.pump();

    expect(taps, 1);
    expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);
  });

  testWidgets(
    'pages 1 and 2 use the standard 15-line grid without vertical centering',
    (tester) async {
      const viewport = Size(390, 700);
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final pageNumber in [1, 2]) {
        await tester.pumpWidget(
          wrapQuranImageTestApp(
            Scaffold(body: QuranImagePage(pageNumber: pageNumber)),
          ),
        );
        await tester.pump();

        final firstLine = tester.widget<Positioned>(
          find.byKey(const ValueKey<int>(0)),
        );
        expect(
          firstLine.top,
          0,
          reason: 'page $pageNumber line slot 0 must start at the top',
        );

        final headerLine = tester.widget<Positioned>(
          find.byKey(const ValueKey<String>('header:3')),
        );
        final layoutHeight = tester
            .getSize(find.byType(QuranImageContent))
            .height;
        final lineHeight = tester
            .getSize(
              find.byKey(const ValueKey<int>(0)),
            )
            .height;
        final expectedHeaderTop =
            (layoutHeight - lineHeight) /
            SurahHeaderConstants.lastLineIndex *
            3;
        expect(
          headerLine.top,
          closeTo(expectedHeaderTop, 0.01),
          reason: 'page $pageNumber surah banner must sit on line slot 3',
        );
      }
    },
  );
}

class _ReadyQuranImageCacheRepository implements QuranImageCacheRepository {
  const _ReadyQuranImageCacheRepository({
    required this.linePathsByPage,
    required this.headerPath,
  });

  final Map<int, Map<int, String>> linePathsByPage;
  final String headerPath;

  @override
  QuranImageCacheStatus get status => const QuranImageCacheStatus.ready();

  @override
  String? lineImageFilePath({
    required int pageNumber,
    required int oneBasedLineNumber,
  }) {
    return linePathsByPage[pageNumber]?[oneBasedLineNumber];
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
  ImageProvider<Object> fileImageProvider({required String imagePath}) {
    return MemoryImage(Uint8List(0));
  }

  @override
  ImageProvider<Object> lineImageProvider({
    required String imagePath,
    required int cacheWidth,
  }) {
    return MemoryImage(Uint8List(0));
  }

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
