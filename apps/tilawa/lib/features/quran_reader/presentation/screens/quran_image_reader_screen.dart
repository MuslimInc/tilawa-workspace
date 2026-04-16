import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_image/core/di/dependency_injection.dart' as qi_di;
import 'package:quran_image/data/repositories/asset_verse_marker_repository.dart';
import 'package:quran_image/domain/repositories/quran_image_cache_repository.dart';
import 'package:quran_image/preloading_screen.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_event.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';
import 'package:quran_image/quran_image_reader.dart';
import 'package:tilawa_core/logger.dart';

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
  ///
  /// If the user already went through the preloading screen in this
  /// session, the cache and marker repos will be initialized and we
  /// can skip straight to the reader.
  void _checkPreloadStatus() {
    final markerRepo = qi_di.sl<AssetVerseMarkerRepository>();
    final imageRepo = qi_di.sl<QuranImageCacheRepository>();
    final alreadyReady = markerRepo.isInitialized && imageRepo.status.isReady;

    if (alreadyReady) {
      _initNavigationBloc();
      _isPreloaded = true;
    }
  }

  /// Initializes the [NavigationBloc] which manages page state and
  /// navigation visibility for the [quran_image] reader.
  void _initNavigationBloc() {
    if (_navigationBloc != null) return;

    int? initialPage;
    if (widget.surahNumber > 0) {
      initialPage = quran.getPageNumber(
        widget.surahNumber,
        widget.initialAyah ?? 1,
      );
    }

    _navigationBloc = NavigationBloc()
      ..add(NavigationInitialized(initialPage: initialPage));
    logger.d(
      '[QuranImageReaderScreen] NavigationBloc initialized with page: $initialPage',
    );
  }

  /// Called by [PreloadingScreen] when the cache and markers are ready.
  void _onPreloadComplete() {
    if (!mounted) return;
    _initNavigationBloc();
    setState(() => _isPreloaded = true);
    logger.d(
      '[QuranImageReaderScreen] preload complete — '
      'transitioning to reader',
    );
  }

  @override
  Widget build(BuildContext context) {
    // During preload, show the quran_image PreloadingScreen.
    if (!_isPreloaded) {
      return PreloadingScreen(onPreloadComplete: _onPreloadComplete);
    }

    // Once preloaded, provide the NavigationBloc and show the reader.
    final bloc = _navigationBloc!;

    return BlocProvider<NavigationBloc>.value(
      value: bloc,
      child: const _ReaderShell(),
    );
  }
}

/// Inner shell that watches [NavigationBloc] state to show
/// loading → error → reader transitions.
class _ReaderShell extends StatelessWidget {
  const _ReaderShell();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (previous, current) {
        // Only rebuild on state-type transitions.
        if (previous is NavigationLoaded && current is NavigationLoaded) {
          return false;
        }
        return current is NavigationLoaded || current is NavigationError;
      },
      builder: (context, state) {
        if (state is NavigationLoaded) {
          return const QuranImageReader(
            preferredSystemUiMode: SystemUiMode.immersiveSticky,
            restoreSystemUiMode: SystemUiMode.edgeToEdge,
            preferredOrientations: [
              DeviceOrientation.portraitUp,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
            restoreOrientations: [DeviceOrientation.portraitUp],
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

        // Loading — silent scaffold matching the quran_image background.
        return const Scaffold(backgroundColor: Color(0xFFFFF9F2));
      },
    );
  }
}
