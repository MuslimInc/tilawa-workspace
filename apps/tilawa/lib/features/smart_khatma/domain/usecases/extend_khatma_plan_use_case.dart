import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

import '../entities/khatma_plan.dart';
import '../repositories/khatma_plan_repository.dart';

final class ExtendKhatmaPlanUseCase {
  const ExtendKhatmaPlanUseCase(this._repository, this._analyticsService);

  final KhatmaPlanRepository _repository;
  final AnalyticsService _analyticsService;

  Future<Either<Failure, KhatmaPlan?>> call({DateTime? now}) async {
    try {
      final KhatmaPlan? plan = await _repository.getActivePlan();
      if (plan == null) {
        return const Right(null);
      }
      final today = now ?? DateTime.now();
      final int extraDays = plan.missedDays(today).clamp(1, 30).toInt();
      final KhatmaPlan updated = plan.copyWith(
        durationDays: plan.durationDays + extraDays,
      );
      await _repository.saveActivePlan(updated);
      await _logAdjustment(plan, updated, today);
      return Right(updated);
    } catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }

  Future<void> _logAdjustment(
    KhatmaPlan previous,
    KhatmaPlan updated,
    DateTime today,
  ) async {
    await _analyticsService.logEvent(
      AnalyticsEvents.khatmaExtendSelected,
      parameters: <String, Object>{
        'plan_id': updated.id,
        'new_duration_days': updated.durationDays,
        'new_daily_target_pages': updated.todayTargetPages(today),
      },
    );
    await _analyticsService.logEvent(
      AnalyticsEvents.khatmaPlanAdjusted,
      parameters: <String, Object>{
        'plan_id': updated.id,
        'old_daily_target_pages': previous.todayTargetPages(today),
        'new_daily_target_pages': updated.todayTargetPages(today),
        'missed_days': previous.missedDays(today),
      },
    );
  }
}
