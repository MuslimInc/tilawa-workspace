import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa/features/today_plan/domain/entities/today_plan.dart';
import 'package:tilawa/features/today_plan/domain/repositories/today_plan_repository.dart';
import 'package:tilawa/features/today_plan/domain/usecases/generate_today_plan_use_case.dart';

void main() {
  group('GenerateTodayPlanUseCase', () {
    test('creates a Quran-first plan from last read and history', () async {
      final useCase = _createUseCase(
        lastReadPage: 303,
        history: [_history(surahNameEn: 'Al-Kahf')],
      );

      final result = await useCase(now: DateTime(2026, 6, 14));
      final plan = result.getOrElse(() => throw StateError('expected plan'));

      expect(plan.tasks.first.kind, TodayPlanTaskKind.reading);
      expect(plan.tasks.first.metadata['page'], 303);
      expect(plan.tasks.first.metadata['pages'], 2);
      expect(plan.tasks[1].kind, TodayPlanTaskKind.listening);
      expect(plan.tasks[1].metadata['surah_name'], 'Al-Kahf');
      expect(plan.minutesRemaining, 18);
    });

    test('prioritizes listening for listening-heavy users', () async {
      final useCase = _createUseCase(
        history: [
          _history(lastPositionMs: 20 * 60 * 1000),
          _history(lastPositionMs: 15 * 60 * 1000),
        ],
      );

      final result = await useCase(now: DateTime(2026, 6, 14));
      final plan = result.getOrElse(() => throw StateError('expected plan'));

      expect(plan.tasks.first.kind, TodayPlanTaskKind.listening);
      expect(plan.isAdaptive, isTrue);
    });

    test('reduces reading goal after missed days', () async {
      final useCase = _createUseCase(
        history: [_history(playedAt: DateTime(2026, 6, 9))],
      );

      final result = await useCase(now: DateTime(2026, 6, 14));
      final plan = result.getOrElse(() => throw StateError('expected plan'));

      final reading = plan.tasks.firstWhere(
        (task) => task.kind == TodayPlanTaskKind.reading,
      );
      expect(reading.metadata['pages'], 1);
      expect(plan.isAdaptive, isTrue);
    });

    test('hydrates completed task ids for today', () async {
      final completionRepository = _MemoryTodayPlanRepository(
        completedIds: {'read_quran'},
      );
      final useCase = _createUseCase(
        completionRepository: completionRepository,
      );

      final result = await useCase(now: DateTime(2026, 6, 14));
      final plan = result.getOrElse(() => throw StateError('expected plan'));

      expect(plan.completedCount, 1);
      expect(plan.tasks.first.isCompleted, isTrue);
    });
  });
}

GenerateTodayPlanUseCase _createUseCase({
  int? lastReadPage,
  List<HistoryEntity> history = const [],
  _MemoryTodayPlanRepository? completionRepository,
}) {
  return GenerateTodayPlanUseCase(
    _FakeQuranReaderRepository(lastReadPage),
    _FakeHistoryRepository(history),
    completionRepository ?? _MemoryTodayPlanRepository(),
  );
}

HistoryEntity _history({
  String surahNameEn = 'Al-Baqarah',
  int lastPositionMs = 5 * 60 * 1000,
  DateTime? playedAt,
}) {
  return HistoryEntity(
    id: 'history_$surahNameEn',
    surahId: 2,
    surahName: 'البقرة',
    surahNameEn: surahNameEn,
    reciterId: '1',
    reciterName: 'Mishary Alafasy',
    moshafId: 1,
    moshafName: 'Hafs',
    lastPositionMs: lastPositionMs,
    durationMs: 60 * 60 * 1000,
    audioUrl: 'https://example.test/audio.mp3',
    playedAt: playedAt ?? DateTime(2026, 6, 14, 9),
  );
}

final class _FakeQuranReaderRepository implements QuranReaderRepository {
  const _FakeQuranReaderRepository(this.page);

  final int? page;

  @override
  Future<({int? ayahNumber, int? page, int? surahNumber})>
  getLastReadPosition() async {
    return (surahNumber: 18, ayahNumber: 1, page: page);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeHistoryRepository implements HistoryRepository {
  const _FakeHistoryRepository(this.history);

  final List<HistoryEntity> history;

  @override
  Future<List<HistoryEntity>> getRecentHistory({int limit = 20}) async {
    return history.take(limit).toList(growable: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _MemoryTodayPlanRepository implements TodayPlanRepository {
  _MemoryTodayPlanRepository({Set<String>? completedIds})
    : _completedIds = completedIds ?? <String>{};

  final Set<String> _completedIds;

  @override
  Future<Set<String>> getCompletedTaskIds(String dateKey) async {
    return _completedIds;
  }

  @override
  Future<void> setTaskCompleted({
    required String dateKey,
    required String taskId,
    required bool completed,
  }) async {
    if (completed) {
      _completedIds.add(taskId);
    } else {
      _completedIds.remove(taskId);
    }
  }
}
