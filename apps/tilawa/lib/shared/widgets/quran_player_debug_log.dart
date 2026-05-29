import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';

/// Temporary diagnostics for [QuranPlayerWidget] expand/collapse UX.
///
/// Enabled in debug builds, or when compiled with
/// `--dart-define=QURAN_PLAYER_DEBUG_LOG=true`.
///
/// Remove this file and its call sites once minimize/white-screen issues are
/// resolved.
abstract final class QuranPlayerDebugLog {
  /// Master switch — no logs in release unless explicitly forced.
  static bool get enabled =>
      kDebugMode ||
      const bool.fromEnvironment(
        'QURAN_PLAYER_DEBUG_LOG',
        defaultValue: false,
      );

  static const String tag = '[QuranPlayer]';

  // #region agent log
  static const String _agentLogPath =
      '/Users/mohammadkamel/flutter_projects/tilawa_workspace/'
      '.cursor/debug-aa8976.log';

  static const String _agentSessionId = 'aa8976';

  static double? _lastAgentProgress;

  /// NDJSON trace for debug-mode transition analysis (session aa8976).
  static void agent({
    required String hypothesisId,
    required String location,
    required String message,
    Map<String, Object?> data = const {},
    String runId = 'pre-fix',
    bool throttleProgress = false,
    double? progress,
  }) {
    if (!kDebugMode) {
      return;
    }
    if (throttleProgress && progress != null) {
      final double? last = _lastAgentProgress;
      if (last != null &&
          (progress - last).abs() < 0.04 &&
          progress > 0.02 &&
          progress < 0.98) {
        return;
      }
      _lastAgentProgress = progress;
    }
    try {
      final Map<String, Object?> payload = <String, Object?>{
        'sessionId': _agentSessionId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'runId': runId,
      };
      File(_agentLogPath).writeAsStringSync(
        '${jsonEncode(payload)}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Host filesystem may be unavailable on device; ignore.
    }
  }

  static double curvedRouteProgress(double raw, AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      return Curves.fastOutSlowIn.flipped.transform(raw);
    }
    return Curves.fastOutSlowIn.transform(raw);
  }

  static void agentResetThrottle() {
    _lastAgentProgress = null;
  }
  // #endregion

  static void log(String event, [Map<String, Object?> fields = const {}]) {
    if (!enabled) {
      return;
    }
    // ignore: avoid_print
    print(_format(event, fields));
  }

  static void warn(String event, [Map<String, Object?> fields = const {}]) {
    log('WARN $event', fields);
  }

  static String playerMode({
    required double expandProgress,
    required bool isCollapsing,
    required bool isUserDragging,
    String? transitionOwner,
  }) {
    if (expandProgress <= 0.01) {
      return transitionOwner == 'heroRouteClosing' ? 'miniClosing' : 'mini';
    }
    if (expandProgress >= 0.99) {
      return transitionOwner == 'heroRoute' ? 'expandedOpening' : 'expanded';
    }
    if (isCollapsing) {
      return 'collapsing';
    }
    if (isUserDragging) {
      return 'dragging';
    }
    return 'transition';
  }

  static void hero(String event, [Map<String, Object?> fields = const {}]) {
    log('hero.$event', fields);
  }

  static void lifecycle(String phase, [Map<String, Object?> fields = const {}]) {
    log('lifecycle.$phase', fields);
  }

  static void animation(String event, [Map<String, Object?> fields = const {}]) {
    log('animation.$event', fields);
  }

  static void drag(String event, [Map<String, Object?> fields = const {}]) {
    log('drag.$event', fields);
  }

  static void layout(String event, [Map<String, Object?> fields = const {}]) {
    log('layout.$event', fields);
  }

  static void gesture(String event, [Map<String, Object?> fields = const {}]) {
    log('gesture.$event', fields);
  }

  static void route(String event, [Map<String, Object?> fields = const {}]) {
    log('route.$event', fields);
  }

  static void overlay(String event, [Map<String, Object?> fields = const {}]) {
    log('overlay.$event', fields);
  }

  /// Logs when both mini and expanded chrome are nearly invisible (white gap).
  static void maybeWarnTransitionGap({
    required double progress,
    required double miniOpacity,
    required double expandedOpacity,
    required String source,
  }) {
    if (!enabled) {
      return;
    }
    const double gapThreshold = 0.12;
    if (progress > 0.05 &&
        progress < 0.95 &&
        miniOpacity < gapThreshold &&
        expandedOpacity < gapThreshold) {
      final Map<String, Object?> gapFields = <String, Object?>{
        'source': source,
        'progress': progress.toStringAsFixed(3),
        'miniOpacity': miniOpacity.toStringAsFixed(3),
        'expandedOpacity': expandedOpacity.toStringAsFixed(3),
      };
      warn('transition.gap', gapFields);
      agent(
        hypothesisId: 'B',
        location: 'quran_player_debug_log.dart:maybeWarnTransitionGap',
        message: 'transition visual gap',
        data: gapFields,
      );
    }
  }

  static String _format(String event, Map<String, Object?> fields) {
    if (fields.isEmpty) {
      return '$tag $event';
    }
    final StringBuffer buffer = StringBuffer('$tag $event');
    for (final MapEntry<String, Object?> entry in fields.entries) {
      buffer.write(' | ${entry.key}=${entry.value}');
    }
    return buffer.toString();
  }
}
