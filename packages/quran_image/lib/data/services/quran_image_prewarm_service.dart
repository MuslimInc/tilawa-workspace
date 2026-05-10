import 'dart:async';
import 'dart:collection';

import 'package:quran_image/core/constants/surah_header_constants.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/domain/entities/page_state.dart';
import 'package:quran_image/domain/repositories/quran_image_cache_repository.dart';
import 'package:quran_image/domain/services/decoded_quran_image_cache.dart';
import 'package:quran_image/domain/services/quran_image_prewarmer.dart';

class QuranImagePrewarmService implements QuranImagePrewarmer {
  QuranImagePrewarmService({
    required QuranImageCacheRepository imageCacheRepository,
    required DecodedQuranImageCache decodedImageCache,
  }) : _imageCacheRepository = imageCacheRepository,
       _decodedImageCache = decodedImageCache;

  static const int _prewarmRadius = 1;
  // 5 images per batch keeps decode-completion callback bursts small enough
  // that the main isolate can respond to vsync signals between completions.
  // 8 was causing 45-image bursts that stalled vsync for 60-140ms.
  static const int _prewarmImagesPerBatch = 5;
  static const int _prewarmBatchBudgetMs = 2;
  // 32ms (2 frames at 60Hz) between batches gives the event loop time to
  // process vsync callbacks between decode-completion bursts.
  static const Duration _prewarmBatchDelay = Duration(milliseconds: 32);
  static const Duration _previewTargetDebounce = Duration(milliseconds: 180);
  static const Duration _settledWindowPrewarmDelay = Duration(
    milliseconds: 220,
  );
  static const Duration _initialWindowPrewarmDelay = Duration(
    milliseconds: 1500,
  );
  static const int _maxReadyPages = 6;

  final QuranImageCacheRepository _imageCacheRepository;
  final DecodedQuranImageCache _decodedImageCache;
  final Queue<_PrewarmImageRequest> _prewarmQueue =
      Queue<_PrewarmImageRequest>();

  Timer? _prewarmDrainTimer;
  Timer? _previewImmediateTimer;
  Timer? _windowPrewarmTimer;
  bool _prewarmDrainScheduled = false;
  int _generation = 0;
  int _lastPrewarmedCenter = -1;
  int _lastPrewarmedCacheWidth = -1;
  int _lastPrewarmedRadius = -1;
  final LinkedHashMap<String, Future<void>> _pageWarmFutures =
      LinkedHashMap<String, Future<void>>();
  final LinkedHashSet<String> _readyPageKeys = LinkedHashSet<String>();

  // Tracks the last page for which preview prewarm actually fired.
  int _lastPreviewImmediatePage = -1;
  int _lastPreviewImmediateCacheWidth = -1;
  int _pendingPreviewImmediatePage = -1;
  int _pendingPreviewImmediateCacheWidth = -1;

  @override
  void startInitialPrewarm({
    required int currentPageNumber,
    required int cacheWidth,
  }) {
    _prewarmSurahHeaderBanner();
    final initialTargetPage = currentPageNumber < PageState.quranPageCount
        ? currentPageNumber + 1
        : currentPageNumber;
    prewarmCurrentTarget(pageNumber: initialTargetPage, cacheWidth: cacheWidth);
    PerfLogger.log(
      widgetName: 'QuranImagePrewarmService',
      message:
          'initial prewarm started targetPage=$initialTargetPage '
          'windowDelayMs=${_initialWindowPrewarmDelay.inMilliseconds}',
    );
    _scheduleWindowPrewarm(
      currentPageNumber,
      cacheWidth: cacheWidth,
      reason: 'initial-window',
      delay: _initialWindowPrewarmDelay,
    );
  }

  @override
  void prewarmCurrentTarget({
    required int pageNumber,
    required int cacheWidth,
  }) {
    _previewImmediateTimer?.cancel();
    unawaited(ensurePageReady(pageNumber: pageNumber, cacheWidth: cacheWidth));
    _prewarmAround(
      pageNumber,
      cacheWidth: cacheWidth,
      radius: 0,
      reason: 'current-target',
    );
  }

  @override
  void prewarmPreviewTarget({
    required int pageNumber,
    required int cacheWidth,
  }) {
    // Keep preview prewarm latest-only. Rapid scrubs should not schedule
    // preview windows or decode every intermediate page the thumb crosses.
    // The final jump path explicitly awaits target readiness before commit.
    _pendingPreviewImmediatePage = pageNumber;
    _pendingPreviewImmediateCacheWidth = cacheWidth;
    _previewImmediateTimer?.cancel();
    _previewImmediateTimer = Timer(
      _previewTargetDebounce,
      _flushPreviewImmediate,
    );
  }

  @override
  void prewarmJumpTarget({required int pageNumber, required int cacheWidth}) {
    _previewImmediateTimer?.cancel();
    _windowPrewarmTimer?.cancel();

    // Reset dedup state unconditionally. Without this reset, a page that was
    // previously visited via slider preview keeps _lastPrewarmedCenter == target,
    // causing _prewarmAround to skip the enqueue entirely — and the jump path
    // loses its chance to start decode work immediately.
    _lastPrewarmedCenter = -1;
    _lastPrewarmedCacheWidth = -1;
    _lastPrewarmedRadius = -1;
    _lastPreviewImmediatePage = -1;
    _lastPreviewImmediateCacheWidth = -1;
    _pendingPreviewImmediatePage = -1;
    _pendingPreviewImmediateCacheWidth = -1;

    unawaited(ensurePageReady(pageNumber: pageNumber, cacheWidth: cacheWidth));

    // Also enqueue via the normal drain path as a safety net (e.g. if the
    // LRU cache evicts an entry between resolve and paint on a low-memory device).
    _prewarmAround(
      pageNumber,
      cacheWidth: cacheWidth,
      radius: 0,
      reason: 'jump-target',
    );
  }

  @override
  Future<void> ensurePageReady({
    required int pageNumber,
    required int cacheWidth,
  }) async {
    final profileSw = PerfLogger.isQuranPerfEnabled
        ? (Stopwatch()..start())
        : null;
    if (!_imageCacheRepository.status.isReady || cacheWidth <= 0) return;
    final requestGeneration = _generation;
    final safeTarget = pageNumber.clamp(1, PageState.quranPageCount).toInt();
    final pageKey = '$cacheWidth:$safeTarget';
    if (_readyPageKeys.remove(pageKey)) {
      _readyPageKeys.add(pageKey);
      if (profileSw != null) {
        PerfLogger.logQuranPerf(
          '[QuranPerf][Prewarm]',
          'ensurePageReady page=$safeTarget elapsedMs=${profileSw.elapsedMilliseconds} '
              'outcome=readyKeyHit cacheKnown=true',
        );
      }
      return;
    }

    final pending = _pageWarmFutures.remove(pageKey);
    if (pending != null) {
      _pageWarmFutures[pageKey] = pending;
      await pending;
      if (profileSw != null && requestGeneration == _generation) {
        PerfLogger.logQuranPerf(
          '[QuranPerf][Prewarm]',
          'ensurePageReady page=$safeTarget elapsedMs=${profileSw.elapsedMilliseconds} '
              'outcome=awaitedInFlight cacheKnown=false',
        );
      }
      return;
    }

    final future = _warmPageImmediate(
      safeTarget,
      cacheWidth,
      reason: 'ensure-page',
    );
    _pageWarmFutures[pageKey] = future;
    try {
      await future;
      if (requestGeneration == _generation) {
        _rememberReadyPageKey(pageKey);
        if (profileSw != null) {
          PerfLogger.logQuranPerf(
            '[QuranPerf][Prewarm]',
            'ensurePageReady page=$safeTarget elapsedMs=${profileSw.elapsedMilliseconds} '
                'outcome=warmed cacheKnown=true',
          );
        }
      }
    } catch (error) {
      PerfLogger.log(
        widgetName: 'QuranImagePrewarmService',
        message:
            'page warm failed '
            'page=$safeTarget '
            'cacheWidth=$cacheWidth '
            'error=$error',
      );
    } finally {
      final current = _pageWarmFutures[pageKey];
      if (identical(current, future)) {
        _pageWarmFutures.remove(pageKey);
      }
    }
  }

  // Maximum line images resolved concurrently per batch inside _warmPageImmediate.
  // Firing all 15 at once causes a burst of ~15 ImageStreamListener callbacks
  // arriving simultaneously on the main isolate ~110-130ms later, which lands
  // during a vsync window and pushes raster time over the 20ms budget.
  // Batching at 5 spreads the burst across 3 groups; each group's callbacks
  // complete and fire before the next group starts, so no single frame sees
  // more than ~5 concurrent decode completions.
  static const int _warmBatchSize = 5;

  Future<void> _warmPageImmediate(
    int pageNumber,
    int cacheWidth, {
    required String reason,
  }) async {
    final paths = <String>[];
    for (var line = 1; line <= SurahHeaderConstants.lineCount; line++) {
      final path = _imageCacheRepository.lineImageFilePath(
        pageNumber: pageNumber,
        oneBasedLineNumber: line,
      );
      if (path != null) paths.add(path);
    }
    if (paths.isEmpty) return;

    final bannerPath = _imageCacheRepository.surahHeaderBannerFilePath();

    final sw = Stopwatch()..start();
    var failedCount = 0;
    Object? firstError;
    StackTrace? firstStackTrace;

    Future<void> runFuture(Future<void> future) async {
      try {
        await future;
      } catch (error, stackTrace) {
        failedCount++;
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    // Resolve line images in batches of _warmBatchSize. Each batch is awaited
    // before starting the next so that callback bursts are spread across
    // separate event-loop turns rather than all arriving in the same vsync.
    for (var i = 0; i < paths.length; i += _warmBatchSize) {
      final end = (i + _warmBatchSize).clamp(0, paths.length);
      final batch = paths.sublist(i, end);
      await Future.wait(
        batch.map(
          (path) => runFuture(
            _decodedImageCache.prewarmLineImage(
              imagePath: path,
              cacheWidth: cacheWidth,
            ),
          ),
        ),
      );
    }

    // Banner is a single file image — resolve it last, outside the line batches.
    if (bannerPath != null) {
      await runFuture(_decodedImageCache.prewarmFileImage(bannerPath));
    }

    if (firstError != null) {
      PerfLogger.log(
        widgetName: 'QuranImagePrewarmService',
        message:
            'page warm incomplete '
            'reason=$reason '
            'page=$pageNumber '
            'images=${paths.length} '
            'failed=$failedCount '
            'elapsedMs=${sw.elapsedMilliseconds}',
      );
      Error.throwWithStackTrace(firstError!, firstStackTrace!);
    }
    PerfLogger.log(
      widgetName: 'QuranImagePrewarmService',
      message:
          'page ready '
          'reason=$reason '
          'page=$pageNumber '
          'images=${paths.length} '
          'elapsedMs=${sw.elapsedMilliseconds}',
    );
  }

  @override
  void prewarmSettledWindow({
    required int pageNumber,
    required int cacheWidth,
  }) {
    _scheduleWindowPrewarm(
      pageNumber,
      cacheWidth: cacheWidth,
      reason: 'settled-window',
      delay: _settledWindowPrewarmDelay,
    );
  }

  @override
  void cancel() {
    _generation++;
    _previewImmediateTimer?.cancel();
    _windowPrewarmTimer?.cancel();
    _prewarmDrainTimer?.cancel();
    _previewImmediateTimer = null;
    _windowPrewarmTimer = null;
    _prewarmDrainTimer = null;
    _prewarmDrainScheduled = false;
    _prewarmQueue.clear();
    _lastPrewarmedCenter = -1;
    _lastPrewarmedCacheWidth = -1;
    _lastPrewarmedRadius = -1;
    _lastPreviewImmediatePage = -1;
    _lastPreviewImmediateCacheWidth = -1;
    _pendingPreviewImmediatePage = -1;
    _pendingPreviewImmediateCacheWidth = -1;
    _pageWarmFutures.clear();
    _readyPageKeys.clear();
  }

  @override
  void handleMemoryPressure() {
    cancel();
    _decodedImageCache.handleMemoryPressure();
    PerfLogger.log(
      widgetName: 'QuranImagePrewarmService',
      message: 'memory pressure handled readyPagesCleared=true',
    );
  }

  @override
  void dispose() => cancel();

  void _prewarmSurahHeaderBanner() {
    final bannerPath = _imageCacheRepository.surahHeaderBannerFilePath();
    if (bannerPath == null) return;
    unawaited(_decodedImageCache.prewarmFileImage(bannerPath));
  }

  void _flushPreviewImmediate() {
    _previewImmediateTimer = null;
    final pageNumber = _pendingPreviewImmediatePage;
    final cacheWidth = _pendingPreviewImmediateCacheWidth;
    if (pageNumber <= 0 || cacheWidth <= 0) return;
    if (_lastPreviewImmediatePage == pageNumber &&
        _lastPreviewImmediateCacheWidth == cacheWidth) {
      return;
    }

    _lastPreviewImmediatePage = pageNumber;
    _lastPreviewImmediateCacheWidth = cacheWidth;
    unawaited(ensurePageReady(pageNumber: pageNumber, cacheWidth: cacheWidth));
  }

  void _scheduleWindowPrewarm(
    int centerPageNumber, {
    required int cacheWidth,
    required String reason,
    required Duration delay,
  }) {
    _windowPrewarmTimer?.cancel();
    _windowPrewarmTimer = Timer(delay, () {
      _prewarmAround(
        centerPageNumber,
        cacheWidth: cacheWidth,
        radius: _prewarmRadius,
        reason: reason,
      );
    });
  }

  void _prewarmAround(
    int centerPageNumber, {
    required int cacheWidth,
    required int radius,
    required String reason,
  }) {
    if (!_imageCacheRepository.status.isReady || cacheWidth <= 0) return;

    final safeCenter = centerPageNumber
        .clamp(1, PageState.quranPageCount)
        .toInt();
    if (_lastPrewarmedCenter == safeCenter &&
        _lastPrewarmedCacheWidth == cacheWidth &&
        _lastPrewarmedRadius == radius) {
      return;
    }

    _lastPrewarmedCenter = safeCenter;
    _lastPrewarmedCacheWidth = cacheWidth;
    _lastPrewarmedRadius = radius;

    final first = (safeCenter - radius)
        .clamp(1, PageState.quranPageCount)
        .toInt();
    final last = (safeCenter + radius)
        .clamp(1, PageState.quranPageCount)
        .toInt();

    _prewarmQueue.clear();
    for (var d = 0; d <= radius; d++) {
      final pages = d == 0
          ? <int>[safeCenter]
          : <int>[safeCenter - d, safeCenter + d];
      for (final pageNumber in pages) {
        if (pageNumber < first || pageNumber > last) continue;
        _enqueuePage(pageNumber, cacheWidth);
      }
    }

    PerfLogger.log(
      widgetName: 'QuranImagePrewarmService',
      message:
          'prewarm enqueued pages=$first-$last '
          'center=$safeCenter '
          'radius=$radius '
          'reason=$reason '
          'cacheWidth=$cacheWidth '
          'images=${_prewarmQueue.length}',
    );

    _scheduleDrain();
  }

  void _enqueuePage(int pageNumber, int cacheWidth) {
    for (var line = 1; line <= SurahHeaderConstants.lineCount; line++) {
      final path = _imageCacheRepository.lineImageFilePath(
        pageNumber: pageNumber,
        oneBasedLineNumber: line,
      );
      if (path == null) continue;
      _prewarmQueue.add(
        _PrewarmImageRequest(imagePath: path, cacheWidth: cacheWidth),
      );
    }
  }

  void _scheduleDrain() {
    if (_prewarmDrainScheduled || _prewarmQueue.isEmpty) return;
    _prewarmDrainScheduled = true;
    // Use _prewarmBatchDelay (32ms) for the initial drain too, not Duration.zero.
    // Duration.zero fires on the next event-loop tick (before the next vsync),
    // causing the first batch's resolve() calls to compete with the current frame
    // build and contribute to vsync stalls. A 32ms delay pushes the first batch
    // past the current and next frame, letting the UI thread breathe first.
    _prewarmDrainTimer = Timer(_prewarmBatchDelay, _drainBatch);
  }

  void _drainBatch() {
    _prewarmDrainScheduled = false;
    if (_prewarmQueue.isEmpty) return;

    final sw = Stopwatch()..start();
    var scheduled = 0;

    while (_prewarmQueue.isNotEmpty &&
        scheduled < _prewarmImagesPerBatch &&
        sw.elapsedMilliseconds < _prewarmBatchBudgetMs) {
      final request = _prewarmQueue.removeFirst();
      unawaited(
        _decodedImageCache.prewarmLineImage(
          imagePath: request.imagePath,
          cacheWidth: request.cacheWidth,
        ),
      );
      scheduled++;
    }

    if (_prewarmQueue.isNotEmpty) {
      _prewarmDrainScheduled = true;
      _prewarmDrainTimer = Timer(_prewarmBatchDelay, _drainBatch);
    }
  }

  void _rememberReadyPageKey(String key) {
    _readyPageKeys.remove(key);
    _readyPageKeys.add(key);
    while (_readyPageKeys.length > _maxReadyPages) {
      _readyPageKeys.remove(_readyPageKeys.first);
    }
  }
}

class _PrewarmImageRequest {
  const _PrewarmImageRequest({
    required this.imagePath,
    required this.cacheWidth,
  });

  final String imagePath;
  final int cacheWidth;
}
