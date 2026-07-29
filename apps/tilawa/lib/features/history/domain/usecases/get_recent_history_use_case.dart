import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';
import '../entities/history_entity.dart';
import '../repositories/history_repository.dart';

class GetRecentHistoryUseCase {
  const GetRecentHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<Either<Failure, List<HistoryEntity>>> call({int limit = 20}) async {
    try {
      final List<HistoryEntity> history = await _repository.getRecentHistory(
        limit: limit,
      );
      return Right(history);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
