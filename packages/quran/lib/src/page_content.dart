import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'helpers/app_logger.dart';
import 'helpers/convert_to_arabic_number.dart';
import 'helpers/quran_text_paint.dart';
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
    this.showOverlays = true,
  });

  /// Whether to show the internal page metadata strips and badges.
  final bool showOverlays;

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
  final ScrollController _scrollController = ScrollController();
  final Map<String, LongPressGestureRecognizer> _wordRecognizers =
      <String, LongPressGestureRecognizer>{};

  // Cached once after data loads; invalidated when pageNumber changes.
  _PageMetaInfo? _cachedPageMeta;

  /// Caches the rendered page as a raster image after first paint so that
  /// subsequent frames during swipe animation composite a cached bitmap
  /// instead of re-rasterizing 15 FittedBox+RichText widgets (~25ms saving).
  final SnapshotController _snapshotController = SnapshotController();
  Orientation? _lastOrientation;
  int _lastCurrentPage = 0;
  bool _snapshotRestoreScheduled = false;
  bool _pendingSnapshotRefresh = false;
  bool _pendingBannerPrewarm = false;

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
    WidgetsBinding.instance.addObserver(this);
    _initQuranData();

    widget.currentPageListenable?.addListener(_handlePageChange);
    _lastCurrentPage = widget.currentPageListenable?.value ?? widget.pageNumber;
  }

  @override
  void didUpdateWidget(PageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPageListenable != widget.currentPageListenable) {
      oldWidget.currentPageListenable?.removeListener(_handlePageChange);
      widget.currentPageListenable?.addListener(_handlePageChange);
      _lastCurrentPage =
          widget.currentPageListenable?.value ?? widget.pageNumber;
      updateKeepAlive();
    }

    final bool pageMetaInputsChanged = _didPageMetaInputsChange(oldWidget);
    final bool snapshotInputsChanged = _didSnapshotInputsChange(oldWidget);
    final bool longPressInputsChanged =
        oldWidget.onLongPress != widget.onLongPress ||
        oldWidget.onLongPressUp != widget.onLongPressUp ||
        oldWidget.onLongPressCancel != widget.onLongPressCancel ||
        oldWidget.onLongPressDown != widget.onLongPressDown;

    if (longPressInputsChanged && !_hasLongPressHandlers) {
      _disposeWordRecognizers();
    }

    if (oldWidget.pageNumber != widget.pageNumber) {
      // Invalidate all page-specific cached state.
      _cachedPageMeta = null;
      _specialLinesCache.remove(oldWidget.pageNumber);
      _specialLinesCache.remove(widget.pageNumber);
      _disposeWordRecognizers();
      _pendingSnapshotRefresh = false;
      _pendingBannerPrewarm = false;
      setState(() => _isLoading = true);
      _initQuranData();
      return;
    }

    if (pageMetaInputsChanged) {
      _cachedPageMeta = null;
    }

    if (snapshotInputsChanged) {
      _requestSnapshotRefresh(
        reason: 'visual inputs changed for page ${widget.pageNumber}',
        prewarmBanner: _pageHasSurahHeader(widget.pageNumber),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Orientation orientation = MediaQuery.orientationOf(context);
    final bool didOrientationChange =
        _lastOrientation != null && _lastOrientation != orientation;

    if (didOrientationChange || orientation == Orientation.landscape) {
      // Don't log if it's already disabled (common in landscape).
      if (_snapshotController.allowSnapshotting) {
        _disableSnapshot(
          reason:
              'orientation change or landscape mode for page ${widget.pageNumber}',
        );
      }
    }

    if (orientation == Orientation.portrait &&
        !_snapshotController.allowSnapshotting) {
      _requestSnapshotRefresh(
        reason: 'portrait snapshot restore for page ${widget.pageNumber}',
        prewarmBanner: _pageHasSurahHeader(widget.pageNumber),
      );
    }

    _lastOrientation = orientation;
  }

  @override
  void reassemble() {
    super.reassemble();
    _requestSnapshotRefresh(
      reason: 'reassemble for page ${widget.pageNumber}',
      prewarmBanner: _pageHasSurahHeader(widget.pageNumber),
    );
  }

  @override
  void dispose() {
    widget.currentPageListenable?.removeListener(_handlePageChange);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _disposeWordRecognizers();
    _snapshotController.dispose();
    super.dispose();
  }


  void _handlePageChange() {
    if (!mounted) {
      return;
    }
    final int currentPage = widget.currentPageListenable!.value;
    final int previousPage = _lastCurrentPage;
    // Only update keep-alive if the distance state changed for this page
    final bool currentlyKeep = (widget.pageNumber - currentPage).abs() <= 2;
    final bool previouslyKeep = (widget.pageNumber - previousPage).abs() <= 2;
    final bool becameCurrent =
        currentPage == widget.pageNumber && previousPage != widget.pageNumber;

    _lastCurrentPage = currentPage;

    if (currentlyKeep != previouslyKeep) {
      updateKeepAlive();
    }

    if (becameCurrent && _pendingSnapshotRefresh) {
      _scheduleSnapshotRestore(
        reason: 'page became current: ${widget.pageNumber}',
      );
    }
  }

  bool get _hasLongPressHandlers {
    return widget.onLongPress != null ||
        widget.onLongPressUp != null ||
        widget.onLongPressCancel != null ||
        widget.onLongPressDown != null;
  }

  bool _didPageMetaInputsChange(PageContent oldWidget) {
    return oldWidget.juzLabel != widget.juzLabel ||
        oldWidget.surahNameBuilder != widget.surahNameBuilder ||
        oldWidget.uiTextDirection != widget.uiTextDirection;
  }

  bool _didSnapshotInputsChange(PageContent oldWidget) {
    final bool metaChanged = _didPageMetaInputsChange(oldWidget);
    final textColorChanged =
        oldWidget.textColor.toARGB32() != widget.textColor.toARGB32();
    final verseBgChanged =
        oldWidget.verseBackgroundColor != widget.verseBackgroundColor;
    final filterChanged =
        oldWidget.headerImageFilter != widget.headerImageFilter;
    final headerTextColorChanged =
        oldWidget.headerTextColor?.toARGB32() !=
        widget.headerTextColor?.toARGB32();
    final fontSizeChanged =
        oldWidget.headerFontSizeMultiplier != widget.headerFontSizeMultiplier;
    final pageBgChanged =
        oldWidget.pageBackgroundColor.toARGB32() !=
        widget.pageBackgroundColor.toARGB32();
    final overlaysChanged = oldWidget.showOverlays != widget.showOverlays;

    return metaChanged ||
        textColorChanged ||
        verseBgChanged ||
        filterChanged ||
        headerTextColorChanged ||
        fontSizeChanged ||
        pageBgChanged ||
        overlaysChanged;
  }

  void _disposeWordRecognizers() {
    for (final LongPressGestureRecognizer recognizer
        in _wordRecognizers.values) {
      recognizer.dispose();
    }
    _wordRecognizers.clear();
  }

  void _disableSnapshot({required String reason}) {
    if (!_snapshotController.allowSnapshotting) {
      return;
    }
    logger.d('[PageContent] Disabling snapshot: $reason');
    _snapshotController.allowSnapshotting = false;
    _snapshotController.clear();
  }

  void _requestSnapshotRefresh({
    required String reason,
    bool prewarmBanner = false,
  }) {
    if (!mounted) {
      return;
    }

    _pendingSnapshotRefresh = true;
    _pendingBannerPrewarm = _pendingBannerPrewarm || prewarmBanner;

    if (_isCurrentPage) {
      _scheduleSnapshotRestore(reason: reason);
    }
  }

  void _scheduleSnapshotRestore({required String reason}) {
    if (!mounted || !_pendingSnapshotRefresh) {
      return;
    }

    if (_snapshotRestoreScheduled) {
      return;
    }

    _disableSnapshot(reason: reason);
    _snapshotRestoreScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _snapshotRestoreScheduled = false;
      if (!mounted) {
        return;
      }

      final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery == null ||
          mediaQuery.orientation != Orientation.portrait ||
          !_isCurrentPage) {
        return;
      }

      final bool shouldPrewarmBanner = _pendingBannerPrewarm;
      _pendingSnapshotRefresh = false;
      _pendingBannerPrewarm = false;

      if (shouldPrewarmBanner) {
        await _prewarmBannerImage();
        if (!mounted) {
          return;
        }
      }

      _snapshotController.allowSnapshotting = true;
    });
  }

  Future<void> _initQuranData() async {
    final startTime = DateTime.now();
    final QuranDataService dataService = QuranDataService.instance;

    if (dataService.isLoaded) {
      if (mounted) {
        _cachedPageMeta = _buildPageMeta(widget.pageNumber);
        // Defer prewarm: context is not safe for inherited-widget lookups in
        // initState — schedule after the first frame instead.
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _completeInitialPageLoad(startTime);
        });
      }
      return;
    }

    try {
      await dataService.ensureLoaded();
      if (!mounted) {
        return;
      }

      _cachedPageMeta = _buildPageMeta(widget.pageNumber);
      // Same deferral for the async-load path.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _completeInitialPageLoad(startTime);
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading Quran data: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeInitialPageLoad(DateTime startTime) async {
    if (_pageHasSurahHeader(widget.pageNumber)) {
      await _prewarmBannerImage();
    }
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
    final Duration duration = DateTime.now().difference(startTime);
    logger.d(
      '[PageContent] Page ${widget.pageNumber} ready in ${duration.inMilliseconds}ms',
    );
  }

  /// Pre-resolves the banner image into Flutter's image cache so that
  /// [SnapshotController] captures a fully painted frame instead of a blank one.
  ///
  /// On initial load the asset hasn't been decoded yet. The snapshot is taken
  /// on the first post-frame callback, which races the async image decode and
  /// wins — producing a blank banner. Awaiting [ImageProvider.resolve] here
  /// ensures the image is in the cache before [_isLoading] is cleared and the
  /// [SnapshotWidget] is first built.
  Future<void> _prewarmBannerImage() async {
    if (!mounted) return;
    const imageProvider = AssetImage('assets/mainframe.png', package: 'quran');
    final ImageConfiguration config = createLocalImageConfiguration(context);
    final completer = Completer<void>();
    final ImageStream stream = imageProvider.resolve(config);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
      onError: (_, _) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    await completer.future;
  }

  /// Returns words for [pageNumber] grouped into 15 lines (O(1) lookup).
  List<List<Map<String, dynamic>>> _getWordsGroupedByLine(int pageNumber) {
    final List<List<Map<String, dynamic>>> rawLines =
        QuranDataService.instance.getPageData(pageNumber) ??
        List.generate(15, (_) => []);

    // The backend JSON packs Fatiha and Baqarah tightly against the top of the grid
    // leaving ~7 empty lines at the very bottom. To match the perfectly centered
    // Ayah app Mushaf visual spacing (2 blank lines above, 2 blank lines between
    // header and Bismillah, and 3 below), we intercept and dynamically remap the arrays.
    if (pageNumber == 1 || pageNumber == 2) {
      // Create a fresh 15-line empty grid
      final List<List<Map<String, dynamic>>> centeredLines = List.generate(
        15,
        (_) => [],
      );

      // Page 1: Header takes index 0, Bismillah takes 1, verses take 2 through 7.
      // Page 2: Header takes 0, Bismillah takes 1, verses take 2 through 7.
      // We will map the content to start lower down the grid.
      // Shift Header to line 3 (index 2).
      // Shift Bismillah and Verses to start at line 6 (index 5).
      centeredLines[0] = [];
      centeredLines[1] = [];
      centeredLines[2] =
          rawLines[0]; // Header index (the logic in _calculateSpecialLines targets this)
      centeredLines[3] = [];
      centeredLines[4] = [];

      // Map the 7 lines of actual content (Bismillah + Verses) down.
      // Guard against rawLines being shorter than expected (e.g. partial data).
      for (var i = 0; i < 7 && (1 + i) < rawLines.length; i++) {
        centeredLines[5 + i] = rawLines[1 + i];
      }
      return centeredLines;
    }

    return rawLines;
  }

  /// Returns the logical word spans to render for [lineIndex] from pre-fetched [lines].
  List<_WordSpanGroup> _getWordSpansForLine(
    List<List<Map<String, dynamic>>> lines,
    int lineIndex,
    TextStyle quranTextStyle,
    TextStyle markerTextStyle,
  ) {
    if (lineIndex < 0 || lineIndex >= 15) {
      return [];
    }
    final List<Map<String, dynamic>> lineWords = lines[lineIndex];
    if (lineWords.isEmpty) {
      return [];
    }

    final hasVerseColorCallback = widget.verseBackgroundColor != null;
    final QuranDataService quranDataService = QuranDataService.instance;
    final wordSpans = <_WordSpanGroup>[];

    for (final word in lineWords) {
      final text = word['text'] as String;
      final int surahNumber = int.tryParse(word['surah'].toString()) ?? 0;
      final int verseNumber = int.tryParse(word['ayah'].toString()) ?? 0;
      final int wordNumber = int.tryParse(word['word'].toString()) ?? 0;
      Color? bgColor;

      if (hasVerseColorCallback) {
        bgColor = widget.verseBackgroundColor!(surahNumber, verseNumber);
      }

      final TextStyle effectiveQuranStyle = bgColor == null
          ? quranTextStyle
          : quranTextStyle.copyWith(backgroundColor: bgColor);
      final TextStyle effectiveMarkerStyle = bgColor == null
          ? markerTextStyle
          : markerTextStyle.copyWith(backgroundColor: bgColor);

      wordSpans.add(
        _WordSpanGroup(
          spans: _buildWordSpans(
            text: text,
            isVerseEndWord: quranDataService.isVerseEndWord(word),
            quranTextStyle: effectiveQuranStyle,
            markerTextStyle: effectiveMarkerStyle,
            recognizer: _recognizerForWord(
              surahNumber: surahNumber,
              verseNumber: verseNumber,
              wordNumber: wordNumber,
            ),
          ),
        ),
      );
    }

    return wordSpans;
  }

  List<InlineSpan> _buildWordSpans({
    required String text,
    required bool isVerseEndWord,
    required TextStyle quranTextStyle,
    required TextStyle markerTextStyle,
    GestureRecognizer? recognizer,
  }) {
    if (!isVerseEndWord || text.isEmpty) {
      return [
        TextSpan(text: text, style: quranTextStyle, recognizer: recognizer),
      ];
    }

    final List<int> runes = text.runes.toList();
    if (runes.length == 1) {
      return [
        TextSpan(text: text, style: markerTextStyle, recognizer: recognizer),
      ];
    }

    return [
      TextSpan(
        text: String.fromCharCodes(runes.take(runes.length - 1)),
        style: quranTextStyle,
        recognizer: recognizer,
      ),
      TextSpan(
        text: String.fromCharCodes(runes.skip(runes.length - 1)),
        style: markerTextStyle,
        recognizer: recognizer,
      ),
    ];
  }

  LongPressGestureRecognizer? _recognizerForWord({
    required int surahNumber,
    required int verseNumber,
    required int wordNumber,
  }) {
    if (!_hasLongPressHandlers ||
        surahNumber <= 0 ||
        verseNumber <= 0 ||
        wordNumber <= 0) {
      return null;
    }

    final key = '${widget.pageNumber}:$surahNumber:$verseNumber:$wordNumber';
    final LongPressGestureRecognizer recognizer = _wordRecognizers.putIfAbsent(
      key,
      LongPressGestureRecognizer.new,
    );

    recognizer.onLongPress = widget.onLongPress == null
        ? null
        : () {
            widget.onLongPress!(surahNumber, verseNumber);
          };
    recognizer.onLongPressStart = widget.onLongPressDown == null
        ? null
        : (LongPressStartDetails details) {
            widget.onLongPressDown!(surahNumber, verseNumber, details);
          };
    recognizer.onLongPressUp = widget.onLongPressUp == null
        ? null
        : () {
            widget.onLongPressUp!(surahNumber, verseNumber);
          };
    recognizer.onLongPressCancel = widget.onLongPressCancel == null
        ? null
        : () {
            widget.onLongPressCancel!(surahNumber, verseNumber);
          };

    return recognizer;
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
    final _PageMetaInfo pageMeta =
        _cachedPageMeta ?? _buildPageMeta(widget.pageNumber);
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

        final double lineHeight = metrics.fontSize * metrics.fontHeight;

        final baseGlyphStyle = TextStyle(
          fontFamily: pageFont,
          fontSize: metrics.fontSize,
          height: metrics.fontHeight,
        );
        final TextStyle quranTextStyle = baseGlyphStyle.copyWith(
          color: widget.textColor,
          shadows: buildQuranBoldShadows(widget.textColor),
        );
        final TextStyle markerTextStyle = baseGlyphStyle.copyWith(
          color: widget.textColor,
        );

        final spaceStyle = TextStyle(
          fontFamily: pageFont,
          fontSize: metrics.fontSize,
          height: metrics.fontHeight,
        );

        final List<int> lineIndices = metrics.isScrollable
            ? List<int>.generate(15, (index) => index).where((lineIndex) {
                // For Fatiha and Baqarah, our structured empty [] lines functionally
                // represent native gaps layout margins, so they MUST be preserved
                // visibly on the screen even during landscape scroll configurations.
                if (widget.pageNumber == 1 || widget.pageNumber == 2) {
                  return true;
                }

                return pageLines[lineIndex].isNotEmpty ||
                    _isSurahHeader(widget.pageNumber, lineIndex + 1) ||
                    _isBismillah(widget.pageNumber, lineIndex + 1);
              }).toList()
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
            final Widget headerWidget = SurahHeaderBanner(
              surahNumber: surahNum,
              lineHeight: lineHeight,
              headerImageFilter: widget.headerImageFilter,
              headerTextColor: widget.headerTextColor,
              headerFontSizeMultiplier: widget.headerFontSizeMultiplier,
            );

            if (widget.onSurahSelected == null) {
              return headerWidget;
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onSurahSelected!(surahNum),
              child: headerWidget,
            );
          }

          if (isBismillah) {
            final String pageStr = widget.pageNumber.toString().padLeft(3, '0');
            final Widget bismillahWidget = BismillahWidget(
              fontSize: metrics.fontSize,
              pageNumber: widget.pageNumber,
              color: widget.textColor,
              fontFamily: 'QCF_P$pageStr',
            );

            return bismillahWidget;
          }

          final List<_WordSpanGroup> wordSpans = _getWordSpansForLine(
            pageLines,
            lineIndex,
            quranTextStyle,
            markerTextStyle,
          );
          final spans = <InlineSpan>[];

          // Insert a thin space after the first word on the first content line
          final isFirstContentLine = lineIndex == firstLineIdx;
          for (var wordIndex = 0; wordIndex < wordSpans.length; wordIndex++) {
            spans.addAll(wordSpans[wordIndex].spans);
            if (isFirstContentLine && wordIndex == 0 && wordSpans.length > 1) {
              spans.add(TextSpan(text: '\u200A', style: spaceStyle));
            }
          }

          if (spans.isEmpty) {
            // Render an empty space using the native font family so empty lines
            // share the exact baseline and physical line height as verses.
            spans.add(TextSpan(text: '\u0020', style: quranTextStyle));
          }

          final richText = RichText(
            textDirection: TextDirection.rtl,
            overflow: TextOverflow.visible,
            maxLines: 1,
            text: TextSpan(children: spans),
          );

          final Widget lineWidget = QuranLine(richText: richText);

          // For Page 1 (Fatiha), Ayah 1 (Bismillah) is at lineIndex 1.
          // Add extra space below it to separate it from the remaining verses.
          if (widget.pageNumber == 1 && lineIndex == 1) {
            return lineWidget;
          }

          return lineWidget;
        }).toList();

        final List<Widget> spacedLineWidgets = [];
        for (var i = 0; i < lineWidgets.length; i++) {
          if (i > 0) {
            final double gap = metrics.lineSpacing;
            spacedLineWidgets.add(SizedBox(height: gap));
          }
          spacedLineWidgets.add(lineWidgets[i]);
        }

        final lines = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: spacedLineWidgets,
        );

        final paddedLines = Padding(padding: metrics.padding, child: lines);

        if (metrics.isScrollable) {
          final Widget scrollChild;
          if (pageMeta.surahNames.isNotEmpty) {
            scrollChild = Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMetadataStrip(pageMeta, metaTextColor),
                  paddedLines,
                ],
              ),
            );
          } else {
            scrollChild = paddedLines;
          }
          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              primary: false,
              physics: const BouncingScrollPhysics(),
              child: scrollChild,
            ),
          );
        }

        return paddedLines;
      },
    );

    final Widget pageNumberBadge = AnimatedOpacity(
      opacity: widget.showOverlays ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: PageNumberBadge(
        label: pageNumberLabel,
        backgroundColor: pageNumberBadgeColor,
        borderColor: pageNumberBorderColor,
        textColor: metaTextColor,
      ),
    );

    final Widget pageChrome;
    if (isPortrait) {
      pageChrome = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pageMeta.surahNames.isNotEmpty)
            _buildMetadataStrip(pageMeta, metaTextColor),
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
            key: ValueKey<Orientation>(
              _lastOrientation ?? Orientation.portrait,
            ),
            autoresize: true,
            controller: _snapshotController,
            child: pageChrome,
          )
        : pageChrome;

    final Duration renderDuration = DateTime.now().difference(renderStartTime);
    if (renderDuration.inMilliseconds > 16) {
      logger.d(
        '[PageContent] Page ${widget.pageNumber} widget tree construction took ${renderDuration.inMilliseconds}ms (excludes layout/paint)',
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

  bool get _isCurrentPage {
    final ValueListenable<int>? listenable = widget.currentPageListenable;
    return listenable == null || listenable.value == widget.pageNumber;
  }

  bool _pageHasSurahHeader(int pageNumber) {
    for (var lineNumber = 1; lineNumber <= 15; lineNumber++) {
      if (_isSurahHeader(pageNumber, lineNumber)) {
        return true;
      }
    }
    return false;
  }

  Widget _buildMetadataStrip(_PageMetaInfo pageMeta, Color textColor) {
    Widget strip = PageMetadataStrip(
      surahNames: pageMeta.surahNames,
      juzLabel: pageMeta.juzLabel(widget.juzLabel),
      uiTextDirection: widget.uiTextDirection,
      textColor: textColor,
    );

    if (widget.onShowIndex != null) {
      strip = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onShowIndex,
        child: strip,
      );
    }

    return IgnorePointer(
      ignoring: !widget.showOverlays,
      child: AnimatedOpacity(
        opacity: widget.showOverlays ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: strip,
      ),
    );
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
            // Fatiha Page 1 special logic.
            // After remapping, Fatiha's Ayah 1 is always at lineNum 6,
            // so Header sits at lineNum - 3 = line 3. The previous fallback
            // to line 1 was dead code given the fixed remapping.
            if (pageNumber == 1) {
              special[lineNum - 3] = 'HEADER:1';
            }
          } else if (surah == 9) {
            // At-Tawbah has no Bismillah — Header only.
            // Place header on the preceding line, or line 1 if at the top.
            special[lineNum > 1 ? lineNum - 1 : 1] = 'HEADER:9';
          } else if (surah == 2 && pageNumber == 2) {
            // Baqarah Page 2 special logic.
            // Header at line 3 (index 2), Bismillah at line 6 (index 5).
            special[3] = 'HEADER:2';
            special[6] = 'BISMILLAH:2';
          } else {
            // Other surahs: Header then Bismillah on the two lines preceding verse 1.
            if (lineNum > 2) {
              special[lineNum - 2] = 'HEADER:$surah';
              special[lineNum - 1] = 'BISMILLAH:$surah';
            } else if (lineNum == 2) {
              // Verse 1 on line 2: Bismillah on line 1, no room for a header.
              special[1] = 'BISMILLAH:$surah';
            } else {
              // Verse 1 on line 1: place header above if possible, else skip.
              // Nothing can be placed above line 1 — header is omitted gracefully.
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

class _WordSpanGroup {
  const _WordSpanGroup({required this.spans});

  final List<InlineSpan> spans;
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
