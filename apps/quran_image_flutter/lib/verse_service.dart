import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Data source type for marker coordinates
enum MarkerDataSource {
  /// Production: Single JSON file with all pages
  production,

  /// Debug: Individual JSON files per page for precise debugging
  debug,
}

class VerseMarkerData {
  final int sura;
  final int ayah;

  /// 0-based index into the 15-slot line grid (matches image file N = line+1).
  /// Used with the yOffsets formula: yCenter = yOffsets[line] + lineHeight/2.
  final int line;

  /// Normalized X in [0.0, 1.0] from the left page edge.
  /// Derived from gap-center (multi-verse lines) or text_left−r (single-verse).
  final double centerX;

  VerseMarkerData({
    required this.sura,
    required this.ayah,
    required this.line,
    required this.centerX,
  });
}

class VerseService {
  Map<String, List<dynamic>>? _markerData;
  final Map<int, List<VerseMarkerData>> _cache = {};

  /// Current data source mode
  MarkerDataSource _dataSource = MarkerDataSource.production;

  /// Loading progress for debug mode preloading
  double _preloadProgress = 0.0;
  bool _isPreloading = false;

  /// Get current preload progress (0.0 to 1.0)
  double get preloadProgress => _preloadProgress;

  /// Check if currently preloading
  bool get isPreloading => _isPreloading;

  /// Check if all pages are preloaded
  bool get isPreloaded => _preloadProgress >= 1.0;

  /// Flag to enable debug mode (per-page files)
  bool get isDebugMode => _dataSource == MarkerDataSource.debug;

  /// Initialize the service with optional data source override
  ///
  /// [forceDebugSource] - When true, loads per-page files from debug directory
  /// [preloadAllPages] - When true (default in debug mode), preloads all 604 pages
  Future<void> init({
    bool forceDebugSource = false,
    bool? preloadAllPages,
  }) async {
    _dataSource = forceDebugSource
        ? MarkerDataSource.debug
        : MarkerDataSource.production;

    // In debug mode, default to preloading all pages unless specified otherwise
    final shouldPreload =
        preloadAllPages ?? (_dataSource == MarkerDataSource.debug);

    try {
      if (_dataSource == MarkerDataSource.debug) {
        debugPrint('VerseService: DEBUG mode - per-page files');
        _markerData = {};

        if (shouldPreload) {
          await _preloadAllDebugPages();
        }
      } else {
        final raw = await rootBundle.loadString(
          'assets/data/verse_marker_coordinates.json',
          cache: false,
        );
        final decoded = json.decode(raw) as Map<String, dynamic>;
        _markerData = decoded.map((k, v) => MapEntry(k, v as List<dynamic>));
        debugPrint('VerseService: Loaded ${_markerData!.length} pages');
      }
    } catch (e) {
      debugPrint('VerseService init error: $e');
    }
  }

  /// Preload all 604 debug page files
  /// This ensures smooth page jumping and slider navigation
  Future<void> _preloadAllDebugPages() async {
    _isPreloading = true;
    _preloadProgress = 0.0;

    debugPrint('VerseService: Preloading all 604 debug pages...');

    const totalPages = 604;
    final futures = <Future<void>>[];

    // Load pages in batches to avoid overwhelming the asset system
    for (int pageNum = 1; pageNum <= totalPages; pageNum++) {
      futures.add(_loadDebugPageAsync(pageNum));

      // Update progress every 10 pages
      if (pageNum % 10 == 0) {
        _preloadProgress = pageNum / totalPages;
        debugPrint(
          'VerseService: Preloading progress ${(_preloadProgress * 100).toStringAsFixed(1)}%',
        );
      }
    }

    // Wait for all pages to load
    await Future.wait(futures);

    _preloadProgress = 1.0;
    _isPreloading = false;

    debugPrint('VerseService: ✓ Preloaded all $totalPages debug pages');
    debugPrint('VerseService: Cached ${_cache.length} pages');
  }

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
        cache: false,
      );
      final decoded = json.decode(raw) as Map<String, dynamic>;
      _markerData = decoded.map((k, v) => MapEntry(k, v as List<dynamic>));
    } else {
      _markerData = {};
      if (preloadAllPages) {
        await _preloadAllDebugPages();
      }
    }
  }

  List<VerseMarkerData> getMarkersForPage(int pageNumber) {
    if (_cache.containsKey(pageNumber)) return _cache[pageNumber]!;
    final result = _buildMarkersForPage(pageNumber);
    _cache[pageNumber] = result;
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
      final raw = await rootBundle.loadString(path, cache: false);
      final decoded = json.decode(raw) as List<dynamic>;
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

  Future<List<VerseMarkerData>> getMarkersForPageAsync(int pageNumber) async {
    if (_dataSource == MarkerDataSource.debug) {
      await _loadDebugPageAsync(pageNumber);
    }
    return getMarkersForPage(pageNumber);
  }

  void close() {}
}

final verseService = VerseService();
