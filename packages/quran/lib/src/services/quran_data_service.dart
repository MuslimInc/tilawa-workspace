import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../helpers/app_logger.dart';

/// A singleton service to manage Quran data loading and caching.
class QuranDataService {
  QuranDataService._internal();
  static final QuranDataService instance = QuranDataService._internal();

  /// Raw structure of the Mushaf after V4 JSON decoding.
  Map<String, dynamic>? _qpcV4Data;

  /// A map for fast indexing of pages containing surahs and lines.
  /// Format: pageNumber -> SurahNumber -> LineNumber -> [Verses]
  Map<int, List<List<Map<String, dynamic>>>>? _processedPageIndex;

  Completer<void>? _loadCompleter;

  /// Returns true if the data is already loaded.
  bool get isLoaded => _qpcV4Data != null && _processedPageIndex != null;

  /// Returns a future that completes when data is loaded.
  Future<void> ensureLoaded() async {
    if (isLoaded) {
      return;
    }
    if (_loadCompleter != null) {
      return _loadCompleter!.future;
    }

    _loadCompleter = Completer<void>();
    final startTime = DateTime.now();
    logger.d('[QuranDataService] Start loading Quran data...');

    try {
      // 1. Load the raw JSON asset from the bundle.
      // We load two files if needed, but the original PageContent logic
      // was a bit different. Let's stick to the dual-file loading
      // seen in the recent PageContent.
      final List<String> responses = await Future.wait([
        rootBundle.loadString('packages/quran/assets/quran_fonts/qpc-v4.json'),
        rootBundle.loadString(
          'packages/quran/assets/quran_fonts/quran_page_index.json',
        ),
      ]);

      // 2. Offload decoding and heavy processing to a background isolate.
      final List<dynamic> decoded = await compute(
        _decodeAndProcessData,
        responses,
      );

      _qpcV4Data = decoded[0] as Map<String, dynamic>;
      _processedPageIndex =
          decoded[1] as Map<int, List<List<Map<String, dynamic>>>>;

      _loadCompleter!.complete();
      final Duration duration = DateTime.now().difference(startTime);
      logger.d(
        '[QuranDataService] Data loaded in ${duration.inMilliseconds}ms',
      );
    } catch (e, s) {
      _loadCompleter?.completeError(e, s);
      _loadCompleter = null; // Allow retry on failure
      logger.e(
        '[QuranDataService] Error loading Quran data',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Get the processed page data for a specific page.
  List<List<Map<String, dynamic>>>? getPageData(int pageNumber) {
    return _processedPageIndex?[pageNumber];
  }

  /// Heavy lifting: decode JSON and pre-build the O(1) page lookup map.
  static List<dynamic> _decodeAndProcessData(List<String> jsonStrings) {
    final qpc = json.decode(jsonStrings[0]) as Map<String, dynamic>;
    final pageIndexRaw = json.decode(jsonStrings[1]) as Map<String, dynamic>;

    final processedIndex = <int, List<List<Map<String, dynamic>>>>{};

    for (final MapEntry<String, dynamic> pageEntry in pageIndexRaw.entries) {
      final int pageNum = int.parse(pageEntry.key);
      final lineMap = pageEntry.value as Map<String, dynamic>;

      final List<List<Map<String, dynamic>>> lines = List.generate(
        15,
        (_) => <Map<String, dynamic>>[],
      );

      for (final MapEntry<String, dynamic> lineEntry in lineMap.entries) {
        final int lineIndex = (int.parse(lineEntry.key) - 1).clamp(0, 14);
        final List<String> wordKeys = (lineEntry.value as List<dynamic>)
            .cast<String>();
        for (final key in wordKeys) {
          final wordData = qpc[key] as Map<String, dynamic>?;
          if (wordData != null) {
            lines[lineIndex].add(wordData);
          }
        }
      }
      processedIndex[pageNum] = lines;
    }

    return [qpc, processedIndex];
  }
}
