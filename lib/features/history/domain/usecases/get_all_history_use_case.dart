import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/history_entity.dart';
import '../repositories/history_repository.dart';

@lazySingleton
class GetAllHistoryUseCase {
  const GetAllHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<Either<Failure, List<HistoryEntity>>> call() async {
    try {
      final List<HistoryEntity> history = await _repository.getAllHistory();
      return Right(history);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
