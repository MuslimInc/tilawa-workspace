import 'package:tilawa_core/services/performance_monitoring_service.dart';

/// Extension to cleanly wrap operations in performance traces.
extension FirestorePerformanceExtension on PerformanceMonitoringService? {
  /// Executes the given [operation] wrapped in a trace named [name] if this service is not null.
  Future<T> trace<T>(String name, Future<T> Function() operation) {
    final self = this;
    if (self == null) {
      return operation();
    }
    return self.traceOperation(name, operation);
  }
}
