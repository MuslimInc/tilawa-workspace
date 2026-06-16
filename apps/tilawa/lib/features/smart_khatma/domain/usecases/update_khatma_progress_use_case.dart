import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

import '../entities/khatma_plan.dart';
import '../repositories/khatma_plan_repository.dart';

final class UpdateKhatmaProgressUseCase {
  const UpdateKhatmaProgressUseCase(this._repository, this._analyticsService);

  final KhatmaPlanRepository _repository;
  final AnalyticsService _analyticsService;

  Future<Either<Failure, KhatmaPlan?>> call({required int currentPage}) async {
    try {
      final KhatmaPlan? plan = await _repository.getActivePlan();
      if (plan == null) {
        return const Right(null);
      }
      final int visitedPage = currentPage
          .clamp(KhatmaPlan.firstQuranPage, KhatmaPlan.lastQuranPage)
          .toInt();
      if (visitedPage <= plan.currentPage) {
        return Right(plan);
      }
      if (visitedPage > plan.currentPage + 1) {
        return Right(plan);
      }
      final int nextPage = visitedPage;
      final KhatmaPlan updated = plan.copyWith(
        currentPage: nextPage,
        status: nextPage >= plan.targetPage
            ? KhatmaPlanStatus.completed
            : KhatmaPlanStatus.active,
      );
      await _repository.saveActivePlan(updated);
      await _analyticsService.logEvent(
        AnalyticsEvents.khatmaProgressUpdated,
        parameters: <String, Object>{
          'plan_id': updated.id,
          'current_page': updated.currentPage,
          'progress_percent': (updated.progress * 100).round(),
          'remaining_pages': updated.remainingPages,
        },
      );
      if (updated.isCompleted) {
        await _analyticsService.logEvent(
          AnalyticsEvents.khatmaCompleted,
          parameters: <String, Object>{
            'plan_id': updated.id,
            'duration_days': updated.durationDays,
          },
        );
      }
      return Right(updated);
    } catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }
}
