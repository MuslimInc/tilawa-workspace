import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/l10n/quran_image_localizations.dart';

/// [MaterialApp] with [QuranImageLocalizations] for widget tests.
Widget wrapQuranImageTestApp(Widget home) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: QuranImageLocalizations.localizationsDelegates,
    supportedLocales: QuranImageLocalizations.supportedLocales,
    home: home,
  );
}

/// 1×1 solid PNG for golden tests (visible when stretched with [BoxFit.fill]).
Future<Uint8List> onePixelSolidPng({
  required int r,
  required int g,
  required int b,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 1, 1),
    ui.Paint()..color = ui.Color.fromARGB(255, r, g, b),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(1, 1);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return byteData!.buffer.asUint8List();
}

/// Shared DI + temp assets for [QuranImagePage] widget tests.
Future<Directory> bootstrapQuranImagePageTest({
  Iterable<int> pageNumbers = const [1],
  bool visiblePlaceholders = false,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await sl.reset();
  await initDependencies();

  final tempDirectory = await Directory.systemTemp.createTemp(
    'quran_image_widget_test_',
  );
  const transparentPixel =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a5m0AAAAASUVORK5CYII=';
  final transparentBytes = base64Decode(transparentPixel);
  final lineBytes = visiblePlaceholders
      ? await onePixelSolidPng(r: 0xE6, g: 0xE6, b: 0xE6)
      : transparentBytes;
  final headerBytes = visiblePlaceholders
      ? await onePixelSolidPng(r: 0xC8, g: 0xA8, b: 0x6E)
      : transparentBytes;

  final linePathsByPage = <int, Map<int, String>>{};
  final bytesByPath = <String, Uint8List>{};
  for (final pageNumber in pageNumbers) {
    final linePaths = <int, String>{};
    for (var line = 1; line <= 15; line++) {
      final file = File(
        '${tempDirectory.path}/page_${pageNumber}_line_$line.png',
      );
      await file.writeAsBytes(lineBytes);
      linePaths[line] = file.path;
      bytesByPath[file.path] = lineBytes;
    }
    linePathsByPage[pageNumber] = linePaths;
  }

  final headerFile = File('${tempDirectory.path}/sura_header_banner.png');
  await headerFile.writeAsBytes(headerBytes);
  bytesByPath[headerFile.path] = headerBytes;

  final imageCacheRepository = _ReadyQuranImageCacheRepository(
    linePathsByPage: linePathsByPage,
    headerPath: headerFile.path,
  );

  await sl.unregister<QuranImageCacheRepository>();
  sl.registerLazySingleton<QuranImageCacheRepository>(
    () => imageCacheRepository,
  );

  await sl.unregister<DecodedQuranImageCache>();
  sl.registerLazySingleton<DecodedQuranImageCache>(
    () => visiblePlaceholders
        ? _BytesDecodedQuranImageCache(bytesByPath)
        : _FakeDecodedQuranImageCache(),
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

class _BytesDecodedQuranImageCache implements DecodedQuranImageCache {
  const _BytesDecodedQuranImageCache(this._bytesByPath);

  final Map<String, Uint8List> _bytesByPath;

  ImageProvider<Object> _provider(String imagePath, {int? cacheWidth}) {
    final Uint8List? bytes = _bytesByPath[imagePath];
    if (bytes == null || bytes.isEmpty) {
      return MemoryImage(Uint8List(0));
    }
    final MemoryImage memoryImage = MemoryImage(bytes);
    if (cacheWidth == null) {
      return memoryImage;
    }
    return ResizeImage.resizeIfNeeded(cacheWidth, null, memoryImage);
  }

  @override
  void handleMemoryPressure() {}

  @override
  ImageProvider<Object> fileImageProvider({required String imagePath}) {
    return _provider(imagePath);
  }

  @override
  ImageProvider<Object> lineImageProvider({
    required String imagePath,
    required int cacheWidth,
  }) {
    return _provider(imagePath, cacheWidth: cacheWidth);
  }

  @override
  Future<void> prewarmFileImage(String imagePath) async {}

  @override
  Future<void> prewarmLineImage({
    required String imagePath,
    required int cacheWidth,
  }) async {}
}

class _FakeDecodedQuranImageCache implements DecodedQuranImageCache {
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
