import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Unified `[DeepLink]` console + NDJSON logging for cold-start routing QA.
///
/// Filter logcat / Xcode: `adb logcat | grep DeepLink` or search `[DeepLink]`.
abstract final class DeepLinkDebugLog {
  static const String _tag = '[DeepLink]';
  static const String _logPath =
      '/Users/mohammadkamel/flutter_projects/tilawa_workspace/.cursor/debug-ffb18e.log';
  static const String _sessionId = 'ffb18e';

  static final Stopwatch _sw = Stopwatch()..start();
  static int _seq = 0;

  /// Milliseconds since the first [DeepLink] log in this process.
  static int get elapsedMs => _sw.elapsedMilliseconds;

  /// Logs an event with elapsed ms since first log in this process.
  static void log(
    String message, {
    String? scenario,
    String? hypothesisId,
    Map<String, Object?>? data,
  }) {
    final int elapsedMs = _sw.elapsedMilliseconds;
    final int id = ++_seq;
    final String scenarioPart = scenario == null ? '' : ' scenario=$scenario';
    debugPrint(
      '$_tag t=${elapsedMs}ms #$id$scenarioPart $message'
      '${data == null ? '' : ' ${jsonEncode(data)}'}',
    );
    _writeNdjson(
      id: id,
      elapsedMs: elapsedMs,
      message: message,
      scenario: scenario,
      hypothesisId: hypothesisId,
      data: data,
    );
  }

  static T time<T>(String label, T Function() action, {String? scenario}) {
    final int start = _sw.elapsedMilliseconds;
    log('$label START', scenario: scenario);
    try {
      final T result = action();
      log(
        '$label END',
        scenario: scenario,
        data: <String, Object?>{
          'durationMs': _sw.elapsedMilliseconds - start,
        },
      );
      return result;
    } catch (e, st) {
      log(
        '$label ERROR',
        scenario: scenario,
        data: <String, Object?>{
          'error': e.toString(),
          'durationMs': _sw.elapsedMilliseconds - start,
        },
      );
      Error.throwWithStackTrace(e, st);
    }
  }

  static Future<T> timeAsync<T>(
    String label,
    Future<T> Function() action, {
    String? scenario,
  }) async {
    final int start = _sw.elapsedMilliseconds;
    log('$label START', scenario: scenario);
    try {
      final T result = await action();
      log(
        '$label END',
        scenario: scenario,
        data: <String, Object?>{
          'durationMs': _sw.elapsedMilliseconds - start,
        },
      );
      return result;
    } catch (e, st) {
      log(
        '$label ERROR',
        scenario: scenario,
        data: <String, Object?>{
          'error': e.toString(),
          'durationMs': _sw.elapsedMilliseconds - start,
        },
      );
      Error.throwWithStackTrace(e, st);
    }
  }

  static void _writeNdjson({
    required int id,
    required int elapsedMs,
    required String message,
    String? scenario,
    String? hypothesisId,
    Map<String, Object?>? data,
  }) {
    if (!kDebugMode) {
      return;
    }
    try {
      final Map<String, Object?> payload = <String, Object?>{
        'sessionId': _sessionId,
        'id': 'dl_$id',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'location': 'DeepLinkDebugLog',
        'message': message,
        'data': <String, Object?>{
          'elapsedMs': elapsedMs,
          'scenario': ?scenario,
          ...?data,
        },
        'hypothesisId': ?hypothesisId,
      };
      File(_logPath).writeAsStringSync(
        '${jsonEncode(payload)}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Ignore file errors on device/simulator without workspace path.
    }
  }
}
