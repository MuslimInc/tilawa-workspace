import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../core/constants/quran_constants.dart';
import '../../domain/models/quran_models.dart';
import '../../domain/models/quran_page_models.dart';
import '../../domain/models/quran_word_metadata.dart';
import '../../domain/repositories/quran_mushaf_service.dart';
import '../../helpers/app_logger.dart';

class QuranPagePreparationService {
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
    required QuranMushafService mushafService,
    Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor,
  }) {
    final totalStopwatch = Stopwatch()..start();
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
        totalStopwatch.stop();
        logger.w(
          '[QuranFontsPerformance] preparePage(page: $pageNumber) CACHE HIT in ${totalStopwatch.elapsedMilliseconds}ms (${totalStopwatch.elapsedMicroseconds}µs)',
        );
        return cached;
      }
    }

    final PreparedQuranPage prepared = _buildPreparedPage(
      pageNumber: pageNumber,
      metrics: metrics,
      viewportWidth: viewportWidth,
      textColor: textColor,
      mushafService: mushafService,
      verseBackgroundColor: verseBackgroundColor,
    );

    if (!hasHighlight) {
      _cache[key] = prepared;
      while (_cache.length > _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
    }

    totalStopwatch.stop();
    logger.w(
      '[QuranFontsPerformance] preparePage(page: $pageNumber) NEW BUILD in ${totalStopwatch.elapsedMilliseconds}ms (${totalStopwatch.elapsedMicroseconds}µs)',
    );
    return prepared;
  }

  void clear() => _cache.clear();

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

  PreparedQuranPage _buildPreparedPage({
    required int pageNumber,
    required QuranLayoutMetrics metrics,
    required double viewportWidth,
    required Color textColor,
    required QuranMushafService mushafService,
    Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor,
  }) {
    final List<List<WordData>> pageLines = _getWordsGroupedByLine(
      pageNumber,
      mushafService,
    );
    final pageFont = 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
    final quranStyle = TextStyle(
      fontFamily: pageFont,
      fontSize: metrics.fontSize,
      height: metrics.fontHeight,
      color: textColor,
    );
    final markerStyle = quranStyle;

    final pageStrutStyle = StrutStyle(
      fontFamily: pageFont,
      fontSize: metrics.fontSize,
      height: metrics.fontHeight,
      forceStrutHeight: true,
    );

    final bool isCenteredPage = QuranConstants.centeredPageNumbers.contains(
      pageNumber,
    );

    final List<PreparedPageBlock> blocks = [];
    final List<InlineSpan> currentSpans = [];
    final List<QuranWordMetadata> currentMetadata = [];
    var currentOffset = 0;

    final nbSpaceSpan = TextSpan(text: '\u00A0', style: quranStyle);

    void flushTextBlock() {
      if (currentSpans.isEmpty) return;

      final painter = TextPainter(
        text: TextSpan(children: currentSpans.toList(growable: false)),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        textWidthBasis: TextWidthBasis.longestLine,
        strutStyle: pageStrutStyle,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
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

    int? centeredHeaderSurah;
    var hasCenteredBismillah = false;
    if (isCenteredPage) {
      for (var rawLine = 1; rawLine <= QuranConstants.linesPerPage; rawLine++) {
        if (_isSurahHeader(pageNumber, rawLine, mushafService)) {
          centeredHeaderSurah = _getSurahAtLine(
            pageNumber,
            rawLine,
            mushafService,
          );
        }
        if (_isBismillah(pageNumber, rawLine, mushafService)) {
          hasCenteredBismillah = true;
        }
      }
    }

    var hasSeenFirstTextLine = false;

    for (var i = 0; i < QuranConstants.linesPerPage; i++) {
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
        if (_isSurahHeader(pageNumber, i + 1, mushafService) ||
            _isBismillah(pageNumber, i + 1, mushafService)) {
          continue;
        }
      } else {
        if (_isSurahHeader(pageNumber, i + 1, mushafService)) {
          flushTextBlock();
          blocks.add(
            PreparedHeaderBlock(
              surahNumber: _getSurahAtLine(pageNumber, i + 1, mushafService),
            ),
          );
          continue;
        }

        if (_isBismillah(pageNumber, i + 1, mushafService)) {
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
        mushafService,
        verseBackgroundColor,
      );

      if (wordSpans.isEmpty) {
        if (isCenteredPage) continue;

        flushTextBlock();
        blocks.add(
          PreparedSpacerBlock(height: metrics.fontSize * metrics.fontHeight),
        );
        continue;
      }

      final bool isFirstTextLine = !hasSeenFirstTextLine;
      hasSeenFirstTextLine = true;

      for (var j = 0; j < wordSpans.length; j++) {
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

      if (!metrics.isScrollable) {
        flushTextBlock();
      } else {
        currentSpans.add(TextSpan(text: '\n', style: quranStyle));
        currentOffset += 1;
      }
    }

    flushTextBlock();

    return PreparedQuranPage(metrics: metrics, blocks: blocks);
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

  List<List<WordData>> _getWordsGroupedByLine(
    int pageNumber,
    QuranMushafService mushafService,
  ) {
    final List<List<WordData>> rawLines =
        mushafService.getPageData(pageNumber) ??
        List.generate(QuranConstants.linesPerPage, (_) => <WordData>[]);
    if (QuranConstants.centeredPageNumbers.contains(pageNumber)) {
      final List<List<WordData>> centered = List.generate(
        QuranConstants.linesPerPage,
        (_) => <WordData>[],
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
    List<List<WordData>> lines,
    int lineIndex,
    TextStyle quranStyle,
    TextStyle markerStyle,
    QuranMushafService mushafService,
    Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor,
  ) {
    if (lineIndex < 0 || lineIndex >= lines.length) {
      return const <_WordSpanGroup>[];
    }
    final List<WordData> words = lines[lineIndex];
    if (words.isEmpty) return const [];

    return words.map((WordData word) {
      final String text = word.text;
      final int surah = word.surah;
      final int ayah = word.ayah;
      final Color? bgColor = verseBackgroundColor?.call(surah, ayah);

      return _WordSpanGroup(
        surah: surah,
        verse: ayah,
        spans: _buildWordSpans(
          text: text,
          isVerseEndWord: mushafService.isVerseEndWord(word),
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

  bool _isSurahHeader(int page, int line, QuranMushafService mushafService) =>
      mushafService.getSpecialLine(page, line)?.isSurahHeader ?? false;

  bool _isBismillah(int page, int line, QuranMushafService mushafService) =>
      mushafService.getSpecialLine(page, line)?.isBismillah ?? false;

  int _getSurahAtLine(int page, int line, QuranMushafService mushafService) {
    return mushafService.getSpecialLine(page, line)?.surahNumber ?? 0;
  }
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
