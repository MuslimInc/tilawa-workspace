import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart';
import 'package:quran/src/services/quran_data_service.dart' as quran_data;
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/page_navigation_bar.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/surah_index_sheet.dart';
import 'package:tilawa/features/share/presentation/cubit/share_cubit.dart';
import 'package:tilawa/features/share/presentation/screens/share_composer_screen.dart';
import 'package:tilawa_core/services/interfaces/keep_awake_service.dart';

import '../../../../core/presentation/cubit/ui_visibility_cubit.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../bloc/quran_reader_bloc.dart';

/// Screen for reading Quran text in a page-by-page Mushaf view.
///
/// Displays [QuranPageView] with a floating action button to open
/// the surah index sheet for quick navigation.
class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
  });

  /// The surah number to open initially.
  final int surahNumber;

  /// Optional initial ayah to scroll to.
  final int? initialAyah;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  late final ValueNotifier<int> _currentPageNotifier;
  late final ValueNotifier<bool> _showOverlaysNotifier;
  bool _manualJumpLock = false;
  late final UiVisibilityCubit _uiVisibilityCubit;
  late final KeepAwakeService _keepAwakeService;
  bool _didInitDependencies = false;
  bool _isInitialPageJumpDone = false;
  late final GlobalKey _screenshotBoundaryKey;

  // Removed _jumpTransitionKey as AnimatedSwitcher was removed to fix PageController conflicts.

  static const _headerFontSizeMultiplier = 0.57;

  // Cached to avoid creating a new ThemeData object on every build(), which
  // would notify all Theme.of(context) dependents and cause a rebuild cascade.
  ThemeData? _cachedThemeData;
  QuranReaderTheme? _cachedReaderTheme;

  // Once true, the outer BlocBuilder is removed from the tree permanently.
  // This eliminates the BlocBuilder.reassemble() setState() replay on hot reload
  // and prevents any further bloc-driven rebuilds of the entire screen scaffold.
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _screenshotBoundaryKey = GlobalKey();
    WidgetsBinding.instance.addObserver(this);
    // Enable landscape and portrait for this screen only
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _uiVisibilityCubit = context.read<UiVisibilityCubit>();

    // Ensure UI is visible when entering the reader
    _uiVisibilityCubit.show();
    // Mirrors UiVisibilityCubit so QuranPageView never rebuilds on tap —
    // only the chrome widgets (badge + strip) rebuild via ValueListenableBuilder.
    _showOverlaysNotifier = ValueNotifier<bool>(!_uiVisibilityCubit.state);

    // Pause audio playback for a distraction-free reading experience
    final audioBloc = context.read<AudioPlayerBloc>();
    if (audioBloc.state.isPlaying) {
      audioBloc.add(const AudioPlayerEvent.pauseAudio());
    }

    _keepAwakeService = getIt<KeepAwakeService>();
    _keepAwakeService.enable();

    final bloc = context.read<QuranReaderBloc>();

    final int inMemoryPage = bloc.state.currentPage?.pageNumber ?? 0;
    print('[STARTUP] initState | surahNumber=${widget.surahNumber} | blocStatus=${bloc.state.status} | inMemoryPage=$inMemoryPage | quranDataLoaded=${quran_data.QuranDataService.instance.isLoaded} | t=${DateTime.now().millisecondsSinceEpoch}ms');

    int initialPage;
    if (widget.surahNumber > 0) {
      initialPage = inMemoryPage > 0
          ? inMemoryPage
          : getPageNumber(widget.surahNumber, 1);

      if (bloc.state.currentSurah?.number != widget.surahNumber) {
        bloc.add(
          QuranReaderEvent.loadSurah(widget.surahNumber, loadStartPage: false),
        );
      }
    } else {
      initialPage = inMemoryPage > 0 ? inMemoryPage : 1;
      if (inMemoryPage > 0) {
        _isInitialPageJumpDone = true;
      }
    }
    // If mustBlock would be false from the very first build, promote _isReady
    // synchronously here so the outer BlocBuilder is never put in the tree at
    // all — eliminating the postFrameCallback setState and the extra build() it
    // causes. mustBlock requires quranDataLoaded=false, so when data is already
    // loaded (the common case) we can skip the BlocBuilder gate entirely.
    final bool mustBlockOnFirstBuild =
        widget.surahNumber == 0 &&
        !_isInitialPageJumpDone &&
        !quran_data.QuranDataService.instance.isLoaded;
    if (!mustBlockOnFirstBuild) {
      _isReady = true;
    }

    print('[STARTUP] initState done | initialPage=$initialPage | _isInitialPageJumpDone=$_isInitialPageJumpDone | _isReady=$_isReady');

    // loadLastRead is already dispatched by the BlocProvider in AppProviders on creation.

    _currentPageNotifier = ValueNotifier<int>(initialPage);
    _pageController = PageController(initialPage: initialPage - 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read Theme here (not in build) so _QuranReaderScreenState is NOT
    // registered as a Theme.of dependent. Without this, every BlocProvider
    // reassemble() that rebuilds MaterialApp produces a new Theme object,
    // notifying all Theme.of(context) dependents — causing 5 extra build()
    // calls on hot reload (one per top-level bloc in AppProviders).
    final incomingReaderTheme = QuranReaderTheme.of(context);
    final incomingTheme = Theme.of(context);
    if (_cachedReaderTheme != incomingReaderTheme || _cachedThemeData == null) {
      _cachedReaderTheme = incomingReaderTheme;
      _cachedThemeData = incomingTheme.copyWith(
        scaffoldBackgroundColor: incomingReaderTheme.pageBackground,
      );
    }
    if (!_didInitDependencies) {
      _didInitDependencies = true;
      _updateSystemUiConfig(_uiVisibilityCubit.state);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _currentPageNotifier.dispose();
    _showOverlaysNotifier.dispose();
    // Revert to portrait only when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _restoreAppSystemUiMode();
    // Ensure UI is visible when leaving the reader
    _uiVisibilityCubit.show();
    _keepAwakeService.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateSystemUiConfig(_uiVisibilityCubit.state);
      _keepAwakeService.enable();
    } else if (state == AppLifecycleState.paused) {
      _keepAwakeService.disable();
    }
  }

  void _updateSystemUiConfig(bool isVisible) {
    // Always stay in immersiveSticky for the duration of the reading screen.
    // This provides an undistracted focus environment and prevents window
    // resizing which was causing the "stretching" effect of the page content.
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

  void _restoreAppSystemUiMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle());
  }

  @override
  Widget build(BuildContext context) {
    print('[STARTUP] build() | _isReady=$_isReady | _isInitialPageJumpDone=$_isInitialPageJumpDone | t=${DateTime.now().millisecondsSinceEpoch}ms');
    // Theme values are read in didChangeDependencies to avoid subscribing this
    // State as a Theme.of dependent (which would cause a build() on every
    // MaterialApp rebuild triggered by any BlocProvider.reassemble()).
    final readerTheme = _cachedReaderTheme!;

    return Theme(
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
                print('[STARTUP] BlocListener<UiVisibilityCubit> | isVisible=$isVisible | t=${DateTime.now().millisecondsSinceEpoch}ms');
                _updateSystemUiConfig(isVisible);
                _showOverlaysNotifier.value = !isVisible;
              },
            ),
            BlocListener<QuranReaderBloc, QuranReaderState>(
              listenWhen: (previous, current) =>
                  previous.currentPage != current.currentPage &&
                  current.currentPage != null,
              listener: (context, state) {
                final pageNumber = state.currentPage!.pageNumber;
                print('[STARTUP] BlocListener: page arrived | page=$pageNumber | _isInitialPageJumpDone=$_isInitialPageJumpDone | t=${DateTime.now().millisecondsSinceEpoch}ms');

                if (!_isInitialPageJumpDone) {
                  // Re-create controller with the correct initial page BEFORE the first build.
                  // This eliminates the Page 1 flicker entirely.
                  _pageController.dispose();
                  _pageController = PageController(initialPage: pageNumber - 1);
                  _currentPageNotifier.value = pageNumber;
                  _isInitialPageJumpDone = true;
                  // Only trigger a setState rebuild when mustBlock was true (i.e. we were
                  // showing the spinner and now need to swap to the real PageView).
                  // When quranDataLoaded=true mustBlock is already false so the builder
                  // output is unchanged — no rebuild needed.
                  final bool mustBlockWasTrue =
                      widget.surahNumber == 0 &&
                      !quran_data.QuranDataService.instance.isLoaded;
                  if (mounted && mustBlockWasTrue) {
                    setState(() {});
                  }
                  return;
                }

                void jumpIfNeeded() {
                  if (!_pageController.hasClients) return;
                  final currentPageInController =
                      _pageController.page ??
                      _pageController.initialPage.toDouble();
                  if ((currentPageInController + 1 - pageNumber).abs() > 0.1) {
                    if (!_pageController.position.isScrollingNotifier.value) {
                      _pageController.jumpToPage(pageNumber - 1);
                    }
                  }
                }

                if (_pageController.hasClients) {
                  jumpIfNeeded();
                } else {
                  // Controller not attached yet — schedule jump for next frame.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => jumpIfNeeded(),
                  );
                }
              },
            ),
          ],
          child: _isReady
              ? _buildReadyStack(readerTheme)
              : BlocBuilder<QuranReaderBloc, QuranReaderState>(
                  buildWhen: (previous, current) {
                    // Gate rebuilds to only the transitions that change the
                    // rendered branch: mustBlock→false, or error enter/exit.
                    final bool mustBlockNow =
                        widget.surahNumber == 0 &&
                        !_isInitialPageJumpDone &&
                        !quran_data.QuranDataService.instance.isLoaded;
                    final bool wasError =
                        previous.status == QuranReaderStatus.error;
                    final bool isError =
                        current.status == QuranReaderStatus.error;
                    return mustBlockNow ||
                        isError ||
                        wasError ||
                        previous.errorMessage != current.errorMessage;
                  },
                  builder: (context, state) {
                    final ThemeData theme = Theme.of(context);
                    final ColorScheme colorScheme = theme.colorScheme;

                    final bool mustBlock =
                        widget.surahNumber == 0 &&
                        !_isInitialPageJumpDone &&
                        !quran_data.QuranDataService.instance.isLoaded;

                    print('[STARTUP] BlocBuilder | status=${state.status} | mustBlock=$mustBlock | _isInitialPageJumpDone=$_isInitialPageJumpDone | quranLoaded=${quran_data.QuranDataService.instance.isLoaded} | t=${DateTime.now().millisecondsSinceEpoch}ms');

                    if (mustBlock) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (state.status == QuranReaderStatus.error) {
                      return Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error,
                                color: colorScheme.error,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.errorMessage,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<QuranReaderBloc>().add(
                                    const QuranReaderEvent.loadLastRead(),
                                  );
                                },
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // mustBlock=false and no error: promote to ready and rebuild
                    // so the outer BlocBuilder is removed from the tree permanently.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_isReady) {
                        setState(() => _isReady = true);
                      }
                    });

                    return _buildReadyStack(readerTheme);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildReadyStack(QuranReaderTheme readerTheme) {
    print('[STARTUP] _buildReadyStack | t=${DateTime.now().millisecondsSinceEpoch}ms');
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
            child: BlocBuilder<QuranReaderBloc, QuranReaderState>(
              buildWhen: (oldState, newState) =>
                  oldState.settings != newState.settings,
              builder: (context, state) {
                print('[STARTUP] innerBlocBuilder(QuranPageView) | status=${state.status} | t=${DateTime.now().millisecondsSinceEpoch}ms');
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
                    onSurahSelected: _jumpToSurah,
                    onShowIndex: _handleShowIndex,
                    showOverlaysListenable: _showOverlaysNotifier,
                  ),
                );
              },
            ),
          ),
        ),
        // Page navigation bar — rebuilds only via ValueListenableBuilders;
        // QuranPageView is never touched on tap or page change.
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: _showOverlaysNotifier,
            builder: (context, showOverlays, child) {
              print('[STARTUP] ValueListenableBuilder<bool>(showOverlays) | showOverlays=$showOverlays | t=${DateTime.now().millisecondsSinceEpoch}ms');
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
                print('[STARTUP] ValueListenableBuilder<int>(currentPage) | currentPage=$currentPage | t=${DateTime.now().millisecondsSinceEpoch}ms');
                return PageNavigationBar(
                  currentPage: currentPage,
                  onPageChanged: (page) => _jumpToPage(page, animate: true),
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
    final surahNumber = primarySurahNumber;
    final firstAyah = primarySurahEntries.first['start'] ?? 1;
    final lastAyah = primarySurahEntries.last['end'] ?? firstAyah;
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
        surahNumber: surahNumber,
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

  void _handleShowIndex() {
    _showSurahIndex(context);
  }

  void _showSurahIndex(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SurahIndexSheet(
        onSurahSelected: (surahNumber) {
          Navigator.of(context).pop();
          _jumpToSurah(surahNumber, animate: true);
        },
      ),
    );
  }

  void _handleOnPageChanged(int pageNumber) {
    if (_currentPageNotifier.value != pageNumber) {
      _currentPageNotifier.value = pageNumber;
    }

    if (_manualJumpLock) return;

    final bloc = context.read<QuranReaderBloc>();
    // Guard against redundant loadPage calls
    if (bloc.state.currentPage?.pageNumber != pageNumber) {
      bloc.add(QuranReaderEvent.loadPage(pageNumber));
    }
  }

  String _getSurahName(int surahNumber) {
    return context.l10n.localeName == 'ar'
        ? getSurahNameArabic(surahNumber)
        : getSurahNameEnglish(surahNumber);
  }

  /// Navigates the [PageView] to the first page of [surahNumber].
  void _jumpToSurah(int surahNumber, {bool animate = false}) {
    final int targetPage = getPageNumber(surahNumber, 1);
    _jumpToPage(targetPage, animate: animate);
  }

  /// Navigates the [PageView] to the given 1-based [pageNumber].
  void _jumpToPage(int pageNumber, {bool animate = false}) {
    _manualJumpLock = true;
    try {
      if (_pageController.hasClients) {
        final targetIndex = pageNumber - 1;
        _pageController.jumpToPage(targetIndex);
      }
      _currentPageNotifier.value = pageNumber;
      context.read<QuranReaderBloc>().add(
        QuranReaderEvent.loadPage(pageNumber),
      );
    } finally {
      _manualJumpLock = false;
    }
  }
}
