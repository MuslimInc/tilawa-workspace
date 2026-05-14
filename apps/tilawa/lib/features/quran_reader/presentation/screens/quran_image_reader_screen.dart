import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/di/dependency_injection.dart' as qi_di;
import 'package:quran_image/data/repositories/asset_verse_marker_repository.dart';
import 'package:quran_image/domain/repositories/quran_image_cache_repository.dart';
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
import '../../../../features/audio_player/presentation/bloc/audio_player_bloc.dart'
    show AudioPlayerBloc;
import '../../../../features/share/presentation/widgets/share_options_sheet.dart';
import '../../domain/usecases/load_quran_fonts_to_engine_use_case.dart';
import '../theme/quran_reader_theme.dart';

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
  });

  /// Surah number to open (`1`–`114`), or `0` to use last-read.
  final int surahNumber;

  /// Optional ayah to jump to within the surah.
  final int? initialAyah;

  @override
  State<QuranImageReaderScreen> createState() => _QuranImageReaderScreenState();
}

class _QuranImageReaderScreenState extends State<QuranImageReaderScreen> {
  bool _isPreloaded = false;
  NavigationBloc? _navigationBloc;

  // Stable fallback key — no RenderRepaintBoundary is attached here, so the
  // share composer will simply skip the reader-page screenshot preview for
  // the image-based reader. This is intentional: the image reader already
  // shows the page as a high-quality cached image, so a live capture is
  // unnecessary.
  final GlobalKey _dummyBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkPreloadStatus();
  }

  @override
  void dispose() {
    _navigationBloc?.close();
    super.dispose();
  }

  /// Checks whether the quran_image cache is already ready.
  void _checkPreloadStatus() {
    final markerRepo = qi_di.sl<AssetVerseMarkerRepository>();
    final imageRepo = qi_di.sl<QuranImageCacheRepository>();
    final alreadyReady = markerRepo.isInitialized && imageRepo.status.isReady;

    if (alreadyReady) {
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
      '[QuranImageReaderScreen] NavigationBloc initialized with page: $initialPage',
    );
  }

  void _onPreloadComplete() {
    if (!mounted) return;
    _initNavigationBloc();
    setState(() => _isPreloaded = true);
    logger.d(
      '[QuranImageReaderScreen] preload complete — '
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

  @override
  Widget build(BuildContext context) {
    if (!_isPreloaded) {
      return PreloadingScreen(onPreloadComplete: _onPreloadComplete);
    }

    final bloc = _navigationBloc!;

    return BlocProvider<NavigationBloc>.value(
      value: bloc,
      child: _ReaderShell(onShareRequested: _showShareOptions),
    );
  }
}

/// Inner shell that watches [NavigationBloc] state to show
/// loading → error → reader transitions.
class _ReaderShell extends StatelessWidget {
  const _ReaderShell({required this.onShareRequested});

  final Future<void> Function(int currentPage) onShareRequested;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (previous, current) {
        if (previous is NavigationLoaded && current is NavigationLoaded) {
          return false;
        }
        return current is NavigationLoaded || current is NavigationError;
      },
      builder: (context, state) {
        if (state is NavigationLoaded) {
          return QuranImageReader(
            preferredSystemUiMode: SystemUiMode.edgeToEdge,
            restoreSystemUiMode: SystemUiMode.edgeToEdge,
            preferredOrientations: AppOrientationService.readerOrientations,
            restoreOrientations: AppOrientationService.defaultOrientations,
            restoreSystemUiOverlayStyle: AppSystemChromeStyle.defaultAppStyle,
            onShareRequested: onShareRequested,
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
    );
  }
}
