import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
Uint8List onePixelSolidPng({required int r, required int g, required int b}) {
  final raw = Uint8List.fromList([0, r, g, b]);
  final compressed = Uint8List.fromList(ZLibCodec().encode(raw));

  Uint8List chunk(String type, Uint8List data) {
    final typeBytes = utf8.encode(type);
    final length = ByteData(4)..setUint32(0, data.length);
    final crcInput = Uint8List.fromList([...typeBytes, ...data]);
    final crc = ByteData(4)..setUint32(0, _pngCrc32(crcInput));
    return Uint8List.fromList([
      ...length.buffer.asUint8List(),
      ...typeBytes,
      ...data,
      ...crc.buffer.asUint8List(),
    ]);
  }

  final ihdr = ByteData(13)
    ..setUint32(0, 1)
    ..setUint32(4, 1)
    ..setUint8(8, 8)
    ..setUint8(9, 2)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);

  return Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    ...chunk('IHDR', ihdr.buffer.asUint8List()),
    ...chunk('IDAT', compressed),
    ...chunk('IEND', Uint8List(0)),
  ]);
}

int _pngCrc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? 0xEDB88320 ^ (crc >> 1) : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
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
      ? onePixelSolidPng(r: 0xE6, g: 0xE6, b: 0xE6)
      : transparentBytes;
  final headerBytes = visiblePlaceholders
      ? onePixelSolidPng(r: 0xC8, g: 0xA8, b: 0x6E)
      : transparentBytes;

  final linePathsByPage = <int, Map<int, String>>{};
  for (final pageNumber in pageNumbers) {
    final linePaths = <int, String>{};
    for (var line = 1; line <= 15; line++) {
      final file = File(
        '${tempDirectory.path}/page_${pageNumber}_line_$line.png',
      );
      await file.writeAsBytes(lineBytes);
      linePaths[line] = file.path;
    }
    linePathsByPage[pageNumber] = linePaths;
  }

  final headerFile = File('${tempDirectory.path}/sura_header_banner.png');
  await headerFile.writeAsBytes(headerBytes);

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
