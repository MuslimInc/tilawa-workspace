import 'dart:developer';
import 'dart:ui' show FramePhase;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Snapshot of a single slow frame, broadcast via [PerfLogger.lastSlowFrame].
///
/// Carries only what [PerfOverlay] needs to render without re-reading global
/// state after the fact.
class SlowFrameInfo extends Equatable {
  const SlowFrameInfo({
    required this.frameNumber,
    required this.buildMs,
    required this.rasterMs,
    required this.totalMs,
    required this.budgetMs,
    required this.buildSlow,
    required this.rasterSlow,
    required this.totalSlow,
    required this.contributors,
    required this.timestamp,
  });

  final int frameNumber;
  final double buildMs;
  final double rasterMs;
  final double totalMs;
  final double budgetMs;
  final bool buildSlow;
  final bool rasterSlow;
  final bool totalSlow;

  /// Widget names that contributed to this frame's build phase.
  final List<String> contributors;

  /// Wall-clock time when this slow frame was detected.
  final DateTime timestamp;

  @override
  List<Object?> get props => [
    frameNumber,
    buildMs,
    rasterMs,
    totalMs,
    budgetMs,
    buildSlow,
    rasterSlow,
    totalSlow,
    contributors,
    timestamp,
  ];
}

/// Lightweight performance logger active only in profile mode.
///
/// All methods are no-ops in debug and release builds.
abstract final class PerfLogger {
  /// Runtime on/off switch for all instrumentation.
  ///
  /// Defaults to `true`.  Set to `false` in one line to silence every
  /// [markBuild], [startEvent], [logMetric], and [trackNextFrame] call across
  /// the entire widget tree — useful for A/B measuring overhead or disabling
  /// instrumentation in specific test scenarios:
  ///
  /// ```dart
  /// PerfLogger.instrumentationEnabled = false; // kill all perf logging
  /// PerfLogger.instrumentationEnabled = true;  // re-enable
  /// ```
  ///
  /// Has no effect in release mode because [isEnabled] already returns `false`
  /// at compile time.
  static bool instrumentationEnabled = true;

  /// `true` when instrumentation should run.
  ///
  /// Combines the compile-time mode check with the [instrumentationEnabled]
  /// runtime toggle so both guards apply.
  static bool get isEnabled =>
      (kProfileMode || kDebugMode) && instrumentationEnabled;

  /// Broadcasts the most recent slow frame detected by [startFrameWatcher].
  ///
  /// [PerfOverlay] listens to this notifier to render the on-device banner.
  /// You can also subscribe directly:
  ///
  /// ```dart
  /// PerfLogger.lastSlowFrame.addListener(() {
  ///   final info = PerfLogger.lastSlowFrame.value;
  /// });
  /// ```
  static final ValueNotifier<SlowFrameInfo?> lastSlowFrame = ValueNotifier(
    null,
  );

  // ---------------------------------------------------------------------------
  // Widget build contributor tracking
  // ---------------------------------------------------------------------------

  /// Per-frame build contributor map, keyed by the frame's vsync start
  /// timestamp ([SchedulerBinding.currentSystemFrameTimeStamp]).
  ///
  /// Each entry accumulates the widgets that called [markBuild] during a
  /// single frame.  The timings callback removes entries by matching
  /// [FrameTiming.vsyncStart], so every slow-frame report only lists the
  /// widgets that built *during that exact frame* rather than sharing a single
  /// batch-level list.
  static final Map<Duration, List<String>> _buildLogByFrame = {};

  /// Notifies whenever any widget calls [markBuild].
  ///
  /// [PerfOverlay] listens to this to "refresh" its display without triggering
  /// its own independent build cycles.
  static final ValueNotifier<int> buildNotifier = ValueNotifier(0);

  /// Internal flag to throttle [buildNotifier] updates to once per frame.
  static bool _buildNotificationPending = false;

  /// Call from the top of a `build()` method to register the widget as a
  /// potential contributor to a slow frame.
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   PerfLogger.markBuild('MyHeavyWidget');
  ///   // …
  /// }
  /// ```
  ///
  /// No-op in release mode.
  static void markBuild(String widgetName) {
    if (!isEnabled) return;
    // Group by the current frame's vsync timestamp so the timings callback
    // can match builds to the exact FrameTiming that covers them.
    final ts = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    (_buildLogByFrame[ts] ??= []).add(widgetName);

    // Bump the build notifier so the PerfOverlay knows it can refresh.
    // Defer to the end of the frame to avoid "setState() called during build".
    if (!_buildNotificationPending) {
      _buildNotificationPending = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _buildNotificationPending = false;
        buildNotifier.value++;
      });
    }

    // Also emit a point marker on the DevTools Timeline so the widget appears
    // in the CPU/frame profiler alongside the frame's build phase.
    Timeline.instantSync(widgetName, arguments: const {'type': 'build'});
  }

  // ---------------------------------------------------------------------------
  // Scoped Timeline events
  // ---------------------------------------------------------------------------

  /// Opens a named scope in the DevTools Timeline that shows up as a
  /// colour-coded span in the frame profiler.
  ///
  /// Must always be paired with a matching [endEvent] call — use a
  /// try/finally when the body can throw:
  ///
  /// ```dart
  /// PerfLogger.startEvent('HeavyWork');
  /// try {
  ///   doHeavyWork();
  /// } finally {
  ///   PerfLogger.endEvent();
  /// }
  /// ```
  static void startEvent(String name) {
    if (!isEnabled) return;
    Timeline.startSync(name);
  }

  /// Closes the innermost [startEvent] scope.
  static void endEvent() {
    if (!isEnabled) return;
    Timeline.finishSync();
  }

  // ---------------------------------------------------------------------------
  // Metric helpers
  // ---------------------------------------------------------------------------

  /// Logs a named metric value to the debug console.
  static void logMetric(String name, dynamic value) {
    if (!isEnabled) return;
    _log('PERF_METRIC: $name = $value');
  }

  /// Measures wall-clock time from *now* until the next painted frame and
  /// logs it labelled with [label].
  static void trackNextFrame(String label) {
    if (!isEnabled) return;
    final start = DateTime.now().millisecondsSinceEpoch;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _logForWidget(
        label,
        'next-frame: ${DateTime.now().millisecondsSinceEpoch - start}ms',
      );
    });
  }

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
      'Frame watcher started at (${DateTime.now()}) hz=${_refreshHz.toStringAsFixed(0)} '
          'budgetMs=${budgetMs.toStringAsFixed(1)}',
    );

    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        // Remove and consume the build log for exactly this frame, keyed by
        // the frame's vsync start timestamp.  Non-slow frames are consumed
        // here too, keeping the map from growing unbounded.
        final vsyncTs = Duration(
          microseconds: timing.timestampInMicroseconds(FramePhase.vsyncStart),
        );
        final frameBuildLog = _buildLogByFrame.remove(vsyncTs) ?? const [];

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

        // Deduplicate widget names while preserving order of first appearance.
        final contributors = frameBuildLog.toSet().toList();
        final contributorSuffix = contributors.isEmpty
            ? ''
            : '  widgets: ${contributors.join(', ')}';

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
              '${totalSlow && !buildSlow && !rasterSlow ? "  ⚠ SLOW TOTAL" : ""}'
              '$contributorSuffix',
        );

        // Broadcast for PerfOverlay and any other listener.
        lastSlowFrame.value = SlowFrameInfo(
          frameNumber: frameNumber,
          buildMs: buildMs,
          rasterMs: rasterMs,
          totalMs: totalMs,
          budgetMs: budgetMs,
          buildSlow: buildSlow,
          rasterSlow: rasterSlow,
          totalSlow: totalSlow,
          contributors: contributors,
          timestamp: DateTime.now(),
        );
      }

      // Safety valve: if entries accumulate (e.g. frames that slipped through
      // without a matching FrameTiming), drop the oldest ones.
      if (_buildLogByFrame.length > 30) {
        _buildLogByFrame.clear();
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

  /// Quran Image Reader markers for device profiling (`flutter run --profile`).
  ///
  /// No-op in debug, release, or when [instrumentationEnabled] is false.
  /// Use consistent [tag] values such as `[QuranPerf][Jump]` for logcat grep.
  static bool get isQuranPerfEnabled =>
      kProfileMode && instrumentationEnabled;

  static void logQuranPerf(String tag, String message) {
    if (!isQuranPerfEnabled) return;
    _log('$tag $message');
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  // ignore: avoid_print
  static void _log(String message) => print(message);

  static void _logForWidget(String widgetName, String message) {
    _log('[AppLaunch][$widgetName]: $message at (${DateTime.now()})');
  }
}

/// Wraps [child] with a [PerfLogger.markBuild] call so any widget can be
/// instrumented without modifying its own `build` method.
///
/// Zero overhead when [PerfLogger.instrumentationEnabled] is `false` or in
/// release mode — the [build] body exits immediately.
///
/// ```dart
/// // Instrument an existing widget with one line:
/// PerfTracked(
///   name: 'HeavyWidget',
///   child: const HeavyWidget(),
/// )
/// ```
class PerfTracked extends StatelessWidget {
  const PerfTracked({super.key, required this.name, required this.child});

  /// Label reported to [PerfLogger.markBuild] and the DevTools Timeline.
  final String name;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild(name);
    return child;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// On-device overlay
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps the widget tree and shows a heads-up banner whenever [PerfLogger]
/// detects a slow frame.
///
/// Place **once** in [MaterialApp.builder] to cover the entire app:
///
/// ```dart
/// builder: (context, child) {
///   return PerfOverlay(
///     child: MediaQuery(
///       data: ...,
///       child: child ?? const SizedBox.shrink(),
///     ),
///   );
/// },
/// ```
///
/// The banner is visible only when [PerfLogger.instrumentationEnabled] is `true`.
/// To keep overhead near zero, it only "refreshes" its display when any widget
/// in the subtree calls [PerfLogger.markBuild], and it avoids triggering its
/// own rebuilds of the [child] app tree.
class PerfOverlay extends StatelessWidget {
  const PerfOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Completely bypass the stack in release mode or if disabled.
    if (!PerfLogger.isEnabled) return child;

    return Stack(children: [child, const _PerfOverlayBannerProxy()]);
  }
}

/// Listens to build events and renders the slow frame banner on top of the app.
class _PerfOverlayBannerProxy extends StatelessWidget {
  const _PerfOverlayBannerProxy();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PerfLogger.buildNotifier,
      builder: (context, _, child) {
        final info = PerfLogger.lastSlowFrame.value;
        if (info == null) return const SizedBox.shrink();

        // Banner auto-dismisses based on build cycles: if the slow frame is
        // older than 2 seconds, we hide it. Since this builder only runs when
        // a widget builds, the "refresh" is perfectly synced with app activity.
        final age = DateTime.now().difference(info.timestamp);
        if (age > const Duration(seconds: 2)) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 16,
          left: 12,
          right: 12,
          child: _SlowFrameBanner(info: info),
        );
      },
    );
  }
}

class _SlowFrameBanner extends StatelessWidget {
  const _SlowFrameBanner({required this.info});

  final SlowFrameInfo info;

  @override
  Widget build(BuildContext context) {
    // Colour encodes severity: red = slow build, orange = slow raster,
    // amber = total stall (vsync/GPU).
    final Color bg = info.buildSlow
        ? const Color(0xEECC0000)
        : info.rasterSlow
        ? const Color(0xEEBB4400)
        : const Color(0xEE886600);

    final buffer = StringBuffer('⚠ #${info.frameNumber}');
    if (info.buildSlow) {
      buffer.write('  build=${info.buildMs.toStringAsFixed(1)}ms');
    }
    if (info.rasterSlow) {
      buffer.write('  raster=${info.rasterMs.toStringAsFixed(1)}ms');
    }
    if (info.totalSlow && !info.buildSlow && !info.rasterSlow) {
      buffer.write('  total=${info.totalMs.toStringAsFixed(1)}ms');
    }
    buffer.write('  budget=${info.budgetMs.toStringAsFixed(1)}ms');
    if (info.contributors.isNotEmpty) {
      buffer.write('\n${info.contributors.join(' · ')}');
    }

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 11,
              fontFamily: 'monospace',
              decoration: TextDecoration.none,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            child: Text(buffer.toString(), maxLines: 3),
          ),
        ),
      ),
    );
  }
}
