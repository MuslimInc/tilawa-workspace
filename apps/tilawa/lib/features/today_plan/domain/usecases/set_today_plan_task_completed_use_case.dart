import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';

import '../repositories/today_plan_repository.dart';

final class SetTodayPlanTaskCompletedUseCase {
  const SetTodayPlanTaskCompletedUseCase(this._repository);

  final TodayPlanRepository _repository;

  Future<Either<Failure, void>> call({
    required String dateKey,
    required String taskId,
    required bool completed,
  }) async {
    try {
      await _repository.setTaskCompleted(
        dateKey: dateKey,
        taskId: taskId,
        completed: completed,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
