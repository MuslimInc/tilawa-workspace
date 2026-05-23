import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

/// Coordinates splash-held startup: shell/tab prep before first [HomeRoute].
///
/// Critical init (Firebase, DI, Hydrated) is already complete when the splash
/// route mounts ([_BootGate]). This type covers the work that used to run on
/// [MainScreen] after navigation (shell activation + initial tab mount).
@lazySingleton
class AppStartupReadiness {
  /// Mirrors [MainScreenCubit] delays so home opens without placeholder staging.
  static const Duration shellActivationDelay = Duration(milliseconds: 260);
  static const Duration initialTabRouteSettleDelay = Duration(
    milliseconds: 1200,
  );
  static const Duration maxSplashDuration = Duration(seconds: 10);

  bool _shellPrepComplete = false;
  bool _timedOut = false;

  /// Whether shell/tab prep finished (on splash or on [MainScreen] fallback).
  bool get shellPrepComplete => _shellPrepComplete;

  /// True when [maxSplashDuration] forced navigation to proceed.
  bool get timedOut => _timedOut;

  /// Waits until the app is ready to leave splash for [prepareShell] targets.
  Future<void> waitUntilReady({required bool prepareShell}) async {
    if (!prepareShell) {
      return;
    }
    if (_shellPrepComplete) {
      return;
    }

    try {
      await _runShellPrep().timeout(
        maxSplashDuration,
        onTimeout: () {
          _timedOut = true;
          _shellPrepComplete = true;
          logger.w(
            'AppStartupReadiness: shell prep timed out after '
            '${maxSplashDuration.inSeconds}s; proceeding',
          );
        },
      );
    } catch (e, st) {
      logger.e(
        'AppStartupReadiness: shell prep failed',
        error: e,
        stackTrace: st,
      );
      _shellPrepComplete = true;
    }
  }

  Future<void> _runShellPrep() async {
    await Future<void>.delayed(shellActivationDelay);
    final Duration tabRemainder =
        initialTabRouteSettleDelay - shellActivationDelay;
    if (tabRemainder > Duration.zero) {
      await Future<void>.delayed(tabRemainder);
    }
    _shellPrepComplete = true;
    if (!kReleaseMode) {
      logger.d(
        'AppStartupReadiness: shell prep complete',
      );
    }
  }

  /// Clears readiness flags between tests.
  @visibleForTesting
  void resetForTesting() {
    _shellPrepComplete = false;
    _timedOut = false;
  }
}
