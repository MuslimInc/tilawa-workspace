import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../logging/app_logger.dart';

/// Cold-start profiling logs for `flutter run --profile`.
///
/// Grep console or logcat with `[StartupPerf]`.
abstract final class StartupPerfLog {
  static final DateTime _startedAt = DateTime.now();
  static int _frameCount = 0;
  static bool _frameCounterInstalled = false;

  @visibleForTesting
  static bool enabledInTests = false;

  @visibleForTesting
  static void resetForTesting() {
    _frameCount = 0;
    _frameCounterInstalled = false;
    enabledInTests = false;
  }

  /// Installs a lightweight frame counter (debug/profile only).
  static void ensureFrameCounter() {
    if (_frameCounterInstalled || _shouldSkip()) {
      return;
    }
    _frameCounterInstalled = true;
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      _frameCount++;
    });
  }

  /// Records a checkpoint. [detail] is optional grep-friendly context.
  static void log(String event, {String? detail}) {
    if (_shouldSkip()) {
      return;
    }
    ensureFrameCounter();
    final int elapsedMs = DateTime.now().difference(_startedAt).inMilliseconds;
    final String phase = SchedulerBinding.instance.schedulerPhase.name;
    final StringBuffer buffer = StringBuffer('[StartupPerf] ')
      ..write('event=$event')
      ..write(' frame=$_frameCount')
      ..write(' elapsed_ms=$elapsedMs')
      ..write(' scheduler_phase=$phase');
    if (detail != null && detail.isNotEmpty) {
      buffer.write(' detail=$detail');
    }
    logger.d(buffer.toString());
  }

  static bool _shouldSkip() {
    if (enabledInTests) {
      return false;
    }
    if (kReleaseMode) {
      return true;
    }
    if (kIsWeb) {
      return false;
    }
    return Platform.environment.containsKey('FLUTTER_TEST');
  }
}
