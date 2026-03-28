import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'helpers/app_logger.dart';
import 'helpers/convert_to_arabic_number.dart';
import 'layout/quran_layout_strategy.dart';
import 'services/functions/page_functions.dart' as page_functions;
import 'services/quran_data_service.dart';
import 'widgets/bismillah_widget.dart';
import 'widgets/page_metadata_strip.dart';
import 'widgets/page_number_badge.dart';
import 'widgets/quran_line.dart';
import 'widgets/surah_header_banner.dart';

class PageContent extends StatefulWidget {
  const PageContent({
    super.key,
    required this.pageNumber,
    required this.textColor,
    this.verseBackgroundColor,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
    this.juzLabel,
    this.hizbLabel,
    this.surahNameBuilder,
    this.onSurahSelected,
    this.onShowIndex,
    this.headerImageFilter,
    this.headerTextColor,
    this.headerFontSizeMultiplier = 0.45,
    required this.pageBackgroundColor,
    this.uiTextDirection = TextDirection.ltr,
    this.currentPageListenable,
  });

  final int pageNumber;

  /// Optional listenable for the current page number in the PageView.
  /// Used for smart keep-alive logic.
  final ValueListenable<int>? currentPageListenable;
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
  final ColorFilter? headerImageFilter;
  final Color? headerTextColor;
  final double headerFontSizeMultiplier;
  final Color pageBackgroundColor;
  final TextDirection uiTextDirection;
  final void Function(
    int surahNumber,
    int verseNumber,
    LongPressStartDetails details,
  )?
  onLongPressDown;

  @override
  State<PageContent> createState() => _PageContentState();
}

// Page caching is now managed by QuranDataService.

class _PageContentState extends State<PageContent>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  /// Shared layout strategy strategy instance (stateless — no need to recreate).
  static final StandardQuranLayoutStrategy _layoutStrategy =
      StandardQuranLayoutStrategy();

  bool _isLoading = true;

  /// Caches the rendered page as a raster image after first paint so that
  /// subsequent frames during swipe animation composite a cached bitmap
  /// instead of re-rasterizing 15 FittedBox+RichText widgets (~25ms saving).
  final SnapshotController _snapshotController = SnapshotController();
  Orientation? _lastOrientation;
  int _lastCurrentPage = 0;

  static const double _portraitPageHorizontalPadding = 6;
  static const double _portraitPageBottomPadding = 2;
  static const double _pageChromeSpacing = 0;
  static const Color _lightMetaTextColor = Color(0xFF9A7A57);
  static const Color _lightPageNumberBackgroundColor = Color(0xFFE8DDD0);
  static const Color _lightPageNumberBorderColor = Color(0xFFD2C0AE);

  @override
  bool get wantKeepAlive {
    if (widget.currentPageListenable == null) {
      return false;
    }
    // Keep alive if within 2 pages of the current page
    final int distance =
        (widget.pageNumber - widget.currentPageListenable!.value).abs();
    return distance <= 2;
  }

  @override
  void initState() {
    super.initState();
    logger.d('[PageContent] initState for page ${widget.pageNumber}');
    WidgetsBinding.instance.addObserver(this);
    _initQuranData();

    widget.currentPageListenable?.addListener(_handlePageChange);
    if (widget.currentPageListenable != null) {
      _lastCurrentPage = widget.currentPageListenable!.value;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Orientation orientation = MediaQuery.orientationOf(context);
    final bool didOrientationChange =
        _lastOrientation != null && _lastOrientation != orientation;

    if (didOrientationChange || orientation == Orientation.landscape) {
      logger.d(
        '[PageContent] Orientation change or landscape, clearing snapshot for page ${widget.pageNumber}',
      );
      _snapshotController.allowSnapshotting = false;
      _snapshotController.clear();
    }

    if (orientation == Orientation.portrait &&
        !_snapshotController.allowSnapshotting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (MediaQuery.orientationOf(context) == Orientation.portrait) {
          _snapshotController.allowSnapshotting = true;
        }
      });
    }

    _lastOrientation = orientation;
  }

  @override
  void dispose() {
    widget.currentPageListenable?.removeListener(_handlePageChange);
    logger.d('[PageContent] dispose for page ${widget.pageNumber}');
    WidgetsBinding.instance.removeObserver(this);
    _snapshotController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      logger.d(
        '[PageContent] App resumed, clearing snapshot for page ${widget.pageNumber}',
      );
      _snapshotController.allowSnapshotting = false;
      _snapshotController.clear();

      // Give images a frame to re-load before re-snapshotting.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _snapshotController.allowSnapshotting = true;
        }
      });
    } else if (state == AppLifecycleState.paused) {
      logger.d('[PageContent] App paused for page ${widget.pageNumber}');
    }
  }

  void _handlePageChange() {
    if (!mounted) {
      return;
    }
    final int currentPage = widget.currentPageListenable!.value;
    // Only update keep-alive if the distance state changed for this page
    final bool currentlyKeep = (widget.pageNumber - currentPage).abs() <= 2;
    final bool previouslyKeep =
        (widget.pageNumber - _lastCurrentPage).abs() <= 2;

    if (currentlyKeep != previouslyKeep) {
      _lastCurrentPage = currentPage;
      updateKeepAlive();
    }
  }

  Future<void> _initQuranData() async {
    final startTime = DateTime.now();
    final QuranDataService dataService = QuranDataService.instance;

    if (dataService.isLoaded) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      await dataService.ensureLoaded();
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      final Duration duration = DateTime.now().difference(startTime);
      logger.d(
        '[PageContent] Page ${widget.pageNumber} ready in ${duration.inMilliseconds}ms',
      );
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading Quran data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Returns words for [pageNumber] grouped into 15 lines (O(1) lookup).
  List<List<Map<String, dynamic>>> _getWordsGroupedByLine(int pageNumber) {
    return QuranDataService.instance.getPageData(pageNumber) ??
        List.generate(15, (_) => []);
  }

  /// Returns the [InlineSpan]s to render for [lineIndex] from pre-fetched [lines].
  List<InlineSpan> _getSpansForLine(
    List<List<Map<String, dynamic>>> lines,
    int lineIndex,
    TextStyle baseStyle,
  ) {
    if (lineIndex < 0 || lineIndex >= 15) {
      return [];
    }
    final List<Map<String, dynamic>> lineWords = lines[lineIndex];
    if (lineWords.isEmpty) {
      return [];
    }

    final hasVerseColorCallback = widget.verseBackgroundColor != null;

    final List<InlineSpan> spans = lineWords.map<InlineSpan>((word) {
      final text = word['text'] as String;

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
    super.build(context);
    final renderStartTime = DateTime.now();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Fetch line data once — does not depend on layout constraints.
    final List<List<Map<String, dynamic>>> pageLines = _getWordsGroupedByLine(
      widget.pageNumber,
    );
    final _PageMetaInfo pageMeta = _buildPageMeta(widget.pageNumber);
    final int firstLineIdx = _firstContentLineIndexFromLines(pageLines);
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final bool isLightPage =
        widget.pageBackgroundColor.computeLuminance() > 0.8;
    final Color metaTextColor = isLightPage
        ? _lightMetaTextColor
        : Color.lerp(widget.textColor, widget.pageBackgroundColor, 0.45)!;
    final Color pageNumberBadgeColor = isLightPage
        ? _lightPageNumberBackgroundColor
        : Color.lerp(widget.pageBackgroundColor, widget.textColor, 0.1)!;
    final Color pageNumberBorderColor = isLightPage
        ? _lightPageNumberBorderColor
        : Color.lerp(widget.pageBackgroundColor, widget.textColor, 0.22)!;
    final String pageNumberLabel = widget.uiTextDirection == TextDirection.rtl
        ? convertToArabicNumber(widget.pageNumber.toString())
        : widget.pageNumber.toString();

    final pageBody = LayoutBuilder(
      builder: (context, constraints) {
        final QuranLayoutMetrics metrics = _layoutStrategy.calculateMetrics(
          context,
          constraints,
          widget.pageNumber,
        );
        final pageFont = 'QCF_P${widget.pageNumber.toString().padLeft(3, '0')}';

        // Pages 1-2 use the same 15-line grid height as all
        // other pages in portrait.
        final bool isSpecialPage =
            widget.pageNumber == 1 || widget.pageNumber == 2;
        final double lineHeight = metrics.fontSize * metrics.fontHeight;

        final baseStyle = TextStyle(
          fontFamily: pageFont,
          fontSize: metrics.fontSize,
          color: widget.textColor,
          height: metrics.fontHeight,
        );

        final spaceStyle = TextStyle(
          fontFamily: pageFont,
          fontSize: metrics.fontSize,
          height: metrics.fontHeight,
        );

        final List<int> lineIndices = metrics.isScrollable
            ? List<int>.generate(15, (index) => index)
                  .where(
                    (lineIndex) =>
                        pageLines[lineIndex].isNotEmpty ||
                        _isSurahHeader(widget.pageNumber, lineIndex + 1) ||
                        _isBismillah(widget.pageNumber, lineIndex + 1),
                  )
                  .toList()
            : List<int>.generate(15, (index) => index);

        final List<Widget> lineWidgets = lineIndices.map((lineIndex) {
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
            return SurahHeaderBanner(
              surahNumber: surahNum,
              lineHeight: lineHeight,
              headerImageFilter: widget.headerImageFilter,
              headerTextColor: widget.headerTextColor,
              headerFontSizeMultiplier: widget.headerFontSizeMultiplier,
            );
          }

          if (isBismillah) {
            final String pageStr = widget.pageNumber.toString().padLeft(3, '0');
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.bismillahHorizontalPadding,
              ),
              child: BismillahWidget(
                fontSize: metrics.fontSize,
                pageNumber: widget.pageNumber,
                color: widget.textColor,
                fontFamily: 'QCF_P$pageStr',
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
            spans.insert(1, TextSpan(text: '\u200A', style: spaceStyle));
          }

          if (spans.isEmpty) {
            return const SizedBox();
          }

          final richText = RichText(
            textDirection: TextDirection.rtl,
            overflow: TextOverflow.visible,
            maxLines: 1,
            text: TextSpan(children: spans),
          );

          return QuranLine(richText: richText);
        }).toList();

        final lines = Column(
          mainAxisAlignment: metrics.isScrollable
              ? MainAxisAlignment.start
              : isSpecialPage
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          spacing: metrics.lineSpacing,
          children: lineWidgets,
        );

        final paddedLines = Padding(padding: metrics.padding, child: lines);

        if (metrics.isScrollable) {
          final Widget scrollChild = pageMeta.surahNames.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SafeArea(
                      bottom: false,
                      child: PageMetadataStrip(
                        surahNames: pageMeta.surahNames,
                        juzLabel: pageMeta.juzLabel(widget.juzLabel),
                        uiTextDirection: widget.uiTextDirection,
                        textColor: metaTextColor,
                      ),
                    ),
                    paddedLines,
                  ],
                )
              : paddedLines;
          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: scrollChild,
            ),
          );
        }

        return paddedLines;
      },
    );

    final Widget pageNumberBadge = PageNumberBadge(
      label: pageNumberLabel,
      backgroundColor: pageNumberBadgeColor,
      borderColor: pageNumberBorderColor,
      textColor: metaTextColor,
    );

    final Widget pageChrome;
    if (isPortrait) {
      pageChrome = SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pageMeta.surahNames.isNotEmpty)
              PageMetadataStrip(
                surahNames: pageMeta.surahNames,
                juzLabel: pageMeta.juzLabel(widget.juzLabel),
                uiTextDirection: widget.uiTextDirection,
                textColor: metaTextColor,
              ),
            Expanded(child: pageBody),
            const SizedBox(height: _pageChromeSpacing),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _portraitPageHorizontalPadding,
                0,
                _portraitPageHorizontalPadding,
                _portraitPageBottomPadding,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: pageNumberBadge,
              ),
            ),
          ],
        ),
      );
    } else {
      // Landscape: scroll body fills edge-to-edge (strip scrolls with content);
      // only the page number badge is fixed.
      pageChrome = Stack(
        children: [
          Positioned.fill(child: pageBody),
          Positioned(
            bottom: _portraitPageBottomPadding,
            left: _portraitPageHorizontalPadding,
            child: pageNumberBadge,
          ),
        ],
      );
    }

    // SnapshotWidget caches a static bitmap — never use it for scrollable
    // (landscape) pages, as it freezes scroll input and can capture the banner
    // before its asset image has loaded.
    final Widget result = isPortrait
        ? SnapshotWidget(
            key: ValueKey<Orientation>(_lastOrientation ?? Orientation.portrait),
            autoresize: true,
            controller: _snapshotController,
            child: pageChrome,
          )
        : pageChrome;

    final Duration renderDuration = DateTime.now().difference(renderStartTime);
    if (renderDuration.inMilliseconds > 16) {
      logger.d(
        '[PageContent] Page ${widget.pageNumber} build took ${renderDuration.inMilliseconds}ms (Slow)',
      );
    }

    return result;
  }

  /// Returns the 0-based line index of the first line that has content.
  int _firstContentLineIndexFromLines(List<List<Map<String, dynamic>>> lines) {
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].isNotEmpty) {
        return i;
      }
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

  _PageMetaInfo _buildPageMeta(int pageNumber) {
    final List<Map<String, int>> pageEntries = page_functions.getPageData(
      pageNumber,
    );
    if (pageEntries.isEmpty) {
      return const _PageMetaInfo(surahNames: '', juzNumber: null);
    }

    final surahNumbers = <int>[];
    for (final entry in pageEntries) {
      final int? surahNumber = entry['surah'];
      if (surahNumber == null) {
        continue;
      }
      if (surahNumbers.isEmpty || surahNumbers.last != surahNumber) {
        surahNumbers.add(surahNumber);
      }
    }

    final int firstSurahNumber = pageEntries.first['surah'] ?? 1;
    final int firstVerseNumber = pageEntries.first['start'] ?? 1;
    final int juzNumber = page_functions.getJuzNumber(
      firstSurahNumber,
      firstVerseNumber,
    );
    final separator = widget.uiTextDirection == TextDirection.rtl ? ' ' : ' · ';
    final String surahNames = surahNumbers
        .map((surahNumber) => _buildSurahName(surahNumber))
        .where((name) => name.isNotEmpty)
        .join(separator);

    return _PageMetaInfo(
      surahNames: surahNames,
      juzNumber: juzNumber > 0 ? juzNumber : null,
    );
  }

  String _buildSurahName(int surahNumber) {
    final String Function(int surahNumber)? builder = widget.surahNameBuilder;
    if (builder != null) {
      return builder(surahNumber);
    }
    return surahNumber.toString();
  }
}

class _PageMetaInfo {
  const _PageMetaInfo({required this.surahNames, required this.juzNumber});

  final String surahNames;
  final int? juzNumber;

  String juzLabel(String? prefix) {
    if (juzNumber == null || prefix == null || prefix.isEmpty) {
      return '';
    }
    if (_isArabicText(prefix)) {
      return '$prefix ${_arabicOrdinalForJuz(juzNumber!)}';
    }
    return '$prefix $juzNumber';
  }

  bool _isArabicText(String value) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  }

  String _arabicOrdinalForJuz(int juzNumber) {
    const arabicOrdinals = <String>[
      'الأول',
      'الثاني',
      'الثالث',
      'الرابع',
      'الخامس',
      'السادس',
      'السابع',
      'الثامن',
      'التاسع',
      'العاشر',
      'الحادي عشر',
      'الثاني عشر',
      'الثالث عشر',
      'الرابع عشر',
      'الخامس عشر',
      'السادس عشر',
      'السابع عشر',
      'الثامن عشر',
      'التاسع عشر',
      'العشرون',
      'الحادي والعشرون',
      'الثاني والعشرون',
      'الثالث والعشرون',
      'الرابع والعشرون',
      'الخامس والعشرون',
      'السادس والعشرون',
      'السابع والعشرون',
      'الثامن والعشرون',
      'التاسع والعشرون',
      'الثلاثون',
    ];

    if (juzNumber < 1 || juzNumber > arabicOrdinals.length) {
      return convertToArabicNumber(juzNumber.toString());
    }

    return arabicOrdinals[juzNumber - 1];
  }
}
