import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';

void main() {
  group('GetKhatmaTodayTargetUseCase', () {
    test('returns the frozen assignment during the same local day', () async {
      final repository = _MemoryRepository(_plan());

      final result = await GetKhatmaTodayTargetUseCase(repository)(
        now: DateTime(2026, 7, 12, 22),
      );
      final target = result.getOrElse(() => null);

      expect(target?.startPage, 1);
      expect(target?.endPage, 21);
      expect(target?.pages, 21);
      expect(repository.saveCount, 0);
    });

    test('partial confirmation does not move the assignment end', () async {
      final repository = _MemoryRepository(_plan(confirmedThrough: 5));

      final target = (await GetKhatmaTodayTargetUseCase(repository)(
        now: DateTime(2026, 7, 12, 23),
      )).getOrElse(() => null);

      expect(target?.startPage, 1);
      expect(target?.endPage, 21);
      expect(target?.completedPages, 5);
      expect(target?.remainingTodayPages, 16);
    });

    test(
      'next local day freezes a new assignment from first unconfirmed page',
      () async {
        final repository = _MemoryRepository(_plan(confirmedThrough: 5));

        final target = (await GetKhatmaTodayTargetUseCase(repository)(
          now: DateTime(2026, 7, 13),
        )).getOrElse(() => null);

        expect(target?.startPage, 6);
        expect(target?.endPage, greaterThan(6));
        expect(repository.saveCount, 1);
      },
    );
  });
}

KhatmaPlan _plan({int? confirmedThrough}) => KhatmaPlan(
  id: 'plan-1',
  createdAt: DateTime(2026, 7, 12),
  startDate: DateTime(2026, 7, 12),
  durationDays: 30,
  startPage: 1,
  targetPage: 604,
  confirmedCompletedThroughPage: confirmedThrough,
  assignmentDate: DateTime(2026, 7, 12),
  assignmentStartPage: 1,
  assignmentEndPage: 21,
);

final class _MemoryRepository implements KhatmaPlanRepository {
  _MemoryRepository(this.plan);

  KhatmaPlan? plan;
  int saveCount = 0;

  @override
  Future<void> clearActivePlan() async => plan = null;

  @override
  Future<KhatmaPlan?> getActivePlan() async => plan;

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) async {
    saveCount++;
    this.plan = plan;
  }
}
