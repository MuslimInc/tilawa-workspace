import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'helpers/app_logger.dart';
import 'helpers/convert_to_arabic_number.dart';
import 'layout/quran_layout_strategy.dart';
import 'services/page_snapshot_service.dart';
import 'services/quran_data_service.dart';
import 'services/quran_page_preparation_service.dart';
import 'widgets/bismillah_widget.dart';
import 'widgets/page_metadata_strip.dart';
import 'widgets/page_number_badge.dart';
import 'widgets/quran_line.dart';
import 'widgets/quran_page_painter.dart';
import 'widgets/surah_header_banner.dart';

class PageContent extends StatefulWidget {
  const PageContent({
    super.key,
    required this.pageNumber,
    this.preparedPage,
    this.preparedWindowListenable,
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
    this.isScrollingListenable,
    this.isWarming = false,
    this.showShadows = true,
  });

  /// Whether to render bold text shadows.
  final bool showShadows;

  /// Whether this page is currently being "warmed up" offstage.
  final bool isWarming;

  /// Controls visibility of the page metadata strip and page number badge.
  final ValueListenable<bool>? showOverlaysListenable;

  /// Controls snapshot mode: when `true`, displays a pre-rendered bitmap
  /// instead of the full widget tree to reduce raster thread cost.
  final ValueListenable<bool>? isScrollingListenable;

  final int pageNumber;

  /// Static prepared page — used when [preparedWindowListenable] is null.
  final PreparedQuranPage? preparedPage;

  /// Live window notifier — when provided, [PageContent] subscribes to it and
  /// re-renders whenever the window contains a [PreparedQuranPage] for this
  /// page. This guarantees the widget rebuilds even when reused by a sliver
  /// (sliver children are not rebuilt on parent widget changes).
  final ValueListenable<PreparedQuranPageWindow?>? preparedWindowListenable;

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
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  _PageMetaInfo? _cachedPageMeta;
  List<List<Map<String, dynamic>>>? _cachedPageLines;
  Orientation? _lastOrientation;

  // Luminance cache — recomputed only when pageBackgroundColor changes.
  Color? _cachedLuminanceColor;
  bool _cachedIsLightPage = false;

  // Spaced lines cache
  List<Widget>? _cachedSpacedLines;
  double? _cachedSpacedLinesLineSpacing;

  // Bitmap snapshot support — captures the rendered page body as a GPU
  // texture for fast blitting during swipe animations.
  final GlobalKey _snapshotBoundaryKey = GlobalKey();
  bool _snapshotScheduled = false;
  bool _snapshotCaptured = false;

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
    _primePageData();
    widget.currentPageListenable?.addListener(_handlePageChange);
    widget.preparedWindowListenable?.addListener(_handleWindowChanged);
    widget.isScrollingListenable?.addListener(_handleScrollStateChanged);
  }

  @override
  void didUpdateWidget(PageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPageListenable != widget.currentPageListenable) {
      oldWidget.currentPageListenable?.removeListener(_handlePageChange);
      widget.currentPageListenable?.addListener(_handlePageChange);
      updateKeepAlive();
    }

    if (oldWidget.preparedWindowListenable != widget.preparedWindowListenable) {
      oldWidget.preparedWindowListenable?.removeListener(_handleWindowChanged);
      widget.preparedWindowListenable?.addListener(_handleWindowChanged);
    }

    if (oldWidget.isScrollingListenable != widget.isScrollingListenable) {
      oldWidget.isScrollingListenable?.removeListener(
        _handleScrollStateChanged,
      );
      widget.isScrollingListenable?.addListener(_handleScrollStateChanged);
    }

    if (oldWidget.pageNumber != widget.pageNumber) {
      _cachedPageMeta = null;
      _cachedPageLines = null;
      _snapshotCaptured = false;
      _snapshotScheduled = false;
      _primePageData();
      return;
    }

    if (oldWidget.textColor != widget.textColor ||
        oldWidget.headerTextColor != widget.headerTextColor ||
        oldWidget.headerImageFilter != widget.headerImageFilter ||
        oldWidget.headerFontSizeMultiplier != widget.headerFontSizeMultiplier ||
        (oldWidget.onSurahSelected == null) !=
            (widget.onSurahSelected == null)) {
      _invalidateLineCaches();
      // Visual change → invalidate the cached snapshot.
      _invalidateSnapshot();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Orientation orientation = MediaQuery.orientationOf(context);
    final bool didOrientationChange =
        _lastOrientation != null && _lastOrientation != orientation;

    if (didOrientationChange) {
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
    widget.preparedWindowListenable?.removeListener(_handleWindowChanged);
    widget.isScrollingListenable?.removeListener(_handleScrollStateChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePageChange() {
    if (!mounted) return;
    updateKeepAlive();
  }

  /// Called when [preparedWindowListenable] fires. If the window now contains
  /// a [PreparedQuranPage] for this page, trigger a rebuild so the content
  /// appears immediately without waiting for the sliver to be recreated.
  void _handleWindowChanged() {
    if (!mounted) return;
    final PreparedQuranPageWindow? window =
        widget.preparedWindowListenable?.value;
    final PreparedQuranPage? resolved = window?.preparedPageFor(
      widget.pageNumber,
    );
    if (!kReleaseMode) {
      debugPrint(
        '[CORRECTNESS] p${widget.pageNumber} window update: '
        '${resolved != null ? "READY" : "still null"} '
        '| window=${window?.preparedPages.keys.toList()}',
      );
    }
    if (resolved != null) {
      setState(() {});
    }
  }

  void _invalidateLineCaches() {
    _cachedSpacedLines = null;
    _cachedSpacedLinesLineSpacing = null;
  }

  /// Called when the scroll state changes (start/end).
  void _handleScrollStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  /// Schedules a bitmap snapshot capture after the next paint.
  void _scheduleSnapshotCapture() {
    if (_snapshotScheduled || _snapshotCaptured || widget.isWarming) return;
    _snapshotScheduled = true;

    // Wait two frames: first for layout, second for paint to complete.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _captureSnapshot();
      });
    });
  }

  /// Captures the page body's render output as a GPU-backed [ui.Image].
  Future<void> _captureSnapshot() async {
    if (_snapshotCaptured) return;

    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final bool captured = await PageSnapshotService.instance.captureSnapshot(
      pageNumber: widget.pageNumber,
      boundaryKey: _snapshotBoundaryKey,
      pixelRatio: pixelRatio,
    );

    if (captured && mounted) {
      _snapshotCaptured = true;
    }
    _snapshotScheduled = false;
  }

  /// Removes the cached snapshot for this page.
  void _invalidateSnapshot() {
    PageSnapshotService.instance.evict(widget.pageNumber);
    _snapshotCaptured = false;
    _snapshotScheduled = false;
  }

  void _primePageData() {
    final QuranDataService dataService = QuranDataService.instance;
    assert(
      dataService.isLoaded,
      'PageContent requires QuranDataService to be loaded before it builds.',
    );
    if (!dataService.isLoaded) return;
    _handleDataLoaded();
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

    final Size mediaSize = MediaQuery.sizeOf(context);
    final double pageWidth = mediaSize.width;
    final double pageHeight = mediaSize.height;
    final Orientation currentOrientation = MediaQuery.orientationOf(context);
    final int t0 = DateTime.now().millisecondsSinceEpoch;

    final PreparedQuranPage? preparedPage =
        widget.preparedWindowListenable?.value?.preparedPageFor(
          widget.pageNumber,
        ) ??
        widget.preparedPage;

    if (!kReleaseMode) {
      debugPrint(
        '[CORRECTNESS] p${widget.pageNumber} build: '
        '${preparedPage != null ? "READY" : "NO DATA — showing blank"}',
      );
    }

    if (preparedPage == null) {
      return ColoredBox(color: widget.pageBackgroundColor);
    }

    final QuranLayoutMetrics metrics = preparedPage.metrics;
    final hasHighlight = widget.verseBackgroundColor != null;

    final List<Widget> lineWidgets;
    final String lineBuildMode;
    if (hasHighlight) {
      lineWidgets = _buildLineWidgets(
        metrics: metrics,
        viewportWidth: pageWidth,
        viewportHeight: pageHeight,
        pageFont: 'QCF_P${widget.pageNumber.toString().padLeft(3, '0')}',
        isPortrait: currentOrientation == Orientation.portrait,
      );
      lineBuildMode = 'HIGHLIGHT';
    } else {
      lineWidgets = _buildPreparedLineWidgets(
        preparedPage: preparedPage,
        metrics: metrics,
        viewportWidth: pageWidth,
        viewportHeight: pageHeight,
        isPortrait: currentOrientation == Orientation.portrait,
      );
      lineBuildMode = 'PREPARED';
    }

    // For the PREPARED path, lineWidgets may contain a single
    // QuranPagePainter (which internally handles spacing). For the
    // HIGHLIGHT path, we still interleave SizedBox spacers.
    final List<Widget> spacedLines;
    if (lineBuildMode == 'PREPARED') {
      spacedLines = lineWidgets;
    } else {
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
    }

    if (!kReleaseMode) {
      final int t3 = DateTime.now().millisecondsSinceEpoch;
      final int buildMs = t3 - t0;
      if (buildMs > 2) {
        logger.i(
          '[PERF][PAGE] ⚠ p${widget.pageNumber} build=${buildMs}ms '
          '(lines=$lineBuildMode)',
        );
      }
      final int buildStart = _buildStartMs;
      final int pageNum = widget.pageNumber;
      final bool isFirst = !_hasFirstLayout;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final int frameMs = DateTime.now().millisecondsSinceEpoch - buildStart;
        final tag = isFirst ? 'FIRST_FRAME' : 'FRAME';
        if (frameMs > 16) {
          logger.i(
            '[PERF][PAGE] ⚠ p$pageNum $tag build→paint=${frameMs}ms exceeds 16ms budget',
          );
        } else if (isFirst) {
          logger.i('[PERF][PAGE] p$pageNum $tag build→paint=${frameMs}ms');
        }
      });
    }
    if (!_hasFirstLayout) _hasFirstLayout = true;

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

    // --- Snapshot swap logic ---
    // During swipe animations, display a pre-rendered bitmap snapshot
    // instead of the full widget tree. This reduces raster cost from
    // ~25ms (15 TextPainters) to ~2ms (single texture blit).
    final bool isScrolling = widget.isScrollingListenable?.value ?? false;
    final ui.Image? snapshot = isScrolling
        ? PageSnapshotService.instance.getSnapshot(widget.pageNumber)
        : null;

    final Widget pageBody;
    if (snapshot != null) {
      // Fast path: single-texture blit during swipe.
      pageBody = RawImage(
        image: snapshot,
        alignment: Alignment.topCenter,
        fit: BoxFit.contain,
        width: pageWidth,
        height: pageHeight,
        filterQuality: FilterQuality.low,
      );
    } else {
      // Live path: full interactive widget tree.
      pageBody = RepaintBoundary(
        key: _snapshotBoundaryKey,
        child: _QuranPageBody(
          metrics: metrics,
          spacedLines: spacedLines,
          scrollController: _scrollController,
        ),
      );

      // Schedule a snapshot capture after the first successful paint.
      if (!_snapshotCaptured && !_snapshotScheduled) {
        _scheduleSnapshotCapture();
      }
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        pageBody,
        _QuranPageOverlays(
          pageNumber: widget.pageNumber,
          showOverlaysListenable: widget.showOverlaysListenable,
          uiTextDirection: widget.uiTextDirection,
          metrics: metrics,
          pageMeta: _cachedPageMeta,
          metaTextColor: metaTextColor,
          badgeColor: pageNumberBadgeColor,
          borderColor: pageNumberBorderColor,
          textColor: widget.textColor,
          onShowIndex: widget.onShowIndex,
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
        final painter = TextPainter(
          text: TextSpan(children: List<InlineSpan>.from(currentSpans)),
          textDirection: TextDirection.rtl,
          textWidthBasis: TextWidthBasis.longestLine,
          strutStyle: StrutStyle(
            fontFamily: pageFont,
            fontSize: metrics.fontSize,
            height: metrics.fontHeight,
            forceStrutHeight: true,
          ),
        )..layout(maxWidth: viewportWidth);
        blocks.add(
          QuranLine(
            textPainter: painter,
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

  /// Builds line widgets from pre-laid-out [PreparedQuranPage] data.
  ///
  /// Consecutive [PreparedTextBlock]s are merged into a single
  /// [QuranPagePainter] that paints all of them in one `paint()` call,
  /// dramatically reducing raster-thread render-object traversal
  /// (from ~15 CustomPaint ops to 1 per page).
  List<Widget> _buildPreparedLineWidgets({
    required PreparedQuranPage preparedPage,
    required QuranLayoutMetrics metrics,
    required double viewportWidth,
    required double viewportHeight,
    required bool isPortrait,
  }) {
    final List<Widget> result = [];
    final pageFont = 'QCF_P${widget.pageNumber.toString().padLeft(3, '0')}';

    // Accumulate consecutive text blocks.
    final List<(TextPainter, List<QuranWordMetadata>)> textRun = [];

    void flushTextRun() {
      if (textRun.isEmpty) return;
      result.add(
        QuranPagePainter(
          painters: List.of(textRun),
          lineSpacing: metrics.lineSpacing,
          onLongPress: widget.onLongPress,
          onLongPressUp: widget.onLongPressUp,
          onLongPressDown: widget.onLongPressDown,
          onLongPressCancel: widget.onLongPressCancel,
        ),
      );
      textRun.clear();
    }

    for (final PreparedPageBlock block in preparedPage.blocks) {
      if (block is PreparedTextBlock) {
        textRun.add((block.painter, block.metadata));
        continue;
      }

      // Non-text block: flush any accumulated text run first.
      flushTextRun();

      if (block is PreparedHeaderBlock) {
        final Widget banner = SurahHeaderBanner(
          surahNumber: block.surahNumber,
          lineHeight: metrics.fontSize * metrics.fontHeight,
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight,
          isLandscape: !isPortrait,
          headerImageFilter: widget.headerImageFilter,
          headerTextColor: widget.headerTextColor,
          headerFontSizeMultiplier: widget.headerFontSizeMultiplier,
        );
        result.add(
          widget.onSurahSelected == null
              ? banner
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onSurahSelected!(block.surahNumber),
                  child: banner,
                ),
        );
        continue;
      }

      if (block is PreparedBismillahBlock) {
        result.add(
          BismillahWidget(
            fontSize: metrics.fontSize,
            pageNumber: widget.pageNumber,
            color: widget.textColor,
            fontFamily: pageFont,
          ),
        );
      }
    }

    // Flush any remaining text lines.
    flushTextRun();
    return result;
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

class _QuranPageBody extends StatelessWidget {
  const _QuranPageBody({
    required this.metrics,
    required this.spacedLines,
    required this.scrollController,
  });

  final QuranLayoutMetrics metrics;
  final List<Widget> spacedLines;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    // No manual RepaintBoundary — the sliver auto-inserts one per child.
    final Widget pageBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: spacedLines,
    );

    final paddedBody = Padding(padding: metrics.padding, child: pageBody);

    if (metrics.isScrollable) {
      return Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollController,
          primary: false,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [paddedBody, const SizedBox(height: 100)],
          ),
        ),
      );
    }
    return paddedBody;
  }
}

class _QuranPageOverlays extends StatelessWidget {
  const _QuranPageOverlays({
    required this.pageNumber,
    required this.showOverlaysListenable,
    required this.uiTextDirection,
    required this.metrics,
    required this.pageMeta,
    required this.metaTextColor,
    required this.badgeColor,
    required this.borderColor,
    required this.textColor,
    this.onShowIndex,
  });

  final int pageNumber;
  final ValueListenable<bool>? showOverlaysListenable;
  final TextDirection uiTextDirection;
  final QuranLayoutMetrics metrics;
  final _PageMetaInfo? pageMeta;
  final Color metaTextColor;
  final Color badgeColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onShowIndex;

  @override
  Widget build(BuildContext context) {
    if (showOverlaysListenable == null) return const SizedBox.shrink();

    final String pageNumberLabel = uiTextDirection == TextDirection.rtl
        ? convertToArabicNumber(pageNumber.toString())
        : pageNumber.toString();

    return Stack(
      children: [
        Positioned(
          top: metrics.padding.top,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: showOverlaysListenable!,
            builder: (context, show, child) {
              // Use Visibility instead of AnimatedOpacity to avoid
              // saveLayer() calls that stall the raster thread.
              return Visibility(visible: show, child: child!);
            },
            child: _MetadataStrip(
              surahNames: pageMeta?.surahNames.join(', ') ?? '',
              juzLabel: pageMeta?.juzLabel ?? '',
              uiTextDirection: uiTextDirection,
              textColor: metaTextColor,
              onShowIndex: onShowIndex,
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 6, // Portrait horizontal padding
          child: ValueListenableBuilder<bool>(
            valueListenable: showOverlaysListenable!,
            builder: (context, show, child) {
              // Use Visibility instead of AnimatedOpacity to avoid
              // saveLayer() calls that stall the raster thread.
              return Visibility(visible: show, child: child!);
            },
            child: PageNumberBadge(
              label: pageNumberLabel,
              backgroundColor: badgeColor,
              borderColor: borderColor,
              textColor: textColor,
            ),
          ),
        ),
      ],
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
