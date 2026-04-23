import 'package:quran_image/core/perf_logger.dart';

/// Thin facade over [PerfLogger] kept for call-site compatibility.
///
/// Prefer calling [PerfLogger] directly in new code.
class PerformanceMonitor {
  static final PerformanceMonitor instance = PerformanceMonitor._();
  PerformanceMonitor._();

  void startEvent(String name) => PerfLogger.startEvent(name);
  void endEvent() => PerfLogger.endEvent();
  void logMetric(String name, dynamic value) =>
      PerfLogger.logMetric(name, value);
  void trackNextFrame(String label) => PerfLogger.trackNextFrame(label);
}
