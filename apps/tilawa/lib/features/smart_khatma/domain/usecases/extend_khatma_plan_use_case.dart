import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

import '../entities/khatma_plan.dart';
import '../repositories/khatma_plan_repository.dart';

final class ExtendKhatmaPlanUseCase {
  ExtendKhatmaPlanUseCase(
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
      final int extraDays = plan.missedDays(today).clamp(1, 30);
      final KhatmaPlan updated = plan.copyWith(
        durationDays: plan.durationDays + extraDays,
        adjustment: KhatmaPlanAdjustment.extended,
        adjustmentDate: _dateOnly(today),
      );
      await _repository.saveActivePlan(updated);
      await _logAdjustment(updated);
      return Right(updated);
    } on Exception catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _logAdjustment(KhatmaPlan updated) async {
    await _analyticsService.logEvent(
      AnalyticsEvents.khatmaExtendSelected,
      parameters: <String, Object>{
        'duration_bucket': updated.durationDays,
      },
    );
    await _analyticsService.logEvent(AnalyticsEvents.khatmaPlanAdjusted);
  }
}
