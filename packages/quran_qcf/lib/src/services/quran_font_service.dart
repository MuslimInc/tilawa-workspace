import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/quran_constants.dart';
import '../constants/surah_header_banner_constants.dart';
import '../helpers/app_logger.dart';
import 'idle_scheduler.dart';
import 'mushaf_service.dart';
import 'quran_page_preparation_service.dart';

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
  static const int _totalFonts = QuranConstants.totalPagesCount;
  static const int _pageWindowRadius = 2;

  String? _fontsDirectory;
  Map<String, File>? _fontFilesByFamily;
  final Set<String> _loadedFontFamilies = <String>{};
  final Set<String> _warmedGlyphFamilies = <String>{};
  final Map<String, Future<void>> _inFlightFontFamilies =
      <String, Future<void>>{};
  final Map<String, Future<void>> _inFlightGlyphWarmUps =
      <String, Future<void>>{};
  Timer? _coalesceTimer;
  bool _fontsLoadedToEngine = false;
  bool _isWarmUpPaused = false;
  bool get hasLoadedFontsToEngine => _fontsLoadedToEngine;

  // The actual font size used by PageContent for rendering — set once after the
  // first layout metrics are computed. Warm-up uses this size so the Impeller/Skia
  // atlas entry it builds is the same one the renderer will look up on first draw.
  // Defaults to 40px (safe fallback if no page has rendered yet).
  double _renderFontSize = 40.0;

  /// Called by [PageContent] after its first layout to register the actual
  /// font size used for rendering. Must be called before [warmInitialPage].
  void setRenderFontSize(double fontSize) {
    if (fontSize > 0) _renderFontSize = fontSize;
  }

  int get loadedCount => _loadedFontFamilies.length;

  bool isFontLoaded(int pageNumber) =>
      _loadedFontFamilies.contains(_pageFamily(pageNumber));

  static Future<void> precacheQuranAssets(BuildContext context) async {
    const AssetImage surahHeaderBannerImage =
        SurahHeaderBannerConstants.assetImage;
    await precacheImage(surahHeaderBannerImage, context);
  }

  Future<void> ensureQuranDataLoaded() async {
    final bool wasLoaded = MushafService.instance.isLoaded;
    await MushafService.instance.ensureLoaded();
    // If data just became available, notify so the reader can retry page
    // preparation — _handleFontRegistryChanged guards on isQuranDataLoaded,
    // which would otherwise never re-fire after a slow data load.
    if (!wasLoaded && MushafService.instance.isLoaded) {
      _scheduleNotify();
    }
  }

  bool get isQuranDataLoaded => MushafService.instance.isLoaded;

  void pauseBackgroundWarmUp() {
    if (!_isWarmUpPaused) {
      _isWarmUpPaused = true;
      logger.i('[FONT] Warm-up PAUSED');
    }
  }

  void resumeBackgroundWarmUp() {
    if (_isWarmUpPaused) {
      _isWarmUpPaused = false;
      logger.i('[FONT] Warm-up RESUMED');
    }
  }

  /// Loads only the font for [pageNumber].
  ///
  /// This intentionally does not trigger glyph atlas warm-up. Off-screen
  /// warm-up uses `Picture.toImage()`, which can compete with the raster
  /// thread and regress swipe smoothness on mid-range devices. Callers that
  /// explicitly want warm-up must opt into [warmInitialPage] or
  /// [warmPreparedPage].
  Future<void> ensureSingleFontLoaded(int pageNumber) async {
    final String family = _pageFamily(pageNumber);
    if (_loadedFontFamilies.contains(family)) return;
    final Map<String, File> fontFilesByFamily = await _getFontFilesByFamily();
    final File? file = fontFilesByFamily[family];
    if (file != null) {
      await _ensureFontFamilyLoaded(family: family, file: file);
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
    for (var dist = 0; dist <= maxDist; dist++) {
      final List<int> candidates = dist == 0
          ? [pivot]
          : [pivot + dist, pivot - dist];

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
    logger.i('[FONT] loadFontsToEngine START | page=$initialPageNumber');

    _currentPage = initialPageNumber;

    try {
      final Map<String, File> fontFilesByFamily = await _getFontFilesByFamily();
      if (fontFilesByFamily.isEmpty) {
        logger.w('[FONT_WARN] No fonts found in index');
        return;
      }

      // Load initial page (Critical)
      final String currentFamily = _pageFamily(initialPageNumber);
      final File? initialFile = fontFilesByFamily[currentFamily];

      if (initialFile != null) {
        await _ensureFontFamilyLoaded(family: currentFamily, file: initialFile);
        _fontsLoadedToEngine = true;
      } else {
        logger.w(
          '[FONT_WARN] Initial page font not found in index: $currentFamily',
        );
      }

      final int tEnd = DateTime.now().millisecondsSinceEpoch;
      logger.i('[FONT] loadFontsToEngine DONE | total=${tEnd - tStart}ms');
    } catch (e, s) {
      logger.e('Font Loading Crash', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Pre-warms the glyph atlas for [pageNumber] after QuranDataService is ready.
  ///
  /// Must be called AFTER both [loadFontsToEngine] and [ensureQuranDataLoaded]
  /// have completed — the font must be registered AND the JSON data must be
  /// available for [_precacheGlyphAtlas] to collect the glyph strings.
  ///
  /// When [preparedPage] is supplied, the already-laid-out [TextPainter] objects
  /// are used directly — no additional text shaping occurs.
  Future<void> warmInitialPage(
    int pageNumber, {
    PreparedQuranPage? preparedPage,
  }) async {
    _scheduleGlyphWarm(
      family: _pageFamily(pageNumber),
      pageNumber: pageNumber,
      preparedPage: preparedPage,
    );
  }

  /// Schedules a glyph atlas warm-up for [preparedPage], reusing its already-laid-out
  /// [TextPainter] objects instead of re-shaping the text.
  ///
  /// Call this immediately after [QuranPagePreparationService.preparePage] returns.
  /// Safe to call multiple times — subsequent calls for the same page are no-ops.
  void warmPreparedPage(int pageNumber, PreparedQuranPage preparedPage) {
    _scheduleGlyphWarm(
      family: _pageFamily(pageNumber),
      pageNumber: pageNumber,
      preparedPage: preparedPage,
    );
  }

  /// Ensures fonts for a small window around [pageNumber] are ready.
  Future<void> ensureFontsForPageWindow({required int pageNumber}) async {
    final Map<String, File> fontFilesByFamily = await _getFontFilesByFamily();
    if (fontFilesByFamily.isEmpty) return;

    for (final int candidatePage in _orderedPageWindow(pageNumber)) {
      final String family = _pageFamily(candidatePage);
      final File? file = fontFilesByFamily[family];
      if (file == null) continue;

      await _ensureFontFamilyLoaded(family: family, file: file);
    }
  }

  List<int> _orderedPageWindow(int centerPage) {
    final pages = <int>[centerPage];
    for (var distance = 1; distance <= _pageWindowRadius; distance++) {
      final int next = centerPage + distance;
      final int previous = centerPage - distance;
      if (next <= _totalFonts) pages.add(next);
      if (previous >= 1) pages.add(previous);
    }
    return pages;
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
      logger.i(
        '[PERF] [FONT_LOAD] $family | read=${tRead - tStart}ms | register=${tEnd - tRead}ms | total=${tEnd - tStart}ms',
      );
    } catch (e) {
      logger.e('[FONT_ERR] $family: $e', error: e);
    }
  }

  /// Fires an off-screen paint of [family]'s glyphs so Impeller builds the
  /// glyph atlas before the page is revealed on-screen.
  ///
  /// **Idle-time only**: The expensive `toImage()` call (GPU↔CPU sync) is
  /// deferred to the [IdleScheduler] so the `toImage()` call never competes
  /// with live frame rasterization. If the user is actively scrolling
  /// (`_isWarmUpPaused`), the warm-up is skipped entirely and will be retried
  /// after resume.
  Future<void> _precacheGlyphAtlas(
    String family, {
    PreparedQuranPage? preparedPage,
  }) async {
    // Skip entirely while the user is actively swiping.
    if (_isWarmUpPaused) return;

    // Use IdleScheduler to serialize with snapshot captures — only one
    // toImage() runs system-wide at a time.
    final IdleTask idleTask = IdleScheduler.instance.runWhenIdle(() async {
      // Re-check pause state after yielding — user may have started swiping.
      if (_isWarmUpPaused) return;

      final int t0 = DateTime.now().millisecondsSinceEpoch;

      try {
        if (preparedPage != null) {
          await _warmFromPreparedPage(preparedPage);
        } else {
          await _warmFromRawData(family);
        }
        logger.i(
          '[PERF] [GLYPH_WARM] $family | took=${DateTime.now().millisecondsSinceEpoch - t0}ms',
        );
      } catch (e) {
        logger.e('[GLYPH_WARM_ERR] $family: $e');
      }
    });

    await idleTask.future;
  }

  /// Paints all [PreparedTextBlock] painters from [page] into a 1×1 off-screen
  /// [ui.Image], causing Impeller/Skia to upload their glyphs to the GPU atlas.
  ///
  /// Zero extra text-shaping work: the [TextPainter] objects were already laid
  /// out by [QuranPagePreparationService.preparePage].
  Future<void> _warmFromPreparedPage(PreparedQuranPage page) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    for (final PreparedPageBlock block in page.blocks) {
      if (block is PreparedTextBlock) {
        block.painter.paint(canvas, Offset.zero);
      }
    }
    final ui.Picture picture = recorder.endRecording();
    try {
      final ui.Image image = await picture.toImage(1, 1);
      image.dispose();
    } finally {
      picture.dispose();
    }
  }

  /// Fallback warm-up path: builds a single concatenated [TextSpan] from raw
  /// JSON glyph data and paints it off-screen.
  ///
  /// Creates ONE [TextPainter] (not 15), so it is still cheaper than the
  /// previous implementation which called [precacheTextGlyphs] which also
  /// built one painter — but now we have explicit control over disposal.
  Future<void> _warmFromRawData(String family) async {
    // Parse page number from family name, e.g. 'QCF_P042' → 42.
    final int? pageNumber = int.tryParse(
      family.replaceFirst(RegExp(r'^QCF_P0*'), ''),
    );
    if (pageNumber == null) return;

    final List<List<Map<String, dynamic>>>? pageData = MushafService.instance
        .getPageData(pageNumber);
    if (pageData == null) return;

    // Collect all word texts into a single string.
    final buffer = StringBuffer();
    for (final List<Map<String, dynamic>> line in pageData) {
      for (final word in line) {
        final text = word['text'] as String?;
        if (text != null) buffer.write(text);
      }
    }
    final glyphs = buffer.toString();
    if (glyphs.isEmpty) return;

    final double fontSize = _renderFontSize;
    final painter = TextPainter(
      text: TextSpan(
        text: glyphs,
        style: TextStyle(fontFamily: family, fontSize: fontSize),
      ),
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: math.max(1.0, glyphs.length * fontSize));

    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      painter.paint(canvas, Offset.zero);
      final ui.Picture picture = recorder.endRecording();
      try {
        final ui.Image image = await picture.toImage(1, 1);
        image.dispose();
      } finally {
        picture.dispose();
      }
    } finally {
      painter.dispose();
    }
  }

  Future<void> _warmGlyphFamily({
    required String family,
    required int pageNumber,
    PreparedQuranPage? preparedPage,
  }) {
    if (_warmedGlyphFamilies.contains(family)) {
      return Future<void>.value();
    }

    // If a PreparedQuranPage is provided, always use it even if a raw-data
    // warm-up is already in-flight — it's cheaper (no extra text shaping) and
    // produces a more accurate atlas entry.
    if (preparedPage != null || !_inFlightGlyphWarmUps.containsKey(family)) {
      _inFlightGlyphWarmUps.remove(family); // cancel any in-flight raw warm-up
      final Future<void> warmFuture =
          _precacheGlyphAtlas(family, preparedPage: preparedPage)
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => logger.w('[GLYPH_WARM] timeout p$pageNumber'),
              )
              .then((_) {
                _warmedGlyphFamilies.add(family);
              })
              .whenComplete(() => _inFlightGlyphWarmUps.remove(family));
      _inFlightGlyphWarmUps[family] = warmFuture;
      return warmFuture;
    }

    return _inFlightGlyphWarmUps[family]!;
  }

  void _scheduleGlyphWarm({
    required String family,
    required int pageNumber,
    PreparedQuranPage? preparedPage,
  }) {
    if (_warmedGlyphFamilies.contains(family)) return;
    // If already in-flight with raw data and we now have a prepared page,
    // still upgrade — the prepared-page path avoids extra text shaping.
    if (_inFlightGlyphWarmUps.containsKey(family) && preparedPage == null) {
      return;
    }

    unawaited(
      _warmGlyphFamily(
        family: family,
        pageNumber: pageNumber,
        preparedPage: preparedPage,
      ).catchError((Object error, StackTrace stackTrace) {
        logger.e(
          '[GLYPH_WARM_ERR] $family: $error',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
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
      logger.i(
        '[PERF] [FONT_INDEX] scanned ${indexed.length} fonts | took=${tEnd - tStart}ms',
      );
      return indexed;
    } catch (e) {
      logger.e('[FONT_INDEX_ERR] $e');
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

  @visibleForTesting
  void debugMarkFontLoaded(int pageNumber) {
    _loadedFontFamilies.add(_pageFamily(pageNumber));
  }

  @visibleForTesting
  void debugResetForTests() {
    _loadedFontFamilies.clear();
    _warmedGlyphFamilies.clear();
    _inFlightGlyphWarmUps.clear();
    _fontsLoadedToEngine = false;
  }
}
