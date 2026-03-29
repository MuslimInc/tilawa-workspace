import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  late final UiVisibilityCubit _uiVisibilityCubit;
  bool _didInitDependencies = false;
  bool _isInitialPageJumpDone = false;
  late final GlobalKey _screenshotBoundaryKey;

  // Removed _jumpTransitionKey as AnimatedSwitcher was removed to fix PageController conflicts.

  static const _headerFontSizeMultiplier = 0.57;

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

    // Pause audio playback for a distraction-free reading experience
    final audioBloc = context.read<AudioPlayerBloc>();
    if (audioBloc.state.isPlaying) {
      audioBloc.add(const AudioPlayerEvent.pauseAudio());
    }

    final bloc = context.read<QuranReaderBloc>();

    final int inMemoryPage = bloc.state.currentPage?.pageNumber ?? 0;

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

    // loadLastRead is already dispatched by the BlocProvider on creation.
    // Only re-dispatch if the bloc is in initial state (e.g. after dispose/recreate).
    if (inMemoryPage == 0 && bloc.state.status == QuranReaderStatus.initial) {
      bloc.add(const QuranReaderEvent.loadLastRead());
    }

    _currentPageNotifier = ValueNotifier<int>(initialPage);
    _pageController = PageController(initialPage: initialPage - 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitDependencies) {
      _didInitDependencies = true;
      _enterReaderImmersiveMode();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _currentPageNotifier.dispose();
    // Revert to portrait only when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _restoreAppSystemUiMode();
    // Ensure UI is visible when leaving the reader
    _uiVisibilityCubit.show();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enterReaderImmersiveMode();
    }
  }

  void _enterReaderImmersiveMode() {
    final readerTheme = QuranReaderTheme.of(context);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: readerTheme.statusBarIconBrightness,
        statusBarBrightness: readerTheme.statusBarBrightness,
        systemNavigationBarColor: Colors.transparent,
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
    final readerTheme = QuranReaderTheme.of(context);
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(scaffoldBackgroundColor: readerTheme.pageBackground),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          statusBarIconBrightness: readerTheme.statusBarIconBrightness,
          statusBarBrightness: readerTheme.statusBarBrightness,
          systemNavigationBarIconBrightness:
              readerTheme.statusBarIconBrightness,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarContrastEnforced: false,
        ),
        child: MultiBlocListener(
          listeners: [
            BlocListener<QuranReaderBloc, QuranReaderState>(
              listenWhen: (previous, current) =>
                  previous.currentPage != current.currentPage &&
                  current.currentPage != null,
              listener: (context, state) {
                final pageNumber = state.currentPage!.pageNumber;

                if (!_isInitialPageJumpDone) {
                  // Re-create controller with the correct initial page BEFORE the first build.
                  // This eliminates the Page 1 flicker entirely.
                  _pageController.dispose();
                  _pageController = PageController(initialPage: pageNumber - 1);
                  _currentPageNotifier.value = pageNumber;
                  if (mounted) {
                    setState(() {
                      _isInitialPageJumpDone = true;
                    });
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
          child: BlocBuilder<QuranReaderBloc, QuranReaderState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.errorMessage != current.errorMessage,
            builder: (context, state) {
              final ThemeData theme = Theme.of(context);
              final ColorScheme colorScheme = theme.colorScheme;

              // Show loading if we are waiting for the last read position
              final bool isLoadingLastRead =
                  widget.surahNumber == 0 &&
                  (!_isInitialPageJumpDone ||
                      state.status == QuranReaderStatus.loading ||
                      state.status == QuranReaderStatus.initial);

              if (isLoadingLastRead) {
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
                        Icon(Icons.error, color: colorScheme.error, size: 48),
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

              return BlocBuilder<UiVisibilityCubit, bool>(
                builder: (context, isVisible) {
                  return Stack(
                    children: [
                      Scaffold(
                        key: const ValueKey('QuranReaderScaffold'),
                        resizeToAvoidBottomInset: false,
                        body: GestureDetector(
                          onTap: () {
                            context.read<UiVisibilityCubit>().toggle();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: BlocBuilder<QuranReaderBloc, QuranReaderState>(
                            buildWhen: (oldState, newState) =>
                                oldState.settings != newState.settings ||
                                oldState.status != newState.status,
                            builder: (context, state) {
                              return SafeArea(
                                child: RepaintBoundary(
                                  key: _screenshotBoundaryKey,
                                  child: QuranPageView(
                                    controller: _pageController,
                                    currentPageListenable: _currentPageNotifier,
                                    pageBackgroundColor:
                                        readerTheme.pageBackground,
                                    textColor: readerTheme.textColor,
                                    headerImageFilter:
                                        readerTheme.headerImageFilter,
                                    headerTextColor:
                                        readerTheme.headerTextColor,
                                    headerFontSizeMultiplier:
                                        _headerFontSizeMultiplier,
                                    uiTextDirection: Directionality.of(context),
                                    onPageChanged: (pageNumber) {
                                      if (_currentPageNotifier.value !=
                                          pageNumber) {
                                        _currentPageNotifier.value = pageNumber;
                                      }
                                      final pageData = getPageData(pageNumber);
                                      final surahNumber =
                                          pageData.first['surah']!;
                                      final bloc = context
                                          .read<QuranReaderBloc>();
                                      bloc.add(
                                        QuranReaderEvent.loadPage(pageNumber),
                                      );
                                      bloc.add(
                                        QuranReaderEvent.saveLastRead(
                                          surahNumber: surahNumber,
                                          page: pageNumber,
                                        ),
                                      );
                                    },
                                    juzLabel: context.l10n.juzPart,
                                    hizbLabel: context.l10n.hizb,
                                    surahNameBuilder: (surahNumber) {
                                      return context.l10n.localeName == 'ar'
                                          ? getSurahNameArabic(surahNumber)
                                          : getSurahNameEnglish(surahNumber);
                                    },
                                    onSurahSelected: _jumpToSurah,
                                    onShowIndex: () => _showSurahIndex(context),
                                    showOverlays: !isVisible,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Page navigation slider — appears when UI chrome is visible.
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          offset: isVisible ? Offset.zero : const Offset(0, 1),
                          child: ValueListenableBuilder<int>(
                            valueListenable: _currentPageNotifier,
                            builder: (context, currentPage, _) {
                              return PageNavigationBar(
                                currentPage: currentPage,
                                onPageChanged: (page) =>
                                    _jumpToPage(page, animate: true),
                                onShowIndex: () => _showSurahIndex(context),
                                onShare: () =>
                                    _showShareOptions(context, currentPage),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
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

  /// Navigates the [PageView] to the first page of [surahNumber].
  void _jumpToSurah(int surahNumber, {bool animate = false}) {
    final int targetPage = getPageNumber(surahNumber, 1);
    _jumpToPage(targetPage, animate: animate);
  }

  /// Navigates the [PageView] to the given 1-based [pageNumber].
  void _jumpToPage(int pageNumber, {bool animate = false}) {
    if (_pageController.hasClients) {
      final targetIndex = pageNumber - 1;

      if (animate) {
        _pageController.jumpToPage(targetIndex);
      } else {
        _pageController.jumpToPage(targetIndex);
      }
    }

    final pageData = getPageData(pageNumber);
    final surahNumber = pageData.first['surah']!;
    final bloc = context.read<QuranReaderBloc>();
    // loadPage updates bloc.state.currentPage so the next initState call
    // (when the user re-enters the reader) resumes at this page.
    bloc.add(QuranReaderEvent.loadPage(pageNumber));
    bloc.add(
      QuranReaderEvent.saveLastReadImmediate(
        surahNumber: surahNumber,
        page: pageNumber,
      ),
    );
  }
}
