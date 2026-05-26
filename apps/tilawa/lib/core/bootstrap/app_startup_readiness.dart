import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';

/// Coordinates splash-held startup: shell/tab prep before first [HomeRoute].
///
/// Critical init (Firebase, DI, Hydrated) is already complete when the splash
/// route mounts ([_BootGate]). This type covers the work that used to run on
/// [MainScreen] after navigation (shell activation + initial tab mount) and
/// preloads the Reciters tab list while the splash is visible.
@lazySingleton
class AppStartupReadiness {
  AppStartupReadiness(this._recitersBloc);

  final RecitersBloc _recitersBloc;

  /// Mirrors [MainScreenCubit] delays so home opens without placeholder staging.
  static const Duration shellActivationDelay = Duration(milliseconds: 260);
  static const Duration initialTabRouteSettleDelay = Duration(
    milliseconds: 400,
  );
  static const Duration maxSplashDuration = Duration(seconds: 10);

  bool _shellPrepComplete = false;
  bool _recitersDataReady = false;
  bool _timedOut = false;

  /// Whether shell/tab prep finished (on splash or on [MainScreen] fallback).
  bool get shellPrepComplete => _shellPrepComplete;

  /// Whether [RecitersBloc] reached [RecitersLoaded] during splash prep.
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
      _prepareRecitersTab(),
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

  Future<void> _prepareRecitersTab() async {
    final RecitersState current = _recitersBloc.state;
    if (current is RecitersLoaded) {
      _recitersDataReady = true;
      return;
    }

    final Completer<void> settled = Completer<void>();
    late final StreamSubscription<RecitersState> subscription;
    subscription = _recitersBloc.stream.listen((RecitersState state) {
      if (state is RecitersLoaded || state is RecitersError) {
        if (!settled.isCompleted) {
          settled.complete();
        }
      }
    });

    if (current is! RecitersLoading) {
      _recitersBloc.add(const LoadReciters());
    }
    try {
      await settled.future;
    } finally {
      await subscription.cancel();
    }

    _recitersDataReady = _recitersBloc.state is RecitersLoaded;
  }

  /// Clears readiness flags between tests.
  @visibleForTesting
  void resetForTesting() {
    _shellPrepComplete = false;
    _recitersDataReady = false;
    _timedOut = false;
  }
}
