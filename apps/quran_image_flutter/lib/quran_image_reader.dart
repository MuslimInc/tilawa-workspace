import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image_flutter/core/design_tokens/design_tokens.dart';
import 'package:quran_image_flutter/core/di/dependency_injection.dart';
import 'package:quran_image_flutter/core/perf_logger.dart';
import 'package:quran_image_flutter/domain/domain.dart';
import 'package:quran_image_flutter/page_mapping.dart';
import 'package:quran_image_flutter/presentation/presentation.dart';
import 'package:quran_image_flutter/verse_marker.dart';

class QuranImageReader extends StatefulWidget {
  const QuranImageReader({super.key});

  @override
  State<QuranImageReader> createState() => _QuranImageReaderState();
}

class _QuranImageReaderState extends State<QuranImageReader> {
  late final PageController _pageController;
  late int _lastSettledPageIndex;

  // Stable cacheWidth resolved from device metrics — updated in didChangeDependencies.
  int _cacheWidth = 0;
  late final QuranImagePrewarmer _imagePrewarmer;
  late final ValueNotifier<PageState?> _previewPageStateNotifier;
  bool _backgroundMarkerWarmUpStarted = false;
  Timer? _backgroundMarkerWarmUpTimer;

  // Throttle slider preview updates to avoid excessive rebuilds during drags.
  // 50ms limit = max 20 updates/second, down from 30-60 updates/second.
  DateTime _lastPreviewUpdateTime = DateTime(2000);
  static const _previewUpdateThrottle = Duration(milliseconds: 50);

  @override
  void initState() {
    final sw = PerfLogger.startTimer();
    super.initState();
    _imagePrewarmer = sl<QuranImagePrewarmer>();
    _previewPageStateNotifier = ValueNotifier<PageState?>(null);

    final currentState = context.read<NavigationBloc>().state;
    final initialIndex = currentState is NavigationLoaded
        ? currentState.pageState.pageIndex
        : 0;
    _lastSettledPageIndex = initialIndex;
    _pageController = PageController(initialPage: initialIndex);

    // Listen on every scroll position change so we pre-warm the destination
    // page images *during* the swipe, not only after it settles.
    _pageController.addListener(_onScrollPositionChanged);

    // Pre-warm images after the first frame so we don't block the initial build.
    // Verse marker warm-up (TextPainters + Impeller paths) was already done
    // during PreloadingScreen._prewarmInitialPage before the reader opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _imagePrewarmer.startInitialPrewarm(
        currentPageNumber: initialIndex + 1,
        cacheWidth: _cacheWidth,
      );
      _scheduleBackgroundMarkerWarmUp();
    });

    PerfLogger.logElapsed(
      sw,
      widgetName: 'QuranImageReader',
      message: 'initState initialPage=${initialIndex + 1}',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    final screenWidth = view.physicalSize.width / dpr;
    _cacheWidth = (screenWidth * dpr).round();
  }

  @override
  void dispose() {
    _backgroundMarkerWarmUpTimer?.cancel();
    _previewPageStateNotifier.dispose();
    _imagePrewarmer.dispose();
    _pageController.removeListener(_onScrollPositionChanged);
    _pageController.dispose();
    super.dispose();
  }

  /// Called on every scroll tick. Computes the nearest page and pre-warms it
  /// if it differs from the last pre-warmed center — avoiding redundant work.
  void _onScrollPositionChanged() {
    final page = _pageController.page;
    if (page == null) return;
    // Round to nearest page index (0-based) then convert to 1-based page number.
    final nearest = page.round() + 1;
    _imagePrewarmer.prewarmCurrentTarget(
      pageNumber: nearest,
      cacheWidth: _cacheWidth,
    );
  }

  void _scheduleBackgroundMarkerWarmUp() {
    if (_backgroundMarkerWarmUpStarted) return;
    _backgroundMarkerWarmUpStarted = true;

    PerfLogger.log(
      widgetName: 'QuranImageReader',
      message: 'background verse marker warm-up scheduled delayMs=700',
    );
    _backgroundMarkerWarmUpTimer = Timer(const Duration(milliseconds: 700), () {
      _backgroundMarkerWarmUpTimer = null;
      unawaited(_warmRemainingVerseMarkersInBackground());
    });
  }

  Future<void> _warmRemainingVerseMarkersInBackground() async {
    if (!mounted) return;

    final view = View.of(context);
    final markerWidth =
        (view.physicalSize.width / view.devicePixelRatio) * 0.05138889;
    final warmUpTimer = PerfLogger.startTimer();
    // batchSize=50 with yieldDelay=zero: ~6 yields total, minimal overhead.
    // Previous: batchSize=8, yieldDelay=16ms → 36 yields × 16ms = 576ms delay alone.
    await VerseMarker.warmUpAll(
      markerWidth: markerWidth,
      batchSize: 50,
      yieldDelay: Duration.zero,
    );
    PerfLogger.logElapsed(
      warmUpTimer,
      widgetName: 'QuranImageReader',
      message:
          'background verse marker warm-up completed '
          'markerWidth=${markerWidth.toStringAsFixed(1)} '
          'glyphs=286',
    );
  }

  void _updatePreviewPage(int displayPage) {
    // Throttle: max 20 updates/second (50ms interval) to reduce rebuild pressure.
    final now = DateTime.now();
    if (now.difference(_lastPreviewUpdateTime) < _previewUpdateThrottle) {
      return;
    }
    _lastPreviewUpdateTime = now;

    final currentState = context.read<NavigationBloc>().state;
    if (currentState is! NavigationLoaded) return;

    final currentPreviewState = _previewPageStateNotifier.value;
    if (displayPage == currentState.pageState.currentPage &&
        currentPreviewState == null) {
      return;
    }
    if (currentPreviewState?.displayPage == displayPage) {
      return;
    }

    final pageInfo = QuranPageMapping.getPageInfo(displayPage);
    _previewPageStateNotifier.value = currentState.pageState.copyWith(
      previewPage: displayPage,
      juzTitle: pageInfo.juzTitle,
      hizbTitle: pageInfo.hizbTitle,
    );
    _imagePrewarmer.prewarmPreviewTarget(
      pageNumber: displayPage,
      cacheWidth: _cacheWidth,
    );
  }

  void _clearPreviewPage() {
    if (_previewPageStateNotifier.value == null) return;
    _previewPageStateNotifier.value = null;
  }

  void _navigateToPage(int pageNumber) {
    final safePageNumber = pageNumber
        .clamp(1, PageState.quranPageCount)
        .toInt();
    final targetIndex = safePageNumber - 1;
    if (targetIndex == _lastSettledPageIndex) {
      _clearPreviewPage();
      return;
    }

    if (!_pageController.hasClients) {
      return;
    }

    final currentIndex = _pageController.page?.round() ?? 0;
    final delta = (targetIndex - currentIndex).abs();

    if (delta > 3) {
      PerfLogger.log(
        widgetName: 'QuranImageReader',
        message:
            'slider jump delta=$delta '
            'from=${currentIndex + 1} to=$safePageNumber',
      );
      unawaited(
        _imagePrewarmer
            .prewarmJumpTargetAndWait(
              pageNumber: safePageNumber,
              cacheWidth: _cacheWidth,
              timeout: const Duration(milliseconds: 1500),
            )
            .then((_) {
              if (!mounted) return;
              _pageController.jumpToPage(targetIndex);
            }),
      );
      return;
    }

    _imagePrewarmer.prewarmJumpTarget(
      pageNumber: safePageNumber,
      cacheWidth: _cacheWidth,
    );
    _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onReaderPageChanged(int pageNumber) {
    final pageIndex = pageNumber - 1;
    _lastSettledPageIndex = pageIndex;
    _clearPreviewPage();
    PerfLogger.log(widgetName: 'PageView', message: 'swiped page=$pageNumber');
    context.read<NavigationBloc>().add(PageChanged(pageNumber));
    _imagePrewarmer.prewarmSettledWindow(
      pageNumber: pageNumber,
      cacheWidth: _cacheWidth,
    );
  }

  void _navigateToPreviousPage() {
    final currentState = context.read<NavigationBloc>().state;
    if (currentState is! NavigationLoaded ||
        currentState.pageState.currentPage <= 1) {
      return;
    }
    _clearPreviewPage();
    _navigateToPage(currentState.pageState.currentPage - 1);
  }

  void _navigateToNextPage() {
    final currentState = context.read<NavigationBloc>().state;
    if (currentState is! NavigationLoaded ||
        currentState.pageState.currentPage >=
            currentState.pageState.totalPages) {
      return;
    }
    _clearPreviewPage();
    _navigateToPage(currentState.pageState.currentPage + 1);
  }

  void _toggleNavigation() {
    context.read<NavigationBloc>().add(const NavigationToggled());
  }

  void _showNavigation() {
    context.read<NavigationBloc>().add(const NavigationShown());
  }

  void _onNavigationInteractionStarted() {
    context.read<NavigationBloc>().add(const NavigationInteractionStarted());
  }

  void _onNavigationInteractionEnded() {
    context.read<NavigationBloc>().add(const NavigationInteractionEnded());
  }

  @override
  Widget build(BuildContext context) {
    final sw = PerfLogger.startTimer();
    final padding = MediaQuery.paddingOf(context);
    final scaffold = Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Padding(
        padding: EdgeInsets.only(
          top: padding.top,
          bottom: padding.bottom,
          left: padding.left,
          right: padding.right,
        ),
        child: Stack(
          children: [
            QuranReaderViewport(
              pageController: _pageController,
              onToggleNavigation: _toggleNavigation,
              onShowNavigation: _showNavigation,
              onPageChanged: _onReaderPageChanged,
            ),

            PremiumNavigationOverlay(
              previewStateListenable: _previewPageStateNotifier,
              onPreviewPageChanged: _updatePreviewPage,
              onPageNavigationRequested: _navigateToPage,
              onPreviousPageRequested: _navigateToPreviousPage,
              onNextPageRequested: _navigateToNextPage,
              onInteractionStart: _onNavigationInteractionStarted,
              onInteractionEnd: _onNavigationInteractionEnded,
            ),
          ],
        ),
      ),
    );

    PerfLogger.logElapsed(sw, widgetName: 'QuranImageReader', message: 'build');
    return scaffold;
  }
}
