import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// A utility class for tracking performance metrics and marking timeline events.
class PerformanceMonitor {
  static final PerformanceMonitor instance = PerformanceMonitor._();
  PerformanceMonitor._();

  /// Marks the start of a custom performance event.
  void startEvent(String name) {
    developer.Timeline.startSync(name);
  }

  /// Marks the end of a custom performance event.
  void endEvent() {
    developer.Timeline.finishSync();
  }

  /// Logs a one-off performance metric.
  void logMetric(String name, dynamic value) {
    developer.log('PERF_METRIC: $name = $value', name: 'tilawa.perf');
  }

  /// Tracks the duration of the next frame.
  void trackNextFrame(String label) {
    if (!kDebugMode && !kProfileMode) return;

    final int start = DateTime.now().millisecondsSinceEpoch;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final int end = DateTime.now().millisecondsSinceEpoch;
      developer.log(
        'FRAME_DURATION [$label]: ${end - start}ms',
        name: 'tilawa.perf',
      );
    });
  }
}
