import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

import '../entities/khatma_plan.dart';
import '../repositories/khatma_plan_repository.dart';

/// Updates schedule fields on the active plan while preserving progress.
final class UpdateKhatmaPlanUseCase {
  UpdateKhatmaPlanUseCase(
    this._repository,
    this._analyticsService, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final KhatmaPlanRepository _repository;
  final AnalyticsService _analyticsService;
  final DateTime Function() _now;

  Future<Either<Failure, KhatmaPlan>> previewDurationChange({
    required KhatmaPlan plan,
    required int durationDays,
  }) async {
    final int? safeDuration = _validatedDuration(plan, durationDays);
    if (safeDuration == null) {
      return const Left(CacheFailure('Invalid Khatma duration'));
    }
    return Right(plan.copyWith(durationDays: safeDuration));
  }

  Future<Either<Failure, KhatmaPlan?>> confirmDurationChange({
    required KhatmaPlan plan,
    required int durationDays,
  }) async {
    try {
      final int? safeDuration = _validatedDuration(plan, durationDays);
      if (safeDuration == null) {
        return const Left(CacheFailure('Invalid Khatma duration'));
      }
      final KhatmaPlan updated = plan.copyWith(durationDays: safeDuration);
      await _repository.saveActivePlan(updated);
      await _analyticsService.logEvent(
        AnalyticsEvents.khatmaPlanAdjusted,
        parameters: <String, Object>{
          'duration_bucket': updated.durationDays,
        },
      );
      return Right(updated);
    } on Exception catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }

  int? _validatedDuration(KhatmaPlan plan, int durationDays) {
    if (durationDays < 1 || durationDays > 365) return null;
    final int minimumDays = plan.currentDay(_now());
    if (durationDays < minimumDays) return null;
    return durationDays;
  }
}
