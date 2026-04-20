import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/page_navigation_bar.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/surah_index_sheet.dart';
import 'package:tilawa/features/share/presentation/cubit/share_cubit.dart';
import 'package:tilawa/features/share/presentation/screens/screenshot_composer_screen.dart';
import 'package:tilawa/features/share/presentation/widgets/share_options_sheet.dart';
import 'package:tilawa_core/logger.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../core/presentation/cubit/ui_visibility_cubit.dart';
import '../../../../core/utils/performance_monitor.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart'
    show AudioPlayerBloc;
import '../bloc/quran_font_loader_bloc.dart';
import '../bloc/quran_reader_bloc.dart';
import '../utils/reader_side_effects_observer.dart';

/// Screen for reading Quran text in a page-by-page Mushaf view.
class QuranReaderScreen extends StatelessWidget {
  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
    this.initialPageNumber,
    this.initialPreparedWindow,
  });

  final int surahNumber;
  final int? initialAyah;
  final int? initialPageNumber;

  /// Pre-computed page window passed from [QuranFontLoaderScreen].
  /// When provided, [_ReaderScaffoldState] publishes it synchronously in
  /// [initState] — no async preparation on first mount, no loading gate.
  final PreparedQuranPageWindow? initialPreparedWindow;

  @override
  Widget build(BuildContext context) {
    return _ReaderScaffold(
      surahNumber: surahNumber,
      initialAyah: initialAyah,
      initialPageNumber: initialPageNumber,
      initialPreparedWindow: initialPreparedWindow,
    );
  }
}

class _ReaderScaffold extends StatefulWidget {
  const _ReaderScaffold({
    required this.surahNumber,
    this.initialAyah,
    this.initialPageNumber,
    this.initialPreparedWindow,
  });

  final int surahNumber;
  final int? initialAyah;
  final int? initialPageNumber;
  final PreparedQuranPageWindow? initialPreparedWindow;

  @override
  State<_ReaderScaffold> createState() => _ReaderScaffoldState();
}

class _ReaderScaffoldState extends State<_ReaderScaffold>
    with WidgetsBindingObserver, ReaderSideEffectsObserver {
  // Ghost/offstage page warming can introduce raster spikes on mid-range
  // devices during rapid swipes. Keep disabled until we add adaptive gating.
  static const bool _enableGhostWarming = false;
  static final StandardQuranLayoutStrategy _pagePreparationLayoutStrategy =
      StandardQuranLayoutStrategy();
  static const int _visiblePageWindowRadius = 2;

  late final PageController _pageController;
  late final ValueNotifier<int> _currentPageNotifier;
  late final ValueNotifier<double> _cacheExtentNotifier;
  late final ValueNotifier<PreparedQuranPageWindow?> _preparedWindowNotifier;
  late final ValueNotifier<bool> _showOverlaysNotifier;
  late final ValueNotifier<_WarmingState> _warmingNotifier;
  late final UiVisibilityCubit _uiVisibilityCubit;
  late final GlobalKey _screenshotBoundaryKey;
  bool _didInitDependencies = false;
  bool _isProgrammaticJump = false;
  bool _isInteracting = false;
  Timer? _resumeWarmingTimer;
  bool _allowSystemPop = false;
  // Convenience getters — read-only access to warming notifier fields.
  bool get _isWarming => _warmingNotifier.value.isWarming;
  int get _warmingPageNumber => _warmingNotifier.value.pageNumber;
  final List<int> _warmingQueue = [];
  Timer? _warmingRotationTimer;
  Timer? _warmingCooldownTimer;
  Timer? _settlementTimer;
  Timer? _cacheExtentRestoreTimer;
  Future<void>? _pendingExitPreparation;

  static const _headerFontSizeMultiplier = 0.57;
  static const double _interactiveCacheExtent = 0;
  double _settledCacheExtent = 0;
  double? _lastPreparedViewportWidth;
  Orientation? _lastPreparedOrientation;
  Future<void>? _pendingWindowPreparation;
  int? _pendingWindowCenterPage;
  bool _didReportInitialPreparedWindow = false;
  late final ValueNotifier<bool> _isScrollingNotifier;

  ThemeData? _cachedThemeData;
  QuranReaderTheme? _cachedReaderTheme;
  SystemUiOverlayStyle? _cachedReaderSystemUiStyle;
  SystemUiOverlayStyle? _cachedAppSystemUiStyle;

  @override
  void initState() {
    super.initState();
    _screenshotBoundaryKey = GlobalKey();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _uiVisibilityCubit = context.read<UiVisibilityCubit>();
    _uiVisibilityCubit.show();
    _showOverlaysNotifier = ValueNotifier<bool>(!_uiVisibilityCubit.state);
    _isScrollingNotifier = ValueNotifier<bool>(false);

    initSideEffects();
    // precacheQuranAssets moved to didChangeDependencies to avoid MediaQuery warning

    final bloc = context.read<QuranReaderBloc>();
    final int syncPage = _resolveInitialPage(bloc);
    _currentPageNotifier = ValueNotifier<int>(syncPage);
    // Start with zero cache extent so the first visible frame lays out only
    // the current page. We restore the settled extent once the local window
    // is fully prepared.
    // Keep cacheExtent at zero. The reader already prepares neighbor pages
    // explicitly, and restoring a full-viewport cacheExtent causes offscreen
    // pages to be rasterized eagerly, which shows up as raster-thread jank.
    _settledCacheExtent = 0.0;
    _cacheExtentNotifier = ValueNotifier<double>(_interactiveCacheExtent);
    // Publish the pre-computed window immediately if the caller provided one.
    // This means PageContent receives a PreparedQuranPage on its very first
    // build — zero async work, zero loading gate.
    _preparedWindowNotifier = ValueNotifier<PreparedQuranPageWindow?>(
      widget.initialPreparedWindow,
    );
    if (widget.initialPreparedWindow != null) {
      _didReportInitialPreparedWindow = true;
    }
    _warmingNotifier = ValueNotifier<_WarmingState>(const _WarmingState());
    _pageController = PageController(initialPage: syncPage - 1);
    QuranFontService.instance.addListener(_handleFontRegistryChanged);

    if (widget.surahNumber > 0 &&
        bloc.state.currentSurah?.number != widget.surahNumber) {
      bloc.add(
        QuranReaderEvent.loadSurah(widget.surahNumber, loadStartPage: false),
      );
    }
  }

  int _resolveInitialPage(QuranReaderBloc bloc) {
    final int explicitInitialPage = widget.initialPageNumber ?? 0;
    if (explicitInitialPage > 0) return explicitInitialPage;
    final int inMemoryPage = bloc.state.currentPage?.pageNumber ?? 0;
    if (inMemoryPage > 0) return inMemoryPage;
    final int hintedPage = bloc.state.initialPageHint ?? 0;
    if (hintedPage > 0) return hintedPage;
    if (widget.surahNumber > 0) return getPageNumber(widget.surahNumber, 1);
    return 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final incomingReaderTheme = QuranReaderTheme.of(context);
    final incomingTheme = Theme.of(context);
    final Orientation currentOrientation = MediaQuery.orientationOf(context);
    final double viewportWidth = context.resolveContentWidth(
      TilawaContentKind.reader,
    );
    final bool didViewportChange =
        _lastPreparedViewportWidth == null ||
        (_lastPreparedViewportWidth! - viewportWidth).abs() > 0.5;
    final bool didOrientationChange =
        _lastPreparedOrientation != currentOrientation;
    final bool didThemeChange = _cachedReaderTheme != incomingReaderTheme;
    _settledCacheExtent = 0.0;
    if (!_isInteracting &&
        _hasPreparedCoverageFor(_currentPageNotifier.value) &&
        (_cacheExtentNotifier.value - _settledCacheExtent).abs() > 0.5) {
      _cacheExtentNotifier.value = _settledCacheExtent;
    }
    if (_cachedReaderTheme != incomingReaderTheme || _cachedThemeData == null) {
      _cachedReaderTheme = incomingReaderTheme;
      _cachedThemeData = incomingTheme.copyWith(
        scaffoldBackgroundColor: incomingReaderTheme.pageBackground,
      );
      // Precache assets once theme and media query info is stable
      unawaited(QuranFontService.precacheQuranAssets(context));
    }
    if (didViewportChange || didOrientationChange || didThemeChange) {
      _lastPreparedViewportWidth = viewportWidth;
      _lastPreparedOrientation = currentOrientation;
      QuranPagePreparationService.instance.clear();
    }
    _cachedAppSystemUiStyle = _buildAppSystemUiOverlayStyle(incomingTheme);
    _cachedReaderSystemUiStyle = _buildReaderSystemUiOverlayStyle(
      incomingReaderTheme,
    );
    if (!_didInitDependencies) {
      _didInitDependencies = true;
      _updateSystemUiConfig(_uiVisibilityCubit.state);
    }
    _preparePageWindowSync(_currentPageNotifier.value);
    if (!_hasPreparedCoverageFor(_currentPageNotifier.value)) {
      _scheduleVisibleWindowPreparation(_currentPageNotifier.value);
    } else {
      _restoreCacheExtentIfReady();
    }
  }

  @override
  void dispose() {
    _debugLog(() => '[READER_EXIT] dispose');
    _warmingCooldownTimer?.cancel();
    _isScrollingNotifier.dispose();
    PageSnapshotService.instance.clear();
    _settlementTimer?.cancel();
    _cacheExtentRestoreTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    QuranFontService.instance.removeListener(_handleFontRegistryChanged);
    _pageController.dispose();
    _currentPageNotifier.dispose();
    _cacheExtentNotifier.dispose();
    _preparedWindowNotifier.dispose();
    _showOverlaysNotifier.dispose();
    _warmingNotifier.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (_pendingExitPreparation == null) {
      _debugLog(() => '[READER_EXIT] dispose fallback restore');
      unawaited(_restoreAppSystemUiMode());
    }
    _uiVisibilityCubit.show();
    disposeSideEffects();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateSystemUiConfig(_uiVisibilityCubit.state);
      onResumedSideEffects();
    } else if (state == AppLifecycleState.paused) {
      onPausedSideEffects();
    }
  }

  void _updateSystemUiConfig(bool isVisible) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      _cachedReaderSystemUiStyle ?? const SystemUiOverlayStyle(),
    );
  }

  SystemUiOverlayStyle _buildReaderSystemUiOverlayStyle(
    QuranReaderTheme readerTheme,
  ) {
    return SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000),
      statusBarIconBrightness: readerTheme.statusBarIconBrightness,
      statusBarBrightness: readerTheme.statusBarBrightness,
      systemNavigationBarColor: const Color(0x00000000),
      systemNavigationBarDividerColor: const Color(0x00000000),
      systemNavigationBarIconBrightness: readerTheme.statusBarIconBrightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }

  SystemUiOverlayStyle _buildAppSystemUiOverlayStyle(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Brightness iconBrightness = isDark
        ? Brightness.light
        : Brightness.dark;
    final Brightness statusBarBrightness = isDark
        ? Brightness.dark
        : Brightness.light;

    return SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000),
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: statusBarBrightness,
      systemNavigationBarColor: const Color(0x00000000),
      systemNavigationBarDividerColor: const Color(0x00000000),
      systemNavigationBarIconBrightness: iconBrightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }

  Future<void> _prepareForExit() {
    return _pendingExitPreparation ??= _restoreAppSystemUiMode(
      waitForSystemUiFrame: true,
    );
  }

  Future<void> _handleExitRequest() async {
    if (_allowSystemPop) return;
    await _prepareForExit();
    if (!mounted) return;
    setState(() => _allowSystemPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).maybePop();
    });
  }

  Future<void> _restoreAppSystemUiMode({
    bool waitForSystemUiFrame = false,
  }) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      _cachedAppSystemUiStyle ?? const SystemUiOverlayStyle(),
    );
    if (waitForSystemUiFrame) {
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowSystemPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _allowSystemPop) return;
        unawaited(_handleExitRequest());
      },
      child: Theme(
        data: _cachedThemeData!,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: _cachedReaderSystemUiStyle!,
          child: _ReaderListener(
            isProgrammaticJump: _isProgrammaticJump,
            syncToPage: _syncToPage,
            updateSystemUiConfig: _updateSystemUiConfig,
            showOverlaysNotifier: _showOverlaysNotifier,
            child: _ReaderStack(
              pageController: _pageController,
              currentPageNotifier: _currentPageNotifier,
              cacheExtentNotifier: _cacheExtentNotifier,
              preparedWindowNotifier: _preparedWindowNotifier,
              showOverlaysNotifier: _showOverlaysNotifier,
              screenshotBoundaryKey: _screenshotBoundaryKey,
              warmingNotifier: _warmingNotifier,
              headerFontSizeMultiplier: _headerFontSizeMultiplier,
              readerTheme: _cachedReaderTheme!,
              onPageChanged: _handleOnPageChanged,
              getSurahName: _getSurahName,
              jumpToSurah: _jumpToSurah,
              handleShowIndex: _handleShowIndex,
              showSurahIndex: _showSurahIndex,
              showShareOptions: _showShareOptions,
              jumpToPage: _jumpToPage,
              onWarming: _handleOnWarming,
              onPointerDown: _pauseWarming,
              onPointerUp: _resumeWarming,
              isScrollingNotifier: _isScrollingNotifier,
            ),
          ),
        ),
      ),
    );
  }

  List<int> _orderedPageWindow(int centerPage) {
    final List<int> pages = [centerPage];
    for (int distance = 1; distance <= _visiblePageWindowRadius; distance++) {
      final int next = centerPage + distance;
      final int previous = centerPage - distance;
      if (next <= QuranConstants.totalPagesCount) pages.add(next);
      if (previous >= 1) pages.add(previous);
    }
    return pages;
  }

  bool _hasPreparedCoverageFor(int centerPage) {
    final PreparedQuranPageWindow? window = _preparedWindowNotifier.value;
    if (window == null || window.centerPage != centerPage) {
      return false;
    }
    if (!QuranFontService.instance.isQuranDataLoaded) {
      return false;
    }

    for (final int pageNumber in _orderedPageWindow(centerPage)) {
      if (window.preparedPageFor(pageNumber) == null) {
        return false;
      }
    }
    return true;
  }

  void _restoreCacheExtentIfReady() {
    if (!_isInteracting &&
        _hasPreparedCoverageFor(_currentPageNotifier.value) &&
        (_cacheExtentNotifier.value - _settledCacheExtent).abs() > 0.5) {
      _cacheExtentNotifier.value = _settledCacheExtent;
      if (!kReleaseMode) {
        logger.i(
          '[READER_CACHE] restore cacheExtent=$_settledCacheExtent (prepared coverage)',
        );
      }
    }
  }

  Future<void> _yieldForNeighborPreparation() {
    // `endOfFrame` can stall indefinitely once the current page is stable and
    // no new frame is scheduled. A small timed yield still gives animation
    // frames breathing room while ensuring neighbor preparation continues when
    // the app is otherwise idle.
    return Future<void>.delayed(const Duration(milliseconds: 16));
  }

  PreparedQuranPage? _preparePageContentSync(int pageNumber) {
    if (!mounted || _cachedReaderTheme == null) return null;
    if (!QuranFontService.instance.isQuranDataLoaded) return null;
    if (!QuranFontService.instance.isFontLoaded(pageNumber)) return null;

    final Size viewportSize = MediaQuery.sizeOf(context);
    final QuranLayoutMetrics metrics = _pagePreparationLayoutStrategy
        .calculateMetrics(
          context,
          BoxConstraints(
            maxWidth: viewportSize.width,
            maxHeight: viewportSize.height,
          ),
          pageNumber,
        );

    QuranFontService.instance.setRenderFontSize(metrics.fontSize);
    final int tPrep = DateTime.now().millisecondsSinceEpoch;
    final PreparedQuranPage page = QuranPagePreparationService.instance
        .preparePage(
          pageNumber: pageNumber,
          metrics: metrics,
          viewportWidth: viewportSize.width,
          textColor: _cachedReaderTheme!.textColor,
        );

    // Warm the glyph atlas in the background for the newly prepared page.
    // This is critical for reducing first-frame raster cost on pages that
    // are rendered for the first time.
    QuranFontService.instance.warmPreparedPage(pageNumber, page);

    if (!kReleaseMode) {
      final int prepMs = DateTime.now().millisecondsSinceEpoch - tPrep;
      // > 0ms means cache miss (TextPainter.layout() ran); 0ms = cache hit.
      if (prepMs > 8) {
        logger.i(
          '[PERF][PAGE] ⚠ p$pageNumber prepare=${prepMs}ms exceeds 8ms budget (cold)',
        );
      } else if (prepMs > 0) {
        logger.i('[PERF][PAGE] p$pageNumber prepare=${prepMs}ms (cold)');
      }
      // prepMs == 0 → cache hit, not logged (zero-cost, nothing to flag)
    }
    return page;
  }

  PreparedQuranPageWindow? _preparePageWindowSync(int centerPage) {
    if (!mounted) return null;
    final PreparedQuranPageWindow? previousWindow =
        _preparedWindowNotifier.value;
    final List<int> windowPages = _orderedPageWindow(centerPage);
    final Set<int> desiredPageNumbers = windowPages.toSet();
    final Set<int> retainedPageNumbers = <int>{
      ...desiredPageNumbers,
      if (previousWindow != null) ...previousWindow.pageNumbers,
    };
    final Map<int, PreparedQuranPage> preparedPages = <int, PreparedQuranPage>{
      if (previousWindow != null)
        for (final MapEntry<int, PreparedQuranPage> entry
            in previousWindow.preparedPages.entries)
          if (retainedPageNumbers.contains(entry.key)) entry.key: entry.value,
    };

    for (final int pageNumber in windowPages) {
      final PreparedQuranPage? preparedPage = _preparePageContentSync(
        pageNumber,
      );
      if (preparedPage == null) {
        // Center page is mandatory — bail entirely if it can't be prepared
        // (font not loaded, data not ready, etc.). Neighbor pages are optional:
        // skip them here and let _prepareVisibleWindow fill them in later.
        if (pageNumber == centerPage) return null;
        continue;
      }
      preparedPages[pageNumber] = preparedPage;
    }

    final PreparedQuranPageWindow nextWindow = PreparedQuranPageWindow(
      centerPage: centerPage,
      radius: _visiblePageWindowRadius,
      visiblePageNumbers: preparedPages.keys.toSet(),
      preparedPages: preparedPages,
    );
    final bool didWindowChange =
        previousWindow == null ||
        previousWindow.centerPage != nextWindow.centerPage ||
        previousWindow.radius != nextWindow.radius ||
        !setEquals(previousWindow.pageNumbers, nextWindow.pageNumbers) ||
        !setEquals(
          previousWindow.preparedPages.keys.toSet(),
          nextWindow.preparedPages.keys.toSet(),
        ) ||
        nextWindow.preparedPages.entries.any(
          (entry) =>
              !identical(previousWindow.preparedPages[entry.key], entry.value),
        );
    if (didWindowChange) {
      _preparedWindowNotifier.value = nextWindow;
    }
    if (!_didReportInitialPreparedWindow &&
        nextWindow.preparedPageFor(_currentPageNotifier.value) != null) {
      _didReportInitialPreparedWindow = true;
    }
    _restoreCacheExtentIfReady();
    return nextWindow;
  }

  Future<void> _prepareVisibleWindow(int centerPage) async {
    if (!mounted) return;
    final int tWindowStart = DateTime.now().millisecondsSinceEpoch;
    if (!kReleaseMode) {
      logger.i('[PERF][WINDOW] start p$centerPage');
    }
    final QuranFontLoaderBloc fontLoaderBloc = context
        .read<QuranFontLoaderBloc>();
    await Future.wait([
      QuranFontService.instance.ensureQuranDataLoaded(),
      fontLoaderBloc.ensureFontReady(centerPage),
    ]);
    if (!mounted) return;
    if (!kReleaseMode) {
      logger.i(
        '[PERF][WINDOW] center font+data ready p$centerPage | ${DateTime.now().millisecondsSinceEpoch - tWindowStart}ms',
      );
    }
    if (_pendingWindowCenterPage != centerPage) return;

    if (_preparedWindowNotifier.value?.preparedPageFor(centerPage) == null) {
      _prepareAndPublishPage(centerPage, windowCenterPage: centerPage);
      if (!mounted || _pendingWindowCenterPage != centerPage) return;
    }

    final List<int> windowPages = _orderedPageWindow(centerPage);
    for (final int pageNumber in windowPages) {
      if (pageNumber == centerPage) continue;
      if (!mounted || _pendingWindowCenterPage != centerPage) return;
      if (_preparedWindowNotifier.value?.preparedPageFor(pageNumber) != null) {
        continue;
      }

      await fontLoaderBloc.ensureFontReady(pageNumber);
      if (!mounted || _pendingWindowCenterPage != centerPage) return;
      await _yieldForNeighborPreparation();
      if (!mounted || _pendingWindowCenterPage != centerPage) return;
      _prepareAndPublishPage(pageNumber, windowCenterPage: centerPage);
    }

    if (mounted && _pendingWindowCenterPage == centerPage) {
      _preparePageWindowSync(centerPage);
      if (!kReleaseMode) {
        logger.i(
          '[PERF][WINDOW] complete p$centerPage | total=${DateTime.now().millisecondsSinceEpoch - tWindowStart}ms',
        );
      }
    }
  }

  /// Prepares [pageNumber] via [QuranPagePreparationService] and immediately
  /// publishes an updated [PreparedQuranPageWindow] so [PageContent] can render
  /// without waiting for the full window to be complete.
  ///
  /// [windowCenterPage] is the center page of the window this preparation
  /// belongs to — passed explicitly to avoid reading the stale
  /// [_currentPageNotifier] value after an async gap.
  void _prepareAndPublishPage(int pageNumber, {required int windowCenterPage}) {
    if (!mounted) return;
    final PreparedQuranPage? preparedPage = _preparePageContentSync(pageNumber);
    if (preparedPage == null) return;

    final PreparedQuranPageWindow? previousWindow =
        _preparedWindowNotifier.value;
    final List<int> windowPages = _orderedPageWindow(windowCenterPage);
    final Set<int> desiredPageNumbers = windowPages.toSet();

    final Map<int, PreparedQuranPage> preparedPages = <int, PreparedQuranPage>{
      if (previousWindow != null)
        for (final MapEntry<int, PreparedQuranPage> entry
            in previousWindow.preparedPages.entries)
          if (desiredPageNumbers.contains(entry.key)) entry.key: entry.value,
      pageNumber: preparedPage,
    };

    _preparedWindowNotifier.value = PreparedQuranPageWindow(
      centerPage: windowCenterPage,
      radius: _visiblePageWindowRadius,
      visiblePageNumbers: preparedPages.keys.toSet(),
      preparedPages: preparedPages,
    );

    if (!_didReportInitialPreparedWindow &&
        preparedPages.containsKey(_currentPageNotifier.value)) {
      _didReportInitialPreparedWindow = true;
    }
    _restoreCacheExtentIfReady();
  }

  void _scheduleVisibleWindowPreparation(int centerPage) {
    if (!mounted) return;
    if (_pendingWindowPreparation != null &&
        _pendingWindowCenterPage == centerPage) {
      return;
    }

    _pendingWindowCenterPage = centerPage;
    late final Future<void> future;
    future = _prepareVisibleWindow(centerPage).whenComplete(() {
      if (identical(_pendingWindowPreparation, future)) {
        _pendingWindowPreparation = null;
        _pendingWindowCenterPage = null;
      }
    });
    _pendingWindowPreparation = future;
    unawaited(future);
  }

  void _handleFontRegistryChanged() {
    if (!mounted) return;
    final int currentPage = _currentPageNotifier.value;
    if (_hasPreparedCoverageFor(currentPage)) {
      _restoreCacheExtentIfReady();
      return;
    }
    _scheduleVisibleWindowPreparation(currentPage);
  }

  void _pauseWarming() {
    _resumeWarmingTimer?.cancel();
    _cacheExtentRestoreTimer?.cancel();
    _isInteracting = true;
    _isScrollingNotifier.value = true;

    // Phase 9: Pause global background warming to ensure the UI thread and Raster thread
    // are dedicated entirely to the user's current interaction.
    context.read<QuranFontLoaderBloc>().pauseBackgroundWarmUp();

    // Reduce adjacent-page prebuild work while the user is actively dragging.
    // This frees raster budget for the current transition frame.
    if (!kReleaseMode) {
      if (_cacheExtentNotifier.value != _interactiveCacheExtent) {
        _cacheExtentNotifier.value = _interactiveCacheExtent;
        logger.i(
          '[READER_CACHE] set cacheExtent=$_interactiveCacheExtent (interaction start)',
        );
      }
    }
    _hotPathLog(() => '[GHOST] Pausing all warming');
    _warmingRotationTimer?.cancel();
    _warmingRotationTimer = null;
    _settlementTimer?.cancel();
  }

  void _resumeWarming() {
    _resumeWarmingTimer?.cancel();
    // Increase debounce to 500ms to ensure the UI has completely settled
    // and the Raster thread is free before background tasks resume.
    _resumeWarmingTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _isInteracting = false;
      _isScrollingNotifier.value = false;
      _cacheExtentRestoreTimer?.cancel();

      // Resume global background warming only after the interaction has settled.
      context.read<QuranFontLoaderBloc>().resumeBackgroundWarmUp();

      // Restore cache extent only after interaction settles to avoid
      // raster spikes from neighboring page builds during active swipe.
      _cacheExtentRestoreTimer = Timer(const Duration(milliseconds: 120), () {
        if (!mounted || _isInteracting) return;
        _restoreCacheExtentIfReady();
      });
      _hotPathLog(() => '[GHOST] Resuming background warming');
      if (_warmingQueue.isNotEmpty) {
        _startWarmingRotation();
      }
    });
  }

  void _handleOnWarming(int pageNumber) {
    if (!_enableGhostWarming) return;
    if (_isInteracting) {
      // Completely ignore warming requests while the user is actively
      // interacting with the slider or page view. This prevents the
      // font engine from becoming saturated during high-frequency drags.
      return;
    }

    // If the slider is hovering current page, we can still warm neighbors
    final int current = _currentPageNotifier.value;
    final int lastWarmed = _warmingQueue.isEmpty
        ? _warmingPageNumber
        : _warmingQueue.last;

    // Determine travel direction:
    // If pageNumber is different from current, user is moving toward pageNumber.
    // Otherwise, assume direction based on last warmed page relative to current.
    int direction = (pageNumber > current)
        ? 1
        : (pageNumber < current ? -1 : (pageNumber >= lastWarmed ? 1 : -1));

    // Generate a window starting from the target page + next 2 neighbors.
    // If pageNumber is current, start from neighbors.
    final List<int> pagesToWarm = [];
    if (pageNumber != current) {
      pagesToWarm.add(pageNumber);
    }
    pagesToWarm.add((pageNumber + direction).clamp(1, 604));
    pagesToWarm.add((pageNumber + (direction * 2)).clamp(1, 604));

    // Deduplicate and filter current
    final uniquePages = pagesToWarm.toSet().toList()
      ..removeWhere((p) => p == current);
    if (uniquePages.isEmpty) return;

    // Priority 1: Ensure fonts are registered in the engine's font manager.
    final fontLoader = context.read<QuranFontLoaderBloc>();
    for (final p in uniquePages) {
      unawaited(fontLoader.ensureFontReady(p));
    }

    // Priority 2: Force GPU rasterization by rotating through the pages in the ghost layer.
    _warmingQueue.clear();
    _warmingQueue.addAll(uniquePages);

    if (_warmingRotationTimer == null && !_isInteracting) {
      _startWarmingRotation();
    }

    _resetWarmingCooldown();
  }

  void _startWarmingRotation() {
    _warmingRotationTimer?.cancel();
    // Use a conservative interval (500ms) to ensure the GPU is not saturated
    // by concurrent PageContent builds.
    _warmingRotationTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (!mounted || _warmingQueue.isEmpty || !_isWarming) {
        timer.cancel();
        _warmingRotationTimer = null;
        return;
      }

      final int nextWarmingPage = _warmingQueue.removeAt(0);
      _hotPathLog(() => '[GHOST] Warming next page: $nextWarmingPage');

      _warmingNotifier.value = _warmingNotifier.value.copyWith(
        pageNumber: nextWarmingPage,
        isWarming: true,
      );

      if (_warmingQueue.isEmpty) {
        timer.cancel();
        _warmingRotationTimer = null;
      }
    });
  }

  void _resetWarmingCooldown() {
    _warmingCooldownTimer?.cancel();
    _warmingCooldownTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isWarming && !_isProgrammaticJump) {
        _warmingNotifier.value = _warmingNotifier.value.copyWith(
          isWarming: false,
        );
      }
    });
  }

  // ─── Lifecycle & Sync Logic ───────────────────────────────────────────────

  Future<void> _syncToPage(int pageNumber) async {
    PerformanceMonitor.instance.startEvent('PageSync:$pageNumber');

    // Skip if we are already on this page or the state is stale.
    if (pageNumber == _currentPageNotifier.value &&
        _pageController.hasClients &&
        (_pageController.page ?? _pageController.initialPage.toDouble())
                .round() ==
            pageNumber - 1) {
      PerformanceMonitor.instance.endEvent();
      return;
    }

    if (!mounted) {
      PerformanceMonitor.instance.endEvent();
      return;
    }

    final fontLoaderBloc = context.read<QuranFontLoaderBloc>();
    if (_currentPageNotifier.value != pageNumber) {
      _currentPageNotifier.value = pageNumber;
    }

    await Future.wait([
      QuranFontService.instance.ensureQuranDataLoaded(),
      fontLoaderBloc.ensureFontReady(pageNumber),
    ]);
    _preparePageWindowSync(pageNumber);
    _scheduleVisibleWindowPreparation(pageNumber);

    void jump() {
      if (!mounted || !_pageController.hasClients) return;
      if (!_pageController.position.isScrollingNotifier.value) {
        _pageController.jumpToPage(pageNumber - 1);
      }
      PerformanceMonitor.instance.endEvent();
    }

    if (_pageController.hasClients) {
      jump();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => jump());
    }
  }

  Future<void> _showShareOptions(int currentPage) async {
    final int t0 = DateTime.now().millisecondsSinceEpoch;
    const Duration previewCaptureDelay = Duration(milliseconds: 180);
    _hotPathLog(
      () => '[SHARE_OPEN] share button tapped | page=$currentPage | t=${t0}ms',
    );

    final pageData = getPageData(currentPage);
    final primarySurahNumber = pageData.first['surah']!;
    final primarySurahEntries = pageData
        .where((entry) => entry['surah'] == primarySurahNumber)
        .toList();
    final firstAyah = primarySurahEntries.first['start'] ?? 1;
    final lastAyah = primarySurahEntries.last['end'] ?? firstAyah;
    // Read context-dependent values before the async gap.
    final audioState = context.read<AudioPlayerBloc>().state;
    final reciterName = audioState.currentAudio?.artist ?? 'Al-Afasy';
    final shareCubit = context.read<ShareCubit>();
    final fontLoaderBloc = context.read<QuranFontLoaderBloc>();
    final navigator = Navigator.of(context);

    // Capture preview bytes concurrently with the route transition so the
    // push is not blocked by GPU readback + PNG encoding (~50–100ms on
    // mid-range devices). The backdrop accepts null and shows nothing until
    // the bytes arrive via the notifier.
    final previewNotifier = ValueNotifier<Uint8List?>(null);
    bool previewNotifierDisposed = false;
    unawaited(
      Future<void>.delayed(
        previewCaptureDelay,
      ).then((_) => _captureSharePreviewBytes()).then((bytes) {
        final int tPreview = DateTime.now().millisecondsSinceEpoch;
        _hotPathLog(
          () =>
              '[SHARE_OPEN] preview bytes ready | bytes=${bytes?.length ?? 0} | took=${tPreview - t0}ms',
        );
        if (!previewNotifierDisposed && bytes != null) {
          previewNotifier.value = bytes;
        }
      }),
    );

    _hotPathLog(
      () =>
          '[SHARE_OPEN] pushing route | took=${DateTime.now().millisecondsSinceEpoch - t0}ms before push',
    );
    fontLoaderBloc.pauseBackgroundWarmUp();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ShareOptionsSheet(
          surahNumber: primarySurahNumber,
          pageNumber: currentPage,
          onShareScreenshot: () {
            navigator.push(
              ScreenshotComposerScreen.route(
                cubit: shareCubit,
                surahNumber: primarySurahNumber,
                currentPage: currentPage,
                initialFromAyah: firstAyah,
                initialToAyah: lastAyah,
                reciterName: reciterName,
                readerBoundaryKey: _screenshotBoundaryKey,
                readerPreviewBytesNotifier: previewNotifier,
              ),
            );
          },
          onShareVideoReel: () {
            // navigator.push(
            //   VideoReelComposerScreen.route(
            //     cubit: shareCubit,
            //     surahNumber: primarySurahNumber,
            //     currentPage: currentPage,
            //     initialFromAyah: firstAyah,
            //     initialToAyah: lastAyah,
            //     reciterName: reciterName,
            //     reciterServerUrl: serverUrl,
            //     readerBoundaryKey: _screenshotBoundaryKey,
            //     readerPreviewBytesNotifier: previewNotifier,
            //   ),
            // );
          },
        ),
      );
    } finally {
      fontLoaderBloc.resumeBackgroundWarmUp();
    }

    _hotPathLog(
      () =>
          '[SHARE_OPEN] share screen dismissed | total=${DateTime.now().millisecondsSinceEpoch - t0}ms',
    );
    previewNotifierDisposed = true;
    previewNotifier.dispose();
  }

  Future<Uint8List?> _captureSharePreviewBytes() async {
    final boundary =
        _screenshotBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;

    try {
      final image = await boundary.toImage(pixelRatio: 0.4);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  void _handleShowIndex() => _showSurahIndex();

  void _showSurahIndex() {
    // Pre-load fonts for all surah start pages so that any index jump is instant.
    unawaited(_prewarmSurahIndexFonts());
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => SurahIndexSheet(
        onSurahSelected: (surahNumber) =>
            Navigator.of(context).pop(surahNumber),
        onSurahTapped: (surahNumber) {
          final pageNumber = getPageNumber(surahNumber, 1);
          _handleOnWarming(pageNumber);
        },
      ),
    ).then((surahNumber) {
      if (surahNumber != null && mounted) {
        unawaited(_jumpToSurah(surahNumber));
      }
    });
  }

  Future<void> _prewarmSurahIndexFonts() async {
    if (!mounted) return;
    final fontLoaderBloc = context.read<QuranFontLoaderBloc>();
    // Collect unique page numbers for all 114 surah start pages.
    final Set<int> pages = {};
    for (int s = 1; s <= 114; s++) {
      pages.add(getPageNumber(s, 1));
    }
    final int tPrewarm = DateTime.now().millisecondsSinceEpoch;
    int loaded = 0;
    int alreadyLoaded = 0;
    _hotPathLog(
      () =>
          '[PREWARM] surah index prewarm START | ${pages.length} unique pages | t=${tPrewarm}ms',
    );
    // Load target fonts only (no neighbor debounce side effects).
    // Each call deduplicates if the font is already in the engine.
    for (final page in pages) {
      if (!mounted) return;
      final bool wasLoaded = fontLoaderBloc.isFontLoaded(page);
      await fontLoaderBloc.ensureFontReady(
        page,
        timeout: const Duration(seconds: 2),
      );
      if (wasLoaded) {
        alreadyLoaded++;
      } else {
        loaded++;
        _hotPathLog(
          () =>
              '[PREWARM] loaded page $page font | loaded=$loaded/${pages.length} | elapsed=${DateTime.now().millisecondsSinceEpoch - tPrewarm}ms',
        );
      }
    }
    _hotPathLog(
      () =>
          '[PREWARM] surah index prewarm DONE | newlyLoaded=$loaded alreadyCached=$alreadyLoaded | total=${DateTime.now().millisecondsSinceEpoch - tPrewarm}ms',
    );
  }

  void _handleOnPageChanged(int pageNumber) {
    _currentPageNotifier.value = pageNumber;
    if (_isProgrammaticJump) return;

    final fontLoaderBloc = context.read<QuranFontLoaderBloc>();

    // Pause background warming immediately to keep the frame budget clear for the animation
    fontLoaderBloc.pauseBackgroundWarmUp();

    // Synchronously update the window notifier so the center page is
    // available to PageContent._handleWindowChanged before the next frame.
    // If the center page font is loaded and cached this is a sub-ms LRU hit.
    // The async _scheduleVisibleWindowPreparation below handles neighbors.
    _preparePageWindowSync(pageNumber);

    _scheduleVisibleWindowPreparation(pageNumber);

    // Defer the heavy "Window Loading" (neighbors) until we are reasonably
    // sure the user has settled on this page.
    _settlementTimer?.cancel();
    _settlementTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        _onPageSettled(pageNumber);
      }
    });

    if (_enableGhostWarming) {
      _warmingNotifier.value = _warmingNotifier.value.copyWith(
        pageNumber: pageNumber,
        isWarming: true,
        isSettled: false,
      );
    }
  }

  void _onPageSettled(int pageNumber) {
    _warmingNotifier.value = _warmingNotifier.value.copyWith(isSettled: true);
    final bloc = context.read<QuranReaderBloc>();
    final fontLoaderBloc = context.read<QuranFontLoaderBloc>();

    if (bloc.state.currentPage?.pageNumber != pageNumber) {
      bloc.add(QuranReaderEvent.loadPage(pageNumber));
    }

    // Notify font service of the new location to re-prioritize the warming buffer
    fontLoaderBloc.add(QuranFontLoaderEvent.updateCurrentPage(pageNumber));

    unawaited(
      (_pendingWindowPreparation ?? Future<void>.value()).whenComplete(() {
        fontLoaderBloc.resumeBackgroundWarmUp();

        // Proactively warm neighbor pages in the ghost layer after current page is ready
        if (mounted && _enableGhostWarming) {
          _handleOnWarming(pageNumber);
        }
      }),
    );
  }

  String _getSurahName(int surahNumber) {
    return context.l10n.localeName == 'ar'
        ? getSurahNameArabic(surahNumber)
        : getSurahNameEnglish(surahNumber);
  }

  Future<void> _jumpToSurah(int surahNumber) {
    return _jumpToPage(getPageNumber(surahNumber, 1));
  }

  Future<void> _jumpToPage(int pageNumber) async {
    _isProgrammaticJump = true;

    if (!mounted) {
      _isProgrammaticJump = false;
      return;
    }

    final fontLoaderBloc = context.read<QuranFontLoaderBloc>();
    final int currentPage = _currentPageNotifier.value;

    // Pause global warming to ensure the jump transition is as smooth as possible.
    fontLoaderBloc.pauseBackgroundWarmUp();

    await Future.wait([
      QuranFontService.instance.ensureQuranDataLoaded(),
      fontLoaderBloc.ensureFontReady(pageNumber),
    ]);
    _preparePageWindowSync(pageNumber);
    _scheduleVisibleWindowPreparation(pageNumber);

    if (!mounted) {
      _isProgrammaticJump = false;
      return;
    }

    fontLoaderBloc.add(QuranFontLoaderEvent.updateCurrentPage(pageNumber));
    _currentPageNotifier.value = pageNumber;

    if (_pageController.hasClients) {
      final bool isDistant = (pageNumber - currentPage).abs() > 5;
      if (isDistant) {
        _cacheExtentNotifier.value = _interactiveCacheExtent;
      }

      _hotPathLog(() => '[JUMP] jumpToPage($pageNumber) fired');
      _pageController.jumpToPage(pageNumber - 1);

      if (isDistant && mounted) {
        Timer(const Duration(milliseconds: 400), () {
          if (mounted) {
            _hotPathLog(() => '[JUMP] cache restored for p$pageNumber');
            _restoreCacheExtentIfReady();
          }
        });
      }
    }

    if (!mounted) return;
    context.read<QuranReaderBloc>().add(QuranReaderEvent.loadPage(pageNumber));
    _pendingWindowPreparation = null;
    _pendingWindowCenterPage = null;

    Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        _isProgrammaticJump = false;
        // Resume background warming once the jump has settled.
        fontLoaderBloc.resumeBackgroundWarmUp();
      }
    });
  }
}

// ─── Component: Reader Listener ──────────────────────────────────────────────

class _ReaderListener extends StatelessWidget {
  const _ReaderListener({
    required this.child,
    required this.isProgrammaticJump,
    required this.syncToPage,
    required this.updateSystemUiConfig,
    required this.showOverlaysNotifier,
  });

  final Widget child;
  final bool isProgrammaticJump;
  final Future<void> Function(int) syncToPage;
  final void Function(bool) updateSystemUiConfig;
  final ValueNotifier<bool> showOverlaysNotifier;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UiVisibilityCubit, bool>(
          listener: (context, isVisible) {
            updateSystemUiConfig(isVisible);
            showOverlaysNotifier.value = !isVisible;
          },
        ),
        BlocListener<QuranReaderBloc, QuranReaderState>(
          listenWhen: (previous, current) =>
              previous.currentPage != current.currentPage &&
              current.currentPage != null,
          listener: (context, state) {
            if (isProgrammaticJump) return;
            unawaited(syncToPage(state.currentPage!.pageNumber));
          },
        ),
      ],
      child: child,
    );
  }
}

// ─── Component: Reader Stack ─────────────────────────────────────────────────

class _ReaderStack extends StatelessWidget {
  const _ReaderStack({
    required this.pageController,
    required this.currentPageNotifier,
    required this.cacheExtentNotifier,
    required this.preparedWindowNotifier,
    required this.showOverlaysNotifier,
    required this.screenshotBoundaryKey,
    required this.warmingNotifier,
    required this.headerFontSizeMultiplier,
    required this.readerTheme,
    required this.onPageChanged,
    required this.getSurahName,
    required this.jumpToSurah,
    required this.handleShowIndex,
    required this.showSurahIndex,
    required this.showShareOptions,
    required this.jumpToPage,
    this.onWarming,
    this.onPointerDown,
    this.onPointerUp,
    required this.isScrollingNotifier,
  });

  final PageController pageController;
  final ValueNotifier<int> currentPageNotifier;
  final ValueNotifier<double> cacheExtentNotifier;
  final ValueNotifier<PreparedQuranPageWindow?> preparedWindowNotifier;
  final ValueNotifier<bool> showOverlaysNotifier;
  final GlobalKey screenshotBoundaryKey;
  final ValueNotifier<_WarmingState> warmingNotifier;
  final double headerFontSizeMultiplier;
  final QuranReaderTheme readerTheme;
  final void Function(int) onPageChanged;
  final String Function(int) getSurahName;
  final Future<void> Function(int) jumpToSurah;
  final VoidCallback handleShowIndex;
  final VoidCallback showSurahIndex;
  final Future<void> Function(int) showShareOptions;
  final Future<void> Function(int) jumpToPage;
  final ValueChanged<int>? onWarming;
  final VoidCallback? onPointerDown;
  final VoidCallback? onPointerUp;
  final ValueNotifier<bool> isScrollingNotifier;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // RepaintBoundary isolates the warming ghost layer. Placed BEFORE the Scaffold
        // so it is rendered underneath the opaque page background, completely hidden from the user.
        RepaintBoundary(
          child: _WarmingLayer(
            warmingNotifier: warmingNotifier,
            readerTheme: readerTheme,
            headerFontSizeMultiplier: headerFontSizeMultiplier,
          ),
        ),
        Scaffold(
          key: const ValueKey('QuranReaderScaffold'),
          resizeToAvoidBottomInset: false,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: GestureDetector(
            onTap: () => context.read<UiVisibilityCubit>().toggle(),
            behavior: HitTestBehavior.opaque,
            child: Listener(
              onPointerDown: (_) => onPointerDown?.call(),
              onPointerUp: (_) => onPointerUp?.call(),
              child: TilawaContentBounds(
                kind: TilawaContentKind.reader,
                alignment: Alignment.center,
                // QuranPageView is always mounted. Each PageContent listens to
                // preparedWindowNotifier directly and rebuilds when its page
                // becomes ready. There is no gate here — gating on null caused
                // QuranPageView to unmount/remount, destroying PageContent state
                // and missing the first notifier fire after mount.
                child: QuranPageView(
                  controller: pageController,
                  currentPageListenable: currentPageNotifier,
                  cacheExtentListenable: cacheExtentNotifier,
                  preparedWindowListenable: preparedWindowNotifier,
                  pageBackgroundColor: readerTheme.pageBackground,
                  textColor: readerTheme.textColor,
                  headerImageFilter: readerTheme.headerImageFilter,
                  headerTextColor: readerTheme.headerTextColor,
                  headerFontSizeMultiplier: headerFontSizeMultiplier,
                  uiTextDirection: Directionality.of(context),
                  onPageChanged: onPageChanged,
                  onScrollStarted: onPointerDown,
                  onScrollEnded: onPointerUp,
                  juzLabel: context.l10n.juzPart,
                  hizbLabel: context.l10n.hizb,
                  surahNameBuilder: getSurahName,
                  onSurahSelected: (surahNumber) =>
                      unawaited(jumpToSurah(surahNumber)),
                  onShowIndex: handleShowIndex,
                  showOverlaysListenable: showOverlaysNotifier,
                  isScrollingListenable: isScrollingNotifier,
                  showShadows: false,
                ),
              ),
            ),
          ),
        ),
        _ReaderOverlay(
          showOverlaysNotifier: showOverlaysNotifier,
          currentPageNotifier: currentPageNotifier,
          jumpToPage: jumpToPage,
          showSurahIndex: showSurahIndex,
          showShareOptions: showShareOptions,
          onWarming: onWarming,
          onPointerDown: onPointerDown,
          onPointerUp: onPointerUp,
        ),
      ],
    );
  }
}

class _WarmingLayer extends StatelessWidget {
  const _WarmingLayer({
    required this.warmingNotifier,
    required this.readerTheme,
    required this.headerFontSizeMultiplier,
  });

  final ValueNotifier<_WarmingState> warmingNotifier;
  final QuranReaderTheme readerTheme;
  final double headerFontSizeMultiplier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_WarmingState>(
      valueListenable: warmingNotifier,
      builder: (context, warming, _) {
        if (!warming.isWarming) return const SizedBox.shrink();

        // Use Opacity 0.001 instead of Offstage. Offstage prevents painting,
        // which prevents RepaintBoundary.toImage() from capturing the texture.
        // Opacity(0.001) forces a paint operation while remaining virtually invisible,
        // allowing the background snapshotter to successfully extract the bitmap.
        return ExcludeSemantics(
          child: Opacity(
            opacity: 0.001,
            child: IgnorePointer(
              child: PageContent(
                key: ValueKey<String>('ghost_${warming.pageNumber}'),
                pageNumber: warming.pageNumber,
                textColor: readerTheme.textColor,
                headerImageFilter: readerTheme.headerImageFilter,
                headerTextColor: readerTheme.headerTextColor,
                headerFontSizeMultiplier: headerFontSizeMultiplier,
                pageBackgroundColor: readerTheme.pageBackground,
                uiTextDirection: Directionality.of(context),
                isWarming: true,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Component: Reader Overlay ───────────────────────────────────────────────

class _ReaderOverlay extends StatelessWidget {
  const _ReaderOverlay({
    required this.showOverlaysNotifier,
    required this.currentPageNotifier,
    required this.jumpToPage,
    required this.showSurahIndex,
    required this.showShareOptions,
    this.onWarming,
    this.onPointerDown,
    this.onPointerUp,
  });

  final ValueListenable<bool> showOverlaysNotifier;
  final ValueListenable<int> currentPageNotifier;
  final Future<void> Function(int) jumpToPage;
  final VoidCallback showSurahIndex;
  final Future<void> Function(int) showShareOptions;
  final ValueChanged<int>? onWarming;
  final VoidCallback? onPointerDown;
  final VoidCallback? onPointerUp;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: 0,
      right: 0,
      bottom: 0,
      child: ValueListenableBuilder<bool>(
        valueListenable: showOverlaysNotifier,
        builder: (context, showOverlays, child) {
          return AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            offset: showOverlays ? Offset.zero : const Offset(0, 1),
            child: child!,
          );
        },
        child: ValueListenableBuilder<int>(
          valueListenable: currentPageNotifier,
          builder: (context, currentPage, _) {
            return TilawaContentBounds(
              kind: TilawaContentKind.reader,
              alignment: Alignment.bottomCenter,
              child: PageNavigationBar(
                currentPage: currentPage,
                onPageChanged: (pageNumber) =>
                    unawaited(jumpToPage(pageNumber)),
                onShowIndex: showSurahIndex,
                onShare: () => showShareOptions(currentPage),
                onWarming: onWarming,
                onPointerDown: onPointerDown,
                onPointerUp: onPointerUp,
              ),
            );
          },
        ),
      ),
    );
  }
}

@immutable
class _WarmingState {
  const _WarmingState({
    this.isWarming = false,
    this.pageNumber = 1,
    this.isSettled = true,
  });
  final bool isWarming;
  final int pageNumber;
  final bool isSettled;

  _WarmingState copyWith({bool? isWarming, int? pageNumber, bool? isSettled}) =>
      _WarmingState(
        isWarming: isWarming ?? this.isWarming,
        pageNumber: pageNumber ?? this.pageNumber,
        isSettled: isSettled ?? this.isSettled,
      );
}

void _debugLog(String Function() messageBuilder) {
  if (!kReleaseMode) {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    logger.i('${messageBuilder()} | t=${timestamp}ms');
  }
}

void _hotPathLog(String Function() messageBuilder) {
  if (!kReleaseMode) {
    logger.i(messageBuilder());
  }
}

class _PerformanceBenchmarkOverlay extends StatefulWidget {
  const _PerformanceBenchmarkOverlay({
    required this.currentPageNotifier,
    required this.fontLoaderBloc,
  });

  final ValueListenable<int> currentPageNotifier;
  final QuranFontLoaderBloc fontLoaderBloc;

  @override
  State<_PerformanceBenchmarkOverlay> createState() =>
      __PerformanceBenchmarkOverlayState();
}

class __PerformanceBenchmarkOverlayState
    extends State<_PerformanceBenchmarkOverlay> {
  Timer? _timer;
  int _frameCount = 0;
  double _fps = 0;
  DateTime _lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          final now = DateTime.now();
          final duration = now.difference(_lastTick).inMilliseconds;
          if (duration > 0) {
            _fps = (_frameCount * 1000) / duration;
          }
          _frameCount = 0;
          _lastTick = now;
        });
      }
    });

    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    if (!mounted) return;
    _frameCount++;
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BENCHMARK',
            style: TextStyle(
              color: Colors.yellowAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _buildStat('FPS', _fps.toStringAsFixed(1)),
          ValueListenableBuilder<int>(
            valueListenable: widget.currentPageNotifier,
            builder: (context, page, _) {
              final isLoaded = widget.fontLoaderBloc.isFontLoaded(page);
              return _buildStat(
                'Font Ready',
                isLoaded ? 'YES' : 'NO',
                valueColor: isLoaded ? Colors.green : Colors.red,
              );
            },
          ),
          _buildStat(
            'Total Loaded',
            '${QuranFontService.instance.loadedCount}/604',
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.cyanAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
