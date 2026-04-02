import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'quran_data_service.dart';

/// Service responsible for managing and loading QCF4 Quran fonts dynamically.
///
/// Phase 6 Strategy: "Windowed Registration"
/// To maintain 60 FPS, we avoid registering more than ~50 font families in the
/// engine at once. We strictly load neighbors and immediate targets.
class QuranFontService extends ChangeNotifier {
  factory QuranFontService() => instance;
  QuranFontService._internal();
  static final QuranFontService instance = QuranFontService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  final String _fontZipUrl =
      'https://pub-7f6f6686010343899ba5b2f0ac6cb7b3.r2.dev/quran_fonts.zip';
  final int _totalFonts = 604;

  String? _fontsDirectory;
  Map<String, File>? _fontFilesByFamily;
  final Set<String> _loadedFontFamilies = <String>{};
  final Set<String> _warmedGlyphFamilies = <String>{};
  final Map<String, Future<void>> _inFlightFontFamilies =
      <String, Future<void>>{};
  Timer? _coalesceTimer;
  bool _fontsLoadedToEngine = false;
  bool _isWarmUpPaused = false;
  bool get hasLoadedFontsToEngine => _fontsLoadedToEngine;
  int get loadedCount => _loadedFontFamilies.length;

  bool isFontLoaded(int pageNumber) =>
      _loadedFontFamilies.contains(_pageFamily(pageNumber));

  static Future<void> precacheQuranAssets(BuildContext context) async {
    const surahHeaderBannerImage = AssetImage(
      'assets/mainframe.png',
      package: 'quran',
    );
    await precacheImage(surahHeaderBannerImage, context);
  }

  Future<void> ensureQuranDataLoaded() =>
      QuranDataService.instance.ensureLoaded();

  void pauseBackgroundWarmUp() {
    if (!_isWarmUpPaused) {
      _isWarmUpPaused = true;
      developer.log('[FONT] Warm-up PAUSED', name: 'tilawa.quran.fonts');
    }
  }

  void resumeBackgroundWarmUp() {
    if (_isWarmUpPaused) {
      _isWarmUpPaused = false;
      developer.log('[FONT] Warm-up RESUMED', name: 'tilawa.quran.fonts');
    }
  }

  /// Loads only the font for [pageNumber]. Use for batch warming.
  Future<void> ensureSingleFontLoaded(int pageNumber) async {
    final String family = _pageFamily(pageNumber);
    if (_loadedFontFamilies.contains(family)) return;
    final Map<String, File> fontFilesByFamily = await _getFontFilesByFamily();
    final File? file = fontFilesByFamily[family];
    if (file != null) {
      await _ensureFontFamilyLoaded(family: family, file: file);
      // Await atlas warm-up so the caller can show a loading indicator and
      // guarantee the first on-screen frame finds the atlas already built.
      await _precacheGlyphAtlas(family);
    }
  }

  /// Batch warms a range of pages. Used for total upfront preparation (Phase 4).
  /// [onProgress] returns the number of successfully warmed pages in this batch.
  Future<void> batchWarmPages(
    int start,
    int end,
    FutureOr<void> Function(int) onProgress, {
    int? pivotPage,
  }) async {
    final Map<String, File> fontFilesByFamily = await _getFontFilesByFamily();
    if (fontFilesByFamily.isEmpty) return;

    final int pivot = pivotPage ?? _currentPage;
    final int maxDist = math.max(pivot - start, end - pivot);

    // Zig-zag loop: [pivot, pivot+1, pivot-1, pivot+2, pivot-2, ...]
    for (int dist = 0; dist <= maxDist; dist++) {
      final List<int> candidates =
          dist == 0 ? [pivot] : [pivot + dist, pivot - dist];

      for (final p in candidates) {
        if (p < start || p > end) continue;

        // Check if we should pause (swiping/interacting)
        while (_isWarmUpPaused) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        final String family = _pageFamily(p);
        final File? file = fontFilesByFamily[family];

        if (file != null) {
          await _ensureFontFamilyLoaded(family: family, file: file);
          if (!_warmedGlyphFamilies.contains(family)) {
            await _precacheGlyphAtlas(family);
            _warmedGlyphFamilies.add(family);
          }
        }

        await onProgress(p);

        // CRITICAL: Yield to the event loop.
        // During background warming, we use a slightly longer yield (25ms)
        // to ensure the UI and Raster threads are completely free for the next frame.
        await Future.delayed(const Duration(milliseconds: 25));
      }
    }
  }

  int _currentPage = 1;

  void updateCurrentPage(int pageNumber) {
    if (pageNumber != _currentPage) {
      _currentPage = pageNumber;
    }
  }

  /// Entry point for the reader to load necessary fonts.
  Future<void> loadFontsToEngine({required int initialPageNumber}) async {
    // If already fully successful, skip.
    if (_fontsLoadedToEngine) return;

    final int tStart = DateTime.now().millisecondsSinceEpoch;
    developer.log(
      '[FONT] loadFontsToEngine START | page=$initialPageNumber',
      name: 'tilawa.quran.fonts',
    );

    _currentPage = initialPageNumber;

    try {
      final Map<String, File> fontFilesByFamily = await _getFontFilesByFamily();
      if (fontFilesByFamily.isEmpty) {
        developer.log(
          '[FONT_WARN] No fonts found in index',
          name: 'tilawa.quran.fonts',
        );
        return;
      }

      // Load initial page (Critical)
      final String currentFamily = _pageFamily(initialPageNumber);
      final File? initialFile = fontFilesByFamily[currentFamily];

      if (initialFile != null) {
        await _ensureFontFamilyLoaded(family: currentFamily, file: initialFile);
        _fontsLoadedToEngine = true;
      } else {
        developer.log(
          '[FONT_WARN] Initial page font not found in index: $currentFamily',
          name: 'tilawa.quran.fonts',
        );
      }

      final int tEnd = DateTime.now().millisecondsSinceEpoch;
      developer.log(
        '[FONT] loadFontsToEngine DONE | total=${tEnd - tStart}ms',
        name: 'tilawa.quran.fonts',
      );
    } catch (e, s) {
      developer.log(
        'Font Loading Crash',
        name: 'tilawa.quran.fonts',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Pre-warms the glyph atlas for [pageNumber] after QuranDataService is ready.
  ///
  /// Must be called AFTER both [loadFontsToEngine] and [ensureQuranDataLoaded]
  /// have completed — the font must be registered AND the JSON data must be
  /// available for [_precacheGlyphAtlas] to collect the glyph strings.
  Future<void> warmInitialPage(int pageNumber) async {
    await _precacheGlyphAtlas(_pageFamily(pageNumber)).timeout(
      const Duration(seconds: 5),
      onTimeout: () => developer.log(
        '[GLYPH_WARM] initial page timeout p$pageNumber',
        name: 'tilawa.quran.fonts',
      ),
    );
  }

  /// Ensures fonts for a small window around [pageNumber] are ready.
  Future<void> ensureFontsForPageWindow({required int pageNumber}) async {
    final Map<String, File> fontFilesByFamily = await _getFontFilesByFamily();
    if (fontFilesByFamily.isEmpty) return;

    // 1. Target Page (Sync)
    final String targetFamily = _pageFamily(pageNumber);
    await _ensureFontFamilyLoaded(
      family: targetFamily,
      file: fontFilesByFamily[targetFamily]!,
    );
    // Await atlas warm-up for the jump target so the first frame is clean.
    await _precacheGlyphAtlas(targetFamily).timeout(
      const Duration(seconds: 5),
      onTimeout: () => developer.log(
        '[GLYPH_WARM] jump target timeout p$pageNumber',
        name: 'tilawa.quran.fonts',
      ),
    );
  }

  Future<String> get _localPath async {
    if (_fontsDirectory != null) return _fontsDirectory!;
    final Directory directory = await getApplicationDocumentsDirectory();
    final fontDir = Directory('${directory.path}/qcf4_fonts');
    if (!fontDir.existsSync()) {
      await fontDir.create(recursive: true);
    }
    _fontsDirectory = fontDir.path;
    return _fontsDirectory!;
  }

  Future<bool> areFontsDownloaded() async {
    final String path = await _localPath;
    final dir = Directory(path);
    if (!dir.existsSync()) return false;
    final int woffCount = dir
        .listSync()
        .where((f) => f.path.endsWith('.woff'))
        .length;
    return woffCount >= _totalFonts;
  }

  Future<void> downloadFonts({Function(double)? onProgress}) async {
    if (await areFontsDownloaded()) return;
    final String path = await _localPath;
    final zipFile = File('$path/quran_fonts.zip');

    try {
      await _dio.download(
        _fontZipUrl,
        zipFile.path,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress((received / total) * 0.8);
          }
        },
      );
      // Extraction logic remains same as established
      final Uint8List bytes = await zipFile.readAsBytes();
      final Archive archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (file.isFile && file.name.endsWith('.woff')) {
          final outPath = '$path/${file.name.split('/').last}';
          await File(outPath).writeAsBytes(file.content as List<int>);
        }
      }
    } finally {
      if (zipFile.existsSync()) await zipFile.delete();
      if (onProgress != null) onProgress(1.0);
    }
  }

  Future<void> _ensureFontFamilyLoaded({
    required String family,
    required File file,
  }) async {
    if (_loadedFontFamilies.contains(family)) return;
    final Future<void>? inFlight = _inFlightFontFamilies[family];
    if (inFlight != null) return inFlight;

    final Future<void> loadFuture = _loadFontFamily(
      family: family,
      file: file,
    ).whenComplete(() => _inFlightFontFamilies.remove(family));
    _inFlightFontFamilies[family] = loadFuture;
    return loadFuture;
  }

  Future<void> _loadFontFamily({
    required String family,
    required File file,
  }) async {
    final int tStart = DateTime.now().millisecondsSinceEpoch;
    try {
      final int size = await file.length();
      if (size == 0) return;

      final Uint8List bytes = await file.readAsBytes();
      final int tRead = DateTime.now().millisecondsSinceEpoch;

      final fontLoader = FontLoader(family);
      fontLoader.addFont(
        Future.value(
          ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
        ),
      );

      // Reduce timeout to 3s. If the engine doesn't register in 3s,
      // something is wrong; fail fast and retry later if needed.
      await fontLoader.load().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('Font registration timed out after 3s');
        },
      );

      _loadedFontFamilies.add(family);
      _scheduleNotify(); // Coalesced: batch multiple font loads into one notify
      final int tEnd = DateTime.now().millisecondsSinceEpoch;
      developer.log(
        '[PERF] [FONT_LOAD] $family | read=${tRead - tStart}ms | register=${tEnd - tRead}ms | total=${tEnd - tStart}ms',
        name: 'tilawa.quran.fonts',
      );
    } catch (e) {
      developer.log(
        '[FONT_ERR] $family: $e',
        name: 'tilawa.quran.fonts',
        error: e,
      );
    }
  }

  /// Fires an off-screen paint of [family]'s glyphs so Impeller builds the
  /// glyph atlas before the page is revealed on-screen.
  Future<void> _precacheGlyphAtlas(String family) async {
    // Parse page number from family name, e.g. 'QCF_P042' → 42.
    final int? pageNumber = int.tryParse(
      family.replaceFirst(RegExp(r'^QCF_P0*'), ''),
    );
    if (pageNumber == null) return;

    final List<List<Map<String, dynamic>>>? pageData = QuranDataService.instance
        .getPageData(pageNumber);
    if (pageData == null) return;

    // Collect all word texts for the page into a single string.
    final buffer = StringBuffer();
    for (final List<Map<String, dynamic>> line in pageData) {
      for (final word in line) {
        final text = word['text'] as String?;
        if (text != null) buffer.write(text);
      }
    }
    final glyphs = buffer.toString();
    if (glyphs.isEmpty) return;

    // Use 40px — ensures glyphs remain sharp when scaled up on tablets/large phones.
    // The atlas is keyed by (fontFamily, fontSize) so size must be consistent.
    const fontSize = 40.0;

    try {
      final int t0 = DateTime.now().millisecondsSinceEpoch;
      await precacheTextGlyphs(
        text: TextSpan(
          text: glyphs,
          style: TextStyle(fontFamily: family, fontSize: fontSize),
        ),
        textDirection: TextDirection.rtl,
        maxWidth: math.max(1.0, glyphs.length * fontSize),
      );
      developer.log(
        '[PERF] [GLYPH_WARM] $family | took=${DateTime.now().millisecondsSinceEpoch - t0}ms',
        name: 'tilawa.quran.fonts',
      );
    } catch (e) {
      // Warm-up failure is non-fatal — the page will still render, just with
      // the atlas-build cost on the first on-screen frame.
      developer.log('[GLYPH_WARM_ERR] $family: $e', name: 'tilawa.quran.fonts');
    }
  }

  /// Coalesce rapid font-load notifications into a single batch.
  /// When multiple fonts load in quick succession (e.g. during warming),
  /// this prevents cascading rebuilds across all kept-alive PageContent widgets.
  void _scheduleNotify() {
    _coalesceTimer?.cancel();
    _coalesceTimer = Timer(const Duration(milliseconds: 50), () {
      notifyListeners();
    });
  }

  Future<Map<String, File>> _getFontFilesByFamily() async {
    if (_fontFilesByFamily != null) return _fontFilesByFamily!;

    // Prevent multiple concurrent indexing operations
    if (_indexingFuture != null) return _indexingFuture!;

    _indexingFuture = _performIndexing();
    return _indexingFuture!;
  }

  Future<Map<String, File>>? _indexingFuture;

  Future<Map<String, File>> _performIndexing() async {
    final int tStart = DateTime.now().millisecondsSinceEpoch;
    final String path = await _localPath;
    final dir = Directory(path);
    if (!dir.existsSync()) return const {};

    final Map<String, File> indexed = {};
    try {
      // Use listSync for high-performance scanning of the 604+ files.
      // Sequential stream overhead was causing stalls on some Android devices.
      final List<FileSystemEntity> entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File) {
          final String? family = _resolvePageFontFamily(entity.path);
          if (family != null) {
            indexed[family] = entity;
          }
        }
      }

      if (indexed.isNotEmpty) {
        _fontFilesByFamily = indexed;
      }

      final int tEnd = DateTime.now().millisecondsSinceEpoch;
      developer.log(
        '[PERF] [FONT_INDEX] scanned ${indexed.length} fonts | took=${tEnd - tStart}ms',
        name: 'tilawa.quran.fonts',
      );
      return indexed;
    } catch (e) {
      developer.log('[FONT_INDEX_ERR] $e', name: 'tilawa.quran.fonts');
      return const {};
    } finally {
      // Clear the future so a retry can actually run the indexing again if needed.
      _indexingFuture = null;
    }
  }

  String? _resolvePageFontFamily(String path) {
    final String filename = path.split('/').last;

    // Strategy 1: Targeted QCF prefix (Handles QCF4001_X-Regular.woff, QCF4_163.woff, etc.)
    final RegExpMatch? qcfMatch = RegExp(
      r'QCF[34]_?(\d+)',
    ).firstMatch(filename);
    if (qcfMatch != null) {
      String pageNumStr = qcfMatch.group(1)!;
      // If it's a version-prefixed number like 4001, extract last 3
      if (pageNumStr.length > 3) {
        pageNumStr = pageNumStr.substring(pageNumStr.length - 3);
      }
      return 'QCF_P${pageNumStr.padLeft(3, '0')}';
    }

    // Strategy 2: Generic numeric before extension (Handles 163.woff, p001.ttf, etc.)
    final RegExpMatch? endMatch = RegExp(r'(\d+)\.[^.]+$').firstMatch(filename);
    if (endMatch != null) {
      String pageNumStr = endMatch.group(1)!;
      // If it's a version-prefixed number like 4001 without QCF prefix, extract last 3
      if (pageNumStr.length > 3) {
        pageNumStr = pageNumStr.substring(pageNumStr.length - 3);
      }
      return 'QCF_P${pageNumStr.padLeft(3, '0')}';
    }

    return null;
  }

  String _pageFamily(int pageNumber) =>
      'QCF_P${pageNumber.toString().padLeft(3, '0')}';
}
