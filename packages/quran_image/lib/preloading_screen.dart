import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:quran_image/data/repositories/asset_verse_marker_repository.dart';
import 'package:quran_image/domain/repositories/quran_image_cache_repository.dart';
import 'package:quran_image/domain/services/decoded_quran_image_cache.dart';
import 'package:quran_image/verse_marker.dart';

import 'core/di/dependency_injection.dart';
import 'domain/entities/app_message.dart';
import 'domain/entities/page_state.dart';
import 'domain/entities/quran_image_cache_status.dart';
import 'domain/usecases/get_last_visited_page.dart';
import 'domain/usecases/prepare_quran_image_cache.dart';
import 'l10n/quran_image_localizations.dart';
import 'presentation/mappers/app_message_mapper.dart';

/// Loading screen shown while the Quran image cache is being prepared
/// and (in debug mode) verse marker files are being preloaded.
class PreloadingScreen extends StatefulWidget {
  final VoidCallback onPreloadComplete;

  const PreloadingScreen({super.key, required this.onPreloadComplete});

  @override
  State<PreloadingScreen> createState() => _PreloadingScreenState();
}

class _PreloadingScreenState extends State<PreloadingScreen> {
  static const String _logSource = 'PreloadingScreen';
  static const Duration _statusPollInterval = Duration(milliseconds: 200);

  QuranImageCacheStatus _cacheStatus = const QuranImageCacheStatus.checking();
  AppMessage? _errorAppMessage;
  bool _isPreparing = false;
  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();
    _log('preload scheduled afterFirstFrame=true');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      _log('preload starting afterFirstFrameDelayMs=100');
      _waitForPreload();
    });
  }

  @override
  void dispose() {
    _stopStatusPolling();
    super.dispose();
  }

  Future<void> _waitForPreload() async {
    if (_isPreparing) return;

    final preloadTimer = PerfLogger.startTimer();
    final markerRepo = sl<AssetVerseMarkerRepository>();
    final initialPageFuture = sl<GetLastVisitedPageUseCase>().executeOrDefault(
      1,
    );
    final markerTimer = markerRepo.isInitialized
        ? null
        : PerfLogger.startTimer();
    final Future<Object?> markerInitResult = markerRepo.isInitialized
        ? Future<Object?>.value(null)
        : markerRepo.init().then<Object?>(
            (_) => null,
            onError: (Object error, _) => error,
          );

    _log('preload started');
    if (markerRepo.isInitialized) {
      _log('marker init skipped alreadyInitialized=true');
    } else {
      _log('marker init started concurrent=true');
    }
    setState(() {
      _errorAppMessage = null;
      _isPreparing = true;
    });
    _startStatusPolling();

    // ── Step 1: prepare image cache ─────────────────────────────────────────
    final cacheTimer = PerfLogger.startTimer();
    final cacheStatus = await sl<PrepareQuranImageCacheUseCase>()(
      onProgress: (status) {
        if (!mounted) return;
        if (status.isReady) {
          _log('ready status received; deferring UI update until handoff');
          return;
        }
        setState(() => _cacheStatus = status);
      },
    );
    PerfLogger.logElapsed(
      cacheTimer,
      widgetName: _logSource,
      message:
          'cache prepare completed phase=${cacheStatus.phase.name} '
          'ready=${cacheStatus.isReady}',
    );

    if (!cacheStatus.isReady) {
      _log(
        'preload cache not ready phase=${cacheStatus.phase.name} '
        'error=${cacheStatus.errorMessage}',
      );
      if (mounted) {
        setState(() {
          _cacheStatus = cacheStatus;
          _errorAppMessage =
              cacheStatus.errorMessage?.toAppMessage() ??
              const CachePreparationFailedMessage();
          _isPreparing = false;
        });
      }
      _stopStatusPolling();
      PerfLogger.logElapsed(
        preloadTimer,
        widgetName: _logSource,
        message: 'preload failed reason=cachePrepare',
      );
      return;
    }

    // ── Step 2: init verse markers ───────────────────────────────────────────
    // Always initialize here (not deferred to the reader) so markers are
    // ready the moment the reader opens — matching the native Ayah app.
    final markerInitError = await markerInitResult;
    if (markerTimer != null) {
      PerfLogger.logElapsed(
        markerTimer,
        widgetName: _logSource,
        message: markerInitError == null
            ? 'marker init completed'
            : 'marker init failed',
      );
    }
    if (markerInitError != null) {
      debugPrint('[PreloadingScreen] marker init error: $markerInitError');
      if (mounted) {
        setState(() {
          _errorAppMessage = const CachePreparationFailedMessage();
          _isPreparing = false;
        });
      }
      _stopStatusPolling();
      PerfLogger.logElapsed(
        preloadTimer,
        widgetName: _logSource,
        message: 'preload failed reason=markerInit',
      );
      return;
    }

    // ── Step 3: prewarm initial page images ──────────────────────────────────
    // Resolve and decode all 15 line images for the page the reader will open
    // on. The reader only becomes visible once the initial page images have
    // been decoded into Flutter's image cache.
    if (!mounted) return;
    await _prewarmInitialPage(
      initialPage: await initialPageFuture,
      markerRepo: markerRepo,
    );

    if (mounted) {
      _stopStatusPolling();
      PerfLogger.logElapsed(
        preloadTimer,
        widgetName: _logSource,
        message: 'preload completed',
      );
      widget.onPreloadComplete();
    }
  }

  void _startStatusPolling() {
    if (_statusPollTimer != null) return;
    _statusPollTimer = Timer.periodic(_statusPollInterval, (_) {
      if (!mounted || !_isPreparing) return;
      final latestStatus = sl<QuranImageCacheRepository>().status;
      if (latestStatus.isReady || latestStatus == _cacheStatus) return;
      setState(() => _cacheStatus = latestStatus);
    });
  }

  void _stopStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = null;
  }

  /// Prewarms all 15 line images for the initial page before the reader opens.
  Future<void> _prewarmInitialPage({
    required int initialPage,
    required AssetVerseMarkerRepository markerRepo,
  }) async {
    final imageRepo = sl<QuranImageCacheRepository>();
    if (!imageRepo.status.isReady) return;

    final safeInitialPage = initialPage.clamp(1, PageState.quranPageCount);

    // Resolve physical pixel width from the platform dispatcher's implicit view.
    final flutterView = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (flutterView == null) return;
    // Use the minimum of physical width and height so cacheWidth is the
    // portrait-page width regardless of orientation at startup. This must
    // match the formula used in QuranImageReader and QuranImagePage so all
    // three agree on the same cacheWidth key.
    final cacheWidth =
        flutterView.physicalSize.width < flutterView.physicalSize.height
        ? flutterView.physicalSize.width.round()
        : flutterView.physicalSize.height.round();
    if (cacheWidth <= 0) return;

    // Collect paths for all 15 line images.
    final paths = <String>[];
    for (var line = 1; line <= 15; line++) {
      final path = imageRepo.lineImageFilePath(
        pageNumber: safeInitialPage,
        oneBasedLineNumber: line,
      );
      if (path != null) paths.add(path);
    }
    if (paths.isEmpty) return;

    _log(
      'initial page prewarm started '
      'page=$safeInitialPage '
      'images=${paths.length} '
      'cacheWidth=$cacheWidth',
    );

    final prewarmTimer = PerfLogger.startTimer();
    final decodedCache = sl<DecodedQuranImageCache>();
    final warmUpMarkerNumbers = <int>{};

    for (final marker in markerRepo.getMarkersForPage(safeInitialPage)) {
      warmUpMarkerNumbers.add(marker.ayah);
    }
    if (safeInitialPage < PageState.quranPageCount) {
      for (final marker in markerRepo.getMarkersForPage(safeInitialPage + 1)) {
        warmUpMarkerNumbers.add(marker.ayah);
      }
    }

    // Fire decode for all 15 images first so that image work can overlap with
    // the marker warm-up below instead of starting afterwards.
    final resolveTimer = PerfLogger.startTimer();
    final imageWarmFutures = <Future<void>>[
      for (final path in paths)
        decodedCache.prewarmLineImage(imagePath: path, cacheWidth: cacheWidth),
    ];
    PerfLogger.logElapsed(
      resolveTimer,
      widgetName: _logSource,
      message:
          'initial page resolve fired '
          'page=$safeInitialPage '
          'images=${paths.length}',
    );

    // Warm only the current page and immediate swipe-target ayah markers on
    // the startup path. The remaining markers are warmed in the background once
    // the reader is already interactive.
    final dpr = flutterView.devicePixelRatio;
    final screenWidth = flutterView.physicalSize.width / dpr;
    final markerWidth = screenWidth * 0.05138889;
    final warmUpTimer = PerfLogger.startTimer();
    await VerseMarker.warmUpNumbers(
      markerWidth: markerWidth,
      verseNumbers: warmUpMarkerNumbers.isEmpty
          ? const <int>[1]
          : warmUpMarkerNumbers,
    );
    PerfLogger.logElapsed(
      warmUpTimer,
      widgetName: _logSource,
      message:
          'verse marker warm-up completed '
          'markerWidth=${markerWidth.toStringAsFixed(1)} '
          'glyphs=${warmUpMarkerNumbers.length}',
    );
    await Future.wait(imageWarmFutures);
    PerfLogger.logElapsed(
      prewarmTimer,
      widgetName: _logSource,
      message: 'initial page prewarm ready page=$safeInitialPage',
    );
  }

  static void _log(String message) {
    PerfLogger.log(widgetName: _logSource, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final sw = PerfLogger.startTimer();
    final l10n = QuranImageLocalizations.of(context);
    final repo = sl<AssetVerseMarkerRepository>();
    final markerProgress = repo.preloadProgress;
    final progress = _cacheStatus.isReady
        ? markerProgress
        : _cacheStatus.progress;
    final errorAppMessage = _errorAppMessage;

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TilawaProductColors product = theme.productColors;

    final scaffold = Scaffold(
      backgroundColor: product.quranPageBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              const AppTitleMessage().localize(l10n),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: product.quranTextPrimary,
              ),
            ),
            const SizedBox(height: 40),
            if (errorAppMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  errorAppMessage.localize(l10n),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _waitForPreload,
                child: Text(const RetryMessage().localize(l10n)),
              ),
            ] else if (!_cacheStatus.isReady) ...[
              Text(
                _cacheStatus.phase.toAppMessage().localize(l10n),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _ProgressBar(progress: progress),
            ] else ...[
              if (repo.isDebugMode) ...[
                Text(
                  const PreparingQuranMessage().localize(l10n),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _ProgressBar(
                  progress: progress,
                  subtitle: PageIndicatorMessage(
                    current: (progress * PageState.quranPageCount)
                        .toStringAsFixed(0),
                    total: PageState.quranPageCount.toString(),
                  ).localize(l10n),
                ),
              ] else ...[
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ],
            ],
          ],
        ),
      ),
    );

    PerfLogger.logElapsed(
      sw,
      widgetName: _logSource,
      message:
          'build phase=${_cacheStatus.phase.name} '
          'ready=${_cacheStatus.isReady} '
          'isPreparing=$_isPreparing '
          'error=${errorAppMessage != null}',
    );
    return scaffold;
  }
}

// ---------------------------------------------------------------------------
// Shared progress bar widget
// ---------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, this.subtitle});

  final double progress;

  /// Optional line of text shown below the percentage label.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final percentage = (progress * 100).toStringAsFixed(0);
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 8,
          child: CustomPaint(
            painter: _ProgressBarPainter(
              progress: progress.clamp(0.0, 1.0),
              trackColor: scheme.outlineVariant,
              fillColor: scheme.primary,
              radius: 4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$percentage%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: scheme.success,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  const _ProgressBarPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.radius,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = Radius.circular(radius);
    final trackRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, rr),
      Paint()..color = trackColor,
    );
    if (progress > 0) {
      final fillRect = Rect.fromLTWH(0, 0, size.width * progress, size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, rr),
        Paint()..color = fillColor,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressBarPainter old) => old.progress != progress;
}
