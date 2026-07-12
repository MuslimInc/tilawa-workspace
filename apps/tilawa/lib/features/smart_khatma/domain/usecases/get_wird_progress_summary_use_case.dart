import 'dart:math' as math;

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
        return Right(_noPlan(today));
      }
      if (!_isValid(plan)) {
        return const Left(CacheFailure('Invalid Smart Khatma plan data'));
      }
      return Right(_fromPlan(plan, today));
    } on Exception catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }

  WirdProgressSummary _noPlan(DateTime today) => WirdProgressSummary.noPlan(
    localPlanDate: _dateKey(today),
  );

  WirdProgressSummary _fromPlan(KhatmaPlan plan, DateTime today) {
    final bool completedPlan = plan.isCompleted;
    final int completedToday = completedPlan ? 0 : _completedToday(plan, today);
    final int assigned = completedPlan
        ? 0
        : _assignedToday(plan, today, completedToday);
    final int completed = completedToday.clamp(0, assigned);
    final String planId = 'local_${plan.createdAt.toIso8601String()}';
    final String localPlanDate = _dateKey(today);
    if (completedPlan) {
      return WirdProgressSummary.completed(
        planId: planId,
        localPlanDate: localPlanDate,
      );
    }
    return WirdProgressSummary.active(
      planId: planId,
      localPlanDate: localPlanDate,
      assignedAmount: assigned,
      completedAmount: completed,
      adjustment: _adjustment(plan, today),
    );
  }

  int _completedToday(KhatmaPlan plan, DateTime today) {
    final DateTime? progressDate = plan.progressDate;
    final int? progressStartPage = plan.progressStartPage;
    if (progressDate == null ||
        progressStartPage == null ||
        !_isSameDate(progressDate, today)) {
      return 0;
    }
    return math.max(0, plan.currentPage - progressStartPage);
  }

  int _assignedToday(KhatmaPlan plan, DateTime today, int completedToday) {
    final int remainingAtDayStart = plan.remainingPages + completedToday;
    return math.min(
      remainingAtDayStart,
      (remainingAtDayStart / plan.remainingDays(today)).ceil(),
    );
  }

  WirdProgressAdjustment _adjustment(KhatmaPlan plan, DateTime today) {
    return switch (plan.adjustment) {
      KhatmaPlanAdjustment.catchUp
          when _isSameDateNullable(plan.adjustmentDate, today) =>
        WirdProgressAdjustment.catchUp,
      KhatmaPlanAdjustment.extended
          when _isSameDateNullable(plan.adjustmentDate, today) =>
        WirdProgressAdjustment.extended,
      KhatmaPlanAdjustment.none when plan.missedDays(today) > 0 =>
        WirdProgressAdjustment.automaticCatchUp,
      _ => WirdProgressAdjustment.none,
    };
  }

  bool _isValid(KhatmaPlan plan) {
    return plan.id.isNotEmpty &&
        plan.readingStyle == KhatmaReadingStyle.pages &&
        plan.durationDays > 0 &&
        plan.startPage >= KhatmaPlan.firstQuranPage &&
        plan.startPage <= plan.targetPage &&
        plan.targetPage <= KhatmaPlan.lastQuranPage &&
        plan.currentPage >= plan.startPage &&
        plan.currentPage <= plan.targetPage &&
        ((plan.progressDate == null && plan.progressStartPage == null) ||
            (plan.progressDate != null &&
                plan.progressStartPage != null &&
                plan.progressStartPage! >= plan.startPage &&
                plan.progressStartPage! <= plan.currentPage));
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  bool _isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  bool _isSameDateNullable(DateTime? first, DateTime second) =>
      first != null && _isSameDate(first, second);
}
