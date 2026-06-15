import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

import '../repositories/khatma_plan_repository.dart';

final class ResetKhatmaPlanUseCase {
  const ResetKhatmaPlanUseCase(this._repository, this._analyticsService);

  final KhatmaPlanRepository _repository;
  final AnalyticsService _analyticsService;

  Future<Either<Failure, void>> call() async {
    try {
      final plan = await _repository.getActivePlan();
      await _repository.clearActivePlan();
      await _analyticsService.logEvent(
        AnalyticsEvents.khatmaReset,
        parameters: <String, Object>{
          if (plan != null) 'plan_id': plan.id,
        },
      );
      return const Right(null);
    } catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }
}
