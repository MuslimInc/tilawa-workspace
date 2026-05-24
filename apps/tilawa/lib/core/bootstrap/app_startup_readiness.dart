import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';

/// Coordinates splash-held startup: shell/tab prep before first [HomeRoute].
///
/// Critical init (Firebase, DI, Hydrated) is already complete when the splash
/// route mounts ([_BootGate]). This type covers the work that used to run on
/// [MainScreen] after navigation (shell activation + initial tab mount) and
/// preloads the reciters catalog while the splash is visible.
@lazySingleton
class AppStartupReadiness {
  AppStartupReadiness(this._getReciters);

  final GetRecitersUseCase _getReciters;

  /// Mirrors [MainScreenCubit] delays so home opens without placeholder staging.
  static const Duration shellActivationDelay = Duration(milliseconds: 260);
  static const Duration initialTabRouteSettleDelay = Duration(
    milliseconds: 1200,
  );
  static const Duration maxSplashDuration = Duration(seconds: 10);

  bool _shellPrepComplete = false;
  bool _recitersDataReady = false;
  bool _timedOut = false;

  /// Whether shell/tab prep finished (on splash or on [MainScreen] fallback).
  bool get shellPrepComplete => _shellPrepComplete;

  /// Whether reciters catalog loaded successfully during splash prep.
  bool get recitersDataReady => _recitersDataReady;

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
      await _runHomeLaunchPrep().timeout(
        maxSplashDuration,
        onTimeout: () {
          _timedOut = true;
          _shellPrepComplete = true;
          logger.w(
            'AppStartupReadiness: home launch prep timed out after '
            '${maxSplashDuration.inSeconds}s; proceeding',
          );
        },
      );
    } catch (e, st) {
      logger.e(
        'AppStartupReadiness: home launch prep failed',
        error: e,
        stackTrace: st,
      );
      _shellPrepComplete = true;
    }
  }

  Future<void> _runHomeLaunchPrep() async {
    await Future.wait(<Future<void>>[
      _runShellDelays(),
      _prepareRecitersCatalog(),
    ]);
    _shellPrepComplete = true;
    if (!kReleaseMode) {
      logger.d(
        'AppStartupReadiness: home launch prep complete '
        '(recitersReady=$_recitersDataReady)',
      );
    }
  }

  Future<void> _runShellDelays() async {
    await Future<void>.delayed(shellActivationDelay);
    final Duration tabRemainder =
        initialTabRouteSettleDelay - shellActivationDelay;
    if (tabRemainder > Duration.zero) {
      await Future<void>.delayed(tabRemainder);
    }
  }

  Future<void> _prepareRecitersCatalog() async {
    final result = await _getReciters();
    _recitersDataReady = result.fold((_) => false, (_) => true);
  }

  /// Clears readiness flags between tests.
  @visibleForTesting
  void resetForTesting() {
    _shellPrepComplete = false;
    _recitersDataReady = false;
    _timedOut = false;
  }
}
