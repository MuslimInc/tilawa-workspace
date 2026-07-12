import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';

void main() {
  final DateTime today = DateTime(2026, 7, 12, 18);

  group('GetWirdProgressSummaryUseCase', () {
    test('produces an explicit versioned no-plan state', () async {
      final result = await GetWirdProgressSummaryUseCase(
        _MemoryKhatmaPlanRepository(),
      )(now: today);
      final summary = result.getOrElse(
        () => throw StateError('expected summary'),
      );

      expect(summary.schemaVersion, 1);
      expect(summary.planStatus, WirdProgressPlanStatus.none);
      expect(summary.planId, isNull);
      expect(summary.localPlanDate, '2026-07-12');
      expect(summary.action, WirdProgressAction.createPlan);
    });

    test('dependency factory exposes the repository-backed producer', () async {
      final useCase = SmartKhatmaDependencies.getWirdProgressSummary(
        _MemoryKhatmaPlanRepository(),
      );

      final result = await useCase(now: today);

      expect(result.isRight(), isTrue);
    });

    test('produces zero, partial, and completed daily progress', () async {
      for (final (currentPage, completed, ratio) in <(int, int, double)>[
        (21, 0, 0),
        (26, 5, 5 / 21),
        (42, 21, 1),
      ]) {
        final summary = await _summary(
          _plan(currentPage: currentPage),
          today,
        );

        expect(summary.assignedAmount, 21);
        expect(summary.completedAmount, completed);
        expect(summary.remainingAmount, 21 - completed);
        expect(summary.completionRatio, ratio);
      }
    });

    test('clamps over-completion and keeps the ratio finite', () async {
      final summary = await _summary(_plan(currentPage: 80), today);

      expect(summary.completedAmount, summary.assignedAmount);
      expect(summary.remainingAmount, 0);
      expect(summary.completionRatio, 1);
      expect(summary.completionRatio.isFinite, isTrue);
    });

    test('represents completed, catch-up, and extended plans', () async {
      final completed = await _summary(
        _plan(
          currentPage: 604,
          status: KhatmaPlanStatus.completed,
        ),
        today,
      );
      final catchUp = await _summary(
        _plan(currentPage: 1, adjustment: KhatmaPlanAdjustment.catchUp),
        today,
      );
      final extended = await _summary(
        _plan(currentPage: 1, adjustment: KhatmaPlanAdjustment.extended),
        today,
      );

      expect(completed.planStatus, WirdProgressPlanStatus.completed);
      expect(completed.completionRatio, 1);
      expect(catchUp.adjustment, WirdProgressAdjustment.catchUp);
      expect(extended.adjustment, WirdProgressAdjustment.extended);
    });

    test('does not expose adjustment metadata from a previous day', () async {
      for (final adjustment in <KhatmaPlanAdjustment>[
        KhatmaPlanAdjustment.catchUp,
        KhatmaPlanAdjustment.extended,
      ]) {
        final summary = await _summary(
          _plan(
            currentPage: 21,
            adjustment: adjustment,
            adjustmentDate: DateTime(2026, 7, 11),
          ),
          today,
        );

        expect(summary.adjustment, WirdProgressAdjustment.none);
      }
    });

    test(
      'uses injected local civil time without mutating stale checkpoint',
      () async {
        final repository = _MemoryKhatmaPlanRepository(_plan(currentPage: 26));
        final useCase = GetWirdProgressSummaryUseCase(
          repository,
          now: () => DateTime(2026, 7, 13, 0, 1),
        );

        final result = await useCase();
        final summary = result.getOrElse(
          () => throw StateError('expected summary'),
        );

        expect(summary.localPlanDate, '2026-07-13');
        expect(summary.completedAmount, 0);
        expect(repository.saveCount, 0);
      },
    );

    test(
      'follows supplied local date across timezone and clock changes',
      () async {
        for (final (localTime, expectedDate) in <(DateTime, String)>[
          (DateTime(2026, 7, 12, 23, 59, 59), '2026-07-12'),
          (DateTime(2026, 7, 13, 0, 0, 1), '2026-07-13'),
          (DateTime(2026, 7, 13, 1), '2026-07-13'),
          (DateTime(2026, 7, 12, 22), '2026-07-12'),
          (DateTime(2026, 10, 25, 1, 30), '2026-10-25'),
        ]) {
          final summary = await _summary(_plan(currentPage: 26), localTime);
          expect(summary.localPlanDate, expectedDate);
        }
      },
    );

    test('rejects invalid and unsupported persisted values', () async {
      final invalidResult = await GetWirdProgressSummaryUseCase(
        _MemoryKhatmaPlanRepository(_plan(currentPage: 605)),
      )(now: today);
      final minutesResult = await GetWirdProgressSummaryUseCase(
        _MemoryKhatmaPlanRepository(
          _plan(currentPage: 21, readingStyle: KhatmaReadingStyle.minutes),
        ),
      )(now: today);

      expect(invalidResult.isLeft(), isTrue);
      expect(minutesResult.isLeft(), isTrue);
    });

    test('rejects checkpoint baselines outside plan bounds', () async {
      for (final baseline in <int>[-1, 605]) {
        final result = await GetWirdProgressSummaryUseCase(
          _MemoryKhatmaPlanRepository(
            _plan(currentPage: 26).copyWith(progressStartPage: baseline),
          ),
        )(now: today);

        expect(result.isLeft(), isTrue);
      }
    });

    test(
      'is deterministic, locale-free, read-only, and ignores listening',
      () async {
        final plan = _plan(currentPage: 26);
        final repository = _MemoryKhatmaPlanRepository(plan);
        final useCase = GetWirdProgressSummaryUseCase(repository);

        final first = await useCase(now: today);
        final second = await useCase(now: today);
        final firstSummary = first.getOrElse(
          () => throw StateError('expected summary'),
        );
        final secondSummary = second.getOrElse(
          () => throw StateError('expected summary'),
        );

        expect(secondSummary.planId, firstSummary.planId);
        expect(firstSummary.planId, 'local_2026-07-11T09:00:00.000Z');
        expect(firstSummary.planId, isNot(plan.id));
        expect(secondSummary.completedAmount, firstSummary.completedAmount);
        expect(repository.saveCount, 0);
        expect(identical(await repository.getActivePlan(), plan), isTrue);
      },
    );
  });
}

Future<WirdProgressSummary> _summary(KhatmaPlan plan, DateTime now) async {
  final result = await GetWirdProgressSummaryUseCase(
    _MemoryKhatmaPlanRepository(plan),
  )(now: now);
  return result.getOrElse(() => throw StateError('expected summary'));
}

KhatmaPlan _plan({
  required int currentPage,
  KhatmaPlanStatus status = KhatmaPlanStatus.active,
  KhatmaPlanAdjustment adjustment = KhatmaPlanAdjustment.none,
  KhatmaReadingStyle readingStyle = KhatmaReadingStyle.pages,
  DateTime? adjustmentDate,
}) {
  return KhatmaPlan(
    id: 'private-infrastructure-id',
    createdAt: DateTime.utc(2026, 7, 11, 9),
    startDate: DateTime(2026, 7, 11),
    durationDays: 30,
    startPage: 1,
    targetPage: 604,
    currentPage: currentPage,
    status: status,
    adjustment: adjustment,
    adjustmentDate:
        adjustmentDate ??
        (adjustment == KhatmaPlanAdjustment.none
            ? null
            : DateTime(2026, 7, 12)),
    readingStyle: readingStyle,
    progressDate: DateTime(2026, 7, 12),
    progressStartPage: currentPage.clamp(1, 21),
  );
}

final class _MemoryKhatmaPlanRepository implements KhatmaPlanRepository {
  _MemoryKhatmaPlanRepository([this._plan]);

  KhatmaPlan? _plan;
  int saveCount = 0;

  @override
  Future<void> clearActivePlan() async => _plan = null;

  @override
  Future<KhatmaPlan?> getActivePlan() async => _plan;

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) async {
    saveCount += 1;
    _plan = plan;
  }
}
