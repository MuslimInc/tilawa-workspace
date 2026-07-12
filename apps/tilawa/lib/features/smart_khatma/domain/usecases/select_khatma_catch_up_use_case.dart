import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

import '../entities/khatma_plan.dart';
import '../repositories/khatma_plan_repository.dart';

final class SelectKhatmaCatchUpUseCase {
  SelectKhatmaCatchUpUseCase(
    this._repository,
    this._analyticsService, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final KhatmaPlanRepository _repository;
  final AnalyticsService _analyticsService;
  final DateTime Function() _now;

  Future<Either<Failure, KhatmaPlan?>> call({DateTime? now}) async {
    try {
      final KhatmaPlan? plan = await _repository.getActivePlan();
      if (plan == null) {
        return const Right(null);
      }
      final today = now ?? _now();
      final KhatmaPlan updated = plan.copyWith(
        adjustment: KhatmaPlanAdjustment.catchUp,
        adjustmentDate: _dateOnly(today),
      );
      await _repository.saveActivePlan(updated);
      await _analyticsService.logEvent(
        AnalyticsEvents.khatmaCatchupSelected,
        parameters: <String, Object>{
          'plan_id': plan.id,
          'new_daily_target_pages': plan.todayTargetPages(today),
          'missed_days': plan.missedDays(today),
        },
      );
      return Right(updated);
    } on Exception catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
