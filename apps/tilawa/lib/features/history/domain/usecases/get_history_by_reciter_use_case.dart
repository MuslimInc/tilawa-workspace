import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/history_entity.dart';
import '../repositories/history_repository.dart';

@lazySingleton
class GetHistoryByReciterUseCase
    implements UseCase<List<HistoryEntity>, String> {
  GetHistoryByReciterUseCase(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Either<Failure, List<HistoryEntity>>> call(String reciterId) async {
    try {
      final result = await _repository.getHistoryByReciter(reciterId);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
