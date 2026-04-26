import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/page_mapping.dart';
import 'package:quran_image/presentation/presentation.dart';
import 'package:quran_image/quran_image_page.dart';
import 'package:quran_image/verse_marker.dart';

class QuranImageReader extends StatefulWidget {
  const QuranImageReader({
    super.key,
    this.preferredSystemUiMode,
    this.restoreSystemUiMode,
    this.preferredOrientations,
    this.restoreOrientations,
    this.onShareRequested,
  });

  /// The system UI mode to enable when the reader enters the screen.
  final SystemUiMode? preferredSystemUiMode;

  /// The system UI mode to restore when the reader leaves the screen.
  final SystemUiMode? restoreSystemUiMode;

  /// The preferred orientations to allow when the reader enters the screen.
  final List<DeviceOrientation>? preferredOrientations;

  /// The orientations to restore when the reader leaves the screen.
  final List<DeviceOrientation>? restoreOrientations;

  /// Called when the user taps the share/reel button in the navigation overlay.
  /// The host app is responsible for opening its share composer.
  final void Function(int currentPage)? onShareRequested;

  @override
  State<QuranImageReader> createState() => _QuranImageReaderState();
}

class _QuranImageReaderState extends State<QuranImageReader>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  late int _lastSettledPageIndex;

  // Stable cacheWidth resolved from device metrics — updated in didChangeDependencies.
  int _cacheWidth = 0;
  String _warmViewportKey = '';
  bool _isLandscape = false;
  late final QuranImagePrewarmer _imagePrewarmer;
  late final ValueNotifier<PageState?> _previewPageStateNotifier;
  late final ValueNotifier<Set<int>> _hiddenWarmupPagesNotifier;
  late final ValueNotifier<_JumpTransitionSnapshot?>
  _jumpTransitionSnapshotNotifier;
  bool _backgroundMarkerWarmUpStarted = false;
  Timer? _backgroundMarkerWarmUpTimer;
  int _navigationRequestGeneration = 0;
  final Map<int, GlobalKey> _hiddenWarmupBoundaryKeys = <int, GlobalKey>{};
  final LinkedHashMap<String, Future<ui.Image?>> _snapshotFutures =
      LinkedHashMap<String, Future<ui.Image?>>();
  final LinkedHashMap<String, ui.Image> _snapshotCache =
      LinkedHashMap<String, ui.Image>();
  static const int _maxSnapshotEntries = 1;
  static const int _maxSnapshotAttempts = 8;

  // Tracks whether the app is in the foreground. Set to false on
  // AppLifecycleState.paused/hidden so that memory pressure events arriving
  // during a lock/background cycle do not evict the image cache. OEM layers
  // (e.g. OPPO) fire didHaveMemoryPressure on every lock even when RAM is
  // plentiful; evicting while invisible only hurts the unlock frame.
  bool _isAppVisible = true;

  // Throttle slider preview updates to avoid excessive rebuilds during drags.
  // 50ms limit = max 20 updates/second, down from 30-60 updates/second.
  DateTime _lastPreviewUpdateTime = DateTime(2000);
  static const _previewUpdateThrottle = Duration(milliseconds: 50);

  // Last page number dispatched to prewarmCurrentTarget. Guards against
  // firing on every sub-pixel scroll tick when the rounded page hasn't changed.
  int _lastScrollPrewarmPage = -1;

  @override
  void initState() {
    final sw = PerfLogger.startTimer();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _imagePrewarmer = sl<QuranImagePrewarmer>();
    _previewPageStateNotifier = ValueNotifier<PageState?>(null);
    _hiddenWarmupPagesNotifier = ValueNotifier<Set<int>>(const <int>{});
    _jumpTransitionSnapshotNotifier = ValueNotifier<_JumpTransitionSnapshot?>(
      null,
    );

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

    // Apply system UI configuration after the first frame to ensure it sticks.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applySystemUiConfig();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    // Quran line images are portrait-page-width images. Use the minimum of
    // physical width and height so cacheWidth is invariant across rotation.
    // On a 1080×2400 device: portrait cacheWidth=1080, landscape cacheWidth=1080.
    // Without this, rotating to landscape sets cacheWidth=2400 (the new width),
    // which upscales the portrait images and triggers a full re-decode of all
    // cached pages simultaneously — causing the slow build/raster frames on rotation.
    final portraitPhysicalWidth =
        view.physicalSize.width.round().clamp(1, 1 << 20) <
            view.physicalSize.height.round().clamp(1, 1 << 20)
        ? view.physicalSize.width.round()
        : view.physicalSize.height.round();
    final newCacheWidth = portraitPhysicalWidth;
    // Viewport key still captures the full dimensions so snapshot cache is
    // invalidated when the screen size actually changes (new device, split-screen).
    final newWarmViewportKey =
        '${view.physicalSize.width.round()}x${view.physicalSize.height.round()}'
        '@${dpr.toStringAsFixed(2)}';
    final newIsLandscape = view.physicalSize.width > view.physicalSize.height;
    final orientationChanged = _isLandscape != newIsLandscape;

    if (_warmViewportKey != newWarmViewportKey) {
      final cacheWidthChanged = _cacheWidth != newCacheWidth;
      _warmViewportKey = newWarmViewportKey;
      _clearSnapshotState();
      // Cancel in-flight prewarm work so the old-dimension decode batches do
      // not continue running against a now-stale cacheWidth.
      if (cacheWidthChanged) {
        _imagePrewarmer.cancel();
        _lastScrollPrewarmPage = -1;
      }
      PerfLogger.log(
        widgetName: 'QuranImageReader',
        message:
            'didChangeDependencies viewportChanged '
            'viewport=$newWarmViewportKey '
            'cacheWidth=$newCacheWidth '
            'cacheWidthChanged=$cacheWidthChanged '
            'orientationChanged=$orientationChanged',
      );
    }
    _cacheWidth = newCacheWidth;
    _isLandscape = newIsLandscape;

    // When the orientation flips, Impeller must re-composite all visible page
    // images at the new layout dimensions (lineHeight changes from ~58px to
    // ~123px in landscape). This causes a 100–140ms raster stall on the first
    // landscape frame. Pre-rasterize the current page off-screen so Impeller
    // can upload textures at the new size before the visible frame is due.
    if (orientationChanged) {
      _scheduleOrientationPrewarm();
    }
  }

  /// Schedules an off-screen warmup of the current page at the new orientation
  /// dimensions so Impeller can upload textures before the user notices jank.
  ///
  /// The warmup page is added in a post-frame callback (after the rotation
  /// frame has been committed), not during didChangeDependencies. Adding it
  /// synchronously in didChangeDependencies put the hidden QuranImagePage build
  /// inside the rotation frame's build pass, contributing ~3ms of extra build
  /// time and ~16ms of extra paint time to an already-expensive frame.
  /// Deferring to the next frame lets the rotation frame complete unencumbered,
  /// then the warmup runs when the GPU is idle.
  void _scheduleOrientationPrewarm() {
    final currentPage = _lastSettledPageIndex + 1;
    PerfLogger.log(
      widgetName: 'QuranImageReader',
      message:
          'orientation prewarm scheduled '
          'page=$currentPage '
          'landscape=$_isLandscape',
    );

    // Wait until the rotation frame has been committed before adding the
    // hidden page. This avoids polluting the rotation frame's build pass.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final pages = Set<int>.from(_hiddenWarmupPagesNotifier.value)
        ..add(currentPage);
      _hiddenWarmupPagesNotifier.value = pages;
      PerfLogger.log(
        widgetName: 'QuranImageReader',
        message: 'orientation prewarm started page=$currentPage',
      );

      // Remove after 2 additional frames — enough for the raster thread to
      // finish uploading textures at the new orientation dimensions.
      for (var i = 0; i < 2; i++) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
      }
      final updated = Set<int>.from(_hiddenWarmupPagesNotifier.value)
        ..remove(currentPage);
      _hiddenWarmupPagesNotifier.value = updated;
      PerfLogger.log(
        widgetName: 'QuranImageReader',
        message: 'orientation prewarm done page=$currentPage',
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundMarkerWarmUpTimer?.cancel();
    _previewPageStateNotifier.dispose();
    _hiddenWarmupPagesNotifier.dispose();
    _jumpTransitionSnapshotNotifier.dispose();
    _disposeAllSnapshots();
    _imagePrewarmer.dispose();
    _pageController.removeListener(_onScrollPositionChanged);
    _pageController.dispose();
    super.dispose();

    if (widget.restoreSystemUiMode != null) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(widget.restoreSystemUiMode!),
      );
    }

    if (widget.restoreOrientations != null) {
      unawaited(
        SystemChrome.setPreferredOrientations(widget.restoreOrientations!),
      );
    }

    // Attempt to restore default overlay style.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  void _applySystemUiConfig() {
    if (!mounted) return;

    if (widget.preferredSystemUiMode != null) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(widget.preferredSystemUiMode!),
      );
    }

    if (widget.preferredOrientations != null) {
      unawaited(
        SystemChrome.setPreferredOrientations(widget.preferredOrientations!),
      );
    }

    // Ensure the status bar is transparent so content can flow behind it if necessary,
    // and icons are visible on the page background.
    _applySystemUiOverlayStyle();
  }

  void _applySystemUiOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applySystemUiConfig();
    }
    final wasVisible = _isAppVisible;
    // Mark invisible on inactive (window loses focus — fires before surface
    // destroy on OPPO/Android lock). This ensures the memory pressure guard
    // is active before didHaveMemoryPressure arrives during the lock sequence.
    // resumed is the only state where we are fully visible and interactive.
    _isAppVisible = state == AppLifecycleState.resumed;
    if (_isAppVisible && !wasVisible) {
      // App returned to foreground — restart prewarm for the current page so
      // the unlock frame has warm images if the cache survived.
      _imagePrewarmer.prewarmCurrentTarget(
        pageNumber: _lastSettledPageIndex + 1,
        cacheWidth: _cacheWidth,
      );
      PerfLogger.log(
        widgetName: 'QuranImageReader',
        message:
            'app foregrounded page=${_lastSettledPageIndex + 1} '
            'cacheWidth=$_cacheWidth',
      );
    }
  }

  @override
  void didHaveMemoryPressure() {
    // Skip eviction while the app is in the background. OEM layers (e.g. OPPO)
    // fire this on every lock screen event regardless of actual RAM pressure.
    // Evicting while invisible forces a full re-decode on the unlock frame,
    // causing unnecessary raster jank. Flutter's imageCache already responds
    // to real OS memory pressure via its own MemoryAllocations listener.
    if (!_isAppVisible) {
      PerfLogger.log(
        widgetName: 'QuranImageReader',
        message:
            'memory pressure ignored reason=app-in-background '
            'page=${_lastSettledPageIndex + 1}',
      );
      return;
    }
    _clearSnapshotState();
    _imagePrewarmer.handleMemoryPressure();
    PerfLogger.log(
      widgetName: 'QuranImageReader',
      message:
          'memory pressure handled '
          'snapshotsCleared=true '
          'page=${_lastSettledPageIndex + 1}',
    );
  }

  /// Called on every scroll tick. Computes the nearest page and pre-warms it
  /// only when the rounded page changes — avoiding a prewarmCurrentTarget call
  /// on every sub-pixel scroll event (which fires 60–120 times per second).
  void _onScrollPositionChanged() {
    final page = _pageController.page;
    if (page == null) return;
    // Round to nearest page index (0-based) then convert to 1-based page number.
    final nearest = page.round() + 1;
    if (nearest == _lastScrollPrewarmPage) return;
    _lastScrollPrewarmPage = nearest;
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
      juzNumber: pageInfo.juzNumber,
      hizbNumber: pageInfo.hizbNumber,
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
    unawaited(_navigateToPageAsync(pageNumber));
  }

  Future<void> _navigateToPageAsync(int pageNumber) async {
    final requestGeneration = ++_navigationRequestGeneration;
    _jumpTransitionSnapshotNotifier.value = null;
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
    final isLongJump = delta > 3;

    if (isLongJump) {
      PerfLogger.log(
        widgetName: 'QuranImageReader',
        message:
            'slider jump delta=$delta '
            'from=${currentIndex + 1} to=$safePageNumber',
      );
      // Do NOT clear preview here. The preview still shows the target page
      // (e.g. 379) while decode + snapshot runs. Clearing it early causes
      // effectivePageState to fall back to the old committedPageState (e.g. 41)
      // for the ~130ms decode window, producing a visible flicker in the
      // NavigationSliderOverlay. Preview is cleared after the jump settles.
    }

    _imagePrewarmer.prewarmJumpTarget(
      pageNumber: safePageNumber,
      cacheWidth: _cacheWidth,
    );
    _JumpTransitionSnapshot? jumpSnapshot;
    if (isLongJump) {
      jumpSnapshot = await _preparePageSnapshotForNavigation(safePageNumber);
    } else {
      await _preparePageForNavigation(safePageNumber);
    }
    if (!mounted ||
        requestGeneration != _navigationRequestGeneration ||
        !_pageController.hasClients) {
      return;
    }

    if (isLongJump) {
      if (jumpSnapshot != null) {
        PerfLogger.log(
          widgetName: 'QuranImageReader',
          message: 'jump snapshot shown page=${jumpSnapshot.pageNumber}',
        );
      }
      _jumpTransitionSnapshotNotifier.value = jumpSnapshot;
      _pageController.jumpToPage(targetIndex);
      // Wait until the PageView reports the target page as settled.
      // onPageChanged fires from the scroll position callback — before the
      // first raster frame of the live page has been produced. We then wait
      // one additional endOfFrame so the raster thread has had a chance to
      // paint the live page at least once before the overlay is removed.
      // This prevents the one-frame flash where the overlay disappears and
      // the GPU hasn't uploaded the live page yet.
      var clearAttempts = 0;
      while (mounted &&
          requestGeneration == _navigationRequestGeneration &&
          clearAttempts < 5) {
        clearAttempts++;
        await WidgetsBinding.instance.endOfFrame;
        if (_lastSettledPageIndex == targetIndex) {
          // One more frame: let the raster thread paint the live page.
          if (mounted && requestGeneration == _navigationRequestGeneration) {
            await WidgetsBinding.instance.endOfFrame;
          }
          break;
        }
      }
      if (mounted && requestGeneration == _navigationRequestGeneration) {
        _jumpTransitionSnapshotNotifier.value = null;
        // Clear preview only after the jump has settled and the BLoC has
        // received PageChanged — at this point committedPageState already
        // reflects the new page so nulling preview causes no flicker.
        _clearPreviewPage();
        PerfLogger.log(
          widgetName: 'QuranImageReader',
          message:
              'jump snapshot cleared '
              'page=$safePageNumber '
              'attempts=$clearAttempts',
        );
      }
      return;
    }

    await _pageController.animateToPage(
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

  String _pageWarmKey(int pageNumber) => '$_warmViewportKey:$pageNumber';

  Future<void> _preparePageForNavigation(int pageNumber) async {
    if (!mounted ||
        pageNumber < 1 ||
        pageNumber > PageState.quranPageCount ||
        _cacheWidth <= 0) {
      return;
    }

    try {
      await _imagePrewarmer.ensurePageReady(
        pageNumber: pageNumber,
        cacheWidth: _cacheWidth,
      );
    } catch (error) {
      PerfLogger.log(
        widgetName: 'QuranImageReader',
        message: 'page prepare failed page=$pageNumber error=$error',
      );
    }
  }

  Future<_JumpTransitionSnapshot?> _preparePageSnapshotForNavigation(
    int pageNumber,
  ) async {
    if (!mounted ||
        pageNumber < 1 ||
        pageNumber > PageState.quranPageCount ||
        _cacheWidth <= 0) {
      return null;
    }

    await _preparePageForNavigation(pageNumber);
    if (!mounted) return null;

    final snapshot = await _ensurePageSnapshotReady(pageNumber);
    if (snapshot == null) {
      return null;
    }

    return _JumpTransitionSnapshot(pageNumber: pageNumber, image: snapshot);
  }

  Future<ui.Image?> _ensurePageSnapshotReady(int pageNumber) async {
    final key = _pageWarmKey(pageNumber);
    final cached = _snapshotCache.remove(key);
    if (cached != null) {
      _snapshotCache[key] = cached;
      return cached;
    }

    final pending = _snapshotFutures.remove(key);
    if (pending != null) {
      _snapshotFutures[key] = pending;
      return pending;
    }

    final future = _captureWarmPageSnapshot(pageNumber, cacheKey: key);
    _snapshotFutures[key] = future;
    try {
      return await future;
    } finally {
      final current = _snapshotFutures[key];
      if (identical(current, future)) {
        _snapshotFutures.remove(key);
      }
    }
  }

  Future<ui.Image?> _captureWarmPageSnapshot(
    int pageNumber, {
    required String cacheKey,
  }) async {
    final sw = Stopwatch()..start();
    final boundaryKey = _hiddenWarmupBoundaryKeys.putIfAbsent(
      pageNumber,
      GlobalKey.new,
    );
    final nextPages = Set<int>.from(_hiddenWarmupPagesNotifier.value)
      ..add(pageNumber);
    _hiddenWarmupPagesNotifier.value = nextPages;

    try {
      for (var attempt = 1; attempt <= _maxSnapshotAttempts; attempt++) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return null;

        final renderObject = boundaryKey.currentContext?.findRenderObject();
        // hasSize is false until layout has run; attached guards against a
        // boundary that was removed from the tree between frames.
        // debugNeedsPaint is only meaningful in debug mode, so we use the
        // public hasSize + attached pair as the cross-mode readiness signal.
        if (renderObject is! RenderRepaintBoundary ||
            !renderObject.attached ||
            !renderObject.hasSize) {
          continue;
        }

        try {
          final image = await renderObject.toImage(
            pixelRatio: View.of(context).devicePixelRatio,
          );
          _rememberSnapshot(cacheKey, image);
          PerfLogger.log(
            widgetName: 'QuranImageReader',
            message:
                'snapshot ready '
                'page=$pageNumber '
                'attempt=$attempt '
                'size=${image.width}x${image.height} '
                'elapsedMs=${sw.elapsedMilliseconds}',
          );
          return image;
        } catch (error) {
          if (attempt == _maxSnapshotAttempts) {
            PerfLogger.log(
              widgetName: 'QuranImageReader',
              message:
                  'snapshot failed '
                  'page=$pageNumber '
                  'attempts=$attempt '
                  'error=$error',
            );
          }
        }
      }

      PerfLogger.log(
        widgetName: 'QuranImageReader',
        message:
            'snapshot unavailable '
            'page=$pageNumber '
            'reason=paint-never-stabilized '
            'elapsedMs=${sw.elapsedMilliseconds}',
      );
      return null;
    } finally {
      _hiddenWarmupBoundaryKeys.remove(pageNumber);
      if (mounted) {
        final updatedPages = Set<int>.from(_hiddenWarmupPagesNotifier.value)
          ..remove(pageNumber);
        _hiddenWarmupPagesNotifier.value = updatedPages;
      }
    }
  }

  void _rememberSnapshot(String key, ui.Image image) {
    final previous = _snapshotCache.remove(key);
    if (previous != null && !identical(previous, image)) {
      previous.dispose();
    }
    _snapshotCache[key] = image;
    while (_snapshotCache.length > _maxSnapshotEntries) {
      final eldestKey = _snapshotCache.keys.first;
      final eldest = _snapshotCache.remove(eldestKey);
      eldest?.dispose();
    }
  }

  void _clearSnapshotState() {
    _hiddenWarmupPagesNotifier.value = const <int>{};
    _hiddenWarmupBoundaryKeys.clear();
    _jumpTransitionSnapshotNotifier.value = null;
    _snapshotFutures.clear();
    _disposeAllSnapshots();
  }

  void _disposeAllSnapshots() {
    for (final image in _snapshotCache.values) {
      image.dispose();
    }
    _snapshotCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    final sw = PerfLogger.startTimer();
    // If we are in an immersive mode, we want the content to be truly full-screen
    // and not be pushed down by the status bar or up by the navigation bar,
    // even if the OS hasn't fully hidden them yet (which avoids the visual gap).
    final bool isImmersive =
        widget.preferredSystemUiMode == SystemUiMode.immersive ||
        widget.preferredSystemUiMode == SystemUiMode.immersiveSticky;
    final padding = _stableQuranPaddingFor(
      MediaQuery.viewPaddingOf(context),
      isImmersive: isImmersive,
    );

    final scaffold = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.dark,
          // Hide bars if immersive
          systemNavigationBarContrastEnforced: !isImmersive,
          systemStatusBarContrastEnforced: !isImmersive,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(padding: padding, viewPadding: padding),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: padding.top,
                    bottom: padding.bottom,
                    left: padding.left,
                    right: padding.right,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ValueListenableBuilder<Set<int>>(
                        valueListenable: _hiddenWarmupPagesNotifier,
                        builder: (context, pageNumbers, _) {
                          if (pageNumbers.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          // Push the warmup subtree off-screen so it is fully painted
                          // (raster layer exists — required for toImage()) but never
                          // composited into the visible viewport.
                          //
                          // Offstage was previously used here but skips painting
                          // entirely, causing toImage() to crash with a null layer.
                          // Transform.translate with a large Y offset keeps the full
                          // render pipeline running while ensuring the content is
                          // outside the physical screen bounds.
                          return Transform.translate(
                            offset: const Offset(0, 100000),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                for (final pageNumber in pageNumbers)
                                  Positioned.fill(
                                    child: RepaintBoundary(
                                      key: _hiddenWarmupBoundaryKeys
                                          .putIfAbsent(
                                            pageNumber,
                                            GlobalKey.new,
                                          ),
                                      child: QuranImagePage(
                                        key: ValueKey<String>(
                                          'warmup:$pageNumber',
                                        ),
                                        pageNumber: pageNumber,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      QuranReaderViewport(
                        pageController: _pageController,
                        onToggleNavigation: _toggleNavigation,
                        onShowNavigation: _showNavigation,
                        onPageChanged: _onReaderPageChanged,
                      ),
                      ValueListenableBuilder<_JumpTransitionSnapshot?>(
                        valueListenable: _jumpTransitionSnapshotNotifier,
                        builder: (context, snapshot, _) {
                          if (snapshot == null) {
                            return const SizedBox.shrink();
                          }
                          return Positioned.fill(
                            child: IgnorePointer(
                              child: RawImage(
                                key: ValueKey<String>(
                                  'jump-transition:${snapshot.pageNumber}',
                                ),
                                image: snapshot.image,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PremiumNavigationOverlay(
              previewStateListenable: _previewPageStateNotifier,
              onPreviewPageChanged: _updatePreviewPage,
              onPageNavigationRequested: _navigateToPage,
              onPreviousPageRequested: _navigateToPreviousPage,
              onNextPageRequested: _navigateToNextPage,
              onInteractionStart: _onNavigationInteractionStarted,
              onInteractionEnd: _onNavigationInteractionEnded,
              onShareRequested: widget.onShareRequested != null
                  ? () => widget.onShareRequested!(_lastSettledPageIndex + 1)
                  : null,
            ),
          ],
        ),
      ),
    );

    PerfLogger.logElapsed(sw, widgetName: 'QuranImageReader', message: 'build');

    return Directionality(textDirection: TextDirection.rtl, child: scaffold);
  }
}

EdgeInsets _stableQuranPaddingFor(
  EdgeInsets viewPadding, {
  required bool isImmersive,
}) {
  if (!isImmersive) {
    return viewPadding;
  }
  return EdgeInsets.fromLTRB(
    viewPadding.left,
    viewPadding.top,
    viewPadding.right,
    0,
  );
}

class _JumpTransitionSnapshot {
  const _JumpTransitionSnapshot({
    required this.pageNumber,
    required this.image,
  });

  final int pageNumber;
  final ui.Image image;
}
