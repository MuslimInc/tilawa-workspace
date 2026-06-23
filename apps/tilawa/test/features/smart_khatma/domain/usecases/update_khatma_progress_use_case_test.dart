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

      final result = await useCase(currentPage: 13);
      final updated = result.getOrElse(() => throw StateError('expected plan'));

      expect(updated?.currentPage, 13);
      expect((await repository.getActivePlan())?.currentPage, 13);
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
