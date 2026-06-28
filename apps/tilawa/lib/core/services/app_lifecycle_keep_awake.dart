import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:tilawa_core/services/interfaces/keep_awake_service.dart';

/// Keeps the screen awake while the app is foreground-resumed and releases
/// the wakelock on background transitions.
///
/// [enable] is deferred to the next frame after [AppLifecycleState.resumed] so
/// Android has attached a foreground activity before wakelock_plus runs.
abstract final class AppLifecycleKeepAwake {
  static void handleStateChange({
    required AppLifecycleState state,
    required KeepAwakeService keepAwakeService,
    SchedulerBinding? schedulerBinding,
  }) {
    final SchedulerBinding scheduler =
        schedulerBinding ?? SchedulerBinding.instance;

    switch (state) {
      case AppLifecycleState.resumed:
        scheduler.scheduleFrameCallback((_) {
          unawaited(keepAwakeService.enable());
        });
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(keepAwakeService.disable());
    }
  }
}
