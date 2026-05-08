/// Abstract handle for a performance trace.
///
/// Following KISS: minimal surface. Use [putAttribute] for both
/// string attributes and numeric metrics (Firebase converts numeric
/// strings to metrics automatically).
abstract class PerformanceTrace {
  /// Stop the trace and send data to the monitoring backend.
  void stop();

  /// Add an attribute to the trace.
  ///
  /// [name] must be unique per trace. Max 5 attributes per trace
  /// (enforced by Firebase SDK, not validated here - YAGNI).
  ///
  /// For metrics, pass numeric values as strings: '1234'.
  void putAttribute(String name, String value);
}
