import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

import '../entities/khatma_plan.dart';
import '../repositories/khatma_plan_repository.dart';

final class UpdateKhatmaProgressUseCase {
  UpdateKhatmaProgressUseCase(
    this._repository,
    this._analyticsService, {
    DateTime Function()? now,
    Future<void> Function()? onProgressChanged,
  }) : onProgressChanged = onProgressChanged,
       _now = now ?? DateTime.now;

  final KhatmaPlanRepository _repository;
  final AnalyticsService _analyticsService;
  final DateTime Function() _now;
  final Future<void> Function()? onProgressChanged;

  Future<Either<Failure, KhatmaPlan?>> call({
    required int currentPage,
    DateTime? now,
  }) async {
    try {
      final KhatmaPlan? plan = await _repository.getActivePlan();
      if (plan == null) {
        return const Right(null);
      }
      final int visitedPage = currentPage.clamp(
        KhatmaPlan.firstQuranPage,
        KhatmaPlan.lastQuranPage,
      );
      if (visitedPage <= plan.currentPage) {
        return Right(plan);
      }
      if (visitedPage > plan.currentPage + 1) {
        return Right(plan);
      }
      final int nextPage = visitedPage;
      final DateTime today = now ?? _now();
      final bool continuesToday = _isSameDate(plan.progressDate, today);
      final KhatmaPlan updated = plan.copyWith(
        currentPage: nextPage,
        status: nextPage >= plan.targetPage
            ? KhatmaPlanStatus.completed
            : KhatmaPlanStatus.active,
        progressDate: continuesToday ? plan.progressDate : _dateOnly(today),
        progressStartPage: continuesToday
            ? plan.progressStartPage
            : plan.currentPage,
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
      await onProgressChanged?.call();
      return Right(updated);
    } on Exception catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }

  bool _isSameDate(DateTime? first, DateTime second) {
    return first?.year == second.year &&
        first?.month == second.month &&
        first?.day == second.day;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
