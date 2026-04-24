import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/perf_logger.dart';
import '../../domain/entities/verse_marker_data.dart';
import '../../domain/repositories/verse_marker_repository.dart';

/// Loads verse-marker coordinates from bundled JSON assets.
///
/// Supports two modes:
///   - **Production**: single `verse_marker_coordinates.json` file.
///   - **Debug**: per-page files under `quran_marker_debug_coordinates/`.
class AssetVerseMarkerRepository implements VerseMarkerRepository {
  static const String _logSource = 'AssetVerseMarkerRepository';

  Map<String, List<dynamic>>? _markerData;
  final Map<int, List<VerseMarkerData>> _cache = {};

  // Production-mode flat buffer and page-offset index for lazy decoding.
  // Storing the raw Float64List avoids a 60ms unpack-all spike on init;
  // individual pages are decoded on first access (~0.1ms each).
  Float64List? _flatBuffer;
  // Maps pageKey → offset in _flatBuffer where that page's marker data starts
  // (points to the markerCount slot, not the pageKey slot).
  Map<int, int>? _pageOffsets;
  Future<void>? _initFuture;

  MarkerDataSource _dataSource = MarkerDataSource.production;

  double _preloadProgress = 0.0;
  bool _isPreloading = false;
  bool _isInitialized = false;

  /// Notified once when the repository transitions to initialized.
  ///
  /// Individual page widgets can listen to this instead of the whole reader
  /// calling setState, avoiding a full tree rebuild on marker ready.
  final ValueNotifier<bool> initializedNotifier = ValueNotifier(false);

  bool get isInitialized => _isInitialized;

  @override
  double get preloadProgress => _preloadProgress;

  @override
  bool get isPreloading => _isPreloading;

  @override
  bool get isPreloaded => _preloadProgress >= 1.0;

  @override
  bool get isDebugMode => _dataSource == MarkerDataSource.debug;

  /// Initialises the repository.
  ///
  /// [forceDebugSource] selects per-page debug files instead of the
  /// single production JSON.
  /// [preloadAllPages] eagerly loads every page into the cache
  /// (defaults to `true` in debug mode).
  Future<void> init({
    bool forceDebugSource = false,
    bool? preloadAllPages,
  }) async {
    final targetSource = forceDebugSource
        ? MarkerDataSource.debug
        : MarkerDataSource.production;
    if (_isInitialized && _dataSource == targetSource) {
      _log('init skipped alreadyInitialized=true source=${targetSource.name}');
      return;
    }
    if (_initFuture != null) {
      _log('init joined inFlight=true source=${_dataSource.name}');
      return _initFuture;
    }

    _log(
      'init requested source=${targetSource.name} '
      'preloadAllPages=${preloadAllPages ?? (_dataSource == MarkerDataSource.debug)}',
    );
    _initFuture = _init(
      forceDebugSource: forceDebugSource,
      preloadAllPages: preloadAllPages,
    );
    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _init({
    required bool forceDebugSource,
    required bool? preloadAllPages,
  }) async {
    final timer = PerfLogger.startTimer();
    _dataSource = forceDebugSource
        ? MarkerDataSource.debug
        : MarkerDataSource.production;

    final shouldPreload =
        preloadAllPages ?? (_dataSource == MarkerDataSource.debug);

    try {
      _log(
        'init started source=${_dataSource.name} '
        'shouldPreload=$shouldPreload',
      );
      if (_dataSource == MarkerDataSource.debug) {
        debugPrint('[AssetVerseMarkerRepository] DEBUG mode - per-page files');
        _markerData = {};
        _cache.clear();
        _preloadProgress = 0.0;
        _isPreloading = false;

        if (shouldPreload) {
          await _preloadAllDebugPages();
        }
      } else {
        final loadTimer = PerfLogger.startTimer();
        // Use load() instead of loadString() — returns ByteData without
        // the ~70ms UTF-16 string conversion on the main thread.
        ByteData byteData;
        try {
          byteData = await rootBundle.load(
            'packages/quran_image/assets/data/verse_marker_coordinates.json',
          );
        } catch (_) {
          // Fallback for tests running from package root
          byteData = await rootBundle.load(
            'assets/data/verse_marker_coordinates.json',
          );
        }
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        PerfLogger.logElapsed(
          loadTimer,
          widgetName: _logSource,
          message: 'production marker asset loaded bytes=${bytes.length}',
        );
        final decodeTimer = PerfLogger.startTimer();
        // JSON decode + flat-pack both run on the isolate.
        // Uint8List transfers zero-copy across isolate boundary.
        final flat = await compute(_decodeMarkersFlatPackedFromBytes, bytes);
        PerfLogger.logElapsed(
          decodeTimer,
          widgetName: _logSource,
          message: 'production marker data decoded (flat packed)',
        );
        // Build a lightweight page-offset index on the UI thread.
        // This is O(pageCount) integer reads — ~0.1ms for 604 pages.
        // Individual pages are decoded lazily in getMarkersForPage(), so
        // the 60ms "unpack all 6000 VerseMarkerData objects at once" spike
        // (frame #52 pattern) is eliminated entirely.
        _markerData = {};
        _flatBuffer = flat;
        final offsets = <int, int>{};
        var i = 0;
        final pageCount = flat[i++].toInt();
        for (var p = 0; p < pageCount; p++) {
          final pageKey = flat[i++].toInt();
          final markerCount = flat[i++].toInt();
          offsets[pageKey] = i; // points to first sura field of first marker
          i += markerCount * 4; // skip past this page's marker data
        }
        _pageOffsets = offsets;
        _preloadProgress = 1.0;
        _isPreloading = false;
        debugPrint(
          '[AssetVerseMarkerRepository] '
          'Indexed ${offsets.length} pages (lazy decode)',
        );
      }
      _isInitialized = true;
      initializedNotifier.value = true;
      PerfLogger.logElapsed(
        timer,
        widgetName: _logSource,
        message:
            'init completed source=${_dataSource.name} '
            'pages=${_pageOffsets?.length ?? _markerData?.length ?? 0}',
      );
    } catch (e) {
      _isInitialized = false;
      PerfLogger.logElapsed(
        timer,
        widgetName: _logSource,
        message: 'init failed source=${_dataSource.name}',
      );
      debugPrint('[AssetVerseMarkerRepository] init error: $e');
      rethrow;
    }
  }

  /// Preloads all 604 debug page files in parallel.
  ///
  /// Progress tracks *completed* loads so the UI shows accurate data.
  Future<void> _preloadAllDebugPages() async {
    final timer = PerfLogger.startTimer();
    _isPreloading = true;
    _preloadProgress = 0.0;

    debugPrint('[AssetVerseMarkerRepository] preloading all 604 debug pages');

    const totalPages = 604;
    const batchSize = 25; // Process in small batches to avoid isolate overhead

    int completedCount = 0;

    for (int i = 1; i <= totalPages; i += batchSize) {
      final end = (i + batchSize - 1).clamp(1, totalPages);
      final batchFutures = <Future<void>>[];

      for (int pageNum = i; pageNum <= end; pageNum++) {
        batchFutures.add(
          _loadDebugPageAsync(pageNum).then((_) {
            completedCount++;
            _preloadProgress = completedCount / totalPages;
          }),
        );
      }

      // Wait for the current batch to finish before starting the next one.
      // This prevents firing 604 isolates (compute() calls) simultaneously.
      await Future.wait(batchFutures);
    }

    _preloadProgress = 1.0;
    _isPreloading = false;

    debugPrint('[AssetVerseMarkerRepository] preloaded all $totalPages pages');
    debugPrint('[AssetVerseMarkerRepository] cached ${_cache.length} pages');
    PerfLogger.logElapsed(
      timer,
      widgetName: _logSource,
      message: 'debug preload completed pages=${_cache.length}',
    );
  }

  /// Switches between production and debug data sources.
  Future<void> setDataSource(
    MarkerDataSource source, {
    bool preloadAllPages = true,
  }) async {
    if (_dataSource == source) return;
    _log(
      'setDataSource source=${source.name} preloadAllPages=$preloadAllPages',
    );
    _dataSource = source;
    _cache.clear();
    _preloadProgress = 0.0;

    if (source == MarkerDataSource.production) {
      String raw;
      try {
        raw = await rootBundle.loadString(
          'packages/quran_image/assets/data/verse_marker_coordinates.json',
        );
      } catch (_) {
        raw = await rootBundle.loadString(
          'assets/data/verse_marker_coordinates.json',
        );
      }
      final flat = await compute(_decodeMarkersFlatPacked, raw);
      _markerData = {};
      var i = 0;
      final pageCount = flat[i++].toInt();
      for (var p = 0; p < pageCount; p++) {
        final pageKey = flat[i++].toInt();
        final markerCount = flat[i++].toInt();
        final markers = <VerseMarkerData>[];
        for (var m = 0; m < markerCount; m++) {
          markers.add(
            VerseMarkerData(
              sura: flat[i++].toInt(),
              ayah: flat[i++].toInt(),
              line: flat[i++].toInt(),
              centerX: flat[i++].toDouble(),
            ),
          );
        }
        _cache[pageKey] = List<VerseMarkerData>.unmodifiable(markers);
      }
      _log('setDataSource production loaded pages=${_cache.length}');
      _isInitialized = true;
      _preloadProgress = 1.0;
      _isPreloading = false;
    } else {
      _markerData = {};
      _isInitialized = true;
      if (preloadAllPages) {
        await _preloadAllDebugPages();
      }
    }
  }

  @override
  List<VerseMarkerData> getMarkersForPage(int pageNumber) {
    final cached = _cache[pageNumber];
    if (cached != null) {
      return cached;
    }

    final result = _buildMarkersForPage(pageNumber);

    // Only cache non-empty results; an empty list from a pending
    // debug-mode async load should not prevent future lookups.
    if (result.isNotEmpty) {
      _cache[pageNumber] = result;
    }
    return result;
  }

  List<VerseMarkerData> _buildMarkersForPage(int pageNumber) {
    if (_dataSource == MarkerDataSource.debug) {
      return _buildMarkersFromDebugSource(pageNumber);
    }
    return _buildMarkersFromProductionSource(pageNumber);
  }

  List<VerseMarkerData> _buildMarkersFromProductionSource(int pageNumber) {
    // Lazy flat-buffer decode: read only this page's slice.
    final flat = _flatBuffer;
    final offsets = _pageOffsets;
    if (flat != null && offsets != null) {
      final offset = offsets[pageNumber];
      if (offset == null) return [];
      // At offset-1 is the markerCount (we stored offset pointing past it,
      // but the index stores the position of the first sura field).
      // Re-derive markerCount from the buffer: it's at offset-1.
      final markerCount = flat[offset - 1].toInt();
      final markers = <VerseMarkerData>[];
      var i = offset;
      for (var m = 0; m < markerCount; m++) {
        markers.add(
          VerseMarkerData(
            sura: flat[i++].toInt(),
            ayah: flat[i++].toInt(),
            line: flat[i++].toInt(),
            centerX: flat[i++],
          ),
        );
      }
      return List<VerseMarkerData>.unmodifiable(markers);
    }

    // Fallback: legacy _markerData path (debug mode / setDataSource).
    final entries = _markerData?[pageNumber.toString()];
    if (entries == null) return [];

    return List<VerseMarkerData>.unmodifiable(
      entries.map((entry) {
        final m = entry as Map<String, dynamic>;
        return VerseMarkerData(
          sura: (m['sura'] as num).toInt(),
          ayah: (m['ayah'] as num).toInt(),
          line: (m['line'] as num).toInt(),
          centerX: (m['centerX'] as num).toDouble(),
        );
      }),
    );
  }

  List<VerseMarkerData> _buildMarkersFromDebugSource(int pageNumber) {
    final cached = _markerData?[pageNumber.toString()];
    if (cached != null) {
      return List<VerseMarkerData>.unmodifiable(
        cached.map((entry) {
          final m = entry as Map<String, dynamic>;
          return VerseMarkerData(
            sura: (m['sura'] as num).toInt(),
            ayah: (m['ayah'] as num).toInt(),
            line: (m['line'] as num).toInt(),
            centerX: (m['centerX'] as num).toDouble(),
          );
        }),
      );
    }
    _loadDebugPageAsync(pageNumber);
    return [];
  }

  Future<void> _loadDebugPageAsync(int pageNumber) async {
    try {
      final path =
          'assets/data/quran_marker_debug_coordinates/$pageNumber.json';
      final prefixedPath =
          'packages/quran_image/assets/data/quran_marker_debug_coordinates/$pageNumber.json';

      String raw;
      try {
        raw = await rootBundle.loadString(prefixedPath);
      } catch (_) {
        raw = await rootBundle.loadString(path);
      }
      final decoded = await compute(jsonDecode, raw) as List<dynamic>;
      _markerData ??= {};
      _markerData![pageNumber.toString()] = decoded;

      final markers = List<VerseMarkerData>.unmodifiable(
        decoded.map((entry) {
          final m = entry as Map<String, dynamic>;
          return VerseMarkerData(
            sura: (m['sura'] as num).toInt(),
            ayah: (m['ayah'] as num).toInt(),
            line: (m['line'] as num).toInt(),
            centerX: (m['centerX'] as num).toDouble(),
          );
        }),
      );

      _cache[pageNumber] = markers;
    } catch (e) {
      debugPrint(
        '[AssetVerseMarkerRepository] error loading page $pageNumber: $e',
      );
    }
  }

  @override
  Future<List<VerseMarkerData>> getMarkersForPageAsync(int pageNumber) async {
    if (_dataSource == MarkerDataSource.debug) {
      await _loadDebugPageAsync(pageNumber);
    }
    return getMarkersForPage(pageNumber);
  }

  @override
  void dispose() {
    initializedNotifier.dispose();
    _cache.clear();
    _markerData = null;
    _flatBuffer = null;
    _pageOffsets = null;
    _initFuture = null;
  }

  static void _log(String message) {
    PerfLogger.log(widgetName: _logSource, message: message);
  }
}

/// Decodes the production marker JSON into a [Float64List] for zero-copy
/// transfer across the isolate boundary. [Float64List] is a typed-data buffer
/// that Dart transfers by moving the underlying memory block rather than
/// copying each element — critical for ~24 000-element payloads.
///
/// Format (all values stored as doubles):
///   [pageCount, page1Key, page1MarkerCount, sura, ayah, line, centerX, ...]
/// Variant that accepts raw [Uint8List] bytes so the caller can use
/// [rootBundle.load] (ByteData) instead of [rootBundle.loadString] — avoiding
/// a ~70ms UTF-16 string allocation on the main thread.
///
/// UTF-8 decode + JSON parse + flat-pack all execute on the isolate.
Float64List _decodeMarkersFlatPackedFromBytes(Uint8List bytes) {
  return _decodeMarkersFlatPacked(utf8.decode(bytes));
}

Float64List _decodeMarkersFlatPacked(String raw) {
  final decoded = json.decode(raw) as Map<String, dynamic>;

  // First pass: count total elements so we can allocate exactly once.
  var totalElements = 1; // pageCount header
  for (final entry in decoded.entries) {
    final markerCount = (entry.value as List<dynamic>).length;
    totalElements +=
        2 + markerCount * 4; // pageKey + markerCount + 4 fields each
  }

  final result = Float64List(totalElements);
  var i = 0;
  result[i++] = decoded.length.toDouble(); // pageCount
  for (final entry in decoded.entries) {
    result[i++] = int.parse(entry.key).toDouble(); // pageKey
    final markers = entry.value as List<dynamic>;
    result[i++] = markers.length.toDouble(); // markerCount
    for (final marker in markers) {
      final m = marker as Map<String, dynamic>;
      result[i++] = (m['sura'] as num).toDouble();
      result[i++] = (m['ayah'] as num).toDouble();
      result[i++] = (m['line'] as num).toDouble();
      result[i++] = (m['centerX'] as num).toDouble();
    }
  }
  return result;
}
