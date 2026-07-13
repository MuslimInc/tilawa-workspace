import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa_core/services/analytics_service.dart';

void main() {
  group('confirmed Khatma progress', () {
    test('starts with no confirmed progress', () {
      final plan = _plan();

      expect(plan.confirmedCompletedThroughPage, isNull);
      expect(plan.completedPages, 0);
      expect(plan.remainingPages, 604);
      expect(plan.progress, 0);
      expect(plan.resumePage, 1);
    });

    test('explicit partial confirmation advances once', () async {
      final repository = _MemoryKhatmaPlanRepository(_plan());
      final useCase = _useCase(repository);

      final first = await useCase(confirmedThroughPage: 5);
      final duplicate = await useCase(confirmedThroughPage: 5);
      final plan = duplicate.getOrElse(() => null);

      expect(first.isRight(), isTrue);
      expect(plan?.confirmedCompletedThroughPage, 5);
      expect(plan?.completedPages, 5);
      expect(plan?.resumePage, 6);
      expect(repository.saveCount, 1);
    });

    test('rejects backward confirmation', () async {
      final repository = _MemoryKhatmaPlanRepository(
        _plan(confirmedThrough: 5),
      );

      final result = await _useCase(repository)(confirmedThroughPage: 4);

      expect(result.isRight(), isTrue);
      expect(repository.saveCount, 0);
      expect(
        (await repository.getActivePlan())?.confirmedCompletedThroughPage,
        5,
      );
    });

    test('rejects confirmation outside today assignment', () async {
      final repository = _MemoryKhatmaPlanRepository(_plan());

      final result = await _useCase(repository)(confirmedThroughPage: 22);

      expect(result.isLeft(), isTrue);
      expect(repository.saveCount, 0);
    });

    test('daily completion keeps the frozen assignment', () async {
      final repository = _MemoryKhatmaPlanRepository(_plan());
      final before = await repository.getActivePlan();

      final result = await _useCase(repository)(confirmedThroughPage: 21);
      final plan = result.getOrElse(() => null);

      expect(plan?.isTodayCompleted, isTrue);
      expect(plan?.remainingTodayPages, 0);
      expect(plan?.assignmentStartPage, before?.assignmentStartPage);
      expect(plan?.assignmentEndPage, before?.assignmentEndPage);
    });

    test('page 604 produces internally consistent full completion', () async {
      final repository = _MemoryKhatmaPlanRepository(
        _plan(
          startPage: 604,
          assignmentStartPage: 604,
          assignmentEndPage: 604,
        ),
      );

      final result = await _useCase(repository)(confirmedThroughPage: 604);
      final plan = result.getOrElse(() => null);

      expect(plan?.isCompleted, isTrue);
      expect(plan?.completedPages, 1);
      expect(plan?.remainingPages, 0);
      expect(plan?.progress, 1);
    });

    test('selected arbitrary target produces full completion', () async {
      final repository = _MemoryKhatmaPlanRepository(
        _plan(
          startPage: 80,
          targetPage: 100,
          assignmentStartPage: 80,
          assignmentEndPage: 100,
        ),
      );

      final result = await _useCase(repository)(confirmedThroughPage: 100);
      final plan = result.getOrElse(() => null);

      expect(plan?.isCompleted, isTrue);
      expect(plan?.completedPages, 21);
      expect(plan?.remainingPages, 0);
      expect(plan?.progress, 1);
    });
  });

  test(
    'extension changes schedule without changing progress or today range',
    () async {
      final repository = _MemoryKhatmaPlanRepository(_plan());
      final result = await ExtendKhatmaPlanUseCase(
        repository,
        _FakeAnalyticsService(),
        now: () => DateTime(2026, 7, 13),
      )();
      final plan = result.getOrElse(() => null);

      expect(plan?.durationDays, greaterThan(30));
      expect(plan?.confirmedCompletedThroughPage, isNull);
      expect(plan?.assignmentStartPage, 1);
      expect(plan?.assignmentEndPage, 21);
    },
  );
}

UpdateKhatmaProgressUseCase _useCase(_MemoryKhatmaPlanRepository repository) =>
    UpdateKhatmaProgressUseCase(repository, _FakeAnalyticsService());

KhatmaPlan _plan({
  int startPage = 1,
  int targetPage = 604,
  int assignmentStartPage = 1,
  int assignmentEndPage = 21,
  int? confirmedThrough,
}) => KhatmaPlan(
  id: 'plan-1',
  createdAt: DateTime(2026, 7, 12),
  startDate: DateTime(2026, 7, 12),
  durationDays: 30,
  startPage: startPage,
  targetPage: targetPage,
  confirmedCompletedThroughPage: confirmedThrough,
  assignmentDate: DateTime(2026, 7, 12),
  assignmentStartPage: assignmentStartPage,
  assignmentEndPage: assignmentEndPage,
);

final class _MemoryKhatmaPlanRepository implements KhatmaPlanRepository {
  _MemoryKhatmaPlanRepository(this._plan);

  KhatmaPlan? _plan;
  int saveCount = 0;

  @override
  Future<void> clearActivePlan() async => _plan = null;

  @override
  Future<KhatmaPlan?> getActivePlan() async => _plan;

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) async {
    saveCount++;
    _plan = plan;
  }
}

final class _FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
