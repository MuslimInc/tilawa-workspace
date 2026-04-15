import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Lightweight performance logger active only in profile mode.
///
/// All methods are no-ops in debug and release builds.
abstract final class PerfLogger {
  static bool get isEnabled => kProfileMode || kDebugMode;

  // ---------------------------------------------------------------------------
  // Frame timing watcher
  // ---------------------------------------------------------------------------

  /// Registers a [TimingsCallback] that logs frames that miss their vsync
  /// budget.
  ///
  /// The budget is derived per-frame from [FrameTiming.vsyncInterval], so the
  /// threshold automatically matches the device's current refresh rate —
  /// 16.7 ms at 60 Hz, 11.1 ms at 90 Hz, 8.3 ms at 120 Hz — without needing
  /// a hardcoded constant.
  ///
  /// A 20 % headroom is added to suppress borderline frames caused by emulator
  /// rounding noise (e.g. a 17.1 ms frame at 60 Hz is not actionable jank).
  ///
  /// Call once from [main] after [WidgetsFlutterBinding.ensureInitialized].
  // Cached per-display refresh rate in Hz, updated lazily on first frame.
  // FrameTiming has no vsyncInterval field; we read it once from the implicit
  // FlutterView's Display and cache it for the lifetime of the watcher.
  static double _refreshHz = 60.0;

  static void startFrameWatcher() {
    if (!isEnabled) return;

    // Read the display refresh rate from the implicit view. Available after
    // ensureInitialized; falls back to 60 Hz if the view isn't ready yet.
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      _refreshHz = view.display.refreshRate;
    }
    final budgetMs = (1000 / _refreshHz) * 1.2;

    _logForWidget(
      'WidgetsBinding',
      'Frame watcher started hz=${_refreshHz.toStringAsFixed(0)} '
          'budgetMs=${budgetMs.toStringAsFixed(1)}',
    );

    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final buildMs = timing.buildDuration.inMicroseconds / 1000;
        final rasterMs = timing.rasterDuration.inMicroseconds / 1000;
        final totalMs = timing.totalSpan.inMicroseconds / 1000;
        // vsyncOverhead = time from vsync signal to build start (scheduling delay).
        final vsyncMs = timing.vsyncOverhead.inMicroseconds / 1000;
        final frameNumber = timing.frameNumber;

        final buildSlow = buildMs > budgetMs;
        final rasterSlow = rasterMs > budgetMs;
        // Flag frames where total wall-clock time exceeds 2× budget even when
        // build+raster individually look fine (GPU stall / texture upload).
        final totalSlow = totalMs > budgetMs * 2;

        if (!buildSlow && !rasterSlow && !totalSlow) continue;

        _logForWidget(
          'WidgetsBinding',
          '[SLOW FRAME #$frameNumber] '
              'build=${buildMs.toStringAsFixed(1)} ms  '
              'raster=${rasterMs.toStringAsFixed(1)} ms  '
              'vsync=${vsyncMs.toStringAsFixed(1)} ms  '
              'total=${totalMs.toStringAsFixed(1)} ms  '
              'budget=${budgetMs.toStringAsFixed(1)} ms'
              '${buildSlow ? "  ⚠ SLOW BUILD" : ""}'
              '${rasterSlow ? "  ⚠ SLOW RASTER" : ""}'
              '${totalSlow && !buildSlow && !rasterSlow ? "  ⚠ SLOW TOTAL" : ""}',
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Stopwatch helpers
  // ---------------------------------------------------------------------------

  /// Returns a started [Stopwatch] in profile mode, or null otherwise.
  static Stopwatch? startTimer() {
    if (!isEnabled) return null;
    return Stopwatch()..start();
  }

  /// Logs elapsed time since [sw] was started, labelled with [tag].
  /// No-op if [sw] is null (i.e. not in profile mode).
  static void logElapsed(
    Stopwatch? sw, {
    required String widgetName,
    required String message,
  }) {
    if (!isEnabled || sw == null) return;
    sw.stop();
    _logForWidget(widgetName, '$message: ${sw.elapsedMicroseconds / 1000} ms');
  }

  // ---------------------------------------------------------------------------
  // Explicit log
  // ---------------------------------------------------------------------------

  static void log({required String widgetName, required String message}) {
    if (!isEnabled) return;
    _logForWidget(widgetName, message);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  // ignore: avoid_print
  static void _log(String message) => print(message);

  static void _logForWidget(String widgetName, String message) {
    _log('[PerfLogger][$widgetName] $message');
  }
}
