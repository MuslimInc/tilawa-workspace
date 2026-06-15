import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';

import '../entities/khatma_plan.dart';
import '../repositories/khatma_plan_repository.dart';

final class GetActiveKhatmaPlanUseCase {
  const GetActiveKhatmaPlanUseCase(this._repository);

  final KhatmaPlanRepository _repository;

  Future<Either<Failure, KhatmaPlan?>> call() async {
    try {
      return Right(await _repository.getActivePlan());
    } catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }
}
