import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Lightweight performance logger active only in profile mode.
///
/// All methods are no-ops in debug and release builds.
abstract final class PerfLogger {
  static const double _slowFrameThresholdMs = 20;

  // ---------------------------------------------------------------------------
  // Frame timing watcher
  // ---------------------------------------------------------------------------

  /// Registers a [TimingsCallback] that logs frames whose build or raster phase
  /// clearly misses budget.
  ///
  /// A slightly higher threshold than the raw 60 Hz budget keeps emulator
  /// rounding noise out of the logs so the remaining entries point at
  /// actionable jank instead of borderline frames.
  ///
  /// Call once from [main] after [WidgetsFlutterBinding.ensureInitialized].
  static void startFrameWatcher() {
    if (!kProfileMode) return;

    _log('[PerfLogger] Frame watcher started');

    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final buildMs = timing.buildDuration.inMicroseconds / 1000;
        final rasterMs = timing.rasterDuration.inMicroseconds / 1000;
        final totalMs = timing.totalSpan.inMicroseconds / 1000;
        final frameNumber = timing.frameNumber;

        final buildSlow = buildMs > _slowFrameThresholdMs;
        final rasterSlow = rasterMs > _slowFrameThresholdMs;

        if (!buildSlow && !rasterSlow) return;

        _log(
          '[SLOW FRAME #$frameNumber] '
          'build=${buildMs.toStringAsFixed(1)} ms  '
          'raster=${rasterMs.toStringAsFixed(1)} ms  '
          'total=${totalMs.toStringAsFixed(1)} ms'
          '${buildSlow ? "  ⚠ SLOW BUILD" : ""}'
          '${rasterSlow ? "  ⚠ SLOW RASTER" : ""}',
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Stopwatch helpers
  // ---------------------------------------------------------------------------

  /// Returns a started [Stopwatch] in profile mode, or null otherwise.
  static Stopwatch? startTimer() {
    if (!kProfileMode) return null;
    return Stopwatch()..start();
  }

  /// Logs elapsed time since [sw] was started, labelled with [tag].
  /// No-op if [sw] is null (i.e. not in profile mode).
  static void logElapsed(Stopwatch? sw, String tag) {
    if (!kProfileMode || sw == null) return;
    sw.stop();
    _log('[PerfLogger] $tag: ${sw.elapsedMicroseconds / 1000} ms');
  }

  // ---------------------------------------------------------------------------
  // Explicit log
  // ---------------------------------------------------------------------------

  static void log(String message) {
    if (!kProfileMode) return;
    _log(message);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  // ignore: avoid_print
  static void _log(String message) => print(message);
}
