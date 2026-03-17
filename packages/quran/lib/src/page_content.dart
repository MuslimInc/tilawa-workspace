import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../quran.dart';
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

/// Pre-seeds the QPC v4 data cache for testing. Avoids the need for
/// `rootBundle` + `compute()` in the test environment.
@visibleForTesting
void preloadPageContentCache(
  Map<String, dynamic> qpcV4Data,
  Map<int, List<List<Map<String, dynamic>>>> processedPageIndex,
) {
  _PageContentState._qpcV4Data = qpcV4Data;
  _PageContentState._processedPageIndex = processedPageIndex;
  _PageContentState._loadCompleter = Completer<void>()..complete();
}

/// Clears the QPC v4 data cache. Call in test tearDown to reset state.
@visibleForTesting
void clearPageContentCache() {
  _PageContentState._qpcV4Data = null;
  _PageContentState._processedPageIndex = null;
  _PageContentState._loadCompleter = null;
}

class _PageContentState extends State<PageContent>
    with AutomaticKeepAliveClientMixin {
  /// Word glyph data keyed by "surah:ayah:wordPos" -> { text, surah, ayah, ... }
  static Map<String, dynamic>? _qpcV4Data;

  /// Processed Page index: page (int) -> 15-element list of word-map lists.
  static Map<int, List<List<Map<String, dynamic>>>>? _processedPageIndex;

  static Completer<void>? _loadCompleter;

  /// Shared layout strategy instance (stateless — no need to recreate).
  static final StandardQuranLayoutStrategy _layoutStrategy =
      StandardQuranLayoutStrategy();

  bool _isLoading = true;

  /// Caches the rendered page as a raster image after first paint so that
  /// subsequent frames during swipe animation composite a cached bitmap
  /// instead of re-rasterizing 15 FittedBox+RichText widgets (~25ms saving).
  final SnapshotController _snapshotController =
      SnapshotController(allowSnapshotting: false);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initQuranData();
  }

  @override
  void dispose() {
    _snapshotController.dispose();
    super.dispose();
  }

  Future<void> _initQuranData() async {
    if (_qpcV4Data != null && _processedPageIndex != null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (_loadCompleter != null) {
      await _loadCompleter!.future;
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _loadCompleter = Completer<void>();
    try {
      final List<String> responses = await Future.wait([
        rootBundle.loadString('packages/quran/assets/quran_fonts/qpc-v4.json'),
        rootBundle.loadString(
          'packages/quran/assets/quran_fonts/quran_page_index.json',
        ),
      ]);

      // Offload decoding and heavy processing to a background isolate.
      final List<dynamic> decoded = await compute(_decodeAndProcess, responses);

      _qpcV4Data = decoded[0] as Map<String, dynamic>;
      _processedPageIndex =
          decoded[1] as Map<int, List<List<Map<String, dynamic>>>>;

      _loadCompleter!.complete();
    } catch (e) {
      debugPrint('Error loading Quran data: $e');
      _loadCompleter!.completeError(e);
      _loadCompleter = null; // Allow retry
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Heavy lifting: decode JSON and pre-build the O(1) page lookup map.
  static List<dynamic> _decodeAndProcess(List<String> jsonStrings) {
    final qpc = json.decode(jsonStrings[0]) as Map<String, dynamic>;
    final pageIndexRaw = json.decode(jsonStrings[1]) as Map<String, dynamic>;

    final processedIndex = <int, List<List<Map<String, dynamic>>>>{};

    for (final pageEntry in pageIndexRaw.entries) {
      final int pageNum = int.parse(pageEntry.key);
      final Map<String, dynamic> lineMap =
          pageEntry.value as Map<String, dynamic>;

      final List<List<Map<String, dynamic>>> lines = List.generate(
        15,
        (_) => <Map<String, dynamic>>[],
      );

      for (final lineEntry in lineMap.entries) {
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

  /// Returns words for [pageNumber] grouped into 15 lines (O(1) lookup).
  List<List<Map<String, dynamic>>> _getWordsGroupedByLine(int pageNumber) {
    return _processedPageIndex?[pageNumber] ?? List.generate(15, (_) => []);
  }

  /// Returns the [InlineSpan]s to render for [lineIndex] from pre-fetched [lines].
  ///
  /// Accepts a pre-built [baseStyle] to avoid allocating a new TextStyle per
  /// word when no verse-specific background color is needed.
  List<InlineSpan> _getSpansForLine(
    List<List<Map<String, dynamic>>> lines,
    int lineIndex,
    TextStyle baseStyle,
  ) {
    if (lineIndex < 0 || lineIndex >= 15) {
      return [];
    }
    final List<Map<String, dynamic>> lineWords = lines[lineIndex];
    if (lineWords.isEmpty) return [];

    final bool hasVerseColorCallback = widget.verseBackgroundColor != null;

    final List<InlineSpan> spans = lineWords.map<InlineSpan>((word) {
      final String text = word['text'] as String;

      if (!hasVerseColorCallback) {
        return TextSpan(text: text, style: baseStyle);
      }

      final int surahNumber = int.tryParse(word['surah'] as String) ?? 0;
      final int verseNumber = int.tryParse(word['ayah'] as String) ?? 0;
      final Color? bgColor = widget.verseBackgroundColor!(
        surahNumber,
        verseNumber,
      );

      if (bgColor == null) {
        return TextSpan(text: text, style: baseStyle);
      }

      return TextSpan(
        text: text,
        style: baseStyle.copyWith(backgroundColor: bgColor),
      );
    }).toList();

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Map<String, int>> ranges = QuranServiceLocator.quranDataService
        .getPageData(widget.pageNumber);
    final Map<String, int> firstVerse = ranges.first;
    final int surahNumber = firstVerse['surah']!;
    final int juzNumber = QuranServiceLocator.quranDataService.getJuzNumber(
      surahNumber,
      firstVerse['start']!,
    );
    final int? quarterNumber = widget.pageNumber == 1 || widget.pageNumber == 2
        ? null
        : QuranServiceLocator.quranDataService.getQuarterNumber(
            surahNumber,
            firstVerse['start']!,
          );

    final String displaySurahName =
        widget.surahNameBuilder?.call(surahNumber) ??
        QuranServiceLocator.surahService
            .getName(surahNumber)
            .replaceAll('Al ', 'Al-');

    final _PageHeader header = _PageHeader(
      surahName: displaySurahName,
      juzNumber: juzNumber,
      juzLabel: widget.juzLabel ?? 'Juz',
      textColor: widget.textColor,
    );

    final _PageFooter footer = _PageFooter(
      quarterNumber: quarterNumber,
      pageNumber: widget.pageNumber,
      hizbLabel: widget.hizbLabel ?? 'Hizb',
      textColor: widget.textColor,
      onSurahSelected: widget.onSurahSelected,
      onShowIndex: widget.onShowIndex,
    );

    // Fetch line data once — does not depend on layout constraints.
    final List<List<Map<String, dynamic>>> pageLines =
        _getWordsGroupedByLine(widget.pageNumber);
    final int firstLineIdx = _firstContentLineIndexFromLines(pageLines);
    // Enable raster caching after the first frame so swipe animation
    // composites a cached bitmap instead of re-rasterizing.
    if (!_snapshotController.allowSnapshotting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _snapshotController.allowSnapshotting = true;
        }
      });
    }

    final Widget result = SnapshotWidget(
      controller: _snapshotController,
      child: SafeArea(
        bottom: false, // Allow it to extend to the very bottom
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: header,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final QuranLayoutMetrics metrics = _layoutStrategy
                      .calculateMetrics(context, constraints);
                  final pageFont =
                      'QCF_P${widget.pageNumber.toString().padLeft(3, '0')}';

                  final isLandscape =
                      MediaQuery.orientationOf(context) == Orientation.landscape;
                  final double lineHeight = metrics.fontSize * metrics.fontHeight;

                  // Build one shared TextStyle for the entire page — all words
                  // share font, size, color, height. Only verse background
                  // color (rare) needs a per-word override via copyWith.
                  final baseStyle = TextStyle(
                    fontFamily: pageFont,
                    fontSize: metrics.fontSize,
                    color: widget.textColor,
                    height: metrics.fontHeight,
                  );

                  // Thin-space style for first content line separator.
                  final spaceStyle = TextStyle(
                    fontFamily: pageFont,
                    fontSize: metrics.fontSize,
                    height: metrics.fontHeight,
                  );

                  final List<Widget> lineWidgets = List.generate(15, (lineIndex) {
                    final bool isHeader = _isSurahHeader(
                      widget.pageNumber,
                      lineIndex + 1,
                    );
                    final bool isBismillah = _isBismillah(
                      widget.pageNumber,
                      lineIndex + 1,
                    );

                    if (isHeader) {
                      final int surahNum = _getSurahAtLine(
                        widget.pageNumber,
                        lineIndex + 1,
                      );
                      return _SurahHeaderBanner(
                        surahNumber: surahNum,
                        lineHeight: lineHeight,
                      );
                    }

                    if (isBismillah) {
                      return SizedBox(
                        width: double.infinity,
                        height: lineHeight,
                        child: Center(
                          child: Text(
                            _getVerseQCF(1, 1, spaceChar: '\u200A'),
                            style: TextStyle(
                              fontFamily: 'QCF_P001',
                              fontSize: metrics.fontSize * 1.1,
                              color: widget.textColor,
                              height: 1.0,
                            ),
                          ),
                        ),
                      );
                    }

                    final List<InlineSpan> spans = _getSpansForLine(
                      pageLines,
                      lineIndex,
                      baseStyle,
                    );

                    // Insert a thin space after the first word on the first content line
                    final isFirstContentLine = lineIndex == firstLineIdx;
                    if (isFirstContentLine && spans.length > 1) {
                      spans.insert(
                        1,
                        TextSpan(text: '\u200A', style: spaceStyle),
                      );
                    }

                    if (spans.isEmpty) return const SizedBox();

                    return Container(
                      width: double.infinity,
                      height: lineHeight,
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: FittedBox(
                        fit: (widget.pageNumber == 1 || widget.pageNumber == 2)
                            ? BoxFit.contain
                            : BoxFit.fill,
                        child: RichText(
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                          textHeightBehavior: const TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                            applyHeightToLastDescent: false,
                          ),
                          text: TextSpan(children: spans),
                        ),
                      ),
                    );
                  });

                  final lines = Column(children: lineWidgets);

                  if (isLandscape) {
                    return SingleChildScrollView(child: lines);
                  }
                  return lines;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: footer,
            ),
          ],
        ),
      ),
    );
    return result;
  }

  /// Returns the 0-based line index of the first line that has content
  /// from pre-fetched [lines]. Avoids a redundant `_getWordsGroupedByLine` call.
  int _firstContentLineIndexFromLines(List<List<Map<String, dynamic>>> lines) {
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].isNotEmpty) return i;
    }
    return 0;
  }

  bool _isSurahHeader(int page, int line) {
    return _getSpecialType(page, line)?.startsWith('HEADER') ?? false;
  }

  bool _isBismillah(int page, int line) {
    return _getSpecialType(page, line)?.startsWith('BISMILLAH') ?? false;
  }

  int _getSurahAtLine(int page, int line) {
    final String? type = _getSpecialType(page, line);
    if (type != null) {
      final List<String> parts = type.split(':');
      if (parts.length > 1) {
        return int.tryParse(parts[1]) ?? 1;
      }
    }

    final List<List<Map<String, dynamic>>> wordsByLine = _getWordsGroupedByLine(
      page,
    );
    final int lineIdx = line - 1;
    if (lineIdx >= 0 && lineIdx < wordsByLine.length) {
      final List<Map<String, dynamic>> words = wordsByLine[lineIdx];
      if (words.isNotEmpty) {
        return int.tryParse(words.first['surah']?.toString() ?? '1') ?? 1;
      }
    }
    return 1;
  }

  static final Map<int, Map<int, String>> _specialLinesCache = {};

  String? _getSpecialType(int page, int line) {
    if (!_specialLinesCache.containsKey(page)) {
      _specialLinesCache[page] = _calculateSpecialLines(page);
    }
    return _specialLinesCache[page]![line];
  }

  Map<int, String> _calculateSpecialLines(int pageNumber) {
    final Map<int, String> special = {};
    final List<List<Map<String, dynamic>>> lines = _getWordsGroupedByLine(
      pageNumber,
    );

    // Standard Quran Mushaf layout logic for headers and bismillah:
    // 1. Scan for Verse 1 of any Surah starting on this page.
    for (int i = 0; i < lines.length; i++) {
      final List<Map<String, dynamic>> lineWords = lines[i];
      if (lineWords.isNotEmpty) {
        final Map<String, dynamic> firstWord = lineWords.first;
        final int surah = int.tryParse(firstWord['surah'].toString()) ?? 0;
        final int ayah = int.tryParse(firstWord['ayah'].toString()) ?? 0;
        final int word = int.tryParse(firstWord['word'].toString()) ?? 0;

        if (ayah == 1 && word == 1) {
          final int lineNum = i + 1;
          if (surah == 1) {
            // Fatiha Page 1 special logic
            if (pageNumber == 1) {
              special[1] = 'HEADER:1';
            }
          } else if (surah == 9) {
            // At-Tawbah: Header only
            if (lineNum > 1) {
              special[lineNum - 1] = 'HEADER:9';
            }
          } else {
            // Other surahs: Header then Bismillah
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

  String _getVerseQCF(
    int surah,
    int ayah, {
    bool addSpace = true,
    String spaceChar = ' ',
  }) {
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
          buffer.write(spaceChar);
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
  const _SurahHeaderBanner({
    required this.surahNumber,
    required this.lineHeight,
  });
  final int surahNumber;
  final double lineHeight;

  static const AssetImage _bannerImage =
      AssetImage('assets/mainframe.png', package: 'quran');

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: SizedBox(
          height: lineHeight,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image(
                  image: _bannerImage,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.low,
                ),
              ),
              Text(
                String.fromCharCode(0xF100 + surahNumber - 1),
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'QCF_BSML',
                  package: 'quran',
                  fontSize: lineHeight * 0.45,
                  color: const Color(0xFF000000),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.surahName,
    required this.juzNumber,
    required this.textColor,
    required this.juzLabel,
  });

  final String surahName;
  final int juzNumber;
  final Color textColor;
  final String juzLabel;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(
      0xFF4E342E,
    ); // Darker brown for better contrast (WCAG AA)
    final double verseFontSize = MediaQuery.sizeOf(context).width * 0.030;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            surahName,
            style: TextStyle(
              color: primaryColor,
              fontSize: verseFontSize,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            '$juzLabel $juzNumber',
            style: TextStyle(
              color: primaryColor,
              fontSize: verseFontSize,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PageFooter extends StatelessWidget {
  const _PageFooter({
    required this.quarterNumber,
    required this.pageNumber,
    required this.hizbLabel,
    required this.textColor,
    required this.onSurahSelected,
    required this.onShowIndex,
  });

  final int? quarterNumber;
  final int pageNumber;
  final String hizbLabel;
  final Color textColor;
  final ValueChanged<int>? onSurahSelected;
  final VoidCallback? onShowIndex;

  String _getHizbLabel() {
    if (quarterNumber == null) {
      return '';
    }
    final int hizbIndex = (quarterNumber! - 1) ~/ 4 + 1;
    final int quarterInHizb = (quarterNumber! - 1) % 4;

    final String prefix;
    switch (quarterInHizb) {
      case 0:
        prefix = '';
      case 1:
        prefix = '1/4 ';
      case 2:
        prefix = '1/2 ';
      case 3:
        prefix = '3/4 ';
      default:
        prefix = '';
    }

    return '$prefix$hizbLabel $hizbIndex';
  }

  @override
  Widget build(BuildContext context) {
    if (pageNumber == 1 || pageNumber == 2) {
      return const SizedBox.shrink();
    }

    final String hizbLabel = _getHizbLabel();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
      ), // Increased horizontal spacing
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SurahIndexButton(onShowIndex: onShowIndex),
          _QuranPageIndex(hizbLabel: hizbLabel, pageNumber: pageNumber),
        ],
      ),
    );
  }
}

class _QuranPageIndex extends StatelessWidget {
  const _QuranPageIndex({required this.hizbLabel, required this.pageNumber});

  final String hizbLabel;
  final int pageNumber;

  static final List<BoxShadow> _shadows = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F5EF),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: _shadows,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hizbLabel.isNotEmpty) ...[
              Text(
                hizbLabel,
                style: const TextStyle(
                  color: Color(0xFF4E342E), // Match header contrast
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 14,
                color: const Color(0xFF4E342E).withValues(alpha: 0.3),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              '$pageNumber',
              style: const TextStyle(
                color: Color(0xFF4E342E), // Match header contrast
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahIndexButton extends StatelessWidget {
  const _SurahIndexButton({required this.onShowIndex});

  final VoidCallback? onShowIndex;

  static final List<BoxShadow> _shadows = [
    BoxShadow(
      color: const Color(0xFFA68B67).withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: InkWell(
        onTap: onShowIndex,
        child: Container(
          width: 40.h,
          height: 40.h,
          decoration: BoxDecoration(
            color: const Color(0xFFA68B67),
            shape: BoxShape.circle,
            boxShadow: _shadows,
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
