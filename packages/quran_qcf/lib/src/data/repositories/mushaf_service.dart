import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../quran_qcf.dart';
import '../../helpers/app_logger.dart';

/// Compact wire format for one word (isolate → UI isolate).
///
/// Using primitives avoids shipping ~90k [WordData] instances through
/// [compute], which blocks the UI isolate during deserialization (ANR).
typedef _CompactWord = List<Object?>;

/// A service to manage Quran data loading and caching.
///
/// Implements [QuranMushafService] to provide a clean domain layer interface
/// to raw Quran word data and special line operations. Register via
/// [QuranQcfLocator.setup] and resolve with `quranQcfLocator<QuranMushafService>()`.
class MushafService extends ChangeNotifier implements QuranMushafService {
  /// pageNumber -> lines -> compact words (materialized to [WordData] on demand).
  Map<int, List<List<_CompactWord>>>? _compactPageIndex;
  Map<int, List<List<WordData>>>? _processedPageIndex;
  Map<String, int>? _verseLastWordIndexByVerse;
  final Map<int, QuranSpecialLineCounts> _specialLineCountsCache = {};
  final Map<int, Map<int, QuranSpecialLine>> _specialLinesCache = {};

  Completer<void>? _loadCompleter;

  /// Returns true if the data is already loaded.
  @override
  bool get isLoaded =>
      _compactPageIndex != null && _verseLastWordIndexByVerse != null;

  /// Returns a future that completes when data is loaded.
  @override
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
      final List<Uint8List> responses = await Future.wait([
        rootBundle
            .load('packages/quran_qcf/assets/quran_fonts/qpc-v4.json')
            .then((d) => d.buffer.asUint8List()),
        rootBundle
            .load('packages/quran_qcf/assets/quran_fonts/quran_page_index.json')
            .then((d) => d.buffer.asUint8List()),
      ]);

      final List<dynamic> result = await compute(
        _decodeAndProcessData,
        responses,
      );
      _compactPageIndex = result[0] as Map<int, List<List<_CompactWord>>>;
      _verseLastWordIndexByVerse = result[1] as Map<String, int>;
      _processedPageIndex = <int, List<List<WordData>>>{};

      final endTime = DateTime.now();
      if (!kReleaseMode) {
        logger.i(
          '[MushafService] Quran data loaded in ${endTime.difference(startTime).inMilliseconds}ms',
        );
      }
      _loadCompleter!.complete();
    } catch (e, s) {
      logger.e(
        '[MushafService] Failed to load Quran data',
        error: e,
        stackTrace: s,
      );
      _loadCompleter!.completeError(e, s);
      _loadCompleter = null;
      rethrow;
    }
  }

  /// Get the processed page data for a specific page.
  @override
  List<List<WordData>>? getPageData(int pageNumber) {
    final cached = _processedPageIndex?[pageNumber];
    if (cached != null) {
      return cached;
    }
    final compact = _compactPageIndex?[pageNumber];
    if (compact == null) {
      return null;
    }
    final List<List<WordData>> lines = <List<WordData>>[
      for (final List<_CompactWord> line in compact)
        <WordData>[
          for (final _CompactWord word in line) _wordFromCompact(word),
        ],
    ];
    _processedPageIndex![pageNumber] = lines;
    return lines;
  }

  @override
  bool isVerseEndWord(WordData wordData) {
    // In QCF V4, char_type 'end' marks the verse marker word.
    return wordData.charType == 'end';
  }

  @override
  int? getLastWordIndexForVerse(int surahNumber, int verseNumber) {
    return _verseLastWordIndexByVerse?['$surahNumber:$verseNumber'];
  }

  /// Heavy lifting: decode JSON and build a compact page index.
  ///
  /// Returns `[compactPageIndex, verseLastWordIndexByVerse]` — no [WordData]
  /// instances — so the UI isolate stays responsive when [compute] completes.
  static List<dynamic> _decodeAndProcessData(List<Uint8List> bytes) {
    final Converter<List<int>, Object?> jsonBytes = utf8.decoder.fuse(
      json.decoder,
    );
    final qpc = jsonBytes.convert(bytes[0])! as Map<String, dynamic>;
    final pageIndexRaw = jsonBytes.convert(bytes[1])! as Map<String, dynamic>;

    final compactIndex = <int, List<List<_CompactWord>>>{};
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

      final List<List<_CompactWord>> lines = List.generate(
        QuranConstants.linesPerPage,
        (_) => <_CompactWord>[],
      );

      for (final MapEntry<String, dynamic> lineEntry in lineMap.entries) {
        final int lineIndex = (int.parse(lineEntry.key) - 1).clamp(
          0,
          QuranConstants.linesPerPage - 1,
        );
        final List<String> wordKeys = (lineEntry.value as List<dynamic>)
            .cast<String>();
        for (final key in wordKeys) {
          final wordMap = qpc[key] as Map<String, dynamic>?;
          if (wordMap != null) {
            lines[lineIndex].add(_compactFromMap(wordMap));
          }
        }
      }
      compactIndex[pageNum] = lines;
    }

    return [compactIndex, verseLastWordIndexByVerse];
  }

  static _CompactWord _compactFromMap(Map<String, dynamic> map) {
    return <Object?>[
      map['text'] as String,
      int.tryParse(map['surah'].toString()) ?? 0,
      int.tryParse(map['ayah'].toString()) ?? 0,
      int.tryParse(map['word'].toString()) ?? 0,
      int.tryParse(map['page'].toString()) ?? 0,
      int.tryParse(map['line'].toString()) ?? 0,
      map['audio']?.toString(),
      map['char_type']?.toString(),
    ];
  }

  static WordData _wordFromCompact(_CompactWord word) {
    return WordData(
      text: word[0]! as String,
      surah: word[1]! as int,
      ayah: word[2]! as int,
      wordIndex: word[3]! as int,
      page: word[4]! as int,
      line: word[5]! as int,
      audio: word[6] as String?,
      charType: word[7] as String?,
    );
  }

  @override
  Map<String, int> getSpecialLineCounts(int pageNumber) {
    return getSpecialLineCountSummary(pageNumber).toLegacyMap();
  }

  @override
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
      if (line.isSurahHeader) headers++;
      if (line.isBismillah) bismillahs++;
    }
    final summary = QuranSpecialLineCounts(
      headers: headers,
      bismillahs: bismillahs,
    );
    _specialLineCountsCache[pageNumber] = summary;
    return summary;
  }

  @override
  QuranSpecialLine? getSpecialLine(int page, int line) {
    return _calculateSpecialLines(page)[line];
  }

  @override
  bool pageHasSurahHeader(int pageNumber) {
    return getSpecialLineCountSummary(pageNumber).headers > 0;
  }

  @override
  PageMetadata getPageMetadata(int pageNumber) {
    final List<List<WordData>>? pageData = getPageData(pageNumber);
    if (pageData == null) {
      return const PageMetadata(surahNumbers: [], hizb: 0, juz: 0);
    }

    final Set<int> surahs = {};
    WordData? firstWord;

    for (final List<WordData> line in pageData) {
      for (final word in line) {
        surahs.add(word.surah);
        firstWord ??= word;
      }
    }

    final int juz = firstWord != null
        ? (getJuzForVerse(firstWord.surah, firstWord.ayah) ?? 0)
        : 0;
    final int hizb = firstWord != null
        ? (getHizbForVerse(firstWord.surah, firstWord.ayah) ?? 0)
        : 0;

    return PageMetadata(
      surahNumbers: surahs.toList()..sort(),
      hizb: hizb,
      juz: juz,
    );
  }

  /// Calculates which lines on a page are special (headers/bismillahs).
  Map<int, QuranSpecialLine> _calculateSpecialLines(int pageNumber) {
    if (_specialLinesCache.containsKey(pageNumber)) {
      return _specialLinesCache[pageNumber]!;
    }

    final List<List<WordData>>? pageData = getPageData(pageNumber);
    if (pageData == null) return {};

    final Map<int, QuranSpecialLine> special = {};

    for (var i = 0; i < pageData.length; i++) {
      final List<WordData> lineWords = pageData[i];
      final int lineNum = i + 1;

      // Logic to identify headers/bismillahs based on metadata patterns.
      // Usually, headers have wordIndex 0 and special charTypes.
      if (lineWords.isNotEmpty) {
        final WordData firstWord = lineWords.first;
        if (firstWord.wordIndex == 0) {
          if (firstWord.text.length > 5) {
            // Likely a surah header if it's the first 'word' but long
            special[lineNum] = QuranSpecialLine.surahHeader(firstWord.surah);
          } else if (firstWord.surah != 1 && firstWord.surah != 9 && i < 2) {
            // Bismillah logic placeholder
          }
        }
      }
    }

    _specialLinesCache[pageNumber] = special;
    return special;
  }
}
