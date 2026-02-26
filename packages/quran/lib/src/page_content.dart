import 'dart:convert';
import 'dart:math';

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
    String pageFont, {
    double? fontHeight,
  }) {
    final List<List<Map<String, dynamic>>> lineWords = _getWordsGroupedByLine(
      widget.pageNumber,
    );
    if (lineWords.length < 15) {
      lineWords.addAll(List.generate(15 - lineWords.length, (_) => []));
    }
    if (lineIndex < 0 || lineIndex >= 15) {
      return [];
    }

    final List<InlineSpan> spans = lineWords[lineIndex].map<InlineSpan>((word) {
      final int surahNumber = int.tryParse(word['surah'] as String) ?? 0;
      final int verseNumber = int.tryParse(word['ayah'] as String) ?? 0;
      return TextSpan(
        text: word['text'] as String,
        style: TextStyle(
          fontFamily: pageFont,
          fontSize: fontSize,
          color: widget.textColor,
          height: fontHeight,
          backgroundColor: widget.verseBackgroundColor?.call(
            surahNumber,
            verseNumber,
          ),
        ),
      );
    }).toList();

    // Insert a thin space after the first word on the first content line of
    // every page. In RTL layout the first word sits at the right edge, so
    // the space appears immediately to its left, marking the page-start word.
    final isFirstContentLine =
        lineIndex == _firstContentLineIndex(widget.pageNumber);
    if (isFirstContentLine && spans.length > 1) {
      spans.insert(
        1,
        TextSpan(
          text: '\u200A',
          style: TextStyle(
            fontFamily: pageFont,
            fontSize: fontSize,
            height: fontHeight,
          ),
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
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

    final header = _PageHeader(
      surahName: displaySurahName,
      juzNumber: juzNumber,
      juzLabel: widget.juzLabel ?? 'Juz',
      textColor: widget.textColor,
    );

    final footer = _PageFooter(
      quarterNumber: quarterNumber,
      pageNumber: widget.pageNumber,
      hizbLabel: widget.hizbLabel ?? 'Hizb',
      textColor: widget.textColor,
      onSurahSelected: widget.onSurahSelected,
      onShowIndex: widget.onShowIndex,
    );

    return SafeArea(
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
                final layoutStrategy = StandardQuranLayoutStrategy();
                final QuranLayoutMetrics metrics = layoutStrategy
                    .calculateMetrics(context, constraints);
                final pageFont =
                    'QCF_P${widget.pageNumber.toString().padLeft(3, '0')}';

                final isLandscape =
                    MediaQuery.orientationOf(context) == Orientation.landscape;
                final double lineHeight = metrics.fontSize * metrics.fontHeight;

                final lines = Column(
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
                      lineIndex,
                      metrics.fontSize,
                      pageFont,
                      fontHeight: metrics.fontHeight,
                    );

                    return Container(
                      width: double.infinity,
                      height: lineHeight,
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: spans.isEmpty
                          ? const SizedBox()
                          : FittedBox(
                              fit: BoxFit.fill,
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
                  }),
                );

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
    );
  }

  /// Returns the 0-based line index of the first line that has content on
  /// [pageNumber]. For most pages this is 0, but pages 1 and 2 start later.
  int _firstContentLineIndex(int pageNumber) {
    final Map<String, dynamic>? pageIndex = _pageIndex;
    if (pageIndex == null) {
      return 0;
    }
    final lineMap = pageIndex[pageNumber.toString()] as Map<String, dynamic>?;
    if (lineMap == null || lineMap.isEmpty) {
      return 0;
    }
    return lineMap.keys.map(int.parse).reduce(min) - 1;
  }

  bool _isSurahHeader(int page, int line) {
    if (_pageIndex == null) {
      return false;
    }
    return _getSpecialType(page, line)?.startsWith('HEADER') ?? false;
  }

  bool _isBismillah(int page, int line) {
    if (_pageIndex == null) {
      return false;
    }
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

    final List<dynamic> wordsByLine = _getWordsGroupedByLine(page);
    final int lineIdx = line - 1;
    if (lineIdx >= 0 && lineIdx < wordsByLine.length) {
      final List<Map<String, dynamic>> words = wordsByLine[lineIdx];
      if (words.isNotEmpty) {
        return int.tryParse(words.first['surah']?.toString() ?? '1') ?? 1;
      }
    }
    return 1;
  }

  final Map<int, Map<int, String>> _specialLinesCache = {};

  String? _getSpecialType(int page, int line) {
    if (!_specialLinesCache.containsKey(page)) {
      _specialLinesCache[page] = _calculateSpecialLines(page);
    }
    return _specialLinesCache[page]![line];
  }

  Map<int, String> _calculateSpecialLines(int pageNumber) {
    final Map<int, String> special = {};
    if (_pageIndex == null) {
      return special;
    }

    final pageKey = pageNumber.toString();
    final lineMap = _pageIndex![pageKey] as Map<String, dynamic>?;
    if (lineMap == null) {
      return special;
    }

    // Standard Quran Mushaf layout logic for headers and bismillah:
    // 1. Scan for Verse 1 of any Surah starting on this page.
    for (final MapEntry<String, dynamic> entry in lineMap.entries) {
      final int lineNum = int.parse(entry.key);
      final List<String> wordKeys = (entry.value as List<dynamic>)
          .cast<String>();
      if (wordKeys.isNotEmpty) {
        final List<String> parts = wordKeys.first.split(':');
        final int surah = int.parse(parts[0]);
        final int ayah = int.parse(parts[1]);
        final int word = int.parse(parts[2]);

        if (ayah == 1 && word == 1) {
          if (surah == 1) {
            // Fatiha Page 1 special logic
            if (pageNumber == 1) {
              special[5] = 'HEADER:1';
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: SizedBox(
        height: lineHeight,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/mainframe.png',
                package: 'quran',
                fit: BoxFit.contain,
              ),
            ),
            Text(
              String.fromCharCode(0xF100 + surahNumber - 1),
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'packages/quran/QCF_BSML',
                fontSize: lineHeight * 0.45,
                color: const Color(0xFF000000),
                height: 1.0,
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5EF),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
    );
  }
}

class _SurahIndexButton extends StatelessWidget {
  const _SurahIndexButton({required this.onShowIndex});

  final VoidCallback? onShowIndex;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onShowIndex,
      child: Container(
        width: 40.h, // Slightly larger for better touch target and circularity
        height: 40.h,
        decoration: BoxDecoration(
          color: const Color(0xFFA68B67),
          shape: BoxShape.circle, // Circular design
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFA68B67,
              ).withValues(alpha: 0.3), // Changed to withOpacity
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.menu_book_rounded,
          size: 22,
          color: Colors.white,
        ),
      ),
    );
  }
}
