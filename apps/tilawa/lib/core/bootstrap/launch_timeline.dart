import 'package:tilawa_core/logger.dart';

/// Utility class for tracking startup performance timing.
/// Measures both total elapsed time and per-phase timing.
class LaunchTimeline {
  LaunchTimeline() : total = Stopwatch()..start(), phase = Stopwatch();

  final Stopwatch total;
  final Stopwatch phase;

  int get phaseElapsedMs => phase.elapsedMilliseconds;

  void startPhase() {
    phase.start();
  }

  void resetPhase() {
    phase
      ..reset()
      ..start();
  }

  void log(String label) {
    logger.d(
      '[AppLaunch] source=LaunchTimeline.$label: '
      'Duration ${phase.elapsedMilliseconds}ms at (${DateTime.now()})',
    );
  }

  void logTotal(String label) {
    logger.d(
      '[AppLaunch] source=LaunchTimeline.TOTAL: '
      '$label: ${total.elapsedMilliseconds}ms at (${DateTime.now()})',
    );
  }
}
