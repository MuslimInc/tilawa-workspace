import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/verse_marker_data.dart';
import '../../domain/repositories/verse_marker_repository.dart';

/// Loads verse-marker coordinates from bundled JSON assets.
///
/// Supports two modes:
///   - **Production**: single `verse_marker_coordinates.json` file.
///   - **Debug**: per-page files under `quran_marker_debug_coordinates/`.
class AssetVerseMarkerRepository implements VerseMarkerRepository {
  Map<String, List<dynamic>>? _markerData;
  final Map<int, List<VerseMarkerData>> _cache = {};
  Future<void>? _initFuture;

  MarkerDataSource _dataSource = MarkerDataSource.production;

  double _preloadProgress = 0.0;
  bool _isPreloading = false;
  bool _isInitialized = false;

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
      return;
    }
    if (_initFuture != null) {
      return _initFuture;
    }

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
    _dataSource = forceDebugSource
        ? MarkerDataSource.debug
        : MarkerDataSource.production;

    final shouldPreload =
        preloadAllPages ?? (_dataSource == MarkerDataSource.debug);

    try {
      if (_dataSource == MarkerDataSource.debug) {
        debugPrint('AssetVerseMarkerRepository: DEBUG mode – per-page files');
        _markerData = {};
        _cache.clear();
        _preloadProgress = 0.0;
        _isPreloading = false;

        if (shouldPreload) {
          await _preloadAllDebugPages();
        }
      } else {
        final raw = await rootBundle.loadString(
          'assets/data/verse_marker_coordinates.json',
        );
        _markerData = await compute(_decodeMarkerDataMap, raw);
        _cache.clear();
        _preloadProgress = 1.0;
        _isPreloading = false;
        debugPrint(
          'AssetVerseMarkerRepository: '
          'Loaded ${_markerData!.length} pages',
        );
      }
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      debugPrint('AssetVerseMarkerRepository init error: $e');
      rethrow;
    }
  }

  /// Preloads all 604 debug page files in parallel.
  ///
  /// Progress tracks *completed* loads so the UI shows accurate data.
  Future<void> _preloadAllDebugPages() async {
    _isPreloading = true;
    _preloadProgress = 0.0;

    debugPrint('AssetVerseMarkerRepository: Preloading all 604 debug pages...');

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

    debugPrint('AssetVerseMarkerRepository: ✓ Preloaded all $totalPages pages');
    debugPrint('AssetVerseMarkerRepository: Cached ${_cache.length} pages');
  }

  /// Switches between production and debug data sources.
  Future<void> setDataSource(
    MarkerDataSource source, {
    bool preloadAllPages = true,
  }) async {
    if (_dataSource == source) return;
    _dataSource = source;
    _cache.clear();
    _preloadProgress = 0.0;

    if (source == MarkerDataSource.production) {
      final raw = await rootBundle.loadString(
        'assets/data/verse_marker_coordinates.json',
      );
      _markerData = await compute(_decodeMarkerDataMap, raw);
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
    if (_cache.containsKey(pageNumber)) {
      return _cache[pageNumber]!;
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
    final entries = _markerData?[pageNumber.toString()];
    if (entries == null) return [];

    return entries.map((entry) {
      final m = entry as Map<String, dynamic>;
      return VerseMarkerData(
        sura: (m['sura'] as num).toInt(),
        ayah: (m['ayah'] as num).toInt(),
        line: (m['line'] as num).toInt(),
        centerX: (m['centerX'] as num).toDouble(),
      );
    }).toList();
  }

  List<VerseMarkerData> _buildMarkersFromDebugSource(int pageNumber) {
    final cached = _markerData?[pageNumber.toString()];
    if (cached != null) {
      return cached.map((entry) {
        final m = entry as Map<String, dynamic>;
        return VerseMarkerData(
          sura: (m['sura'] as num).toInt(),
          ayah: (m['ayah'] as num).toInt(),
          line: (m['line'] as num).toInt(),
          centerX: (m['centerX'] as num).toDouble(),
        );
      }).toList();
    }
    _loadDebugPageAsync(pageNumber);
    return [];
  }

  Future<void> _loadDebugPageAsync(int pageNumber) async {
    try {
      final path =
          'assets/data/quran_marker_debug_coordinates/$pageNumber.json';
      final raw = await rootBundle.loadString(path);
      final decoded = await compute(jsonDecode, raw) as List<dynamic>;
      _markerData ??= {};
      _markerData![pageNumber.toString()] = decoded;

      final markers = decoded.map((entry) {
        final m = entry as Map<String, dynamic>;
        return VerseMarkerData(
          sura: (m['sura'] as num).toInt(),
          ayah: (m['ayah'] as num).toInt(),
          line: (m['line'] as num).toInt(),
          centerX: (m['centerX'] as num).toDouble(),
        );
      }).toList();

      _cache[pageNumber] = markers;
    } catch (e) {
      debugPrint('Error loading debug page $pageNumber: $e');
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
  void dispose() {}
}

Map<String, List<dynamic>> _decodeMarkerDataMap(String raw) {
  final decoded = json.decode(raw) as Map<String, dynamic>;
  return decoded.map((k, v) => MapEntry(k, v as List<dynamic>));
}
