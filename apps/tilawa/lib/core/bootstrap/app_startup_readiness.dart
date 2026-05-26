import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';

/// Coordinates splash-held startup: shell/tab prep before first [HomeRoute].
///
/// Critical init (Firebase, DI, Hydrated) is already complete when the splash
/// route mounts ([_BootGate]). This type covers the work that used to run on
/// [MainScreen] after navigation (shell activation + initial tab mount) and
/// prefetches the reciters catalog + favorites list while the splash is
/// visible so downstream blocs can hydrate without a loading flash.
@lazySingleton
class AppStartupReadiness {
  AppStartupReadiness(this._getReciters, this._getFavorites);

  final GetRecitersUseCase _getReciters;
  final GetFavoriteRecitersUseCase _getFavorites;

  /// Mirrors [MainScreenCubit] delays so home opens without placeholder staging.
  static const Duration shellActivationDelay = Duration(milliseconds: 260);
  static const Duration initialTabRouteSettleDelay = Duration(
    milliseconds: 1200,
  );

  /// Per-prefetch cap so a single hung endpoint cannot extend splash to the
  /// full [maxSplashDuration] safety net.
  static const Duration prefetchTimeout = Duration(seconds: 4);
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
      _prefetch(
        label: 'reciters',
        fetch: () => _getReciters(),
        onSuccess: () => _recitersDataReady = true,
      ),
      // Favorites readiness is encoded in FavoritesCubit.state — no flag needed.
      _prefetch(
        label: 'favorites',
        fetch: () => _getFavorites(const NoParams()),
      ),
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

  /// Runs [fetch] with a per-call timeout, swallows failures, and invokes
  /// [onSuccess] only when the underlying repository returned [Right].
  ///
  /// Uses [Future.any] (not [Future.timeout]) because `dartz_plus.Either`
  /// callers return `Right<...>`/`Left<...>` subtypes whose reified generics
  /// reject the `Left` fallback that `onTimeout` would need.
  Future<void> _prefetch({
    required String label,
    required Future<Either<Failure, List<ReciterEntity>>> Function() fetch,
    VoidCallback? onSuccess,
  }) async {
    try {
      final Either<Failure, List<ReciterEntity>> result =
          await Future.any(<Future<Either<Failure, List<ReciterEntity>>>>[
            fetch(),
            Future<Either<Failure, List<ReciterEntity>>>.delayed(
              prefetchTimeout,
              () => Left<Failure, List<ReciterEntity>>(
                UnexpectedFailure('$label prefetch timeout'),
              ),
            ),
          ]);
      result.fold((_) {}, (_) => onSuccess?.call());
    } catch (e, st) {
      logger.w(
        'AppStartupReadiness: $label prefetch failed; falling back to lazy load',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Clears readiness flags between tests.
  @visibleForTesting
  void resetForTesting() {
    _shellPrepComplete = false;
    _recitersDataReady = false;
    _timedOut = false;
  }
}
