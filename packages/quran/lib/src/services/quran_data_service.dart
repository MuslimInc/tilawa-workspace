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
  Map<String, int>? _verseLastWordIndexByVerse;

  Completer<void>? _loadCompleter;

  /// Returns true if the data is already loaded.
  bool get isLoaded =>
      _qpcV4Data != null &&
      _processedPageIndex != null &&
      _verseLastWordIndexByVerse != null;

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
      _verseLastWordIndexByVerse = decoded[2] as Map<String, int>;

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

  /// Returns whether the given [wordData] is the ayah-end word on its verse.
  ///
  /// Ayah-end words carry the verse number marker glyph that must sometimes be
  /// styled differently from the Quran text itself.
  bool isVerseEndWord(Map<String, dynamic> wordData) {
    final int surahNumber = int.tryParse(wordData['surah'].toString()) ?? 0;
    final int verseNumber = int.tryParse(wordData['ayah'].toString()) ?? 0;
    final int wordNumber = int.tryParse(wordData['word'].toString()) ?? 0;
    final int? lastWordIndex = getLastWordIndexForVerse(
      surahNumber,
      verseNumber,
    );

    return lastWordIndex != null && wordNumber == lastWordIndex;
  }

  @visibleForTesting
  int? getLastWordIndexForVerse(int surahNumber, int verseNumber) {
    return _verseLastWordIndexByVerse?['$surahNumber:$verseNumber'];
  }

  /// Heavy lifting: decode JSON and pre-build the O(1) page lookup map.
  static List<dynamic> _decodeAndProcessData(List<String> jsonStrings) {
    final qpc = json.decode(jsonStrings[0]) as Map<String, dynamic>;
    final pageIndexRaw = json.decode(jsonStrings[1]) as Map<String, dynamic>;

    final processedIndex = <int, List<List<Map<String, dynamic>>>>{};
    final verseLastWordIndexByVerse = <String, int>{};

    for (final MapEntry<String, dynamic> wordEntry in qpc.entries) {
      final Map<String, dynamic> wordData =
          wordEntry.value as Map<String, dynamic>;
      final String surah = wordData['surah'].toString();
      final String ayah = wordData['ayah'].toString();
      final int wordIndex = int.tryParse(wordData['word'].toString()) ?? 0;
      final String verseKey = '$surah:$ayah';
      final int previousMax = verseLastWordIndexByVerse[verseKey] ?? 0;
      if (wordIndex > previousMax) {
        verseLastWordIndexByVerse[verseKey] = wordIndex;
      }
    }

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

    return [qpc, processedIndex, verseLastWordIndexByVerse];
  }

  /// Returns counts of [headers, bismillahs] for a specific page.
  Map<String, int> getSpecialLineCounts(int pageNumber) {
    final Map<int, String> special = _calculateSpecialLines(pageNumber);
    var headers = 0;
    var bismillahs = 0;
    for (final String type in special.values) {
      if (type.startsWith('HEADER')) headers++;
      if (type.startsWith('BISMILLAH')) bismillahs++;
    }
    return {'headers': headers, 'bismillahs': bismillahs};
  }

  /// Calculates which lines on a page should be headers or bismillahs.
  /// Logic moved from PageContent for centralized layout management.
  Map<int, String> _calculateSpecialLines(int pageNumber) {
    final Map<int, String> special = {};
    final List<List<Map<String, dynamic>>> lines =
        getPageData(pageNumber) ?? [];

    for (var i = 0; i < lines.length; i++) {
      final List<Map<String, dynamic>> lineWords = lines[i];
      if (lineWords.isNotEmpty) {
        final Map<String, dynamic> firstWord = lineWords.first;
        final int surah = int.tryParse(firstWord['surah'].toString()) ?? 0;
        final int ayah = int.tryParse(firstWord['ayah'].toString()) ?? 0;
        final int word = int.tryParse(firstWord['word'].toString()) ?? 0;

        if (ayah == 1 && word == 1) {
          final int lineNum = i + 1;
          if (surah == 1) {
            if (pageNumber == 1) special[1] = 'HEADER:1';
          } else if (surah == 9) {
            if (lineNum > 1) special[lineNum - 1] = 'HEADER:9';
          } else {
            if (lineNum > 2) {
              special[lineNum - 2] = 'HEADER:$surah';
              special[lineNum - 1] = 'BISMILLAH:$surah';
            } else if (lineNum == 2) {
              special[1] = 'BISMILLAH:$surah';
            }
          }
        }
      }
    }
    return special;
  }
}
