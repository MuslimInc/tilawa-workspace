import 'package:flutter/foundation.dart';
import 'package:tilawa/core/logging/app_logger.dart';

/// Profile/debug markers for cold-start notification and deep-link routing.
///
/// Filter logcat/console with `[ColdStartNav]` when measuring time-to-route
/// vs time-to-usable UI in `--profile` builds.
class ColdStartNavigationMetrics {
  ColdStartNavigationMetrics._();

  static int _splashScreenCount = 0;

  /// Splash UIs shown this process (BootGate + GoRouter `/splash`).
  static int get splashScreenCount => _splashScreenCount;

  @visibleForTesting
  static void resetForTesting() {
    _splashScreenCount = 0;
  }

  static void recordBootGateSplash() {
    _splashScreenCount++;
    logger.d('[ColdStartNav] splash=boot_gate count=$_splashScreenCount');
  }

  static void recordRouterSplash() {
    _splashScreenCount++;
    logger.d('[ColdStartNav] splash=router_initial count=$_splashScreenCount');
  }

  static void logResolvedRoute(String location, {Object? extra}) {
    logger.d(
      '[ColdStartNav] resolved_route=$location '
      'has_extra=${extra != null}',
    );
  }

  static void logNavigation({
    required String phase,
    required String location,
    required bool coldStart,
    Object? extra,
  }) {
    logger.d(
      '[ColdStartNav] phase=$phase cold_start=$coldStart '
      'location=$location has_extra=${extra != null}',
    );
  }

  static void logMatchedLocation(String? location) {
    logger.d('[ColdStartNav] matched_location=$location');
  }
}
