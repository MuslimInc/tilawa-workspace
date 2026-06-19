import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Temporary scroll/collapse diagnostics for the home hero slivers.
///
/// Filter logcat / console with: `[HomeSliverApp]`
class HomeSliverAppDebugLog {
  HomeSliverAppDebugLog._();

  static const bool _enabled = bool.fromEnvironment(
    'TILAWA_HOME_SLIVER_DEBUG_LOG',
  );

  static const String tag = '[HomeSliverApp]';

  static final Map<String, Object?> _lastThrottled = {};
  static final Map<String, int> _buildCounts = {};

  static int bumpBuild(String widget) {
    if (!kDebugMode || !_enabled) {
      return 0;
    }

    final int count = (_buildCounts[widget] ?? 0) + 1;
    _buildCounts[widget] = count;
    return count;
  }

  static void log(
    String event, {
    Map<String, Object?> data = const {},
    String? hypothesisId,
  }) {
    if (!kDebugMode || !_enabled) {
      return;
    }

    final String payload = data.isEmpty ? event : '$event ${jsonEncode(data)}';
    final String line = hypothesisId == null
        ? '$tag $payload'
        : '$tag [$hypothesisId] $payload';

    // ignore: avoid_print
    print(line);
  }

  /// Logs only when [throttleKey] value changes enough to matter.
  static void logThrottled(
    String throttleKey,
    String event, {
    required Object? throttleValue,
    Map<String, Object?> data = const {},
    String? hypothesisId,
    double doubleDelta = 0.04,
  }) {
    if (!kDebugMode || !_enabled) {
      return;
    }

    final Object? last = _lastThrottled[throttleKey];
    if (throttleValue is double && last is double) {
      if ((throttleValue - last).abs() < doubleDelta) {
        return;
      }
    } else if (throttleValue == last) {
      return;
    }

    _lastThrottled[throttleKey] = throttleValue;
    log(event, data: data, hypothesisId: hypothesisId);
  }
}
