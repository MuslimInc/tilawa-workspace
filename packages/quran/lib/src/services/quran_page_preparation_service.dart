import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../constants/quran_constants.dart';
import '../layout/quran_layout_strategy.dart';
import '../widgets/quran_line.dart';
import 'quran_data_service.dart';
import 'quran_special_line.dart';

class QuranPagePreparationService {
  QuranPagePreparationService._();

  static final QuranPagePreparationService instance =
      QuranPagePreparationService._();

  // 25 pages × ~20KB per PreparedQuranPage (TextPainter + spans) ≈ 500KB.
  // Keeps a wide navigation window hot without significant memory pressure.
  static const int _maxEntries = 25;

  final LinkedHashMap<_PreparedPageKey, PreparedQuranPage> _cache =
      LinkedHashMap<_PreparedPageKey, PreparedQuranPage>();

  PreparedQuranPage? getPreparedPage({
    required int pageNumber,
    required QuranLayoutMetrics metrics,
    required double viewportWidth,
    required Color textColor,
    Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor,
  }) {
    return _cache[_buildKey(
      pageNumber: pageNumber,
      metrics: metrics,
      viewportWidth: viewportWidth,
      textColor: textColor,
      verseBackgroundColor: verseBackgroundColor,
    )];
  }

  PreparedQuranPage preparePage({
    required int pageNumber,
    required QuranLayoutMetrics metrics,
    required double viewportWidth,
    required Color textColor,
    Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor,
  }) {
    final hasHighlight = verseBackgroundColor != null;
    final _PreparedPageKey key = _buildKey(
      pageNumber: pageNumber,
      metrics: metrics,
      viewportWidth: viewportWidth,
      textColor: textColor,
      verseBackgroundColor: verseBackgroundColor,
    );

    if (!hasHighlight) {
      final PreparedQuranPage? cached = _cache.remove(key);
      if (cached != null) {
        _cache[key] = cached;
        return cached;
      }
    }

    final PreparedQuranPage prepared = _buildPreparedPage(
      pageNumber: pageNumber,
      metrics: metrics,
      viewportWidth: viewportWidth,
      textColor: textColor,
      verseBackgroundColor: verseBackgroundColor,
    );

    if (!hasHighlight) {
      _cache[key] = prepared;
      while (_cache.length > _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      // NOTE: Glyph atlas warm-up (toImage) is intentionally NOT called here.
      // It must be scheduled at idle time by the reader to avoid GPU↔CPU sync
      // during swipe transitions — see quran_font_service.dart.
    }

    return prepared;
  }

  void clear() => _cache.clear();

  /// Re-inserts a previously prepared page into the cache without rebuilding.
  ///
  /// Used to survive a [clear] call when the caller already holds valid
  /// [PreparedQuranPage] objects — e.g. re-seeding after a viewport change
  /// so the LRU doesn't evict pages that were pre-computed before mount.
  void seedPage({
    required int pageNumber,
    required PreparedQuranPage preparedPage,
    required QuranLayoutMetrics metrics,
    required double viewportWidth,
    required Color textColor,
  }) {
    final _PreparedPageKey key = _buildKey(
      pageNumber: pageNumber,
      metrics: metrics,
      viewportWidth: viewportWidth,
      textColor: textColor,
    );
    _cache.remove(key);
    _cache[key] = preparedPage;
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  _PreparedPageKey _buildKey({
    required int pageNumber,
    required QuranLayoutMetrics metrics,
    required double viewportWidth,
    required Color textColor,
    Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor,
  }) {
    return _PreparedPageKey(
      pageNumber: pageNumber,
      fontSize: metrics.fontSize,
      fontHeight: metrics.fontHeight,
      viewportWidth: viewportWidth,
      textColorValue: textColor.toARGB32(),
      hasHighlight: verseBackgroundColor != null,
    );
  }

  PreparedQuranPage _buildPreparedPage({
    required int pageNumber,
    required QuranLayoutMetrics metrics,
    required double viewportWidth,
    required Color textColor,
    Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor,
  }) {
    final List<List<Map<String, dynamic>>> pageLines = _getWordsGroupedByLine(
      pageNumber,
    );
    final pageFont = 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
    final quranStyle = TextStyle(
      fontFamily: pageFont,
      fontSize: metrics.fontSize,
      height: metrics.fontHeight,
      color: textColor,
    );
    final markerStyle = quranStyle;

    // Hoist StrutStyle out of flushTextBlock — it is identical for every text
    // block on this page and allocating it per-block (up to 15×) is wasteful.
    final pageStrutStyle = StrutStyle(
      fontFamily: pageFont,
      fontSize: metrics.fontSize,
      height: metrics.fontHeight,
      forceStrutHeight: true,
    );

    final bool isCenteredPage = QuranConstants.centeredPageNumbers.contains(
      pageNumber,
    );

    final List<int> lineIndices = metrics.isScrollable
        ? List.generate(QuranConstants.linesPerPage, (int i) => i).where((i) {
            return isCenteredPage ||
                pageLines[i].isNotEmpty ||
                _isSurahHeader(pageNumber, i + 1) ||
                _isBismillah(pageNumber, i + 1);
          }).toList()
        : List.generate(QuranConstants.linesPerPage, (int i) => i);

    final List<PreparedPageBlock> blocks = [];
    final List<InlineSpan> currentSpans = [];
    final List<QuranWordMetadata> currentMetadata = [];
    var currentOffset = 0;

    final newlineSpan = TextSpan(text: '\n', style: quranStyle);
    final nbSpaceSpan = TextSpan(text: '\u00A0', style: quranStyle);

    void flushTextBlock() {
      if (currentSpans.isEmpty) return;

      final painter = TextPainter(
        text: TextSpan(children: currentSpans.toList(growable: false)),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        textWidthBasis: TextWidthBasis.longestLine,
        strutStyle: pageStrutStyle,
      )..layout(maxWidth: viewportWidth);

      blocks.add(
        PreparedTextBlock(
          painter: painter,
          metadata: List<QuranWordMetadata>.from(currentMetadata),
        ),
      );

      currentSpans.clear();
      currentMetadata.clear();
      currentOffset = 0;
    }

    // For pages 1 & 2, pre-compute centered positions for header/bismillah.
    // The _getWordsGroupedByLine centering puts:
    //   centered[2] = rawLines[0] (header line — empty word data)
    //   centered[5..11] = rawLines[1..7] (verse text)
    // The header should visually appear at index 2, and the bismillah just
    // before the verse block at index 4.
    //
    // NOTE: Page 1 (Al-Fatihah) has NO separate bismillah — the Bismillah IS
    // verse 1 and is already present in the QCF word data. Only pages with an
    // explicit BISMILLAH special line (e.g. page 2) get a BismillahBlock.
    int? centeredHeaderSurah;
    var hasCenteredBismillah = false;
    if (isCenteredPage) {
      for (var rawLine = 1; rawLine <= QuranConstants.linesPerPage; rawLine++) {
        if (_isSurahHeader(pageNumber, rawLine)) {
          centeredHeaderSurah = _getSurahAtLine(pageNumber, rawLine);
        }
        if (_isBismillah(pageNumber, rawLine)) {
          hasCenteredBismillah = true;
        }
      }
    }

    // Track whether we've seen the first textual line (for QCF first-line spacing).
    var hasSeenFirstTextLine = false;

    for (final i in lineIndices) {
      // --- Centered page layout (pages 1 & 2) ---
      // Header and bismillah are placed at specific centered positions
      // instead of at raw line-map positions (which would put them at
      // the very top, breaking the Madinah Mushaf centered layout).
      if (isCenteredPage) {
        if (i == QuranConstants.centeredHeaderLineIndex &&
            centeredHeaderSurah != null) {
          flushTextBlock();
          blocks.add(PreparedHeaderBlock(surahNumber: centeredHeaderSurah));
          continue;
        }
        if (i == QuranConstants.centeredBismillahLineIndex &&
            hasCenteredBismillah) {
          flushTextBlock();
          blocks.add(const PreparedBismillahBlock());
          continue;
        }
        // Skip raw special-line positions — they are handled above.
        if (_isSurahHeader(pageNumber, i + 1) ||
            _isBismillah(pageNumber, i + 1)) {
          continue;
        }
      } else {
        // --- Standard page layout (pages 3–604) ---
        if (_isSurahHeader(pageNumber, i + 1)) {
          flushTextBlock();
          blocks.add(
            PreparedHeaderBlock(
              surahNumber: _getSurahAtLine(pageNumber, i + 1),
            ),
          );
          continue;
        }

        if (_isBismillah(pageNumber, i + 1)) {
          flushTextBlock();
          blocks.add(const PreparedBismillahBlock());
          continue;
        }
      }

      final List<_WordSpanGroup> wordSpans = _getWordSpansForLine(
        pageLines,
        i,
        quranStyle,
        markerStyle,
        verseBackgroundColor,
      );

      if (wordSpans.isEmpty) {
        // Centered pages should NOT have blank lines at the top/bottom,
        // so the Column can be 'min' sized and perfectly centered.
        if (isCenteredPage) continue;

        const blankLine = '\u00A0\n';
        currentSpans.add(TextSpan(text: blankLine, style: quranStyle));
        currentOffset += blankLine.length;
        continue;
      }

      final bool isFirstTextLine = !hasSeenFirstTextLine;
      hasSeenFirstTextLine = true;

      for (var j = 0; j < wordSpans.length; j++) {
        // QCF standard: insert U+00A0 between the 1st and 2nd glyph
        // on the first textual line of each page. This triggers the
        // correct spacing behavior in the QCF font without enabling
        // Flutter's line-breaking algorithm (which U+0020 would do).
        if (isFirstTextLine && j == 1) {
          currentSpans.add(nbSpaceSpan);
          currentOffset += 1;
        }

        final _WordSpanGroup group = wordSpans[j];
        currentSpans.addAll(group.spans);

        var groupLength = 0;
        for (final InlineSpan span in group.spans) {
          if (span is TextSpan) {
            groupLength += span.text?.length ?? 0;
          }
        }

        currentMetadata.add(
          QuranWordMetadata(
            surah: group.surah,
            verse: group.verse,
            startOffset: currentOffset,
            endOffset: currentOffset + groupLength,
          ),
        );

        currentOffset += groupLength;
      }

      // In portrait mushaf mode (!isScrollable), we flush after every line.
      // This turns every single line into its own PreparedTextBlock widget.
      if (!metrics.isScrollable) {
        flushTextBlock();
      } else {
        currentSpans.add(newlineSpan);
        currentOffset += 1;
      }
    }

    flushTextBlock();

    return PreparedQuranPage(metrics: metrics, blocks: blocks);
  }

  List<List<Map<String, dynamic>>> _getWordsGroupedByLine(int pageNumber) {
    final List<List<Map<String, dynamic>>> rawLines =
        QuranDataService.instance.getPageData(pageNumber) ??
        List.generate(
          QuranConstants.linesPerPage,
          (_) => <Map<String, dynamic>>[],
        );
    if (QuranConstants.centeredPageNumbers.contains(pageNumber)) {
      final List<List<Map<String, dynamic>>> centered = List.generate(
        QuranConstants.linesPerPage,
        (_) => <Map<String, dynamic>>[],
      );
      centered[QuranConstants.centeredHeaderLineIndex] = rawLines[0];
      for (
        var i = 0;
        i < QuranConstants.centeredTextLineCount &&
            (QuranConstants.centeredTextRawStartLineIndex + i) <
                rawLines.length;
        i++
      ) {
        centered[QuranConstants.centeredTextStartLineIndex + i] =
            rawLines[QuranConstants.centeredTextRawStartLineIndex + i];
      }
      return centered;
    }
    return rawLines;
  }

  List<_WordSpanGroup> _getWordSpansForLine(
    List<List<Map<String, dynamic>>> lines,
    int lineIndex,
    TextStyle quranStyle,
    TextStyle markerStyle,
    Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor,
  ) {
    if (lineIndex < 0 || lineIndex >= QuranConstants.linesPerPage) {
      return const <_WordSpanGroup>[];
    }
    final List<Map<String, dynamic>> words = lines[lineIndex];
    if (words.isEmpty) return const [];

    final QuranDataService quranDataService = QuranDataService.instance;
    return words.map((word) {
      final text = word['text'] as String;
      final int surah = int.tryParse(word['surah'].toString()) ?? 0;
      final int ayah = int.tryParse(word['ayah'].toString()) ?? 0;
      final Color? bgColor = verseBackgroundColor?.call(surah, ayah);

      return _WordSpanGroup(
        surah: surah,
        verse: ayah,
        spans: _buildWordSpans(
          text: text,
          isVerseEndWord: quranDataService.isVerseEndWord(word),
          quranTextStyle: bgColor != null
              ? quranStyle.copyWith(backgroundColor: bgColor)
              : quranStyle,
          markerTextStyle: bgColor != null
              ? markerStyle.copyWith(backgroundColor: bgColor)
              : markerStyle,
        ),
      );
    }).toList();
  }

  List<InlineSpan> _buildWordSpans({
    required String text,
    required bool isVerseEndWord,
    required TextStyle quranTextStyle,
    required TextStyle markerTextStyle,
  }) {
    if (!isVerseEndWord || text.isEmpty) {
      return [TextSpan(text: text, style: quranTextStyle)];
    }

    final List<int> runes = text.runes.toList();
    if (runes.length == 1) {
      return [TextSpan(text: text, style: markerTextStyle)];
    }

    return [
      TextSpan(
        text: String.fromCharCodes(runes.take(runes.length - 1)),
        style: quranTextStyle,
      ),
      TextSpan(
        text: String.fromCharCodes(runes.skip(runes.length - 1)),
        style: markerTextStyle,
      ),
    ];
  }

  bool _isSurahHeader(int page, int line) =>
      _getSpecialLine(page, line)?.isSurahHeader ?? false;

  bool _isBismillah(int page, int line) =>
      _getSpecialLine(page, line)?.isBismillah ?? false;

  int _getSurahAtLine(int page, int line) {
    return _getSpecialLine(page, line)?.surahNumber ?? 0;
  }

  QuranSpecialLine? _getSpecialLine(int page, int line) {
    return QuranDataService.instance.getSpecialLine(page, line);
  }
}

class PreparedQuranPage {
  const PreparedQuranPage({required this.metrics, required this.blocks});

  final QuranLayoutMetrics metrics;
  final List<PreparedPageBlock> blocks;
}

@immutable
class PreparedQuranPageWindow {
  PreparedQuranPageWindow({
    required this.centerPage,
    required this.radius,
    required Set<int> visiblePageNumbers,
    required Map<int, PreparedQuranPage> preparedPages,
  }) : visiblePageNumbers = Set<int>.unmodifiable(visiblePageNumbers),
       preparedPages = Map<int, PreparedQuranPage>.unmodifiable(preparedPages);

  final int centerPage;
  final int radius;
  final Set<int> visiblePageNumbers;
  final Map<int, PreparedQuranPage> preparedPages;

  Set<int> get pageNumbers => visiblePageNumbers;

  bool contains(int pageNumber) => visiblePageNumbers.contains(pageNumber);

  PreparedQuranPage? preparedPageFor(int pageNumber) =>
      preparedPages[pageNumber];
}

sealed class PreparedPageBlock extends Equatable {
  const PreparedPageBlock();
}

class PreparedTextBlock extends PreparedPageBlock {
  const PreparedTextBlock({required this.painter, required this.metadata});

  final TextPainter painter;
  final List<QuranWordMetadata> metadata;

  @override
  List<Object?> get props => [painter, metadata];
}

class PreparedHeaderBlock extends PreparedPageBlock {
  const PreparedHeaderBlock({required this.surahNumber});

  final int surahNumber;

  @override
  List<Object?> get props => [surahNumber];
}

class PreparedBismillahBlock extends PreparedPageBlock {
  const PreparedBismillahBlock();

  @override
  List<Object?> get props => [];
}

@immutable
class _PreparedPageKey extends Equatable {
  const _PreparedPageKey({
    required this.pageNumber,
    required this.fontSize,
    required this.fontHeight,
    required this.viewportWidth,
    required this.textColorValue,
    required this.hasHighlight,
  });

  final int pageNumber;
  final double fontSize;
  final double fontHeight;
  final double viewportWidth;
  final int textColorValue;
  final bool hasHighlight;

  int get _fontSizeKey => (fontSize * 100).round();
  int get _fontHeightKey => (fontHeight * 100).round();
  int get _viewportWidthKey => (viewportWidth * 100).round();

  @override
  List<Object?> get props => [
    pageNumber,
    _fontSizeKey,
    _fontHeightKey,
    _viewportWidthKey,
    textColorValue,
    hasHighlight,
  ];
}

class _WordSpanGroup extends Equatable {
  const _WordSpanGroup({
    required this.spans,
    required this.surah,
    required this.verse,
  });

  final List<InlineSpan> spans;
  final int surah;
  final int verse;

  @override
  List<Object?> get props => [spans, surah, verse];
}
