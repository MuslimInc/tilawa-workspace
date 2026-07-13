import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';

import '../entities/khatma_plan.dart';
import '../entities/wird_progress_summary.dart';
import '../repositories/khatma_plan_repository.dart';

final class GetWirdProgressSummaryUseCase {
  GetWirdProgressSummaryUseCase(
    this._repository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final KhatmaPlanRepository _repository;
  final DateTime Function() _now;

  Future<Either<Failure, WirdProgressSummary>> call({DateTime? now}) async {
    try {
      final DateTime today = now ?? _now();
      final KhatmaPlan? plan = await _repository.getActivePlan();
      if (plan == null) {
        return Right(
          WirdProgressSummary.noPlan(localPlanDate: _dateKey(today)),
        );
      }
      if (plan.isCompleted) {
        return Right(
          WirdProgressSummary.completed(
            planId: 'local_plan',
            localPlanDate: _dateKey(today),
          ),
        );
      }
      return Right(
        WirdProgressSummary.active(
          planId: 'local_plan',
          localPlanDate: _dateKey(today),
          assignedAmount: plan.assignedTodayPages,
          completedAmount: plan.confirmedTodayPages,
          adjustment:
              plan.adjustment == KhatmaPlanAdjustment.extended &&
                  _isSameDate(plan.adjustmentDate, today)
              ? WirdProgressAdjustment.extended
              : WirdProgressAdjustment.none,
        ),
      );
    } on Exception catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  bool _isSameDate(DateTime? first, DateTime second) =>
      first?.year == second.year &&
      first?.month == second.month &&
      first?.day == second.day;
}
