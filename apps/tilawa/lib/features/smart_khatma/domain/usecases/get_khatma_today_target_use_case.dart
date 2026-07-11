import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa_core/core.dart';

import '../entities/khatma_plan.dart';
import '../repositories/khatma_plan_repository.dart';

final class GetKhatmaTodayTargetUseCase {
  const GetKhatmaTodayTargetUseCase(
    this._repository,
    this._quranReaderRepository,
  );

  final KhatmaPlanRepository _repository;
  final QuranReaderRepository _quranReaderRepository;

  Future<Either<Failure, KhatmaTodayTarget?>> call({DateTime? now}) async {
    try {
      final KhatmaPlan? plan = await _repository.getActivePlan();
      if (plan == null || plan.isCompleted) {
        return const Right(null);
      }
      final lastRead = await _quranReaderRepository.getLastReadPosition();
      final int startPage = (lastRead.page ?? plan.currentPage).clamp(
        KhatmaPlan.firstQuranPage,
        KhatmaPlan.lastQuranPage,
      );
      final DateTime today = now ?? DateTime.now();
      return Right(
        KhatmaTodayTarget(
          plan: plan,
          startPage: startPage,
          pages: plan.todayTargetPages(today),
          missedDays: plan.missedDays(today),
        ),
      );
    } catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }
}
