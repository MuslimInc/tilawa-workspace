import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/preloading_screen.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_event.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';
import 'package:quran_image/quran_image_reader.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/share_composer_extra.dart';
import 'package:tilawa_core/logger.dart';
import 'package:tilawa_core/services/app_orientation_service.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart'
    show AudioPlayerBloc;
import '../../../recitation_practice/presentation/cubit/recitation_practice_cubit.dart';
import '../../../recitation_practice/presentation/widgets/recitation_practice_host.dart';
import '../../../recitation_practice/recitation_practice_feature_flags.dart';
import '../../../share/presentation/widgets/share_options_sheet.dart';
import '../../../smart_khatma/smart_khatma.dart';
import '../../domain/ports/quran_image_preload_status.dart';
import '../../domain/usecases/load_quran_fonts_to_engine_use_case.dart';
import '../../domain/usecases/save_last_read_position_use_case.dart';
import '../navigation/quran_image_reader_index_navigation.dart';
import '../theme/quran_reader_theme.dart';
import '../widgets/surah_index_sheet.dart';

/// Wraps `quran_image`'s reader flow inside the Tilawa app.
///
/// This screen:
/// 1. Shows the image-cache [PreloadingScreen] if necessary.
/// 2. On completion, creates a [NavigationBloc] and shows
///    [QuranImageReader] — the high-performance image-based reader.
///
/// The `quran_image` package owns the reading experience; Tilawa owns
/// the route, navigation params, and integration with the rest of the
/// app (share flow, audio player, etc.).
class QuranImageReaderScreen extends StatefulWidget {
  /// Creates the wrapper screen.
  ///
  /// Pass [surahNumber] > 0 to open a specific surah.
  /// Pass `0` to resume from the last-read page.
  const QuranImageReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
    this.openPracticeOnLaunch = false,
    this.onActiveSurahChanged,
    this.viewSwitchAction,
  });

  /// Surah number to open (`1`–`114`), or `0` to use last-read.
  final int surahNumber;

  /// Optional ayah to jump to within the surah.
  final int? initialAyah;

  /// Opens the recitation practice panel after the reader is ready.
  final bool openPracticeOnLaunch;

  /// Notifies the host when the visible Mushaf page changes surah.
  final ValueChanged<int>? onActiveSurahChanged;

  /// Host-supplied view-switch control rendered in the reader's bottom
  /// navigation panel (thumb-reachable), replacing the old top-corner toggle.
  final Widget? viewSwitchAction;

  @override
  State<QuranImageReaderScreen> createState() => _QuranImageReaderScreenState();
}

class _QuranImageReaderScreenState extends State<QuranImageReaderScreen>
    with WidgetsBindingObserver {
  bool _isPreloaded = false;
  NavigationBloc? _navigationBloc;
  late final SaveLastReadPositionUseCase _saveLastReadPosition;
  UpdateKhatmaProgressUseCase? _updateKhatmaProgress;
  late final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(1);
  bool _didSchedulePracticeLaunch = false;

  // Stable fallback key — no RenderRepaintBoundary is attached here, so the
  // share composer will simply skip the reader-page screenshot preview for
  // the image-based reader. This is intentional: the image reader already
  // shows the page as a high-quality cached image, so a live capture is
  // unnecessary.
  final GlobalKey _dummyBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _saveLastReadPosition = getIt<SaveLastReadPositionUseCase>();
    if (isSmartKhatmaEnabled()) {
      _updateKhatmaProgress = SmartKhatmaDependencies.updateProgress();
    }
    WidgetsBinding.instance.addObserver(this);
    unawaited(AppOrientationService.allowReaderOrientations());
    _checkPreloadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(AppOrientationService.restoreDefaultOrientations());
    _currentPageNotifier.dispose();
    _navigationBloc?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AppOrientationService.allowReaderOrientations());
    }
  }

  /// Checks whether the quran_image cache is already ready.
  void _checkPreloadStatus() {
    if (getIt<QuranImagePreloadStatus>().isReady) {
      _initNavigationBloc();
      _isPreloaded = true;
    }
  }

  void _initNavigationBloc() {
    if (_navigationBloc != null) return;

    int? initialPage;
    if (widget.surahNumber > 0) {
      initialPage = getPageNumber(widget.surahNumber, widget.initialAyah ?? 1);
    }

    _navigationBloc = NavigationBloc()
      ..add(NavigationInitialized(initialPage: initialPage));
    logger.d(
      '[QuranImagesPerformance] source=QuranImageReaderScreen NavigationBloc initialized with page: $initialPage',
    );
  }

  void _onPreloadComplete() {
    if (!mounted) return;
    _initNavigationBloc();
    setState(() => _isPreloaded = true);
    logger.d(
      '[QuranImagesPerformance] source=QuranImageReaderScreen preload complete — '
      'transitioning to reader',
    );
  }

  SystemUiOverlayStyle _buildReaderSystemUiOverlayStyle(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Brightness iconBrightness = isDark
        ? Brightness.light
        : Brightness.dark;
    final Brightness statusBarBrightness = isDark
        ? Brightness.dark
        : Brightness.light;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: statusBarBrightness,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }

  SystemUiOverlayStyle _buildShareSheetSystemUiOverlayStyle(ThemeData theme) {
    final Color statusBarColor = theme.colorScheme.scrim.withValues(
      alpha: 0.45,
    );
    final Color navigationBarColor = theme.colorScheme.surface;

    final Brightness statusBarColorBrightness =
        ThemeData.estimateBrightnessForColor(statusBarColor);
    final Brightness statusBarIconBrightness =
        statusBarColorBrightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    final Brightness navigationBarColorBrightness =
        ThemeData.estimateBrightnessForColor(navigationBarColor);
    final Brightness navigationBarIconBrightness =
        navigationBarColorBrightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    return SystemUiOverlayStyle(
      statusBarColor: statusBarColor,
      statusBarIconBrightness: statusBarIconBrightness,
      statusBarBrightness: statusBarColorBrightness,
      systemNavigationBarColor: navigationBarColor,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: navigationBarIconBrightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }

  Future<void> _showShareOptions(int currentPage) async {
    // Read context-dependent values before the async gap.
    final pageData = getPageData(currentPage);
    final primarySurahNumber = pageData.first.surah;

    final audioState = context.read<AudioPlayerBloc>().state;
    final reciterName = audioState.currentAudio?.artist ?? 'Al-Afasy';
    final serverUrl = audioState.currentAudio?.url ?? '';
    final fontEngine = getIt<LoadQuranFontsToEngineUseCase>();
    final theme = Theme.of(context);
    final readerOverlayStyle = _buildReaderSystemUiOverlayStyle(theme);

    fontEngine.pauseBackgroundWarmUp();
    SystemChrome.setSystemUIOverlayStyle(
      _buildShareSheetSystemUiOverlayStyle(theme),
    );
    try {
      await showTilawaModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => ShareOptionsSheet(
          surahNumber: primarySurahNumber,
          pageNumber: currentPage,
          onShareScreenshot: (selectedSurah) {
            final surahEntries = pageData
                .where((entry) => entry.surah == selectedSurah)
                .toList();
            final firstAyah = surahEntries.first.start;
            final lastAyah = surahEntries.last.end;

            unawaited(
              ScreenshotComposerRoute(
                $extra: ScreenshotComposerNavExtra(
                  surahNumber: selectedSurah,
                  currentPage: currentPage,
                  initialFromAyah: firstAyah,
                  initialToAyah: lastAyah,
                  reciterName: reciterName,
                  readerBoundaryKey: _dummyBoundaryKey,
                ),
              ).push(this.context),
            );
          },
          onShareVideoReel: (selectedSurah) {
            final surahEntries = pageData
                .where((entry) => entry.surah == selectedSurah)
                .toList();
            final firstAyah = surahEntries.first.start;
            final lastAyah = surahEntries.last.end;

            unawaited(
              VideoReelComposerRoute(
                $extra: VideoReelComposerNavExtra(
                  surahNumber: selectedSurah,
                  initialFromAyah: firstAyah,
                  initialToAyah: lastAyah,
                  reciterName: reciterName,
                  reciterServerUrl: serverUrl,
                ),
              ).push(this.context),
            );
          },
        ),
      );
    } finally {
      SystemChrome.setSystemUIOverlayStyle(readerOverlayStyle);
      fontEngine.resumeBackgroundWarmUp();
    }
  }

  Future<void> _showSurahIndex() async {
    final NavigationBloc? navigationBloc = _navigationBloc;
    if (navigationBloc == null) {
      return;
    }

    final fontEngine = getIt<LoadQuranFontsToEngineUseCase>();
    final theme = Theme.of(context);
    final readerOverlayStyle = _buildReaderSystemUiOverlayStyle(theme);

    fontEngine.pauseBackgroundWarmUp();
    SystemChrome.setSystemUIOverlayStyle(
      _buildShareSheetSystemUiOverlayStyle(theme),
    );
    try {
      final int? selectedSurah = await showTilawaModalBottomSheet<int>(
        context: context,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => SurahIndexSheet(
          onSurahSelected: (surahNumber) {
            Navigator.of(sheetContext).pop(surahNumber);
          },
        ),
      );
      if (selectedSurah == null ||
          !QuranImageReaderIndexNavigation.shouldDispatchSelection(
            isMounted: mounted,
            selectedSurah: selectedSurah,
          )) {
        return;
      }
      QuranImageReaderIndexNavigation.dispatchSelection(
        navigationBloc,
        selectedSurah,
      );
    } finally {
      SystemChrome.setSystemUIOverlayStyle(readerOverlayStyle);
      fontEngine.resumeBackgroundWarmUp();
    }
  }

  Future<void> _recordReadingProgress(int currentPage) async {
    _currentPageNotifier.value = currentPage;
    final pageData = getPageData(currentPage);
    if (pageData.isEmpty) {
      return;
    }
    await _saveLastReadPosition(
      surahNumber: pageData.first.surah,
      page: currentPage,
    );
    widget.onActiveSurahChanged?.call(pageData.first.surah);
    final UpdateKhatmaProgressUseCase? updateKhatmaProgress =
        _updateKhatmaProgress;
    if (updateKhatmaProgress != null) {
      await updateKhatmaProgress(currentPage: currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPreloaded) {
      return PreloadingScreen(onPreloadComplete: _onPreloadComplete);
    }

    final bloc = _navigationBloc!;

    final Widget reader = BlocProvider<NavigationBloc>.value(
      value: bloc,
      child: _ReaderShell(
        onShareRequested: _showShareOptions,
        onShowIndex: _showSurahIndex,
        onPageSettled: (page) => unawaited(_recordReadingProgress(page)),
        viewSwitchAction: widget.viewSwitchAction,
      ),
    );

    if (!isRecitationPracticeEnabled()) {
      return reader;
    }

    return RecitationPracticeHost(
      currentPageListenable: _currentPageNotifier,
      showFloatingMic: true,
      builder: (BuildContext context, openPractice) {
        if (widget.openPracticeOnLaunch && !_didSchedulePracticeLaunch) {
          _didSchedulePracticeLaunch = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            final int page = _currentPageNotifier.value;
            final RecitationPracticeCubit practiceCubit = context
                .read<RecitationPracticeCubit>();
            if (widget.surahNumber > 0) {
              unawaited(
                practiceCubit.openForAyah(
                  pageNumber: page,
                  surahNumber: widget.surahNumber,
                  ayahNumber: widget.initialAyah ?? 1,
                ),
              );
              return;
            }
            unawaited(openPractice(page));
          });
        }

        return reader;
      },
    );
  }
}

/// Inner shell that watches [NavigationBloc] state to show
/// loading → error → reader transitions.
class _ReaderShell extends StatelessWidget {
  const _ReaderShell({
    required this.onShareRequested,
    required this.onShowIndex,
    required this.onPageSettled,
    this.viewSwitchAction,
  });

  final Future<void> Function(int currentPage) onShareRequested;
  final VoidCallback onShowIndex;
  final ValueChanged<int> onPageSettled;
  final Widget? viewSwitchAction;

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationBloc, NavigationState>(
      listenWhen: (previous, current) {
        if (current is! NavigationLoaded) {
          return false;
        }
        return previous is! NavigationLoaded ||
            previous.pageState.currentPage != current.pageState.currentPage;
      },
      listener: (context, state) {
        if (state is NavigationLoaded) {
          onPageSettled(state.pageState.currentPage);
        }
      },
      child: BlocBuilder<NavigationBloc, NavigationState>(
        buildWhen: (previous, current) {
          if (previous is NavigationLoaded && current is NavigationLoaded) {
            return false;
          }
          return current is NavigationLoaded || current is NavigationError;
        },
        builder: (context, state) {
          if (state is NavigationLoaded) {
            return QuranImageReader(
              preferredSystemUiMode: SystemUiMode.immersiveSticky,
              restoreSystemUiMode: SystemUiMode.edgeToEdge,
              preferredOrientations: AppOrientationService.readerOrientations,
              restoreOrientations: AppOrientationService.defaultOrientations,
              restoreSystemUiOverlayStyle: AppSystemChromeStyle.defaultAppStyle,
              onShareRequested: onShareRequested,
              onShowIndex: onShowIndex,
              viewSwitchAction: viewSwitchAction,
              headerImageFilter: Theme.of(
                context,
              ).extension<QuranReaderTheme>()?.headerImageFilter,
            );
          }

          if (state is NavigationError) {
            return Scaffold(
              body: TilawaErrorState(
                icon: Icons.error_outline_rounded,
                title: context.l10n.error,
                retryLabel: context.l10n.retry,
                onRetry: () => context.read<NavigationBloc>().add(
                  const NavigationRetryRequested(),
                ),
                iconColor: Theme.of(context).colorScheme.error,
              ),
            );
          }

          return const Scaffold(
            body: TilawaLoadingIndicator(),
          );
        },
      ),
    );
  }
}
