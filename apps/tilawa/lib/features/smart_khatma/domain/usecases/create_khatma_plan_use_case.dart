import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa_core/core.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

import '../entities/khatma_plan.dart';
import '../repositories/khatma_plan_repository.dart';

final class CreateKhatmaPlanUseCase {
  const CreateKhatmaPlanUseCase(
    this._repository,
    this._quranReaderRepository,
    this._analyticsService,
  );

  final KhatmaPlanRepository _repository;
  final QuranReaderRepository _quranReaderRepository;
  final AnalyticsService _analyticsService;

  Future<Either<Failure, KhatmaPlan>> call({
    required int durationDays,
    KhatmaReadingStyle readingStyle = KhatmaReadingStyle.pages,
    int? preferredMinutesPerDay,
    DateTime? now,
  }) async {
    try {
      final DateTime createdAt = now ?? DateTime.now();
      final lastRead = await _quranReaderRepository.getLastReadPosition();
      final int startPage = (lastRead.page ?? KhatmaPlan.firstQuranPage)
          .clamp(KhatmaPlan.firstQuranPage, KhatmaPlan.lastQuranPage)
          .toInt();
      final plan = KhatmaPlan(
        id: 'local_${createdAt.toIso8601String()}',
        createdAt: createdAt,
        startDate: DateTime(createdAt.year, createdAt.month, createdAt.day),
        durationDays: durationDays.clamp(1, 365).toInt(),
        startPage: startPage,
        targetPage: KhatmaPlan.lastQuranPage,
        currentPage: startPage,
        readingStyle: readingStyle,
        preferredMinutesPerDay: preferredMinutesPerDay,
      );
      await _repository.saveActivePlan(plan);
      await _analyticsService.logEvent(
        AnalyticsEvents.khatmaCreated,
        parameters: _analyticsParameters(plan),
      );
      await _analyticsService.logEvent(
        AnalyticsEvents.khatmaStarted,
        parameters: _analyticsParameters(plan),
      );
      return Right(plan);
    } catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }

  Map<String, Object> _analyticsParameters(KhatmaPlan plan) {
    return <String, Object>{
      'plan_id': plan.id,
      'duration_days': plan.durationDays,
      'start_page': plan.startPage,
      'target_page': plan.targetPage,
      'daily_target_pages': plan.plannedDailyPages(),
      'reading_style': plan.readingStyle.name,
    };
  }
}
