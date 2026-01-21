import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import '../repositories/history_repository.dart';

@lazySingleton
class ClearAllHistoryUseCase {
  const ClearAllHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<Either<Failure, void>> call() async {
    try {
      await _repository.deleteAllHistory();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
