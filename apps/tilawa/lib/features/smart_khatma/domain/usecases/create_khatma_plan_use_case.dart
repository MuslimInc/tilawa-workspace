import 'dart:math' as math;

import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

import '../entities/khatma_plan.dart';
import '../repositories/khatma_plan_repository.dart';

final class CreateKhatmaPlanUseCase {
  const CreateKhatmaPlanUseCase(
    this._repository,
    this._analyticsService,
  );

  final KhatmaPlanRepository _repository;
  final AnalyticsService _analyticsService;

  Future<Either<Failure, KhatmaPlan>> preview({
    required int durationDays,
    required int startPage,
    required int targetPage,
    DateTime? now,
  }) async {
    try {
      final DateTime createdAt = now ?? DateTime.now();
      if (startPage < KhatmaPlan.firstQuranPage ||
          targetPage > KhatmaPlan.lastQuranPage ||
          startPage > targetPage) {
        return const Left(CacheFailure('Invalid Khatma boundaries'));
      }
      final int safeDuration = durationDays.clamp(1, 365);
      final int totalPages = targetPage - startPage + 1;
      final int assignedPages = math.min(
        totalPages,
        (totalPages / safeDuration).ceil(),
      );
      final DateTime localDate = _dateOnly(createdAt);
      return Right(
        KhatmaPlan(
          id: 'local_${createdAt.toIso8601String()}',
          createdAt: createdAt,
          startDate: localDate,
          durationDays: safeDuration,
          startPage: startPage,
          targetPage: targetPage,
          assignmentDate: localDate,
          assignmentStartPage: startPage,
          assignmentEndPage: startPage + assignedPages - 1,
        ),
      );
    } on Exception catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }

  Future<Either<Failure, KhatmaPlan>> confirm(KhatmaPlan plan) async {
    try {
      await _repository.saveActivePlan(plan);
      await _analyticsService.logEvent(
        AnalyticsEvents.khatmaCreated,
        parameters: <String, Object>{
          'duration_bucket': plan.durationDays,
        },
      );
      return Right(plan);
    } on Exception catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
