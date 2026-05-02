import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/services/performance_monitoring_service.dart';
import 'package:tilawa_core/services/performance_trace.dart';

/// Firebase Performance Monitoring implementation.
///
/// RELEASE-ONLY: Tracking disabled in debug and profile modes.
/// Following KISS: minimal validation, let Firebase SDK handle limits.
/// Error-safe: all operations swallow exceptions (monitoring never breaks features).
@Singleton(as: PerformanceMonitoringService)
class FirebasePerformanceService implements PerformanceMonitoringService {
  FirebasePerformanceService(this._performance) {
    if (!_isReleaseMode) {
      _performance.setPerformanceCollectionEnabled(false);
    }
  }

  final FirebasePerformance _performance;

  @visibleForTesting
  bool testMode = false;

  /// True only in release mode (not debug, not profile).
  static bool get _isReleaseMode => kReleaseMode;

  @override
  Future<T> traceOperation<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    if (!_isReleaseMode && !testMode) {
      return operation();
    }

    final Trace trace = _performance.newTrace(name);
    try {
      await trace.start();
      final T result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      // Ensure trace is stopped even on error
      try {
        await trace.stop();
      } catch (_) {
        // Ignore stop errors
      }
      // Log but don't throw - monitoring shouldn't break functionality
      logger.d('Performance trace error: $e');
      rethrow; // Rethrow the original operation error, not the trace error
    }
  }

  @override
  PerformanceTrace? startTrace(String name) {
    if (!_isReleaseMode && !testMode) {
      return null;
    }

    try {
      final Trace trace = _performance.newTrace(name);
      trace.start();
      return _FirebasePerformanceTrace(trace);
    } catch (e) {
      logger.d('Performance startTrace error: $e');
      return null;
    }
  }

  @override
  void setEnabled(bool enabled) {
    try {
      _performance.setPerformanceCollectionEnabled(enabled);
    } catch (e) {
      logger.d('Performance setEnabled error: $e');
    }
  }
}

/// Internal wrapper for Firebase Trace.
///
/// KISS: delegates directly to Firebase SDK. No local state management.
class _FirebasePerformanceTrace implements PerformanceTrace {
  _FirebasePerformanceTrace(this._trace);

  final Trace _trace;

  @override
  void stop() {
    try {
      _trace.stop();
    } catch (e) {
      logger.d('Performance trace stop error: $e');
    }
  }

  @override
  void putAttribute(String name, String value) {
    try {
      _trace.putAttribute(name, value);
    } catch (e) {
      logger.d('Performance putAttribute error: $e');
    }
  }
}
