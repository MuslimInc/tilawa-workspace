import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

import '../entities/khatma_plan.dart';
import '../repositories/khatma_plan_repository.dart';

/// Persists progress explicitly confirmed by the user.
final class UpdateKhatmaProgressUseCase {
  UpdateKhatmaProgressUseCase(
    this._repository,
    this._analyticsService, {
    this.onProgressChanged,
  });

  final KhatmaPlanRepository _repository;
  final AnalyticsService _analyticsService;
  final Future<void> Function()? onProgressChanged;

  Future<Either<Failure, KhatmaPlan?>> call({
    required int confirmedThroughPage,
  }) async {
    try {
      final KhatmaPlan? plan = await _repository.getActivePlan();
      if (plan == null) return const Right(null);
      final int? previous = plan.confirmedCompletedThroughPage;
      if (previous != null && confirmedThroughPage <= previous) {
        return Right(plan);
      }
      if (confirmedThroughPage < plan.assignmentStartPage ||
          confirmedThroughPage > plan.assignmentEndPage) {
        return const Left(
          CacheFailure('Confirmed page is outside today’s assignment'),
        );
      }
      final KhatmaPlan updated = plan.copyWith(
        confirmedCompletedThroughPage: confirmedThroughPage,
      );
      await _repository.saveActivePlan(updated);
      await _analyticsService.logEvent(
        AnalyticsEvents.khatmaProgressUpdated,
        parameters: const <String, Object>{'source': 'user_confirmation'},
      );
      if (updated.isTodayCompleted) {
        await _analyticsService.logEvent(
          AnalyticsEvents.khatmaGoalCompleted,
        );
      }
      if (updated.isCompleted) {
        await _analyticsService.logEvent(AnalyticsEvents.khatmaCompleted);
      }
      await onProgressChanged?.call();
      return Right(updated);
    } on Exception catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }
}
