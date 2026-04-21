import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../constants/quran_constants.dart';
import '../helpers/app_logger.dart';
import 'quran_special_line.dart';

/// A singleton service to manage Quran data loading and caching.
class MushafService {
  MushafService._internal();
  static final MushafService instance = MushafService._internal();

  /// Raw structure of the Mushaf after V4 JSON decoding.
  /// A map for fast indexing of pages containing surahs and lines.
  /// Format: pageNumber -> SurahNumber -> LineNumber -> [Verses]
  Map<int, List<List<Map<String, dynamic>>>>? _processedPageIndex;
  Map<String, int>? _verseLastWordIndexByVerse;
  final Map<int, QuranSpecialLineCounts> _specialLineCountsCache = {};
  final Map<int, Map<int, QuranSpecialLine>> _specialLinesCache = {};

  Completer<void>? _loadCompleter;

  /// Returns true if the data is already loaded.
  bool get isLoaded =>
      _processedPageIndex != null && _verseLastWordIndexByVerse != null;

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
    if (!kReleaseMode) {
      logger.i('[MushafService] Start loading Quran data...');
    }

    try {
      // 1. Load the raw bytes from the bundle.
      // Loading bytes is faster on the main thread than loadString
      // because it avoids synchronous utf8 decoding of large strings.
      final List<Uint8List> responses = await Future.wait([
        rootBundle
            .load('packages/quran/assets/quran_fonts/qpc-v4.json')
            .then((d) => d.buffer.asUint8List()),
        rootBundle
            .load('packages/quran/assets/quran_fonts/quran_page_index.json')
            .then((d) => d.buffer.asUint8List()),
      ]);

      // 2. Offload decoding and heavy processing to a background isolate.
      final List<dynamic> decoded = await compute(
        _decodeAndProcessData,
        responses,
      );

      _processedPageIndex =
          decoded[0] as Map<int, List<List<Map<String, dynamic>>>>;
      _verseLastWordIndexByVerse = decoded[1] as Map<String, int>;

      _loadCompleter!.complete();
      final Duration duration = DateTime.now().difference(startTime);
      if (!kReleaseMode) {
        logger.i('[MushafService] Data loaded in ${duration.inMilliseconds}ms');
      }
    } catch (e, s) {
      _loadCompleter?.completeError(e, s);
      _loadCompleter = null; // Allow retry on failure
      logger.e(
        '[MushafService] Error loading Quran data',
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
  static List<dynamic> _decodeAndProcessData(List<Uint8List> bytes) {
    // Decoding large strings is done here in the background isolate.
    final qpc = json.decode(utf8.decode(bytes[0])) as Map<String, dynamic>;
    final pageIndexRaw =
        json.decode(utf8.decode(bytes[1])) as Map<String, dynamic>;

    final processedIndex = <int, List<List<Map<String, dynamic>>>>{};
    final verseLastWordIndexByVerse = <String, int>{};

    for (final MapEntry<String, dynamic> wordEntry in qpc.entries) {
      final wordData = wordEntry.value as Map<String, dynamic>;
      final surah = wordData['surah'].toString();
      final ayah = wordData['ayah'].toString();
      final int wordIndex = int.tryParse(wordData['word'].toString()) ?? 0;
      final verseKey = '$surah:$ayah';
      final int previousMax = verseLastWordIndexByVerse[verseKey] ?? 0;
      if (wordIndex > previousMax) {
        verseLastWordIndexByVerse[verseKey] = wordIndex;
      }
    }

    for (final MapEntry<String, dynamic> pageEntry in pageIndexRaw.entries) {
      final int pageNum = int.parse(pageEntry.key);
      final lineMap = pageEntry.value as Map<String, dynamic>;

      final List<List<Map<String, dynamic>>> lines = List.generate(
        QuranConstants.linesPerPage,
        (_) => <Map<String, dynamic>>[],
      );

      for (final MapEntry<String, dynamic> lineEntry in lineMap.entries) {
        final int lineIndex = (int.parse(lineEntry.key) - 1).clamp(
          0,
          QuranConstants.linesPerPage - 1,
        );
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

    return [processedIndex, verseLastWordIndexByVerse];
  }

  /// Returns counts of [headers, bismillahs] for a specific page.
  Map<String, int> getSpecialLineCounts(int pageNumber) {
    return getSpecialLineCountSummary(pageNumber).toLegacyMap();
  }

  QuranSpecialLineCounts getSpecialLineCountSummary(int pageNumber) {
    if (_specialLineCountsCache.containsKey(pageNumber)) {
      return _specialLineCountsCache[pageNumber]!;
    }
    final Map<int, QuranSpecialLine> special = _calculateSpecialLines(
      pageNumber,
    );
    var headers = 0;
    var bismillahs = 0;
    for (final QuranSpecialLine line in special.values) {
      if (line.isSurahHeader) {
        headers++;
      }
      if (line.isBismillah) {
        bismillahs++;
      }
    }
    return _specialLineCountsCache[pageNumber] = QuranSpecialLineCounts(
      headers: headers,
      bismillahs: bismillahs,
    );
  }

  /// Calculates which lines on a page should be headers or bismillahs.
  /// Logic moved from PageContent for centralized layout management.
  Map<int, QuranSpecialLine> _calculateSpecialLines(int pageNumber) {
    if (_specialLinesCache.containsKey(pageNumber)) {
      return _specialLinesCache[pageNumber]!;
    }
    final Map<int, QuranSpecialLine> special = {};
    final List<List<Map<String, dynamic>>> lines =
        getPageData(pageNumber) ?? <List<Map<String, dynamic>>>[];

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
            if (pageNumber == QuranConstants.minPageNumber) {
              special[1] = const QuranSpecialLine.surahHeader(1);
            }
          } else if (surah == 9) {
            if (lineNum > 1) {
              special[lineNum - 1] = const QuranSpecialLine.surahHeader(9);
            }
          } else {
            if (lineNum > 2) {
              special[lineNum - 2] = QuranSpecialLine.surahHeader(surah);
              special[lineNum - 1] = QuranSpecialLine.bismillah(surah);
            } else if (lineNum == 2) {
              special[1] = QuranSpecialLine.bismillah(surah);
            }
          }
        }
      }
    }
    return _specialLinesCache[pageNumber] = special;
  }

  QuranSpecialLine? getSpecialLine(int page, int line) {
    if (!isLoaded) {
      return null;
    }
    return _calculateSpecialLines(page)[line];
  }

  bool pageHasSurahHeader(int pageNumber) {
    if (!isLoaded) {
      return false;
    }
    return getSpecialLineCountSummary(pageNumber).hasSurahHeader;
  }

  /// Returns the special type (HEADER, BISMILLAH) for a given page and line.
  String? getSpecialType(int page, int line) {
    final QuranSpecialLine? specialLine = getSpecialLine(page, line);
    if (specialLine == null) {
      return null;
    }
    return switch (specialLine.type) {
      QuranSpecialLineType.surahHeader => 'HEADER:${specialLine.surahNumber}',
      QuranSpecialLineType.bismillah => 'BISMILLAH:${specialLine.surahNumber}',
    };
  }

  /// Returns metadata for a given page (surah numbers, juz, hizb).
  Map<String, dynamic> getPageMetadata(int page) {
    if (!isLoaded) {
      return <String, dynamic>{'surahNumbers': <int>[], 'juz': 0, 'hizb': 0};
    }
    final List<List<Map<String, dynamic>>> lines =
        getPageData(page) ?? <List<Map<String, dynamic>>>[];
    final Set<int> surahs = {};
    var juz = 0;
    var hizb = 0;

    for (final line in lines) {
      for (final word in line) {
        final int s = int.tryParse(word['surah'].toString()) ?? 0;
        if (s > 0) surahs.add(s);
        // Juz/Hizb are usually constant per page in standard Uthmani Mushaf,
        // but we can extract them from the first word.
        if (juz == 0) {
          juz = int.tryParse(word['juz']?.toString() ?? '') ?? 0;
          hizb = int.tryParse(word['hizb']?.toString() ?? '') ?? 0;
        }
      }
    }

    return {'surahNumbers': surahs.toList()..sort(), 'juz': juz, 'hizb': hizb};
  }
}
