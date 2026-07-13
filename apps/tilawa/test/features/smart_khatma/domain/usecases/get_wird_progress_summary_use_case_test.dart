import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';

void main() {
  test('summary derives only from confirmed progress', () async {
    final repository = _Repository(_plan(confirmedThrough: 5));

    final summary = (await GetWirdProgressSummaryUseCase(repository)(
      now: DateTime(2026, 7, 12),
    )).getOrElse(() => throw StateError('expected summary'));

    expect(summary.assignedAmount, 21);
    expect(summary.completedAmount, 5);
    expect(summary.remainingAmount, 16);
    expect(summary.completionRatio, closeTo(5 / 21, 0.001));
  });

  test('page 604 summary is completed', () async {
    final summary = (await GetWirdProgressSummaryUseCase(
      _Repository(_plan(confirmedThrough: 604)),
    )()).getOrElse(() => throw StateError('expected summary'));

    expect(summary.planStatus, WirdProgressPlanStatus.completed);
    expect(summary.completionRatio, 1);
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

final class _Repository implements KhatmaPlanRepository {
  _Repository(this.plan);
  KhatmaPlan? plan;

  @override
  Future<void> clearActivePlan() async => plan = null;

  @override
  Future<KhatmaPlan?> getActivePlan() async => plan;

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) async => this.plan = plan;
}
