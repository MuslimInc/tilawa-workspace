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
import 'package:tilawa_core/logger.dart';

import '../../../../features/audio_player/presentation/bloc/audio_player_bloc.dart'
    show AudioPlayerBloc;
import '../../../../features/share/presentation/cubit/share_cubit.dart';
import '../../../../features/share/presentation/screens/screenshot_composer_screen.dart';
import '../../../../features/share/presentation/screens/video_reel_composer_screen.dart';
import '../../../../features/share/presentation/widgets/share_options_sheet.dart';
import '../bloc/quran_font_loader_bloc.dart';

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

  Future<void> _showShareOptions(int currentPage) async {
    // Read context-dependent values before the async gap.
    final pageData = getPageData(currentPage);
    final primarySurahNumber = pageData.first.surah;
    final primarySurahEntries = pageData
        .where((entry) => entry.surah == primarySurahNumber)
        .toList();
    final firstAyah = primarySurahEntries.first.start;
    final lastAyah = primarySurahEntries.last.end;

    final audioState = context.read<AudioPlayerBloc>().state;
    final reciterName = audioState.currentAudio?.artist ?? 'Al-Afasy';
    final serverUrl = audioState.currentAudio?.url ?? '';
    final shareCubit = context.read<ShareCubit>();
    final fontLoaderBloc = context.read<QuranFontLoaderBloc>();
    final navigator = Navigator.of(context);

    fontLoaderBloc.pauseBackgroundWarmUp();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
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

            navigator.push(
              ScreenshotComposerScreen.route(
                cubit: shareCubit,
                surahNumber: selectedSurah,
                currentPage: currentPage,
                initialFromAyah: firstAyah,
                initialToAyah: lastAyah,
                reciterName: reciterName,
                readerBoundaryKey: _dummyBoundaryKey,
              ),
            );
          },
          onShareVideoReel: (selectedSurah) {
            final surahEntries = pageData
                .where((entry) => entry.surah == selectedSurah)
                .toList();
            final firstAyah = surahEntries.first.start;
            final lastAyah = surahEntries.last.end;

            navigator.push(
              VideoReelComposerScreen.route(
                cubit: shareCubit,
                surahNumber: selectedSurah,
                currentPage: currentPage,
                initialFromAyah: firstAyah,
                initialToAyah: lastAyah,
                reciterName: reciterName,
                reciterServerUrl: serverUrl,
                readerBoundaryKey: _dummyBoundaryKey,
              ),
            );
          },
        ),
      );
    } finally {
      fontLoaderBloc.resumeBackgroundWarmUp();
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
            preferredSystemUiMode: SystemUiMode.immersiveSticky,
            restoreSystemUiMode: SystemUiMode.edgeToEdge,
            preferredOrientations: const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
            restoreOrientations: const [DeviceOrientation.portraitUp],
            onShareRequested: onShareRequested,
          );
        }

        if (state is NavigationError) {
          return Scaffold(
            backgroundColor: const Color(0xFFFFF9F2),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Color(0xFF8A2D2D),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Failed to initialize the reader.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Color(0xFF5D4037)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.read<NavigationBloc>().add(
                        const NavigationRetryRequested(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const Scaffold(backgroundColor: Color(0xFFFFF9F2));
      },
    );
  }
}
