import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_last_read_position_use_case.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/quran_engagement_streak.dart';
import 'home_quran_resume_state.dart';

@injectable
class HomeQuranResumeCubit extends Cubit<HomeQuranResumeState> {
  HomeQuranResumeCubit(
    this._getLastReadPosition,
    this._historyRepository,
  ) : super(const HomeQuranResumeState());

  final GetLastReadPositionUseCase _getLastReadPosition;
  final HistoryRepository _historyRepository;

  Future<void> load({DateTime? now}) async {
    emit(
      state.copyWith(
        status: HomeQuranResumeStatus.loading,
        clearFailure: true,
      ),
    );

    final DateTime effectiveNow = now ?? DateTime.now();
    final Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>
    positionResult = await _getLastReadPosition();
    final List<HistoryEntity> history = await _historyRepository
        .getRecentHistory(limit: 30);

    KhatmaTodayTarget? khatmaTarget;
    if (isSmartKhatmaEnabled()) {
      final useCase = SmartKhatmaDependencies.getTodayTarget(
        SmartKhatmaDependencies.repository(),
      );
      final Either<Failure, KhatmaTodayTarget?> targetResult = await useCase(
        now: effectiveNow,
      );
      khatmaTarget = targetResult.fold((_) => null, (value) => value);
    }

    positionResult.fold(
      (failure) => emit(
        state.copyWith(
          status: HomeQuranResumeStatus.failure,
          failure: failure,
          streakDays: 0,
          clearPosition: true,
          clearGoalProgress: true,
          hasActiveKhatmaPlan: false,
        ),
      ),
      (position) {
        final int streakDays = quranEngagementStreakDays(
          history: history,
          today: effectiveNow,
        );
        emit(
          HomeQuranResumeState(
            status: HomeQuranResumeStatus.ready,
            surahNumber: position.surahNumber,
            ayahNumber: position.ayahNumber,
            page: position.page,
            streakDays: streakDays > 0 ? streakDays : null,
            goalProgress: _goalProgress(
              khatmaTarget: khatmaTarget,
              lastReadPage: position.page,
            ),
            hasActiveKhatmaPlan: khatmaTarget != null,
          ),
        );
      },
    );
  }

  double? _goalProgress({
    required KhatmaTodayTarget? khatmaTarget,
    required int? lastReadPage,
  }) {
    if (khatmaTarget == null || khatmaTarget.pages <= 0) {
      return null;
    }
    final int? page = lastReadPage;
    if (page == null) {
      return null;
    }
    final int readToday = (page - khatmaTarget.startPage).clamp(
      0,
      khatmaTarget.pages,
    );
    if (readToday <= 0) {
      return null;
    }
    return (readToday / khatmaTarget.pages).clamp(0.0, 1.0);
  }
}
