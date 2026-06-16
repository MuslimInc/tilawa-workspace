import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/core/services/hive_readiness.dart';
import 'package:tilawa_core/core.dart';

import '../../../history/domain/entities/history_entity.dart';
import '../../../history/domain/repositories/history_repository.dart';
import '../../../quran_reader/domain/repositories/quran_reader_repository.dart';
import '../../../smart_khatma/domain/entities/khatma_plan.dart';
import '../../../smart_khatma/domain/usecases/get_khatma_today_target_use_case.dart';
import '../entities/today_plan.dart';
import '../repositories/today_plan_repository.dart';

final class GenerateTodayPlanUseCase {
  const GenerateTodayPlanUseCase(
    this._quranReaderRepository,
    this._historyRepository,
    this._todayPlanRepository,
    this._hiveReadiness, [
    this._getKhatmaTodayTarget,
  ]);

  final QuranReaderRepository _quranReaderRepository;
  final HistoryRepository _historyRepository;
  final TodayPlanRepository _todayPlanRepository;
  final HiveReadiness? _hiveReadiness;
  final GetKhatmaTodayTargetUseCase? _getKhatmaTodayTarget;

  Future<Either<Failure, TodayPlan>> call({DateTime? now}) async {
    try {
      final DateTime today = now ?? DateTime.now();
      final String dateKey = _dateKey(today);
      final completedIds = await _todayPlanRepository.getCompletedTaskIds(
        dateKey,
      );
      final lastRead = await _quranReaderRepository.getLastReadPosition();
      await _hiveReadiness?.ensureReady();
      final history = await _historyRepository.getRecentHistory(limit: 10);
      final bool listeningHeavy = _isListeningHeavy(history, today);
      final KhatmaTodayTarget? khatmaTarget = await _loadKhatmaTarget(today);
      final int readingPages =
          khatmaTarget?.pages ?? _readingPagesFor(history, today);

      final tasks = <TodayPlanTask>[
        _readingTask(lastRead, readingPages, khatmaTarget),
        _listeningTask(history),
        const TodayPlanTask(
          id: 'morning_adhkar',
          kind: TodayPlanTaskKind.adhkar,
          minutes: 2,
        ),
      ];

      if (listeningHeavy) {
        final TodayPlanTask listening = tasks.removeAt(1);
        tasks.insert(0, listening);
      }

      final hydratedTasks = tasks
          .map((task) {
            if (!completedIds.contains(task.id)) {
              return task;
            }
            return task.copyWith(status: TodayPlanTaskStatus.completed);
          })
          .toList(growable: false);

      return Right(
        TodayPlan(
          dateKey: dateKey,
          tasks: hydratedTasks,
          streakDays: _streakDays(history, today),
          isAdaptive:
              listeningHeavy ||
              readingPages != 2 ||
              (khatmaTarget?.missedDays ?? 0) > 0,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  TodayPlanTask _readingTask(
    ({int? surahNumber, int? ayahNumber, int? page}) lastRead,
    int pages,
    KhatmaTodayTarget? khatmaTarget,
  ) {
    final int? page = khatmaTarget?.startPage ?? lastRead.page;
    return TodayPlanTask(
      id: 'read_quran',
      kind: TodayPlanTaskKind.reading,
      minutes: pages * 3,
      metadata: <String, Object?>{
        'pages': pages,
        'page': page,
        if (khatmaTarget != null) ...<String, Object?>{
          'khatma_plan_id': khatmaTarget.plan.id,
          'khatma_progress_percent': (khatmaTarget.progress * 100).round(),
          'khatma_remaining_pages': khatmaTarget.remainingPages,
          'khatma_missed_days': khatmaTarget.missedDays,
        },
      },
    );
  }

  Future<KhatmaTodayTarget?> _loadKhatmaTarget(DateTime today) async {
    final useCase = _getKhatmaTodayTarget;
    if (useCase == null) {
      return null;
    }
    final result = await useCase(now: today);
    return result.fold((_) => null, (target) => target);
  }

  TodayPlanTask _listeningTask(List<HistoryEntity> history) {
    final HistoryEntity? last = history.isEmpty ? null : history.first;
    return TodayPlanTask(
      id: 'listen_quran',
      kind: TodayPlanTaskKind.listening,
      minutes: 10,
      metadata: <String, Object?>{
        ...last == null
            ? <String, Object?>{}
            : <String, Object?>{
                'surah_id': last.surahId,
                'surah_name': last.surahNameEn,
                'reciter_id': last.reciterId,
                'reciter_name': last.reciterName,
              },
      },
    );
  }

  bool _isListeningHeavy(List<HistoryEntity> history, DateTime today) {
    final DateTime sevenDaysAgo = today.subtract(const Duration(days: 7));
    final recent = history.where((item) => item.playedAt.isAfter(sevenDaysAgo));
    final int listeningMinutes = recent.fold<int>(
      0,
      (total, item) => total + item.lastPosition.inMinutes,
    );
    return listeningMinutes >= 30;
  }

  int _readingPagesFor(List<HistoryEntity> history, DateTime today) {
    final int inactiveDays = _inactiveDays(history, today);
    if (inactiveDays >= 3) {
      return 1;
    }
    if (_streakDays(history, today) >= 5) {
      return 3;
    }
    return 2;
  }

  int _inactiveDays(List<HistoryEntity> history, DateTime today) {
    if (history.isEmpty) {
      return 0;
    }
    final DateTime latest = history.first.playedAt;
    return DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime(latest.year, latest.month, latest.day)).inDays;
  }

  int _streakDays(List<HistoryEntity> history, DateTime today) {
    final Set<String> activeDays = history
        .map((item) => _dateKey(item.playedAt))
        .toSet();
    final String todayKey = _dateKey(today);
    final String yesterdayKey = _dateKey(
      today.subtract(const Duration(days: 1)),
    );

    late final DateTime startDay;
    if (activeDays.contains(todayKey)) {
      startDay = today;
    } else if (activeDays.contains(yesterdayKey)) {
      startDay = today.subtract(const Duration(days: 1));
    } else {
      return 0;
    }

    var streak = 0;
    for (var day = startDay; activeDays.contains(_dateKey(day));) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _dateKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
