import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'helpers/convert_to_arabic_number.dart';
import 'layout/quran_layout_strategy.dart';
import 'services/quran_data_service.dart';
import 'services/quran_font_service.dart';
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
    this.showOverlaysListenable,
    this.isWarming = false,
    this.showShadows = true,
  });

  /// Whether to render bold text shadows.
  final bool showShadows;

  /// Whether this page is currently being "warmed up" offstage.
  final bool isWarming;

  /// Controls visibility of the page metadata strip and page number badge.
  final ValueListenable<bool>? showOverlaysListenable;

  final int pageNumber;

  /// Optional listenable for the current page number in the PageView.
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

class _PageContentState extends State<PageContent>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  static final StandardQuranLayoutStrategy _layoutStrategy =
      StandardQuranLayoutStrategy();

  bool _isLoading = false;
  bool _isDeferringText = false;
  Timer? _deferTimer;
  final ScrollController _scrollController = ScrollController();
  _PageMetaInfo? _cachedPageMeta;
  List<List<Map<String, dynamic>>>? _cachedPageLines;
  Orientation? _lastOrientation;

  // Metrics cache
  QuranLayoutMetrics? _cachedMetrics;
  double? _cachedMetricsWidth;
  double? _cachedMetricsHeight;
  Orientation? _cachedMetricsOrientation;

  // Luminance cache — recomputed only when pageBackgroundColor changes.
  Color? _cachedLuminanceColor;
  bool _cachedIsLightPage = false;

  // Line widgets cache
  List<Widget>? _cachedLineWidgets;
  double? _cachedLineWidgetsFontSize;
  Color? _cachedLineWidgetsTextColor;
  Color? _cachedLineWidgetsHeaderTextColor;
  ColorFilter? _cachedLineWidgetsHeaderImageFilter;
  double? _cachedLineWidgetsFontSizeMultiplier;
  bool? _cachedLineWidgetsHasOnSurahSelected;

  // Spaced lines cache
  List<Widget>? _cachedSpacedLines;
  double? _cachedSpacedLinesLineSpacing;

  // Track whether we already received our font-load notification.
  bool _fontLoadHandled = false;

  static const double _portraitPageHorizontalPadding = 6;
  static const Color _lightMetaTextColor = Color(0xFF9A7A57);
  static const Color _lightPageNumberBackgroundColor = Color(0xFFE8DDD0);
  static const Color _lightPageNumberBorderColor = Color(0xFFD2C0AE);

  @override
  bool get wantKeepAlive {
    if (widget.isWarming) return true;
    if (widget.currentPageListenable == null) return false;
    final int distance =
        (widget.pageNumber - widget.currentPageListenable!.value).abs();
    // Keep a tighter active window to reduce retained raster layers and
    // compositing pressure on mid-range devices during rapid page flips.
    return distance <= 1;
  }

  bool _hasFirstLayout = false;
  int _buildStartMs = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initQuranData();
    _checkDeferralStatus(duringInit: true);
    widget.currentPageListenable?.addListener(_handlePageChange);
    QuranFontService.instance.addListener(_handleFontLoad);
  }

  @override
  void didUpdateWidget(PageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPageListenable != widget.currentPageListenable) {
      oldWidget.currentPageListenable?.removeListener(_handlePageChange);
      widget.currentPageListenable?.addListener(_handlePageChange);
      _checkDeferralStatus();
      updateKeepAlive();
    }

    if (oldWidget.pageNumber != widget.pageNumber) {
      _cachedPageMeta = null;
      _cachedPageLines = null;
      _fontLoadHandled = false;
      _isLoading = false;
      _initQuranData();
      return;
    }

    if (oldWidget.textColor != widget.textColor ||
        oldWidget.headerTextColor != widget.headerTextColor ||
        oldWidget.headerImageFilter != widget.headerImageFilter ||
        oldWidget.headerFontSizeMultiplier != widget.headerFontSizeMultiplier ||
        (oldWidget.onSurahSelected == null) !=
            (widget.onSurahSelected == null)) {
      _invalidateLineCaches();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Orientation orientation = MediaQuery.orientationOf(context);
    final bool didOrientationChange =
        _lastOrientation != null && _lastOrientation != orientation;

    if (didOrientationChange) {
      _cachedMetrics = null;
      _cachedMetricsOrientation = null;
      _invalidateLineCaches();
    }

    if (orientation == Orientation.portrait) {
      _prewarmBannerImage();
    }
    _lastOrientation = orientation;
  }

  @override
  void dispose() {
    widget.currentPageListenable?.removeListener(_handlePageChange);
    QuranFontService.instance.removeListener(_handleFontLoad);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePageChange() {
    if (!mounted) return;
    updateKeepAlive();
    final int current = widget.currentPageListenable?.value ?? widget.pageNumber;
    print(
      '[PC_DEF] page=${widget.pageNumber} current=$current onPageChange',
    );
    // Re-evaluate whether we should defer heavy rendering when the current
    // page changes (e.g., after swipes/jumps). Without this, a page that was
    // built while offscreen can remain stuck in the skeleton state.
    _checkDeferralStatus();
  }

  void _handleFontLoad() {
    if (!mounted) return;
    // Only rebuild once: when the page's own font transitions to loaded.
    if (_fontLoadHandled) return;
    if (QuranFontService.instance.isFontLoaded(widget.pageNumber)) {
      _fontLoadHandled = true;
      setState(() {
        _invalidateLineCaches();
      });
    }
  }

  void _invalidateLineCaches() {
    _cachedLineWidgets = null;
    _cachedLineWidgetsFontSize = null;
    _cachedLineWidgetsTextColor = null;
    _cachedLineWidgetsHeaderTextColor = null;
    _cachedLineWidgetsHeaderImageFilter = null;
    _cachedLineWidgetsFontSizeMultiplier = null;
    _cachedLineWidgetsHasOnSurahSelected = null;
    _cachedSpacedLines = null;
    _cachedSpacedLinesLineSpacing = null;
  }

  void _checkDeferralStatus({bool duringInit = false}) {
    _deferTimer?.cancel();

    // Defer heavy rendering only for explicit ghost warming pages and far pages.
    // Keep immediate neighbors (distance <= 1) eagerly rendered so the next/prev
    // page is already painted when the swipe starts.
    final bool isVisible =
        widget.currentPageListenable == null ||
        widget.currentPageListenable!.value == widget.pageNumber;
    final int pageDistance = widget.currentPageListenable == null
        ? 0
        : (widget.currentPageListenable!.value - widget.pageNumber).abs();

    final bool shouldDefer = widget.isWarming || (!isVisible && pageDistance > 1);
    if (shouldDefer) {
      // During initState we are not yet mounted, so assign directly.
      if (duringInit) {
        _isDeferringText = true;
        print(
          '[PC_DEF] page=${widget.pageNumber} -> defer=true (init) '
          'warming=${widget.isWarming} visible=$isVisible distance=$pageDistance',
        );
      } else if (!_isDeferringText) {
        setState(() => _isDeferringText = true);
        print(
          '[PC_DEF] page=${widget.pageNumber} -> defer=true '
          'warming=${widget.isWarming} visible=$isVisible distance=$pageDistance',
        );
      }
      // Only auto-resume deferral for the explicit ghost warming page so it can
      // perform raster warm-up. Non-visible pages stay deferred until visible.
      if (widget.isWarming) {
        _deferTimer = Timer(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          final bool stillVisible =
              widget.currentPageListenable == null ||
              widget.currentPageListenable!.value == widget.pageNumber;
          if (widget.isWarming || stillVisible) {
            setState(() => _isDeferringText = false);
            print(
              '[PC_DEF] page=${widget.pageNumber} warming defer timer elapsed '
              '-> defer=false (stillVisible=$stillVisible)',
            );
          }
        });
      }
    } else {
      // If it became visible, stop deferring immediately.
      // During init this is a no-op (default is already false).
      if (!duringInit && _isDeferringText) {
        setState(() => _isDeferringText = false);
        print(
          '[PC_DEF] page=${widget.pageNumber} -> defer=false '
          '(became visible)',
        );
      }
    }
  }

  void _initQuranData() {
    final QuranDataService dataService = QuranDataService.instance;
    if (dataService.isLoaded) {
      _handleDataLoaded();
      return;
    }
    _isLoading = true;
    _loadDataAsync();
  }

  Future<void> _loadDataAsync() async {
    try {
      await QuranDataService.instance.ensureLoaded();
      if (!mounted) return;
      _handleDataLoaded();
      setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleDataLoaded() {
    _cachedPageMeta = _buildPageMeta(widget.pageNumber);
    _cachedPageLines = _getWordsGroupedByLine(widget.pageNumber);
    _invalidateLineCaches();
    if (_pageHasSurahHeader(widget.pageNumber)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _prewarmBannerImage(),
      );
    }
  }

  Future<void> _prewarmBannerImage() async {
    if (!mounted) return;
    const imageProvider = AssetImage('assets/mainframe.png');
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _buildStartMs = DateTime.now().millisecondsSinceEpoch;

    if (_isLoading || _isDeferringText) {
      return _QuranPageSkeleton(
        pageBackgroundColor: widget.pageBackgroundColor,
        isLightPage: widget.pageBackgroundColor.computeLuminance() > 0.8,
      );
    }

    // Use MediaQuery instead of LayoutBuilder — PageContent always fills the
    // full viewport in SliverFillViewport, so MediaQuery.size equals the
    // LayoutBuilder constraints. This avoids the ~25ms layout traversal cost
    // that LayoutBuilder imposes on first render of each jumped-to page.
    final Size mediaSize = MediaQuery.sizeOf(context);
    final double pageWidth = mediaSize.width;
    final double pageHeight = mediaSize.height;
    final Orientation currentOrientation = MediaQuery.orientationOf(context);
    final syntheticConstraints = BoxConstraints(
      maxWidth: pageWidth,
      maxHeight: pageHeight,
    );

    final int t0 = DateTime.now().millisecondsSinceEpoch;

    // 1. Resolve Layout Metrics (Cached)
    final QuranLayoutMetrics metrics;
    final bool metricsCacheHit =
        _cachedMetrics != null &&
        _cachedMetricsWidth == pageWidth &&
        _cachedMetricsHeight == pageHeight &&
        _cachedMetricsOrientation == currentOrientation;
    if (metricsCacheHit) {
      metrics = _cachedMetrics!;
    } else {
      metrics = _layoutStrategy.calculateMetrics(
        context,
        syntheticConstraints,
        widget.pageNumber,
      );
      _cachedMetrics = metrics;
      _cachedMetricsWidth = pageWidth;
      _cachedMetricsHeight = pageHeight;
      _cachedMetricsOrientation = currentOrientation;
      _invalidateLineCaches();
    }
    final int t1 = DateTime.now().millisecondsSinceEpoch;

    final pageFont = 'QCF_P${widget.pageNumber.toString().padLeft(3, '0')}';
    final hasHighlight = widget.verseBackgroundColor != null;

    // 2. Resolve Line Widgets (Cached)
    final List<Widget> lineWidgets;
    final bool linesCacheHit =
        !hasHighlight &&
        _cachedLineWidgets != null &&
        _cachedLineWidgetsFontSize == metrics.fontSize &&
        _cachedLineWidgetsTextColor == widget.textColor &&
        _cachedLineWidgetsHeaderTextColor == widget.headerTextColor &&
        _cachedLineWidgetsHeaderImageFilter == widget.headerImageFilter &&
        _cachedLineWidgetsFontSizeMultiplier ==
            widget.headerFontSizeMultiplier &&
        _cachedLineWidgetsHasOnSurahSelected ==
            (widget.onSurahSelected != null);
    if (linesCacheHit) {
      lineWidgets = _cachedLineWidgets!;
    } else {
      lineWidgets = _buildLineWidgets(
        metrics: metrics,
        viewportWidth: pageWidth,
        viewportHeight: pageHeight,
        pageFont: pageFont,
        isPortrait: currentOrientation == Orientation.portrait,
      );
      if (!hasHighlight) {
        _cachedLineWidgets = lineWidgets;
        _cachedLineWidgetsFontSize = metrics.fontSize;
        _cachedLineWidgetsTextColor = widget.textColor;
        _cachedLineWidgetsHeaderTextColor = widget.headerTextColor;
        _cachedLineWidgetsHeaderImageFilter = widget.headerImageFilter;
        _cachedLineWidgetsFontSizeMultiplier = widget.headerFontSizeMultiplier;
        _cachedLineWidgetsHasOnSurahSelected = widget.onSurahSelected != null;
        _cachedSpacedLines = null;
        _cachedSpacedLinesLineSpacing = null;
      }
    }
    final int t2 = DateTime.now().millisecondsSinceEpoch;

    // 3. Resolve Spaced Container (Cached)
    final List<Widget> spacedLines;
    final bool spacedCacheHit =
        _cachedSpacedLines != null &&
        _cachedSpacedLinesLineSpacing == metrics.lineSpacing;
    if (spacedCacheHit) {
      spacedLines = _cachedSpacedLines!;
    } else {
      final List<Widget> built = [];
      for (var i = 0; i < lineWidgets.length; i++) {
        if (i > 0) built.add(SizedBox(height: metrics.lineSpacing));
        built.add(lineWidgets[i]);
      }
      spacedLines = built;
      _cachedSpacedLines = spacedLines;
      _cachedSpacedLinesLineSpacing = metrics.lineSpacing;
    }
    final int t3 = DateTime.now().millisecondsSinceEpoch;

    if (!kReleaseMode) {
      print(
        '[PC] p${widget.pageNumber} build | '
        'metrics=${metricsCacheHit ? "HIT" : "MISS"}(${t1 - t0}ms) '
        'lines=${linesCacheHit ? "HIT" : "MISS"}(${t2 - t1}ms) '
        'spaced=${spacedCacheHit ? "HIT" : "MISS"}(${t3 - t2}ms) '
        'total=${t3 - t0}ms',
      );
      final int buildStart = _buildStartMs;
      final int pageNum = widget.pageNumber;
      final bool isFirst = !_hasFirstLayout;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final int now = DateTime.now().millisecondsSinceEpoch;
        print('[PC] p$pageNum ${isFirst ? "FIRST_FRAME" : "FRAME"} | build→paint=${now - buildStart}ms');
      });
    }
    if (!_hasFirstLayout) _hasFirstLayout = true;

    // ONE RepaintBoundary for the entire page content.
    final bool isFontReady =
        QuranFontService.instance.isFontLoaded(widget.pageNumber);

    final Widget pageBody = !isFontReady || _isDeferringText
        ? _QuranPageSkeleton(
            pageBackgroundColor: widget.pageBackgroundColor,
            isLightPage: widget.pageBackgroundColor.computeLuminance() > 0.5,
          )
        : RepaintBoundary(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: spacedLines,
            ),
          );

    final paddedBody = Padding(padding: metrics.padding, child: pageBody);

    Widget finalContent;
    if (metrics.isScrollable) {
      finalContent = Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          primary: false,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [paddedBody, const SizedBox(height: 100)],
          ),
        ),
      );
    } else {
      finalContent = paddedBody;
    }

    if (_cachedLuminanceColor != widget.pageBackgroundColor) {
      _cachedLuminanceColor = widget.pageBackgroundColor;
      _cachedIsLightPage = widget.pageBackgroundColor.computeLuminance() > 0.8;
    }
    final bool isLightPage = _cachedIsLightPage;
    final Color metaTextColor = isLightPage
        ? _lightMetaTextColor
        : Color.lerp(widget.textColor, widget.pageBackgroundColor, 0.45)!;
    final Color pageNumberBadgeColor = isLightPage
        ? _lightPageNumberBackgroundColor
        : Color.lerp(widget.pageBackgroundColor, widget.textColor, 0.1)!;
    final Color pageNumberBorderColor = isLightPage
        ? _lightPageNumberBorderColor
        : Color.lerp(widget.pageBackgroundColor, widget.textColor, 0.22)!;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        finalContent,
        _buildOverlays(
          context,
          metrics,
          metaTextColor,
          pageNumberBadgeColor,
          pageNumberBorderColor,
        ),
      ],
    );
  }

  List<Widget> _buildLineWidgets({
    required QuranLayoutMetrics metrics,
    required double viewportWidth,
    required double viewportHeight,
    required String pageFont,
    required bool isPortrait,
  }) {
    final List<List<Map<String, dynamic>>> pageLines = _cachedPageLines!;
    final quranStyle = TextStyle(
      fontFamily: pageFont,
      fontSize: metrics.fontSize,
      height: metrics.fontHeight,
      color: widget.textColor,
    );
    final markerStyle = quranStyle;

    final List<int> lineIndices = metrics.isScrollable
        ? List.generate(15, (i) => i).where((i) {
            return widget.pageNumber <= 2 ||
                pageLines[i].isNotEmpty ||
                _isSurahHeader(widget.pageNumber, i + 1) ||
                _isBismillah(widget.pageNumber, i + 1);
          }).toList()
        : List.generate(15, (i) => i);

    final List<Widget> blocks = [];
    final List<InlineSpan> currentSpans = [];
    final List<QuranWordMetadata> currentMetadata = [];
    var currentOffset = 0;

    void flushSpans() {
      if (currentSpans.isNotEmpty) {
        blocks.add(
          QuranLine(
            richText: RichText(
              textDirection: TextDirection.rtl,
              overflow: TextOverflow.visible,
              softWrap: false,
              textWidthBasis: TextWidthBasis.longestLine,
              strutStyle: StrutStyle(
                fontFamily: pageFont,
                fontSize: metrics.fontSize,
                height: metrics.fontHeight,
                forceStrutHeight: true,
              ),
              text: TextSpan(children: List.from(currentSpans)),
            ),
            metadata: List.from(currentMetadata),
            onLongPress: widget.onLongPress,
            onLongPressUp: widget.onLongPressUp,
            onLongPressDown: widget.onLongPressDown,
            onLongPressCancel: widget.onLongPressCancel,
          ),
        );
        currentSpans.clear();
        currentMetadata.clear();
        currentOffset = 0;
      }
    }

    for (final i in lineIndices) {
      if (_isSurahHeader(widget.pageNumber, i + 1)) {
        flushSpans();
        final int surahNum = _getSurahAtLine(widget.pageNumber, i + 1);
        final banner = SurahHeaderBanner(
          surahNumber: surahNum,
          lineHeight: metrics.fontSize * metrics.fontHeight,
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight,
          isLandscape: !isPortrait,
          headerImageFilter: widget.headerImageFilter,
          headerTextColor: widget.headerTextColor,
          headerFontSizeMultiplier: widget.headerFontSizeMultiplier,
        );
        blocks.add(
          widget.onSurahSelected == null
              ? banner
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onSurahSelected!(surahNum),
                  child: banner,
                ),
        );
        continue;
      }

      if (_isBismillah(widget.pageNumber, i + 1)) {
        flushSpans();
        blocks.add(
          BismillahWidget(
            fontSize: metrics.fontSize,
            pageNumber: widget.pageNumber,
            color: widget.textColor,
            fontFamily: pageFont,
          ),
        );
        continue;
      }

      final List<_WordSpanGroup> wordSpans = _getWordSpansForLine(
        pageLines,
        i,
        quranStyle,
        markerStyle,
      );
      if (wordSpans.isEmpty) {
        const char = '\u0020\n';
        currentSpans.add(TextSpan(text: char, style: quranStyle));
        currentOffset += char.length;
      } else {
        for (var idx = 0; idx < wordSpans.length; idx++) {
          final _WordSpanGroup group = wordSpans[idx];
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
        const newline = '\n';
        currentSpans.add(TextSpan(text: newline, style: quranStyle));
        currentOffset += newline.length;
      }
    }
    flushSpans();
    return blocks;
  }

  Widget _buildOverlays(
    BuildContext context,
    QuranLayoutMetrics metrics,
    Color metaTextColor,
    Color badgeColor,
    Color borderColor,
  ) {
    if (widget.showOverlaysListenable == null) return const SizedBox.shrink();

    final String pageNumberLabel = widget.uiTextDirection == TextDirection.rtl
        ? convertToArabicNumber(widget.pageNumber.toString())
        : widget.pageNumber.toString();

    return Stack(
      children: [
        Positioned(
          top: metrics.padding.top,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.showOverlaysListenable!,
            builder: (context, show, child) {
              return IgnorePointer(
                ignoring: !show,
                child: AnimatedOpacity(
                  opacity: show ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: child,
                ),
              );
            },
            child: _MetadataStrip(
              surahNames: _cachedPageMeta?.surahNames.join(', ') ?? '',
              juzLabel: _cachedPageMeta?.juzLabel ?? '',
              uiTextDirection: widget.uiTextDirection,
              textColor: metaTextColor,
              onShowIndex: widget.onShowIndex,
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: _portraitPageHorizontalPadding,
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.showOverlaysListenable!,
            builder: (context, show, child) {
              return AnimatedOpacity(
                opacity: show ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: child,
              );
            },
            child: PageNumberBadge(
              label: pageNumberLabel,
              backgroundColor: badgeColor,
              borderColor: borderColor,
              textColor: widget.textColor,
            ),
          ),
        ),
      ],
    );
  }

  List<List<Map<String, dynamic>>> _getWordsGroupedByLine(int pageNumber) {
    final List<List<Map<String, dynamic>>> rawLines =
        QuranDataService.instance.getPageData(pageNumber) ??
        List.generate(15, (_) => []);
    if (pageNumber == 1 || pageNumber == 2) {
      final List<List<Map<String, dynamic>>> centered = List.generate(
        15,
        (_) => <Map<String, dynamic>>[],
      );
      centered[2] = rawLines[0];
      for (var i = 0; i < 7 && (1 + i) < rawLines.length; i++) {
        centered[5 + i] = rawLines[1 + i];
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
  ) {
    if (lineIndex < 0 || lineIndex >= 15) return [];
    final List<Map<String, dynamic>> words = lines[lineIndex];
    if (words.isEmpty) return [];
    final QuranDataService qData = QuranDataService.instance;
    return words.map((word) {
      final text = word['text'] as String;
      final int surah = int.tryParse(word['surah'].toString()) ?? 0;
      final int ayah = int.tryParse(word['ayah'].toString()) ?? 0;
      final Color? bgColor = widget.verseBackgroundColor?.call(surah, ayah);
      return _WordSpanGroup(
        surah: surah,
        verse: ayah,
        spans: _buildWordSpans(
          text: text,
          isVerseEndWord: qData.isVerseEndWord(word),
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
      _getSpecialType(page, line)?.startsWith('HEADER') ?? false;

  bool _isBismillah(int page, int line) =>
      _getSpecialType(page, line)?.startsWith('BISMILLAH') ?? false;

  bool _pageHasSurahHeader(int page) {
    for (var i = 1; i <= 15; i++) {
      if (_isSurahHeader(page, i)) return true;
    }
    return false;
  }

  int _getSurahAtLine(int page, int line) {
    final String? type = _getSpecialType(page, line);
    if (type == null) return 0;
    final List<String> parts = type.split(':');
    if (parts.length < 2) return 0;
    return int.tryParse(parts[1]) ?? 0;
  }

  String? _getSpecialType(int page, int line) {
    return QuranDataService.instance.getSpecialType(page, line);
  }

  _PageMetaInfo _buildPageMeta(int page) {
    final Map<String, dynamic> rawMeta = QuranDataService.instance
        .getPageMetadata(page);
    final surahNumbers = rawMeta['surahNumbers'] as List<int>;
    final List<String> surahNames = surahNumbers
        .map((n) => widget.surahNameBuilder?.call(n) ?? 'Surah $n')
        .toList();
    final int juz = rawMeta['juz'] as int? ?? 0;
    return _PageMetaInfo(
      surahNames: surahNames,
      juzLabel: widget.juzLabel ?? 'Juz $juz',
      hizbNumber: rawMeta['hizb'] as int? ?? 0,
    );
  }
}

class _MetadataStrip extends StatelessWidget {
  const _MetadataStrip({
    required this.surahNames,
    required this.juzLabel,
    required this.uiTextDirection,
    required this.textColor,
    this.onShowIndex,
  });
  final String surahNames;
  final String juzLabel;
  final TextDirection uiTextDirection;
  final Color textColor;
  final VoidCallback? onShowIndex;

  @override
  Widget build(BuildContext context) {
    if (surahNames.isEmpty) return const SizedBox.shrink();
    Widget strip = PageMetadataStrip(
      surahNames: surahNames,
      juzLabel: juzLabel,
      uiTextDirection: uiTextDirection,
      textColor: textColor,
    );
    if (onShowIndex != null) {
      strip = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onShowIndex,
        child: strip,
      );
    }
    return strip;
  }
}

class _WordSpanGroup {
  const _WordSpanGroup({
    required this.spans,
    required this.surah,
    required this.verse,
  });
  final List<InlineSpan> spans;
  final int surah;
  final int verse;
}

class _QuranPageSkeleton extends StatelessWidget {
  const _QuranPageSkeleton({
    required this.pageBackgroundColor,
    required this.isLightPage,
  });
  final Color pageBackgroundColor;
  final bool isLightPage;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: pageBackgroundColor,
      child: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

class _PageMetaInfo {
  _PageMetaInfo({
    required this.surahNames,
    required this.juzLabel,
    required this.hizbNumber,
  });
  final List<String> surahNames;
  final String juzLabel;
  final int hizbNumber;
}
