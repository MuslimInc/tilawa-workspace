import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'layout/quran_layout_strategy.dart';

class PageContent extends StatefulWidget {
  const PageContent({
    super.key,
    required this.pageNumber,
    required this.textColor,
    this.verseBackgroundColor,
    this.onLongPress,
    this.onLongPressUp,
    required this.onLongPressCancel,
    required this.onLongPressDown,
    this.juzLabel,
    this.hizbLabel,
    this.surahNameBuilder,
    this.onSurahSelected,
    this.onShowIndex,
  });

  final int pageNumber;
  final Color textColor;
  final Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor;
  final void Function(int surahNumber, int verseNumber)? onLongPress;
  final void Function(int surahNumber, int verseNumber)? onLongPressUp;
  final void Function(int surahNumber, int verseNumber)? onLongPressCancel;
  final String? juzLabel;
  final String? hizbLabel;
  final String Function(int surahNumber)? surahNameBuilder;
  final ValueChanged<int>? onSurahSelected;
  final VoidCallback? onShowIndex;
  final void Function(
    int surahNumber,
    int verseNumber,
    LongPressStartDetails details,
  )?
  onLongPressDown;

  @override
  State<PageContent> createState() => _PageContentState();
}

class _PageContentState extends State<PageContent> {
  /// Word glyph data keyed by "surah:ayah:wordPos" -> { text, surah, ayah, ... }
  static Map<String, dynamic>? _qpcV4Data;

  /// Page index: page (str) -> line (str) -> [word keys sorted by id]
  /// Structure: { "3": { "1": ["2:6:1", "2:6:2", ...], "2": [...], ... }, ... }
  static Map<String, dynamic>? _pageIndex;

  /// Cache: pageNumber -> 15-element list of word-map lists (one per line).
  static final Map<int, List<List<Map<String, dynamic>>>> _pageLineCache = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initQuranData();
  }

  Future<void> _initQuranData() async {
    if (_qpcV4Data == null || _pageIndex == null) {
      try {
        final List<String> responses = await Future.wait([
          rootBundle.loadString(
            'packages/quran/assets/quran_fonts/qpc-v4.json',
          ),
          rootBundle.loadString(
            'packages/quran/assets/quran_fonts/quran_page_index.json',
          ),
        ]);
        _qpcV4Data = json.decode(responses[0]) as Map<String, dynamic>;
        _pageIndex = json.decode(responses[1]) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Error loading Quran data: $e');
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Returns words for [pageNumber] grouped into 15 lines.
  ///
  /// [_pageIndex] maps page → line → pre-sorted list of word keys.
  /// Each key is looked up in [_qpcV4Data] to get the glyph text and
  /// surah/ayah metadata. The result is cached after the first call.
  List<List<Map<String, dynamic>>> _getWordsGroupedByLine(int pageNumber) {
    if (_pageLineCache.containsKey(pageNumber)) {
      return _pageLineCache[pageNumber]!;
    }

    final Map<String, dynamic>? qpc = _qpcV4Data;
    final Map<String, dynamic>? pageIndex = _pageIndex;
    if (qpc == null || pageIndex == null) {
      return List.generate(15, (_) => []);
    }

    final pageKey = pageNumber.toString();
    final lineMap = pageIndex[pageKey] as Map<String, dynamic>?;

    // Build a 15-element list; lines not present in the index stay empty.
    final List<List<Map<String, dynamic>>> lines = List.generate(
      15,
      (_) => <Map<String, dynamic>>[],
    );

    if (lineMap != null) {
      for (final MapEntry<String, dynamic> entry in lineMap.entries) {
        final int lineIndex = (int.parse(entry.key) - 1).clamp(0, 14);
        final List<String> wordKeys = (entry.value as List<dynamic>)
            .cast<String>();
        for (final key in wordKeys) {
          final wordData = qpc[key] as Map<String, dynamic>?;
          if (wordData != null) {
            lines[lineIndex].add(wordData);
          }
        }
      }
    }

    _pageLineCache[pageNumber] = lines;
    return lines;
  }

  /// Returns the [InlineSpan]s to render for [lineIndex] on the current page.
  List<InlineSpan> _getSpansForLine(
    int lineIndex,
    double fontSize,
    String pageFont,
  ) {
    final List<List<Map<String, dynamic>>> lineWords = _getWordsGroupedByLine(
      widget.pageNumber,
    );
    if (lineIndex >= lineWords.length) {
      return [];
    }

    return lineWords[lineIndex].map<InlineSpan>((word) {
      final int surahNumber = int.tryParse(word['surah'] as String) ?? 0;
      final int verseNumber = int.tryParse(word['ayah'] as String) ?? 0;
      return TextSpan(
        text: word['text'] as String,
        style: TextStyle(
          fontFamily: pageFont,
          fontSize: fontSize,
          color: widget.textColor,
          backgroundColor: widget.verseBackgroundColor?.call(
            surahNumber,
            verseNumber,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layoutStrategy = StandardQuranLayoutStrategy();
          final QuranLayoutMetrics metrics = layoutStrategy.calculateMetrics(
            context,
            constraints,
          );
          final pageFont =
              'QCF_P${widget.pageNumber.toString().padLeft(3, '0')}';

          // Fixed line height — every slot occupies exactly 1/15th of the
          // available height, preserving the Mushaf grid regardless of whether
          // a line has content or not.
          final double lineHeight = constraints.maxHeight / 15;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (lineIndex) {
              final bool isHeader = _isSurahHeader(
                widget.pageNumber,
                lineIndex + 1,
              );
              final bool isBismillah = _isBismillah(
                widget.pageNumber,
                lineIndex + 1,
              );

              if (isHeader) {
                return _SurahHeaderBanner(
                  surahName:
                      widget.surahNameBuilder?.call(
                        _getSurahAtLine(widget.pageNumber, lineIndex + 1),
                      ) ??
                      '',
                  lineHeight: lineHeight,
                );
              }

              if (isBismillah) {
                return SizedBox(
                  width: double.infinity,
                  height: lineHeight,
                  child: Center(
                    child: Text(
                      _getVerseQCF(1, 1, addSpace: false),
                      style: TextStyle(
                        fontFamily: 'QCF_P001',
                        fontSize: metrics.fontSize * 1.1,
                        color: widget.textColor,
                      ),
                    ),
                  ),
                );
              }

              final List<InlineSpan> spans = _getSpansForLine(
                lineIndex,
                metrics.fontSize,
                pageFont,
              );

              // Empty lines (no content for this slot) collapse to zero height.
              if (spans.isEmpty) {
                return const SizedBox.shrink();
              }

              return SizedBox(
                width: double.infinity,
                height: lineHeight,
                child: Center(
                  child: RichText(text: TextSpan(children: spans)),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  bool _isSurahHeader(int page, int line) => false;
  bool _isBismillah(int page, int line) => false;
  int _getSurahAtLine(int page, int line) => 1;

  String _getVerseQCF(int surah, int ayah, {bool addSpace = true}) {
    if (_qpcV4Data == null) {
      return '';
    }
    final buffer = StringBuffer();
    var wordIndex = 1;
    while (true) {
      final key = '$surah:$ayah:$wordIndex';
      final wordData = _qpcV4Data![key] as Map<String, dynamic>?;
      if (wordData != null) {
        buffer.write(wordData['text']);
        if (addSpace) {
          buffer.write(' ');
        }
        wordIndex++;
      } else {
        break;
      }
    }
    return buffer.toString();
  }
}

class _SurahHeaderBanner extends StatelessWidget {
  const _SurahHeaderBanner({required this.surahName, required this.lineHeight});
  final String surahName;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: lineHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/surah_header_frame.png'),
        ),
      ),
      child: Center(
        child: Text(
          surahName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
