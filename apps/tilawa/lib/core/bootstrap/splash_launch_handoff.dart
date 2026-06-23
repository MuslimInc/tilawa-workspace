import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:tilawa/core/telemetry/startup_perf_log.dart';
import 'package:tilawa/core/telemetry/startup_telemetry.dart';

import 'first_frame_log.dart';

/// Coordinates the launch splash overlay until the routed Flutter app paints
/// its first frame after [BootGate] swaps in the real app tree.
abstract final class SplashLaunchHandoff {
  /// Becomes true after the first routed app frame paints.
  ///
  /// The initial route may be `/splash` or a resolved launch target such as
  /// `/`, so this is intentionally broader than the splash route itself.
  static final ValueNotifier<bool> splashRouteHasPainted = ValueNotifier(false);

  /// Resets handoff state for a new process launch or hot restart.
  static void resetForNewLaunch() {
    splashRouteHasPainted.value = false;
    firstFrameLog('handoff reset (splashRouteHasPainted=false)');
    StartupPerfLog.log('splash_handoff_reset');
  }

  /// Called when the routed app has completed its first frame.
  static void markSplashRoutePainted() {
    if (splashRouteHasPainted.value) {
      firstFrameLog('handoff mark skipped (already painted)');
      StartupPerfLog.log(
        'splash_handoff_mark_skipped',
        detail: 'already_painted',
      );
      return;
    }
    splashRouteHasPainted.value = true;
    firstFrameLog('handoff complete (splashRouteHasPainted=true)');
    StartupPerfLog.log('splash_handoff_marked');
    StartupPerfLog.log('startup_completed');
    unawaited(StartupTelemetry.phase('first_route_painted'));
    unawaited(StartupTelemetry.completed());
  }
}
