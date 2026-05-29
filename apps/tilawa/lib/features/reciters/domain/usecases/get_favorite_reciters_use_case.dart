import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../repositories/reciters_repository.dart';

@lazySingleton
class GetFavoriteRecitersUseCase
    implements UseCase<List<ReciterEntity>, NoParams> {
  GetFavoriteRecitersUseCase(this._repository);
  final RecitersRepository _repository;

  Either<Failure, List<ReciterEntity>>? _cachedSuccess;
  Future<Either<Failure, List<ReciterEntity>>>? _inFlight;

  @override
  ResultFuture<List<ReciterEntity>> call(NoParams params) async {
    final cachedSuccess = _cachedSuccess;
    if (cachedSuccess != null) {
      _cachedSuccess = null;
      return cachedSuccess;
    }

    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _repository.getFavoriteReciters().then((result) {
      result.fold((_) {}, (_) {
        _cachedSuccess = result;
      });
      return result;
    });
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  @visibleForTesting
  void clearCacheForTesting() {
    _cachedSuccess = null;
    _inFlight = null;
  }

  /// Returns and clears favorites loaded during startup readiness.
  ///
  /// Cache is one-shot so later writes (toggle/clear) or sign-in changes go
  /// back to the repository.
  List<ReciterEntity>? takeCachedSuccessForStartup() {
    final cachedSuccess = _cachedSuccess;
    if (cachedSuccess == null) {
      return null;
    }
    _cachedSuccess = null;
    return cachedSuccess.fold<List<ReciterEntity>?>(
      (_) => null,
      (favorites) => favorites,
    );
  }
}
