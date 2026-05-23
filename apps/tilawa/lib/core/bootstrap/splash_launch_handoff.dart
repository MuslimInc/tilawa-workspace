import 'package:flutter/foundation.dart';

/// Coordinates the launch splash overlay until [SplashScreen] paints its first
/// frame after [BootGate] swaps in the real app tree.
abstract final class SplashLaunchHandoff {
  /// Becomes true after the first frame of [SplashScreen] on `/splash`.
  static final ValueNotifier<bool> splashRouteHasPainted = ValueNotifier(false);

  /// Resets handoff state for a new process launch or hot restart.
  static void resetForNewLaunch() {
    splashRouteHasPainted.value = false;
  }

  /// Called when [SplashScreen] has completed its first frame.
  static void markSplashRoutePainted() {
    if (splashRouteHasPainted.value) {
      return;
    }
    splashRouteHasPainted.value = true;
  }
}
