import 'dart:math' as math;

import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';

import '../entities/khatma_plan.dart';
import '../repositories/khatma_plan_repository.dart';

final class GetKhatmaTodayTargetUseCase {
  const GetKhatmaTodayTargetUseCase(this._repository);

  final KhatmaPlanRepository _repository;

  Future<Either<Failure, KhatmaTodayTarget?>> call({DateTime? now}) async {
    try {
      KhatmaPlan? plan = await _repository.getActivePlan();
      if (plan == null || plan.isCompleted) return const Right(null);
      final DateTime today = _dateOnly(now ?? DateTime.now());
      if (!_isSameDate(plan.assignmentDate, today)) {
        final int assignmentStart =
            (plan.confirmedCompletedThroughPage ?? plan.startPage - 1) + 1;
        final int pages = plan.targetPagesFor(today);
        plan = plan.copyWith(
          assignmentDate: today,
          assignmentStartPage: assignmentStart,
          assignmentEndPage: math.min(
            plan.targetPage,
            assignmentStart + pages - 1,
          ),
        );
        await _repository.saveActivePlan(plan);
      }
      return Right(
        KhatmaTodayTarget(plan: plan, missedDays: plan.missedDays(today)),
      );
    } on Exception catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }

  bool _isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
