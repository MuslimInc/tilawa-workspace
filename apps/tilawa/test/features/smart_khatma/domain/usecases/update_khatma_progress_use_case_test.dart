import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa_core/services/analytics_service.dart';

void main() {
  group('UpdateKhatmaProgressUseCase', () {
    test('advances the active plan current page', () async {
      final repository = _MemoryKhatmaPlanRepository(_plan(currentPage: 12));
      final useCase = UpdateKhatmaProgressUseCase(
        repository,
        _FakeAnalyticsService(),
      );

      final result = await useCase(
        currentPage: 13,
        now: DateTime(2026, 7, 12),
      );
      final updated = result.getOrElse(() => throw StateError('expected plan'));

      expect(updated?.currentPage, 13);
      expect((await repository.getActivePlan())?.currentPage, 13);
      expect(updated?.progressDate, DateTime(2026, 7, 12));
      expect(updated?.progressStartPage, 12);
    });

    test(
      'does not move progress backward when reader navigates back',
      () async {
        final repository = _MemoryKhatmaPlanRepository(_plan(currentPage: 40));
        final useCase = UpdateKhatmaProgressUseCase(
          repository,
          _FakeAnalyticsService(),
        );

        final result = await useCase(currentPage: 32);
        final updated = result.getOrElse(
          () => throw StateError('expected plan'),
        );

        expect(updated?.currentPage, 40);
        expect((await repository.getActivePlan())?.currentPage, 40);
      },
    );

    test('does not count long page jumps as reading progress', () async {
      final repository = _MemoryKhatmaPlanRepository(_plan(currentPage: 40));
      final useCase = UpdateKhatmaProgressUseCase(
        repository,
        _FakeAnalyticsService(),
      );

      final result = await useCase(currentPage: 120);
      final updated = result.getOrElse(() => throw StateError('expected plan'));

      expect(updated?.currentPage, 40);
      expect((await repository.getActivePlan())?.currentPage, 40);
    });

    test('marks the plan completed at the target page', () async {
      final repository = _MemoryKhatmaPlanRepository(_plan(currentPage: 603));
      final useCase = UpdateKhatmaProgressUseCase(
        repository,
        _FakeAnalyticsService(),
      );

      final result = await useCase(currentPage: 604);
      final updated = result.getOrElse(() => throw StateError('expected plan'));

      expect(updated?.status, KhatmaPlanStatus.completed);
      expect(updated?.isCompleted, isTrue);
    });

    test(
      'keeps one baseline for multiple updates on the same local day',
      () async {
        final repository = _MemoryKhatmaPlanRepository(_plan(currentPage: 12));
        final useCase = UpdateKhatmaProgressUseCase(
          repository,
          _FakeAnalyticsService(),
          now: () => DateTime(2026, 7, 12, 23, 59),
        );

        await useCase(currentPage: 13);
        final second = await useCase(currentPage: 14);
        final updated = second.getOrElse(
          () => throw StateError('expected plan'),
        );

        expect(updated?.progressDate, DateTime(2026, 7, 12));
        expect(updated?.progressStartPage, 12);
      },
    );

    test(
      'rolls baseline before first advancement on a new local day',
      () async {
        final repository = _MemoryKhatmaPlanRepository(
          _plan(currentPage: 20).copyWith(
            progressDate: DateTime(2026, 7, 10),
            progressStartPage: 12,
          ),
        );
        final useCase = UpdateKhatmaProgressUseCase(
          repository,
          _FakeAnalyticsService(),
          now: () => DateTime(2026, 7, 13, 0, 1),
        );

        final result = await useCase(currentPage: 21);
        final updated = result.getOrElse(
          () => throw StateError('expected plan'),
        );

        expect(updated?.progressDate, DateTime(2026, 7, 13));
        expect(updated?.progressStartPage, 20);
        expect(updated?.currentPage, 21);
      },
    );
  });

  group('ExtendKhatmaPlanUseCase', () {
    test('extends a missed plan and reduces today pressure', () async {
      final now = DateTime(2026, 6, 10);
      final plan = _plan(
        createdAt: DateTime(2026, 6),
        startDate: DateTime(2026, 6),
        currentPage: 21,
      );
      final repository = _MemoryKhatmaPlanRepository(plan);
      final useCase = ExtendKhatmaPlanUseCase(
        repository,
        _FakeAnalyticsService(),
      );
      final int previousTarget = plan.todayTargetPages(now);

      final result = await useCase(now: now);
      final updated = result.getOrElse(() => throw StateError('expected plan'));

      expect(updated?.durationDays, greaterThan(plan.durationDays));
      expect(updated?.todayTargetPages(now), lessThan(previousTarget));
      expect(updated?.adjustmentDate, DateTime(2026, 6, 10));
    });
  });

  group('SelectKhatmaCatchUpUseCase', () {
    test('preserves same-day progress checkpoint', () async {
      final checkpointDate = DateTime(2026, 7, 12);
      final plan = _plan(currentPage: 26).copyWith(
        progressDate: checkpointDate,
        progressStartPage: 21,
      );
      final repository = _MemoryKhatmaPlanRepository(plan);
      final useCase = SelectKhatmaCatchUpUseCase(
        repository,
        _FakeAnalyticsService(),
        now: () => checkpointDate,
      );

      final result = await useCase();
      final updated = result.getOrElse(
        () => throw StateError('expected plan'),
      );

      expect(updated?.progressDate, checkpointDate);
      expect(updated?.progressStartPage, 21);
      expect(updated?.adjustment, KhatmaPlanAdjustment.catchUp);
      expect(updated?.adjustmentDate, checkpointDate);
    });

    test('latest same-day adjustment replaces the previous strategy', () async {
      final today = DateTime(2026, 7, 12);
      final repository = _MemoryKhatmaPlanRepository(_plan(currentPage: 21));
      final analytics = _FakeAnalyticsService();

      await SelectKhatmaCatchUpUseCase(
        repository,
        analytics,
        now: () => today,
      )();
      final result = await ExtendKhatmaPlanUseCase(
        repository,
        analytics,
        now: () => today,
      )();
      final updated = result.getOrElse(
        () => throw StateError('expected plan'),
      );

      expect(updated?.adjustment, KhatmaPlanAdjustment.extended);
      expect(updated?.adjustmentDate, today);
    });
  });

  group('ResetKhatmaPlanUseCase', () {
    test('clears the active plan', () async {
      final repository = _MemoryKhatmaPlanRepository(_plan(currentPage: 40));
      final useCase = ResetKhatmaPlanUseCase(
        repository,
        _FakeAnalyticsService(),
      );

      final result = await useCase();

      expect(result.isRight(), isTrue);
      expect(await repository.getActivePlan(), isNull);
    });
  });
}

KhatmaPlan _plan({
  DateTime? createdAt,
  DateTime? startDate,
  int currentPage = 1,
}) {
  return KhatmaPlan(
    id: 'plan-1',
    createdAt: createdAt ?? DateTime(2026, 6, 1),
    startDate: startDate ?? DateTime(2026, 6, 1),
    durationDays: 30,
    startPage: 1,
    targetPage: 604,
    currentPage: currentPage,
  );
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

final class _FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
