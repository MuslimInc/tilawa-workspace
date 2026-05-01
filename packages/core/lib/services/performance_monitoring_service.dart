import 'performance_trace.dart';

/// Abstract interface for performance monitoring.
///
/// Following KISS: 3 methods only. No HTTP-specific methods
/// (Firebase auto-captures HTTP), no global attributes.
abstract class PerformanceMonitoringService {
  /// Auto-instrument an async operation with a trace.
  ///
  /// Handles start/stop automatically. Never throws.
  Future<T> traceOperation<T>(String name, Future<T> Function() operation);

  /// Start a manual trace. Returns null if collection is disabled.
  ///
  /// Caller must call [PerformanceTrace.stop].
  PerformanceTrace? startTrace(String name);

  /// Enable or disable performance data collection.
  void setEnabled(bool enabled);
}
