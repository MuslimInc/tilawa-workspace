import 'dart:async';
import 'dart:ui' as ui;

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
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart'
    show AudioPlayerBloc;
import '../bloc/quran_font_loader_bloc.dart';
import '../bloc/quran_reader_bloc.dart';
import '../cubit/quran_settings_cubit.dart';
import '../../domain/entities/entities.dart';
import '../utils/reader_side_effects_observer.dart';

/// Screen for reading Quran text in a page-by-page Mushaf view.
class QuranReaderScreen extends StatefulWidget {
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
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen>
    with WidgetsBindingObserver, ReaderSideEffectsObserver {
  late final PageController _pageController;
  late final ValueNotifier<int> _currentPageNotifier;
  late final ValueNotifier<bool> _showOverlaysNotifier;
  late final UiVisibilityCubit _uiVisibilityCubit;
  late final GlobalKey _screenshotBoundaryKey;
  bool _didInitDependencies = false;
  bool _isProgrammaticJump = false;
  bool _allowSystemPop = false;
  Future<void>? _pendingExitPreparation;

  static const _headerFontSizeMultiplier = 0.57;

  // Cached to avoid subscribing this State as a Theme.of dependent.
  ThemeData? _cachedThemeData;
  QuranReaderTheme? _cachedReaderTheme;
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

    // Delegate audio-pause + keep-awake to the mixin.
    initSideEffects();

    final bloc = context.read<QuranReaderBloc>();
    final int syncPage = _resolveInitialPage(bloc);
    _currentPageNotifier = ValueNotifier<int>(syncPage);
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
    }
    _cachedAppSystemUiStyle = _buildAppSystemUiOverlayStyle(incomingTheme);
    if (!_didInitDependencies) {
      _didInitDependencies = true;
      _updateSystemUiConfig(_uiVisibilityCubit.state);
    }
  }

  @override
  void dispose() {
    _debugLog('[READER_EXIT] dispose');
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _currentPageNotifier.dispose();
    _showOverlaysNotifier.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (_pendingExitPreparation == null) {
      _debugLog('[READER_EXIT] dispose fallback restore');
      unawaited(_restoreAppSystemUiMode());
    } else {
      _debugLog('[READER_EXIT] dispose skips duplicate restore');
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
    _debugLog(
      '[READER_EXIT] apply immersiveSticky | overlaysVisible=$isVisible',
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final readerTheme = QuranReaderTheme.of(context);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: const Color(0x00000000),
        statusBarIconBrightness: readerTheme.statusBarIconBrightness,
        statusBarBrightness: readerTheme.statusBarBrightness,
        systemNavigationBarColor: const Color(0x00000000),
        systemNavigationBarDividerColor: const Color(0x00000000),
        systemNavigationBarIconBrightness: readerTheme.statusBarIconBrightness,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
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
    if (_pendingExitPreparation != null) {
      _debugLog('[READER_EXIT] reuse pending exit preparation');
    } else {
      _debugLog('[READER_EXIT] prepareForExit requested');
    }
    return _pendingExitPreparation ??= _restoreAppSystemUiMode(
      waitForSystemUiFrame: true,
    );
  }

  Future<void> _handleExitRequest() async {
    _debugLog(
      '[READER_EXIT] handleExitRequest | allowSystemPop=$_allowSystemPop',
    );
    if (_allowSystemPop) {
      return;
    }

    await _prepareForExit();
    _debugLog('[READER_EXIT] exit preparation completed');
    if (!mounted) {
      _debugLog('[READER_EXIT] widget unmounted before pop');
      return;
    }

    setState(() {
      _allowSystemPop = true;
    });
    _debugLog('[READER_EXIT] allowSystemPop=true');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _debugLog('[READER_EXIT] widget unmounted before maybePop');
        return;
      }
      _debugLog('[READER_EXIT] maybePop requested');
      Navigator.of(context).maybePop();
    });
  }

  Future<void> _restoreAppSystemUiMode({
    bool waitForSystemUiFrame = false,
  }) async {
    _debugLog(
      '[READER_EXIT] restoreAppSystemUiMode start | waitForSystemUiFrame=$waitForSystemUiFrame',
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _debugLog('[READER_EXIT] edgeToEdge applied');
    SystemChrome.setSystemUIOverlayStyle(
      _cachedAppSystemUiStyle ?? const SystemUiOverlayStyle(),
    );
    _debugLog(
      '[READER_EXIT] overlay style restored | navIconBrightness=${_cachedAppSystemUiStyle?.systemNavigationBarIconBrightness}',
    );
    if (waitForSystemUiFrame) {
      await SchedulerBinding.instance.endOfFrame;
      _debugLog('[READER_EXIT] waited for endOfFrame after restore');
    }
  }

  @override
  Widget build(BuildContext context) {
    final readerTheme = _cachedReaderTheme!;

    return PopScope(
      canPop: _allowSystemPop,
      onPopInvokedWithResult: (didPop, result) {
        _debugLog(
          '[READER_EXIT] onPopInvoked | didPop=$didPop | allowSystemPop=$_allowSystemPop',
        );
        if (didPop || _allowSystemPop) {
          return;
        }
        unawaited(_handleExitRequest());
      },
      child: Theme(
        data: _cachedThemeData!,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: const Color(0x00000000),
            systemNavigationBarColor: const Color(0x00000000),
            systemNavigationBarDividerColor: const Color(0x00000000),
            statusBarIconBrightness: readerTheme.statusBarIconBrightness,
            statusBarBrightness: readerTheme.statusBarBrightness,
            systemNavigationBarIconBrightness:
                readerTheme.statusBarIconBrightness,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: false,
          ),
          child: MultiBlocListener(
            listeners: [
              BlocListener<UiVisibilityCubit, bool>(
                listener: (context, isVisible) {
                  _updateSystemUiConfig(isVisible);
                  _showOverlaysNotifier.value = !isVisible;
                },
              ),
              BlocListener<QuranReaderBloc, QuranReaderState>(
                listenWhen: (previous, current) =>
                    previous.currentPage != current.currentPage &&
                    current.currentPage != null,
                listener: (context, state) {
                  if (_isProgrammaticJump) return;
                  unawaited(_syncToPage(state.currentPage!.pageNumber));
                },
              ),
            ],
            child: _buildStack(readerTheme),
          ),
        ),
      ),
    );
  }

  Future<void> _syncToPage(int pageNumber) async {
    if (pageNumber == _currentPageNotifier.value &&
        _pageController.hasClients &&
        (_pageController.page ?? _pageController.initialPage.toDouble())
                .round() ==
            pageNumber - 1) {
      return;
    }

    await context.read<QuranFontLoaderBloc>().ensurePageWindowLoaded(
      pageNumber,
    );
    if (!mounted) {
      return;
    }

    _currentPageNotifier.value = pageNumber;

    void jump() {
      if (!mounted || !_pageController.hasClients) return;
      if (!_pageController.position.isScrollingNotifier.value) {
        _pageController.jumpToPage(pageNumber - 1);
      }
    }

    if (_pageController.hasClients) {
      jump();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => jump());
    }
  }

  Widget _buildStack(QuranReaderTheme readerTheme) {
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
            // BlocBuilder scope is now only QuranSettingsCubit — page swipes
            // no longer cause QuranPageView to rebuild.
            child: BlocBuilder<QuranSettingsCubit, ReaderSettingsEntity>(
              buildWhen: (old, next) => old != next,
              builder: (context, settings) {
                return RepaintBoundary(
                  key: _screenshotBoundaryKey,
                  child: QuranPageView(
                    controller: _pageController,
                    currentPageListenable: _currentPageNotifier,
                    pageBackgroundColor: readerTheme.pageBackground,
                    textColor: readerTheme.textColor,
                    headerImageFilter: readerTheme.headerImageFilter,
                    headerTextColor: readerTheme.headerTextColor,
                    headerFontSizeMultiplier: _headerFontSizeMultiplier,
                    uiTextDirection: Directionality.of(context),
                    onPageChanged: _handleOnPageChanged,
                    juzLabel: context.l10n.juzPart,
                    hizbLabel: context.l10n.hizb,
                    surahNameBuilder: _getSurahName,
                    onSurahSelected: (surahNumber) =>
                        unawaited(_jumpToSurah(surahNumber)),
                    onShowIndex: _handleShowIndex,
                    showOverlaysListenable: _showOverlaysNotifier,
                  ),
                );
              },
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: _showOverlaysNotifier,
            builder: (context, showOverlays, child) {
              return AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                offset: showOverlays ? Offset.zero : const Offset(0, 1),
                child: child!,
              );
            },
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, currentPage, _) {
                return PageNavigationBar(
                  currentPage: currentPage,
                  onPageChanged: (pageNumber) =>
                      unawaited(_jumpToPage(pageNumber)),
                  onShowIndex: () => _showSurahIndex(context),
                  onShare: () => _showShareOptions(context, currentPage),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showShareOptions(BuildContext context, int currentPage) async {
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
    final navigator = Navigator.of(context);
    final previewBytes = await _captureSharePreviewBytes();
    if (!mounted) return;

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
        readerPreviewBytes: previewBytes,
      ),
    );
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

  void _handleShowIndex() => _showSurahIndex(context);

  void _showSurahIndex(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SurahIndexSheet(
        onSurahSelected: (surahNumber) {
          Navigator.of(context).pop();
          unawaited(_jumpToSurah(surahNumber, animate: true));
        },
      ),
    );
  }

  void _handleOnPageChanged(int pageNumber) {
    _currentPageNotifier.value = pageNumber;
    if (_isProgrammaticJump) return;

    final bloc = context.read<QuranReaderBloc>();
    if (bloc.state.currentPage?.pageNumber != pageNumber) {
      bloc.add(QuranReaderEvent.loadPage(pageNumber));
    }
  }

  String _getSurahName(int surahNumber) {
    return context.l10n.localeName == 'ar'
        ? getSurahNameArabic(surahNumber)
        : getSurahNameEnglish(surahNumber);
  }

  Future<void> _jumpToSurah(int surahNumber, {bool animate = false}) {
    return _jumpToPage(getPageNumber(surahNumber, 1));
  }

  Future<void> _jumpToPage(int pageNumber) async {
    _isProgrammaticJump = true;
    try {
      await context.read<QuranFontLoaderBloc>().ensurePageWindowLoaded(
        pageNumber,
      );
      if (!mounted) {
        return;
      }
      _currentPageNotifier.value = pageNumber;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(pageNumber - 1);
      }
      context.read<QuranReaderBloc>().add(
        QuranReaderEvent.loadPage(pageNumber),
      );
    } finally {
      _isProgrammaticJump = false;
    }
  }
}

void _debugLog(String message) {
  assert(() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    debugPrint('$message | t=${timestamp}ms');
    return true;
  }());
}
