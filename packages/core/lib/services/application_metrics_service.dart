/// Attribute values accepted by application metrics.
///
/// Keep values low-cardinality so the observability backend can aggregate them
/// efficiently. Use strings for categories, booleans for flags, and numbers for
/// bounded measurements.
typedef ApplicationMetricAttributes = Map<String, Object>;

/// Unit names shared by application metrics implementations.
abstract final class ApplicationMetricUnit {
  /// Milliseconds.
  static const String millisecond = 'millisecond';

  /// Full seconds.
  static const String second = 'second';

  /// Bytes.
  static const String byte = 'byte';

  /// Megabytes.
  static const String megabyte = 'megabyte';

  /// Floating point fraction of `1`.
  static const String ratio = 'ratio';

  /// Ratio expressed as a fraction of `100`.
  static const String percent = 'percent';
}

/// Records product and operational metrics for the app.
///
/// Feature code depends on this contract instead of a concrete observability
/// SDK. Implementations must never throw; metrics are diagnostic side effects
/// and should not change app behavior.
abstract class ApplicationMetricsService {
  /// Records how many times an event happened.
  void count(
    String name, {
    int value = 1,
    ApplicationMetricAttributes? attributes,
  });

  /// Records a point-in-time value that can increase or decrease.
  void gauge(
    String name,
    num value, {
    String? unit,
    ApplicationMetricAttributes? attributes,
  });

  /// Records a value for percentile and histogram analysis.
  void distribution(
    String name,
    num value, {
    String? unit,
    ApplicationMetricAttributes? attributes,
  });
}
