import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../repositories/reciters_repository.dart';

@Singleton()
class GetRecitersUseCase {
  GetRecitersUseCase(this._repository);

  final RecitersRepository _repository;
  Either<Failure, List<ReciterEntity>>? _cachedSuccess;
  Future<Either<Failure, List<ReciterEntity>>>? _inFlight;

  ResultFuture<List<ReciterEntity>> call() async {
    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _repository.getReciters().then((result) {
      result.fold(
        (_) {},
        (_) {
          _cachedSuccess = result;
        },
      );
      return result;
    });
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  /// Clears startup prefetch cache so the next [call] hits the repository.
  ///
  /// Used when the app language changes so reciter names reload in the new
  /// locale instead of reusing a one-shot splash cache.
  void invalidateCache() {
    _cachedSuccess = null;
  }

  @visibleForTesting
  void clearCacheForTesting() {
    _cachedSuccess = null;
    _inFlight = null;
  }

  /// Returns and clears reciters loaded during startup readiness.
  ///
  /// The cache is intentionally one-shot so later language changes or manual
  /// refreshes go back to the repository.
  List<ReciterEntity>? takeCachedSuccessForStartup() {
    final cachedSuccess = _cachedSuccess;
    if (cachedSuccess == null) {
      return null;
    }
    _cachedSuccess = null;
    return cachedSuccess.fold<List<ReciterEntity>?>(
      (_) => null,
      (reciters) => reciters,
    );
  }
}
