import 'dart:async';
import 'dart:collection';

import 'package:quran_image_flutter/core/constants/surah_header_constants.dart';
import 'package:quran_image_flutter/core/perf_logger.dart';
import 'package:quran_image_flutter/domain/entities/page_state.dart';
import 'package:quran_image_flutter/domain/repositories/quran_image_cache_repository.dart';
import 'package:quran_image_flutter/domain/services/decoded_quran_image_cache.dart';
import 'package:quran_image_flutter/domain/services/quran_image_prewarmer.dart';

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
  static const Duration _previewImmediateDelay = Duration(milliseconds: 100);
  static const Duration _previewPrewarmDelay = Duration(milliseconds: 80);
  static const Duration _settledWindowPrewarmDelay = Duration(
    milliseconds: 220,
  );
  static const Duration _initialWindowPrewarmDelay = Duration(
    milliseconds: 1500,
  );

  final QuranImageCacheRepository _imageCacheRepository;
  final DecodedQuranImageCache _decodedImageCache;
  final Queue<_PrewarmImageRequest> _prewarmQueue =
      Queue<_PrewarmImageRequest>();

  Timer? _prewarmDrainTimer;
  Timer? _previewImmediateTimer;
  Timer? _previewPrewarmTimer;
  Timer? _windowPrewarmTimer;
  bool _prewarmDrainScheduled = false;
  int _lastPrewarmedCenter = -1;
  int _lastPrewarmedCacheWidth = -1;
  int _lastPrewarmedRadius = -1;

  // Generation token for jump-wait cancellation. Each call to
  // prewarmJumpTargetAndWait increments this before entering the poll loop.
  // The loop compares its captured value against the current token every tick;
  // a mismatch means a newer jump superseded it and the loop exits immediately.
  int _jumpWaitGeneration = 0;

  // Tracks the last page for which preview prewarm actually fired.
  int _lastPreviewImmediatePage = -1;
  int _lastPreviewImmediateCacheWidth = -1;
  int _pendingPreviewImmediatePage = -1;
  int _pendingPreviewImmediateCacheWidth = -1;

  // Poll interval for the decode-completion check. One frame (16 ms) is the
  // right granularity: checking faster wastes CPU, checking slower adds latency.
  static const Duration _jumpPollInterval = Duration(milliseconds: 16);

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
    _previewPrewarmTimer?.cancel();
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
    // Keep preview prewarm latest-only. Rapid slider scrubs should not decode
    // every page the thumb crosses; that created the raster spikes seen in the
    // profile logs. The final hovered page still gets warmed quickly, and the
    // jump path remains protected by prewarmJumpTargetAndWait().
    _pendingPreviewImmediatePage = pageNumber;
    _pendingPreviewImmediateCacheWidth = cacheWidth;
    _previewImmediateTimer?.cancel();
    _previewImmediateTimer = Timer(
      _previewImmediateDelay,
      _flushPreviewImmediate,
    );

    _previewPrewarmTimer?.cancel();
    _previewPrewarmTimer = Timer(_previewPrewarmDelay, () {
      _prewarmAround(
        pageNumber,
        cacheWidth: cacheWidth,
        radius: _prewarmRadius,
        reason: 'preview-window',
      );
    });
  }

  @override
  void prewarmJumpTarget({required int pageNumber, required int cacheWidth}) {
    _previewImmediateTimer?.cancel();
    _previewPrewarmTimer?.cancel();
    _windowPrewarmTimer?.cancel();

    // Reset dedup state unconditionally. Without this reset, a page that was
    // previously visited via slider preview keeps _lastPrewarmedCenter == target,
    // causing _prewarmAround to skip the enqueue entirely — and the jump renders
    // with gray placeholders even though no decode has started.
    _lastPrewarmedCenter = -1;
    _lastPrewarmedCacheWidth = -1;
    _lastPrewarmedRadius = -1;
    _lastPreviewImmediatePage = -1;
    _lastPreviewImmediateCacheWidth = -1;
    _pendingPreviewImmediatePage = -1;
    _pendingPreviewImmediateCacheWidth = -1;

    // Fire resolve() for all 15 line images of the target page IMMEDIATELY —
    // before jumpToPage triggers the first build frame.  The queue drain uses
    // Timer(Duration.zero, …) which fires on the next event-loop tick, i.e.
    // AFTER jumpToPage already built the page with empty placeholders.  By
    // calling _resolve() synchronously here we give the image codec maximum
    // lead time to finish decoding before the raster thread needs to upload.
    _prewarmPageImmediate(pageNumber, cacheWidth, reason: 'jump-target');

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
  Future<void> prewarmJumpTargetAndWait({
    required int pageNumber,
    required int cacheWidth,
    required Duration timeout,
  }) async {
    // Bump the generation before any async gap so a concurrent call to this
    // method (a second jump while we're polling) immediately cancels this one.
    _jumpWaitGeneration++;
    final myGeneration = _jumpWaitGeneration;

    // Start decoding immediately — reuses the existing synchronous resolve path
    // so both the dedup reset and the _prewarmPageImmediate call happen here.
    prewarmJumpTarget(pageNumber: pageNumber, cacheWidth: cacheWidth);

    if (!_imageCacheRepository.status.isReady || cacheWidth <= 0) return;

    final safeTarget = pageNumber.clamp(1, PageState.quranPageCount).toInt();

    // Collect the paths we need to check — mirrors _prewarmPageImmediate.
    final paths = <String>[];
    for (var line = 1; line <= SurahHeaderConstants.lineCount; line++) {
      final path = _imageCacheRepository.lineImageFilePath(
        pageNumber: safeTarget,
        oneBasedLineNumber: line,
      );
      if (path != null) paths.add(path);
    }
    if (paths.isEmpty) return;

    final deadline = DateTime.now().add(timeout);
    final waitTimer = Stopwatch()..start();
    var pollCount = 0;

    while (true) {
      // A newer jump superseded us — abandon without jumping.
      if (_jumpWaitGeneration != myGeneration) {
        PerfLogger.log(
          widgetName: 'QuranImagePrewarmService',
          message:
              'jump-wait cancelled page=$safeTarget '
              'gen=$myGeneration '
              'supersededBy=$_jumpWaitGeneration '
              'elapsedMs=${waitTimer.elapsedMilliseconds} '
              'polls=$pollCount',
        );
        return;
      }

      // Check all paths concurrently — each obtainCacheStatus() call resolves
      // the provider key asynchronously; running them in parallel avoids
      // paying N serial round-trips per poll tick.
      final statuses = await Future.wait(
        paths.map(
          (p) => _decodedImageCache.isLineImageCached(
            imagePath: p,
            cacheWidth: cacheWidth,
          ),
        ),
      );
      pollCount++;
      final readyCount = statuses.where((r) => r).length;
      final allReady = readyCount == paths.length;

      if (allReady) {
        PerfLogger.log(
          widgetName: 'QuranImagePrewarmService',
          message:
              'jump-wait ready page=$safeTarget '
              'gen=$myGeneration '
              'elapsedMs=${waitTimer.elapsedMilliseconds} '
              'polls=$pollCount',
        );
        // Settle delay: give Impeller time to upload textures to GPU before
        // the jump triggers raster work. Without this, jump-wait reports 0ms
        // but the subsequent frame still has slow raster (21-42ms) due to
        // on-demand GPU upload during the first paint. 150ms allows upload
        // to complete on mid-range devices (OPPO A98).
        await Future<void>.delayed(const Duration(milliseconds: 150));
        return;
      }

      if (DateTime.now().isAfter(deadline)) {
        PerfLogger.log(
          widgetName: 'QuranImagePrewarmService',
          message:
              'jump-wait timeout page=$safeTarget '
              'gen=$myGeneration '
              'timeoutMs=${timeout.inMilliseconds} '
              'readyImages=$readyCount/${paths.length} '
              'polls=$pollCount',
        );
        return;
      }

      // Yield one frame to the event loop without blocking the UI thread.
      await Future<void>.delayed(_jumpPollInterval);
    }
  }

  /// Calls [DecodedQuranImageCache.prewarmLineImage] for every line of
  /// [pageNumber] **without** going through the queue or any timer.
  ///
  /// Each call fires [ImageProvider.resolve] synchronously, starting the
  /// image-codec decode pipeline immediately on the current event-loop tick.
  void _prewarmPageImmediate(
    int pageNumber,
    int cacheWidth, {
    String reason = 'immediate',
  }) {
    if (!_imageCacheRepository.status.isReady || cacheWidth <= 0) return;
    final safeCenter = pageNumber.clamp(1, PageState.quranPageCount).toInt();
    for (var line = 1; line <= SurahHeaderConstants.lineCount; line++) {
      final path = _imageCacheRepository.lineImageFilePath(
        pageNumber: safeCenter,
        oneBasedLineNumber: line,
      );
      if (path == null) continue;
      _decodedImageCache.prewarmLineImage(
        imagePath: path,
        cacheWidth: cacheWidth,
      );
    }
    PerfLogger.log(
      widgetName: 'QuranImagePrewarmService',
      message:
          'immediate resolve '
          'reason=$reason '
          'page=$safeCenter '
          'images=${SurahHeaderConstants.lineCount}',
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
    _previewImmediateTimer?.cancel();
    _previewPrewarmTimer?.cancel();
    _windowPrewarmTimer?.cancel();
    _prewarmDrainTimer?.cancel();
    _previewImmediateTimer = null;
    _previewPrewarmTimer = null;
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
  }

  @override
  void dispose() => cancel();

  void _prewarmSurahHeaderBanner() {
    final bannerPath = _imageCacheRepository.surahHeaderBannerFilePath();
    if (bannerPath == null) return;
    _decodedImageCache.prewarmFileImage(bannerPath);
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
    _prewarmPageImmediate(pageNumber, cacheWidth, reason: 'preview-target');
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
      _decodedImageCache.prewarmLineImage(
        imagePath: request.imagePath,
        cacheWidth: request.cacheWidth,
      );
      scheduled++;
    }

    if (_prewarmQueue.isNotEmpty) {
      _prewarmDrainScheduled = true;
      _prewarmDrainTimer = Timer(_prewarmBatchDelay, _drainBatch);
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
