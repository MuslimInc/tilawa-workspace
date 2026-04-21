import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../helpers/app_logger.dart';
import 'idle_scheduler.dart';

/// Caches pre-rendered bitmap snapshots of Quran pages.
///
/// The raster thread takes ~25–50ms to composite a full page of Arabic
/// glyphs during swipe animations. By pre-capturing each page's render
/// output as a [ui.Image], we replace the expensive compositing with a
/// single-texture blit (~2ms) during transitions.
///
/// **Lifecycle**:
/// 1. After a page's first frame completes, [captureSnapshot] renders the
///    [RepaintBoundary]'s layer tree to a GPU-backed [ui.Image].
/// 2. During swipe animations, [PageContent] displays the cached image
///    via [RawImage] instead of the full widget tree.
/// 3. When the page settles (user stops swiping), the live widget tree
///    is restored for interactive gestures (long-press on words).
class PageSnapshotService {
  PageSnapshotService._();

  static final PageSnapshotService instance = PageSnapshotService._();

  /// Maximum number of snapshots to retain.
  ///
  /// Each snapshot at 1080×2400 @3x ≈ 24MB of GPU texture memory.
  /// 10 snapshots ≈ 240MB — a safe budget for mid-range devices.
  static const int _maxSnapshots = 10;

  /// Pixel-ratio multiplier for off-center pages. Reduces `toImage()` GPU
  /// work by ~44% for pages that are only briefly visible during swipe.
  static const double _offCenterPixelRatioScale = 0.75;

  final LinkedHashMap<int, ui.Image> _cache = LinkedHashMap<int, ui.Image>();

  /// Handle for the currently pending idle-scheduled capture, if any.
  IdleTask? _pendingCapture;

  /// Whether a snapshot is available for [pageNumber].
  bool hasSnapshot(int pageNumber) => _cache.containsKey(pageNumber);

  /// Retrieves the cached snapshot for [pageNumber], or `null`.
  ui.Image? getSnapshot(int pageNumber) {
    final ui.Image? image = _cache.remove(pageNumber);
    if (image != null) {
      // Re-insert to promote in the LRU order.
      _cache[pageNumber] = image;
    }
    return image;
  }

  /// Schedules a bitmap snapshot capture via the [IdleScheduler] so the
  /// expensive `toImage()` call never competes with live frame rasterization.
  ///
  /// [centerPage] is the currently visible page — used to apply a reduced
  /// pixel ratio for off-center pages (cheaper GPU work for pages only
  /// glimpsed during swipe).
  ///
  /// Returns an [IdleTask] handle that the caller can cancel if the page
  /// scrolls away before capture completes.
  IdleTask scheduleCaptureWhenIdle({
    required int pageNumber,
    required GlobalKey boundaryKey,
    required double pixelRatio,
    int? centerPage,
  }) {
    final double effectiveRatio =
        (centerPage != null && centerPage != pageNumber)
        ? pixelRatio * _offCenterPixelRatioScale
        : pixelRatio;

    return IdleScheduler.instance.runWhenIdle(() async {
      await captureSnapshot(
        pageNumber: pageNumber,
        boundaryKey: boundaryKey,
        pixelRatio: effectiveRatio,
      );
    });
  }

  /// Captures a bitmap snapshot from a [RepaintBoundary]'s render object.
  ///
  /// The [boundaryKey] must be attached to a [RepaintBoundary] that has
  /// completed at least one paint cycle. Returns `true` if the capture
  /// succeeded.
  Future<bool> captureSnapshot({
    required int pageNumber,
    required GlobalKey boundaryKey,
    required double pixelRatio,
  }) async {
    // Already captured — skip.
    if (_cache.containsKey(pageNumber)) return true;

    final BuildContext? context = boundaryKey.currentContext;
    if (context == null) return false;

    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject == null || renderObject is! RenderRepaintBoundary) {
      return false;
    }

    try {
      // Safety check: if the boundary is marked as dirty (needs paint),
      // attempting to capture it via toImage() will trigger a Flutter assertion
      // error. We skip the capture and let it be retried on the next idle cycle.
      if (renderObject.debugNeedsPaint) {
        if (!kReleaseMode) {
          logger.w('[SNAPSHOT_SKIP] p$pageNumber: boundary is dirty');
        }
        return false;
      }

      final int t0 = DateTime.now().millisecondsSinceEpoch;
      final ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);
      final int t1 = DateTime.now().millisecondsSinceEpoch;

      // Evict oldest entries if over budget.
      while (_cache.length >= _maxSnapshots) {
        final int evictedKey = _cache.keys.first;
        _cache.remove(evictedKey)?.dispose();
      }

      _cache[pageNumber] = image;

      if (!kReleaseMode) {
        logger.i(
          '[SNAPSHOT] p$pageNumber captured '
          '(${image.width}×${image.height}) '
          'in ${t1 - t0}ms | cache=${_cache.length}/$_maxSnapshots',
        );
      }
      return true;
    } catch (e) {
      if (!kReleaseMode) {
        logger.e('[SNAPSHOT_ERR] p$pageNumber: $e');
      }
      return false;
    }
  }

  /// Cancels any pending idle-scheduled capture.
  void cancelPending() {
    _pendingCapture?.cancel();
    _pendingCapture = null;
  }

  /// Removes and disposes the snapshot for [pageNumber].
  void evict(int pageNumber) {
    _cache.remove(pageNumber)?.dispose();
  }

  /// Disposes all cached snapshots and cancels pending captures.
  void clear() {
    cancelPending();
    IdleScheduler.instance.cancelAll();
    for (final ui.Image image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }
}
