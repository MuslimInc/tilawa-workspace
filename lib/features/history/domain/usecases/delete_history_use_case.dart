import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/history_repository.dart';

@lazySingleton
class DeleteHistoryUseCase {
  const DeleteHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<Either<Failure, void>> call(String id) async {
    try {
      await _repository.deleteHistory(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
