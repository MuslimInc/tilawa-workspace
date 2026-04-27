import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../quran_qcf.dart';
import '../../helpers/app_logger.dart';
import 'bismillah_widget.dart';
import 'page_background.dart';
import 'page_overlays.dart';
import 'page_text_renderer.dart';
import 'quran_line.dart';
import 'quran_page_painter.dart';

class PageContent extends StatefulWidget {
  const PageContent({
    super.key,
    required this.pageNumber,
    this.preparedPage,
    this.preparedWindowListenable,
    required this.textColor,
    this.verseBackgroundColor,
    this.verseTextColor,
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
    this.headerFontSizeMultiplier =
        SurahHeaderBannerConstants.defaultFontSizeMultiplier,
    required this.pageBackgroundColor,
    this.uiTextDirection = TextDirection.ltr,
    this.currentPageListenable,
    this.showOverlaysListenable,
    this.isScrollingListenable,
    this.isWarming = false,
    this.showShadows = true,
    this.alignTextToTop = false,
    this.showSpecialBlocks = true,
    this.viewportSize,
    this.enableSnapshots = true,
    this.isCapturing = false,
    required this.mushafService,
    required this.pageSnapshotService,
  });

  /// The service for accessing Quran text and metadata.
  final QuranMushafService mushafService;

  /// The service for capturing and caching page snapshots.
  final PageSnapshotService pageSnapshotService;

  /// Whether to render bold text shadows.
  final bool showShadows;

  /// When true, pins page text to the top instead of vertically centering it.
  /// Useful for share/export compositions with explicit header banners.
  final bool alignTextToTop;

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
  final Color? Function(int surahNumber, int verseNumber)? verseTextColor;
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
  final bool showSpecialBlocks;
  final Size? viewportSize;
  final bool enableSnapshots;
  final bool isCapturing;
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
  static const Duration _centerSnapshotDeferral = Duration(milliseconds: 1200);

  final ScrollController _scrollController = ScrollController();
  PageMetaInfo? _cachedPageMeta;
  List<List<WordData>>? _cachedPageLines;
  Orientation? _lastOrientation;

  // Luminance cache — recomputed only when pageBackgroundColor changes.
  Color? _cachedLuminanceColor;
  bool _cachedIsLightPage = false;

  // Bitmap snapshot support — captures the rendered page body as a GPU
  // texture for fast blitting during swipe animations.
  final GlobalKey _snapshotBoundaryKey = GlobalKey();
  bool _snapshotScheduled = false;
  bool _snapshotCaptured = false;
  bool _snapshotFailed = false;
  IdleTask? _pendingIdleCapture;
  Timer? _deferredSnapshotTimer;
  bool _hasDeferredCenterSnapshotCapture = false;

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
      _deferredSnapshotTimer?.cancel();
      _deferredSnapshotTimer = null;
      _hasDeferredCenterSnapshotCapture = false;
      _snapshotCaptured = false;
      _snapshotScheduled = false;
      _snapshotFailed = false;
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
    _deferredSnapshotTimer?.cancel();
    _pendingIdleCapture?.cancel();
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
    // The highlight path intentionally rebuilds line widgets every build so
    // per-line visual-bound alignment cannot reuse stale QuranLine instances.
  }

  /// Called when the scroll state changes (start/end).
  void _handleScrollStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  /// Schedules a bitmap snapshot capture via the [IdleScheduler] so the
  /// expensive `toImage()` call runs only when the GPU is idle.
  void _scheduleSnapshotCapture() {
    if (widget.isCapturing ||
        !widget.enableSnapshots ||
        _snapshotScheduled ||
        _snapshotCaptured ||
        _snapshotFailed) {
      return;
    }
    final int centerPage =
        widget.currentPageListenable?.value ?? widget.pageNumber;

    // Defer center-page capture shortly after mount so toImage() does not
    // contend with first interaction frames.
    if (widget.pageNumber == centerPage &&
        !_hasDeferredCenterSnapshotCapture &&
        _deferredSnapshotTimer == null) {
      _hasDeferredCenterSnapshotCapture = true;
      _deferredSnapshotTimer = Timer(_centerSnapshotDeferral, () {
        _deferredSnapshotTimer = null;
        if (!mounted || _snapshotScheduled || _snapshotCaptured) return;
        _scheduleSnapshotCapture();
      });
      return;
    }

    // No scroll guard needed here — IdleScheduler already defers the
    // expensive toImage() call to a post-frame idle slot, so the GPU
    // work never competes with live frame rasterization.
    _snapshotScheduled = true;
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);

    _pendingIdleCapture?.cancel();
    final IdleTask idleCapture = widget.pageSnapshotService
        .scheduleCaptureWhenIdle(
          pageNumber: widget.pageNumber,
          boundaryKey: _snapshotBoundaryKey,
          pixelRatio: pixelRatio,
          centerPage: centerPage,
        );
    _pendingIdleCapture = idleCapture;

    idleCapture.future.then((_) {
      if (!mounted) return;
      if (!identical(_pendingIdleCapture, idleCapture)) return;
      if (!idleCapture.isCancelled &&
          widget.pageSnapshotService.hasSnapshot(widget.pageNumber)) {
        _snapshotCaptured = true;
      } else if (!idleCapture.isCancelled) {
        _snapshotFailed = true;
      }
      _snapshotScheduled = false;
      _pendingIdleCapture = null;
    });
  }

  /// Removes the cached snapshot for this page.
  void _invalidateSnapshot() {
    _deferredSnapshotTimer?.cancel();
    _deferredSnapshotTimer = null;
    _hasDeferredCenterSnapshotCapture = false;
    _pendingIdleCapture?.cancel();
    _pendingIdleCapture = null;
    widget.pageSnapshotService.evict(widget.pageNumber);
    _snapshotCaptured = false;
    _snapshotScheduled = false;
    _snapshotFailed = false;
  }

  void _primePageData() {
    final QuranMushafService dataService = widget.mushafService;
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
    const AssetImage imageProvider = SurahHeaderBannerConstants.assetImage;
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

    final Size mediaSize = widget.viewportSize ?? MediaQuery.sizeOf(context);
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
    final bool hasHighlight =
        widget.verseBackgroundColor != null || widget.verseTextColor != null;

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
      final List<Widget> built = [];
      for (var i = 0; i < lineWidgets.length; i++) {
        if (i > 0) built.add(SizedBox(height: metrics.lineSpacing));
        built.add(lineWidgets[i]);
      }
      spacedLines = built;
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
    final bool snapshotsEnabled = widget.enableSnapshots && !widget.isCapturing;
    final bool isScrolling = widget.isScrollingListenable?.value ?? false;
    final ui.Image? snapshot = snapshotsEnabled && isScrolling
        ? widget.pageSnapshotService.getSnapshot(widget.pageNumber)
        : null;
    if (snapshotsEnabled && snapshot == null) {
      // Schedule a snapshot capture after the first successful paint,
      // unless we are just warming up the cache (which doesn't need a snapshot).
      if (!widget.isWarming && !_snapshotCaptured && !_snapshotScheduled) {
        _scheduleSnapshotCapture();
      }
    }

    return PageBackground(
      color: widget.pageBackgroundColor,
      child: Stack(
        alignment: metrics.isScrollable || widget.alignTextToTop
            ? Alignment.topCenter
            : Alignment.center,
        children: [
          PageTextRenderer(
            metrics: metrics,
            spacedLines: spacedLines,
            scrollController: _scrollController,
            snapshotBoundaryKey: _snapshotBoundaryKey,
            snapshot: snapshot,
            pageWidth: pageWidth,
            pageHeight: pageHeight,
          ),
          Positioned.fill(
            child: PageOverlays(
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
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLineWidgets({
    required QuranLayoutMetrics metrics,
    required double viewportWidth,
    required double viewportHeight,
    required String pageFont,
    required bool isPortrait,
  }) {
    final List<List<WordData>> pageLines = _cachedPageLines!;
    final double lineWidth = _verseLineWidth(metrics, viewportWidth);
    final quranStyle = TextStyle(
      fontFamily: pageFont,
      fontSize: metrics.fontSize,
      height: metrics.fontHeight,
      color: widget.textColor,
    );
    final markerStyle = quranStyle;

    final bool isCenteredPage = QuranConstants.centeredPageNumbers.contains(
      widget.pageNumber,
    );

    final List<int> lineIndices = metrics.isScrollable
        ? List.generate(QuranConstants.linesPerPage, (int i) => i).where((i) {
            return isCenteredPage ||
                pageLines[i].isNotEmpty ||
                _isSurahHeader(widget.pageNumber, i + 1) ||
                _isBismillah(widget.pageNumber, i + 1);
          }).toList()
        : List.generate(QuranConstants.linesPerPage, (int i) => i);

    final List<_PendingQuranBlock> blocks = [];
    final List<InlineSpan> currentSpans = [];
    final List<QuranWordMetadata> currentMetadata = [];
    var currentOffset = 0;
    final nbSpaceSpan = TextSpan(text: '\u00A0', style: quranStyle);

    void flushSpans() {
      if (currentSpans.isNotEmpty) {
        final painter = TextPainter(
          text: TextSpan(children: List<InlineSpan>.from(currentSpans)),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          strutStyle: StrutStyle(
            fontFamily: pageFont,
            fontSize: metrics.fontSize,
            height: metrics.fontHeight,
            forceStrutHeight: true,
          ),
        )..layout(minWidth: lineWidth, maxWidth: lineWidth);
        blocks.add(
          _PendingQuranTextLine(
            textPainter: painter,
            metadata: List.from(currentMetadata),
            visualBounds: quranLineVisualBoundsFor(painter),
          ),
        );
        currentSpans.clear();
        currentMetadata.clear();
        currentOffset = 0;
      }
    }

    // For pages 1 & 2, pre-compute the header surah number and
    // whether a separate bismillah block is needed.
    // Page 1 (Al-Fatihah) has no separate bismillah — it IS verse 1.
    int? centeredHeaderSurah;
    var hasCenteredBismillah = false;
    if (isCenteredPage) {
      for (var rawLine = 1; rawLine <= QuranConstants.linesPerPage; rawLine++) {
        if (_isSurahHeader(widget.pageNumber, rawLine)) {
          centeredHeaderSurah = _getSurahAtLine(widget.pageNumber, rawLine);
        }
        if (_isBismillah(widget.pageNumber, rawLine)) {
          hasCenteredBismillah = true;
        }
      }
    }

    var hasSeenFirstTextLine = false;

    for (final i in lineIndices) {
      if (isCenteredPage) {
        // Centered page: emit header at index 2, bismillah at index 4.
        if (i == QuranConstants.centeredHeaderLineIndex &&
            centeredHeaderSurah != null) {
          flushSpans();
          if (!widget.showSpecialBlocks) {
            continue;
          }
          final int surahNum = centeredHeaderSurah;
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
            _PendingWidgetBlock(
              widget: widget.onSurahSelected == null
                  ? banner
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onSurahSelected!(surahNum),
                      child: banner,
                    ),
            ),
          );
          continue;
        }
        if (i == QuranConstants.centeredBismillahLineIndex &&
            hasCenteredBismillah) {
          flushSpans();
          if (!widget.showSpecialBlocks) {
            continue;
          }
          blocks.add(
            _PendingWidgetBlock(
              widget: BismillahWidget(
                fontSize: metrics.fontSize,
                pageNumber: widget.pageNumber,
                color: widget.textColor,
                fontFamily: pageFont,
              ),
            ),
          );
          continue;
        }
        // Skip raw special-line positions.
        if (_isSurahHeader(widget.pageNumber, i + 1) ||
            _isBismillah(widget.pageNumber, i + 1)) {
          const char = '\u00A0\n';
          currentSpans.add(TextSpan(text: char, style: quranStyle));
          currentOffset += char.length;
          continue;
        }
      } else {
        // Standard page: use raw special-line positions.
        if (_isSurahHeader(widget.pageNumber, i + 1)) {
          flushSpans();
          if (!widget.showSpecialBlocks) {
            continue;
          }
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
            _PendingWidgetBlock(
              widget: widget.onSurahSelected == null
                  ? banner
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onSurahSelected!(surahNum),
                      child: banner,
                    ),
            ),
          );
          continue;
        }

        if (_isBismillah(widget.pageNumber, i + 1)) {
          flushSpans();
          if (!widget.showSpecialBlocks) {
            continue;
          }
          blocks.add(
            _PendingWidgetBlock(
              widget: BismillahWidget(
                fontSize: metrics.fontSize,
                pageNumber: widget.pageNumber,
                color: widget.textColor,
                fontFamily: pageFont,
              ),
            ),
          );
          continue;
        }
      }

      final List<_WordSpanGroup> wordSpans = _getWordSpansForLine(
        pageLines,
        i,
        quranStyle,
        markerStyle,
      );
      if (wordSpans.isEmpty) {
        const char = '\u00A0\n';
        currentSpans.add(TextSpan(text: char, style: quranStyle));
        currentOffset += char.length;
      } else {
        final bool isFirstTextLine = !hasSeenFirstTextLine;
        hasSeenFirstTextLine = true;

        for (var idx = 0; idx < wordSpans.length; idx++) {
          if (isFirstTextLine && idx == 1) {
            currentSpans.add(nbSpaceSpan);
            currentOffset += 1;
          }

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

        if (!metrics.isScrollable) {
          flushSpans();
        } else {
          const newline = '\n';
          currentSpans.add(TextSpan(text: newline, style: quranStyle));
          currentOffset += newline.length;
        }
      }
    }
    flushSpans();
    final QuranLineVisualBounds? targetBounds = quranLineTargetBoundsFor(
      blocks.whereType<_PendingQuranTextLine>().map(
        (line) => line.visualBounds,
      ),
    );
    return blocks
        .map((block) {
          return switch (block) {
            _PendingQuranTextLine() => QuranLine(
              textPainter: block.textPainter,
              width: lineWidth,
              alignment: switch ((block.visualBounds, targetBounds)) {
                (
                  final QuranLineVisualBounds source,
                  final QuranLineVisualBounds target,
                ) =>
                  QuranLineAlignment(source: source, target: target),
                _ => null,
              },
              metadata: block.metadata,
              onLongPress: widget.onLongPress,
              onLongPressUp: widget.onLongPressUp,
              onLongPressDown: widget.onLongPressDown,
              onLongPressCancel: widget.onLongPressCancel,
            ),
            _PendingWidgetBlock() => block.widget,
          };
        })
        .toList(growable: false);
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
    final double lineWidth = _verseLineWidth(metrics, viewportWidth);

    // Accumulate consecutive text blocks.
    final List<(TextPainter, List<QuranWordMetadata>)> textRun = [];

    void flushTextRun() {
      if (textRun.isEmpty) return;
      result.add(
        QuranPagePainter(
          painters: List.of(textRun),
          lineSpacing: metrics.lineSpacing,
          width: lineWidth,
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
        if (!widget.showSpecialBlocks) {
          continue;
        }
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
        if (!widget.showSpecialBlocks) {
          continue;
        }
        result.add(
          BismillahWidget(
            fontSize: metrics.fontSize,
            pageNumber: widget.pageNumber,
            color: widget.textColor,
            fontFamily: pageFont,
          ),
        );
        continue;
      }

      if (block is PreparedSpacerBlock) {
        result.add(SizedBox(height: block.height));
      }
    }

    // Flush any remaining text lines.
    flushTextRun();
    return result;
  }

  double _verseLineWidth(QuranLayoutMetrics metrics, double viewportWidth) {
    final double lineWidth =
        viewportWidth - (metrics.verseHorizontalPadding * 2);
    if (lineWidth.isFinite && lineWidth > 0) return lineWidth;
    return viewportWidth;
  }

  List<List<WordData>> _getWordsGroupedByLine(int pageNumber) {
    final List<List<WordData>> rawLines =
        widget.mushafService.getPageData(pageNumber) ??
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
  ) {
    if (lineIndex < 0 || lineIndex >= lines.length) {
      return <_WordSpanGroup>[];
    }
    final List<WordData> words = lines[lineIndex];
    if (words.isEmpty) return [];
    final QuranMushafService qData = widget.mushafService;
    return words.map((WordData word) {
      final String text = word.text;
      final int surah = word.surah;
      final int ayah = word.ayah;
      final Color? bgColor = widget.verseBackgroundColor?.call(surah, ayah);
      final Color textColor =
          widget.verseTextColor?.call(surah, ayah) ?? widget.textColor;
      return _WordSpanGroup(
        surah: surah,
        verse: ayah,
        spans: _buildWordSpans(
          text: text,
          isVerseEndWord: qData.isVerseEndWord(word),
          quranTextStyle: quranStyle.copyWith(
            color: textColor,
            backgroundColor: bgColor,
          ),
          markerTextStyle: markerStyle.copyWith(
            color: textColor,
            backgroundColor: bgColor,
          ),
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

  bool _pageHasSurahHeader(int page) =>
      widget.mushafService.pageHasSurahHeader(page);

  int _getSurahAtLine(int page, int line) {
    return _getSpecialLine(page, line)?.surahNumber ?? 0;
  }

  QuranSpecialLine? _getSpecialLine(int page, int line) {
    return widget.mushafService.getSpecialLine(page, line);
  }

  PageMetaInfo _buildPageMeta(int page) {
    final PageMetadata meta = widget.mushafService.getPageMetadata(page);
    final List<String> surahNames = meta.surahNumbers
        .map((n) => widget.surahNameBuilder?.call(n) ?? 'Surah $n')
        .toList();

    return PageMetaInfo(
      surahNames: surahNames,
      juzLabel: widget.juzLabel ?? '',
      hizbNumber: meta.hizb,
    );
  }
}

sealed class _PendingQuranBlock {
  const _PendingQuranBlock();
}

class _PendingQuranTextLine extends _PendingQuranBlock {
  const _PendingQuranTextLine({
    required this.textPainter,
    required this.metadata,
    required this.visualBounds,
  });

  final TextPainter textPainter;
  final List<QuranWordMetadata> metadata;
  final QuranLineVisualBounds? visualBounds;
}

class _PendingWidgetBlock extends _PendingQuranBlock {
  const _PendingWidgetBlock({required this.widget});

  final Widget widget;
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
