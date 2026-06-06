import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

import '../logging/app_logger.dart';
import 'startup_health_log_sink.dart';

/// Cold-start observability: Crashlytics breadcrumbs, Analytics funnel, and
/// Firestore backend logs ([FirestoreStartupHealthLogSink.collectionName]).
abstract final class StartupTelemetry {
  static final DateTime _processStartedAt = DateTime.now();
  static final String _sessionId =
      'startup_${_processStartedAt.microsecondsSinceEpoch}';

  // Lazy: constructed on first write so FirebaseFirestore.instance is never
  // called before Firebase.initializeApp() completes.
  static StartupHealthLogSink? _healthLogSinkInstance;
  static StartupHealthLogSink get _healthLogSink =>
      _healthLogSinkInstance ??= FirestoreStartupHealthLogSink();
  static bool _crashlyticsPrimed = false;
  static String? _lastPhase;
  static String? _appVersion;
  static String? _buildNumber;
  static bool _contextLoaded = false;

  @visibleForTesting
  static bool firestoreLoggingEnabled = true;

  @visibleForTesting
  static bool analyticsLoggingEnabled = true;

  @visibleForTesting
  static bool crashlyticsLoggingEnabled = true;

  @visibleForTesting
  static bool enabledInTests = false;

  @visibleForTesting
  static void configureForTesting({
    StartupHealthLogSink? healthLogSink,
    bool? firestoreLogging,
    bool? analyticsLogging,
    bool? crashlyticsLogging,
  }) {
    resetForTesting();
    if (healthLogSink != null) {
      _healthLogSinkInstance = healthLogSink;
    }
    if (firestoreLogging != null) {
      firestoreLoggingEnabled = firestoreLogging;
    }
    if (analyticsLogging != null) {
      analyticsLoggingEnabled = analyticsLogging;
    }
    if (crashlyticsLogging != null) {
      crashlyticsLoggingEnabled = crashlyticsLogging;
    }
    enabledInTests = true;
  }

  @visibleForTesting
  static void resetForTesting() {
    enabledInTests = false;
    _crashlyticsPrimed = false;
    _lastPhase = null;
    _appVersion = null;
    _buildNumber = null;
    _contextLoaded = false;
    _healthLogSinkInstance = const NoopStartupHealthLogSink();
    firestoreLoggingEnabled = true;
    analyticsLoggingEnabled = true;
    crashlyticsLoggingEnabled = true;
  }

  /// Call once [Firebase.initializeApp] has succeeded so boot failures reach
  /// Crashlytics before deferred [CrashlyticsService.initialize].
  static Future<void> onFirebaseReady() async {
    if (_shouldSkip()) {
      return;
    }
    await _ensureContext();
    if (!_crashlyticsPrimed && crashlyticsLoggingEnabled) {
      try {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          kReleaseMode,
        );
        await _applyCrashlyticsContext();
        _crashlyticsPrimed = true;
        await _crashlyticsLog('StartupTelemetry: firebase ready');
      } catch (e) {
        logger.d('StartupTelemetry onFirebaseReady: $e');
      }
    }
    unawaited(phase('firebase_ready'));
  }

  /// Records a startup milestone (non-blocking).
  static Future<void> phase(
    String name, {
    Map<String, Object?>? data,
  }) async {
    if (_shouldSkip()) {
      return;
    }
    _lastPhase = name;
    final int elapsedMs = _elapsedMs();
    await _ensureContext();

    final Map<String, Object?> payload = <String, Object?>{
      'level': 'info',
      'event': AnalyticsEvents.startupPhase,
      'phase': name,
      'elapsed_ms': elapsedMs,
      ...?data,
      ..._baseFields(),
    };

    logger.d('[StartupTelemetry] phase=$name elapsed_ms=$elapsedMs');

    await _crashlyticsLog('startup_phase:$name');
    unawaited(
      _logAnalytics(
        AnalyticsEvents.startupPhase,
        <String, Object>{
          AnalyticsParams.phase: name,
          AnalyticsParams.elapsedMs: elapsedMs,
          AnalyticsParams.appVersion: ?_appVersion,
          AnalyticsParams.buildNumber: ?_buildNumber,
          AnalyticsParams.sessionId: _sessionId,
        },
      ),
    );
    unawaited(_writeHealthLog(payload));
  }

  /// Records a startup failure (non-blocking).
  static Future<void> failure(
    String reason,
    Object error,
    StackTrace? stackTrace, {
    String? phase,
  }) async {
    if (_shouldSkip()) {
      return;
    }
    final String effectivePhase = phase ?? _lastPhase ?? 'unknown';
    final int elapsedMs = _elapsedMs();
    await _ensureContext();

    final String errorMessage = error.toString();
    final Map<String, Object?> payload = <String, Object?>{
      'level': 'error',
      'event': AnalyticsEvents.startupFailed,
      'phase': effectivePhase,
      'reason': reason,
      'error_type': error.runtimeType.toString(),
      'error_message': _truncate(errorMessage, 500),
      'elapsed_ms': elapsedMs,
      ..._baseFields(),
    };

    logger.e(
      '[StartupTelemetry] failure reason=$reason phase=$effectivePhase',
      error: error,
      stackTrace: stackTrace,
    );

    if (crashlyticsLoggingEnabled && Firebase.apps.isNotEmpty) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: reason,
          fatal: false,
        ),
      );
      unawaited(_crashlyticsLog('startup_failed:$reason phase=$effectivePhase'));
    }

    unawaited(
      _logAnalytics(
        AnalyticsEvents.startupFailed,
        <String, Object>{
          AnalyticsParams.reason: reason,
          AnalyticsParams.phase: effectivePhase,
          AnalyticsParams.elapsedMs: elapsedMs,
          AnalyticsParams.error: _truncate(errorMessage, 100),
          AnalyticsParams.appVersion: ?_appVersion,
          AnalyticsParams.buildNumber: ?_buildNumber,
          AnalyticsParams.sessionId: _sessionId,
        },
      ),
    );
    unawaited(_writeHealthLog(payload));
  }

  /// Records successful cold start (first routed frame).
  static Future<void> completed({Map<String, Object?>? data}) async {
    if (_shouldSkip()) {
      return;
    }
    final int elapsedMs = _elapsedMs();
    await _ensureContext();

    final Map<String, Object?> payload = <String, Object?>{
      'level': 'info',
      'event': AnalyticsEvents.startupCompleted,
      'phase': 'startup_completed',
      'elapsed_ms': elapsedMs,
      ...?data,
      ..._baseFields(),
    };

    logger.d('[StartupTelemetry] completed elapsed_ms=$elapsedMs');

    unawaited(_crashlyticsLog('startup_completed'));
    unawaited(
      _logAnalytics(
        AnalyticsEvents.startupCompleted,
        <String, Object>{
          AnalyticsParams.elapsedMs: elapsedMs,
          AnalyticsParams.appVersion: ?_appVersion,
          AnalyticsParams.buildNumber: ?_buildNumber,
          AnalyticsParams.sessionId: _sessionId,
        },
      ),
    );
    unawaited(_writeHealthLog(payload));
  }

  static bool _shouldSkip() {
    if (enabledInTests) {
      return false;
    }
    // Platform.environment is unsupported on web; kIsWeb is always false on
    // Android/iOS so this short-circuit is zero-cost on mobile.
    if (kIsWeb) {
      return false;
    }
    return Platform.environment.containsKey('FLUTTER_TEST');
  }

  static int _elapsedMs() {
    return DateTime.now().difference(_processStartedAt).inMilliseconds;
  }

  static Future<void> _ensureContext() async {
    if (_contextLoaded) {
      return;
    }
    _contextLoaded = true;
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    } catch (e) {
      logger.d('StartupTelemetry package info: $e');
    }
    if (_crashlyticsPrimed) {
      await _applyCrashlyticsContext();
    }
  }

  static Future<void> _applyCrashlyticsContext() async {
    if (!crashlyticsLoggingEnabled || Firebase.apps.isEmpty) {
      return;
    }
    final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;
    if (_appVersion != null) {
      await crashlytics.setCustomKey('app_version', _appVersion!);
    }
    if (_buildNumber != null) {
      await crashlytics.setCustomKey('build_number', _buildNumber!);
    }
    await crashlytics.setCustomKey('startup_session_id', _sessionId);
    if (_lastPhase != null) {
      await crashlytics.setCustomKey('startup_last_phase', _lastPhase!);
    }
  }

  static Map<String, Object?> _baseFields() {
    return <String, Object?>{
      'session_id': _sessionId,
      'client_timestamp_ms': DateTime.now().millisecondsSinceEpoch,
      'app_version': _appVersion,
      'build_number': _buildNumber,
      'platform': _platformName(),
      'build_mode': kReleaseMode
          ? 'release'
          : kProfileMode
          ? 'profile'
          : 'debug',
    };
  }

  static String? _platformName() {
    if (kIsWeb) {
      return 'web';
    }
    return Platform.operatingSystem;
  }

  static Future<void> _crashlyticsLog(String message) async {
    if (!crashlyticsLoggingEnabled || Firebase.apps.isEmpty) {
      return;
    }
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  static Future<void> _logAnalytics(
    String name,
    Map<String, Object> parameters,
  ) async {
    if (!analyticsLoggingEnabled || Firebase.apps.isEmpty) {
      return;
    }
    if (kDebugMode) {
      return;
    }
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      logger.d('StartupTelemetry analytics: $e');
    }
  }

  static Future<void> _writeHealthLog(Map<String, Object?> entry) async {
    if (!firestoreLoggingEnabled) {
      return;
    }
    await _healthLogSink.write(entry);
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}…';
  }
}
