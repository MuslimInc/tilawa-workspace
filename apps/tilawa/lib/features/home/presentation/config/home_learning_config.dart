import 'package:flutter/foundation.dart';

/// Configuration constants for the Home Learning entry strategy.
@immutable
abstract final class HomeLearningConfig {
  /// How long before a session starts to promote it as imminent to the top slot.
  static const Duration imminentSessionThreshold = Duration(hours: 2);

  /// How long a completed session's revision remains active before aging out.
  static const Duration revisionAgeOutThreshold = Duration(days: 7);
}
