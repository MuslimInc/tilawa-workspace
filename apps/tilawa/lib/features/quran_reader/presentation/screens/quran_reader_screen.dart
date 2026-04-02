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
import 'package:tilawa/features/share/presentation/screens/share_composer_screen.dart';

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
  });

  final int surahNumber;
  final int? initialAyah;
  final int? initialPageNumber;

  @override
  Widget build(BuildContext context) {
    return _ReaderScaffold(
      surahNumber: surahNumber,
      initialAyah: initialAyah,
      initialPageNumber: initialPageNumber,
    );
  }
}

class _ReaderScaffold extends StatefulWidget {
  const _ReaderScaffold({
    required this.surahNumber,
    this.initialAyah,
    this.initialPageNumber,
  });

  final int surahNumber;
  final int? initialAyah;
  final int? initialPageNumber;

  @override
  State<_ReaderScaffold> createState() => _ReaderScaffoldState();
}

class _ReaderScaffoldState extends State<_ReaderScaffold>
    with WidgetsBindingObserver, ReaderSideEffectsObserver {
  // Ghost/offstage page warming can introduce raster spikes on mid-range
  // devices during rapid swipes. Keep disabled until we add adaptive gating.
  static const bool _enableGhostWarming = false;

  late final PageController _pageController;
  late final ValueNotifier<int> _currentPageNotifier;
  late final ValueNotifier<double> _cacheExtentNotifier;
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
  static const double _settledCacheExtent = 0;

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

    initSideEffects();
    // precacheQuranAssets moved to didChangeDependencies to avoid MediaQuery warning

    final bloc = context.read<QuranReaderBloc>();
    final int syncPage = _resolveInitialPage(bloc);
    _currentPageNotifier = ValueNotifier<int>(syncPage);
    _cacheExtentNotifier = ValueNotifier<double>(_settledCacheExtent);
    _warmingNotifier = ValueNotifier<_WarmingState>(const _WarmingState());
    _pageController = PageController(initialPage: syncPage - 1);

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
    if (_cachedReaderTheme != incomingReaderTheme || _cachedThemeData == null) {
      _cachedReaderTheme = incomingReaderTheme;
      _cachedThemeData = incomingTheme.copyWith(
        scaffoldBackgroundColor: incomingReaderTheme.pageBackground,
      );
      // Precache assets once theme and media query info is stable
      unawaited(QuranFontService.precacheQuranAssets(context));
    }
    _cachedAppSystemUiStyle = _buildAppSystemUiOverlayStyle(incomingTheme);
    _cachedReaderSystemUiStyle = _buildReaderSystemUiOverlayStyle(
      incomingReaderTheme,
    );
    if (!_didInitDependencies) {
      _didInitDependencies = true;
      _updateSystemUiConfig(_uiVisibilityCubit.state);
    }
  }

  @override
  void dispose() {
    _debugLog(() => '[READER_EXIT] dispose');
    _warmingCooldownTimer?.cancel();
    _settlementTimer?.cancel();
    _cacheExtentRestoreTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _currentPageNotifier.dispose();
    _cacheExtentNotifier.dispose();
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
            ),
          ),
        ),
      ),
    );
  }

  void _pauseWarming() {
    _resumeWarmingTimer?.cancel();
    _cacheExtentRestoreTimer?.cancel();
    _isInteracting = true;

    // Phase 9: Pause global background warming to ensure the UI thread and Raster thread
    // are dedicated entirely to the user's current interaction.
    context.read<QuranFontLoaderBloc>().pauseBackgroundWarmUp();

    // Reduce adjacent-page prebuild work while the user is actively dragging.
    // This frees raster budget for the current transition frame.
    if (_cacheExtentNotifier.value != _interactiveCacheExtent) {
      _cacheExtentNotifier.value = _interactiveCacheExtent;
      print('[READER_CACHE] set cacheExtent=$_interactiveCacheExtent (interaction start)');
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
      _cacheExtentRestoreTimer?.cancel();

      // Resume global background warming only after the interaction has settled.
      context.read<QuranFontLoaderBloc>().resumeBackgroundWarmUp();

      // Restore cache extent only after interaction settles to avoid
      // raster spikes from neighboring page builds during active swipe.
      _cacheExtentRestoreTimer = Timer(const Duration(milliseconds: 120), () {
        if (!mounted || _isInteracting) return;
        if (_cacheExtentNotifier.value != _settledCacheExtent) {
          _cacheExtentNotifier.value = _settledCacheExtent;
          print('[READER_CACHE] restore cacheExtent=$_settledCacheExtent (interaction settled)');
        }
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
      unawaited(fontLoader.ensureSingleFontLoaded(p));
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

    // Phase 4: Await core font registration BEFORE jumping
    // This moves the 30ms registration delay to the button click rather than the animation.
    await fontLoaderBloc.ensureSingleFontLoaded(pageNumber);
    unawaited(fontLoaderBloc.ensurePageWindowLoaded(pageNumber));

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
    final serverUrl = audioState.currentAudio?.url ?? '';
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
      await navigator.push(
        ShareComposerScreen.route(
          cubit: shareCubit,
          surahNumber: primarySurahNumber,
          currentPage: currentPage,
          initialFromAyah: firstAyah,
          initialToAyah: lastAyah,
          reciterName: reciterName,
          reciterServerUrl: serverUrl,
          readerBoundaryKey: _screenshotBoundaryKey,
          readerPreviewBytesNotifier: previewNotifier,
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
      await fontLoaderBloc.ensureSingleFontLoaded(page);
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

    // Proactively register the font for the NEW current page immediately (fast sync check)
    // so it's ready as soon as the swap completes.
    unawaited(fontLoaderBloc.ensureSingleFontLoaded(pageNumber));

    // Immediately ghost-warm the next 2 pages ahead so Impeller builds their
    // glyph atlases during settle time, before the user swipes again.
    final int direction = pageNumber >= _warmingPageNumber ? 1 : -1;
    final int next1 = (pageNumber + direction).clamp(1, 604);
    final int next2 = (pageNumber + direction * 2).clamp(1, 604);
    unawaited(fontLoaderBloc.ensureSingleFontLoaded(next1));
    unawaited(fontLoaderBloc.ensureSingleFontLoaded(next2));

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
        pageNumber: next1,
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
      fontLoaderBloc.ensurePageWindowLoaded(pageNumber).then((_) {
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
    final int direction = pageNumber >= currentPage ? 1 : -1;
    final int nextNeighbor = (pageNumber + direction).clamp(1, 604);
    final int secondNeighbor = (pageNumber + (direction * 2)).clamp(1, 604);

    // Pause global warming to ensure the jump transition is as smooth as possible.
    fontLoaderBloc.pauseBackgroundWarmUp();

    // Await font registration + atlas warm-up so the first on-screen frame
    // finds the atlas already built in Impeller (no raster spike).
    // The current page stays visible during this wait (~50-100ms).
    await fontLoaderBloc.ensureSingleFontLoaded(pageNumber);
    unawaited(fontLoaderBloc.ensureSingleFontLoaded(nextNeighbor));
    unawaited(fontLoaderBloc.ensureSingleFontLoaded(secondNeighbor));

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
            _cacheExtentNotifier.value = _settledCacheExtent;
          }
        });
      }
    }

    if (!mounted) return;
    context.read<QuranReaderBloc>().add(QuranReaderEvent.loadPage(pageNumber));
    unawaited(fontLoaderBloc.ensurePageWindowLoaded(pageNumber));

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
  });

  final PageController pageController;
  final ValueNotifier<int> currentPageNotifier;
  final ValueNotifier<double> cacheExtentNotifier;
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
              child: QuranPageView(
                controller: pageController,
                currentPageListenable: currentPageNotifier,
                cacheExtentListenable: cacheExtentNotifier,
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
                showShadows: false, // Hard-disabled for Phase 9 performance
              ),
            ),
          ),
        ),
        // Ghost warming layer — uses ValueListenableBuilder so only this subtree
        // rebuilds when warming state changes, leaving QuranPageView untouched.
        ValueListenableBuilder<_WarmingState>(
          valueListenable: warmingNotifier,
          builder: (context, warming, _) {
            if (!warming.isWarming) return const SizedBox.shrink();
            return Offstage(
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
            );
          },
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
            return PageNavigationBar(
              currentPage: currentPage,
              onPageChanged: (pageNumber) => unawaited(jumpToPage(pageNumber)),
              onShowIndex: showSurahIndex,
              onShare: () => showShareOptions(currentPage),
              onWarming: onWarming,
              onPointerDown: onPointerDown,
              onPointerUp: onPointerUp,
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
  assert(() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    print('${messageBuilder()} | t=${timestamp}ms');
    return true;
  }());
}

void _hotPathLog(String Function() messageBuilder) {
  assert(() {
    print(messageBuilder());
    return true;
  }());
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
