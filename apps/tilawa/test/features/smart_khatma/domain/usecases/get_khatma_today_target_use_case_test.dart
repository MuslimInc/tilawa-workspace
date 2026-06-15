import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';

void main() {
  group('GetKhatmaTodayTargetUseCase', () {
    test('returns null when there is no active plan', () async {
      final useCase = GetKhatmaTodayTargetUseCase(
        _MemoryKhatmaPlanRepository(),
        const _FakeQuranReaderRepository(page: 1),
      );

      final result = await useCase(now: DateTime(2026, 6, 15));

      expect(
        result.getOrElse(() => throw StateError('expected right')),
        isNull,
      );
    });

    test(
      'computes today target from remaining pages and remaining days',
      () async {
        final plan = KhatmaPlan(
          id: 'plan-1',
          createdAt: DateTime(2026, 6, 15),
          startDate: DateTime(2026, 6, 15),
          durationDays: 30,
          startPage: 1,
          targetPage: 604,
          currentPage: 303,
        );
        final useCase = GetKhatmaTodayTargetUseCase(
          _MemoryKhatmaPlanRepository(plan),
          const _FakeQuranReaderRepository(page: 303),
        );

        final result = await useCase(now: DateTime(2026, 6, 15));
        final target = result.getOrElse(
          () => throw StateError('expected target'),
        );

        expect(target?.startPage, 303);
        expect(target?.pages, 11);
        expect(target?.remainingPages, 302);
        expect((target?.progress ?? 0) > 0.49, isTrue);
      },
    );

    test('increases target when elapsed days create page debt', () async {
      final plan = KhatmaPlan(
        id: 'plan-1',
        createdAt: DateTime(2026, 6, 1),
        startDate: DateTime(2026, 6, 1),
        durationDays: 30,
        startPage: 1,
        targetPage: 604,
        currentPage: 21,
      );
      final useCase = GetKhatmaTodayTargetUseCase(
        _MemoryKhatmaPlanRepository(plan),
        const _FakeQuranReaderRepository(page: 21),
      );

      final result = await useCase(now: DateTime(2026, 6, 10));
      final target = result.getOrElse(
        () => throw StateError('expected target'),
      );

      expect(target?.missedDays, greaterThan(0));
      expect(target?.pages, greaterThan(plan.plannedDailyPages()));
    });
  });
}

final class _MemoryKhatmaPlanRepository implements KhatmaPlanRepository {
  _MemoryKhatmaPlanRepository([this._plan]);

  KhatmaPlan? _plan;

  @override
  Future<void> clearActivePlan() async {
    _plan = null;
  }

  @override
  Future<KhatmaPlan?> getActivePlan() async => _plan;

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) async {
    _plan = plan;
  }
}

final class _FakeQuranReaderRepository implements QuranReaderRepository {
  const _FakeQuranReaderRepository({required this.page});

  final int? page;

  @override
  Future<({int? ayahNumber, int? page, int? surahNumber})>
  getLastReadPosition() async {
    return (surahNumber: 2, ayahNumber: 1, page: page);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
