import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa_core/services/analytics_service.dart';

void main() {
  group('Khatma persistence and lifecycle', () {
    test('reset deletes the active plan', () async {
      final repository = _Repository(_plan());
      final useCase = ResetKhatmaPlanUseCase(repository, _Analytics());

      await useCase();

      expect(repository.plan, isNull);
    });

    test('resume page opens at assignment start before confirmation', () {
      final plan = _plan();

      expect(plan.resumePage, 22);
    });

    test('resume page advances after partial confirmation', () {
      final plan = _plan(confirmedThrough: 30);

      expect(plan.resumePage, 31);
    });
  });
}

KhatmaPlan _plan({int? confirmedThrough}) => KhatmaPlan(
  id: 'plan-1',
  createdAt: DateTime(2026, 7, 12),
  startDate: DateTime(2026, 7, 12),
  durationDays: 30,
  startPage: 22,
  targetPage: 139,
  confirmedCompletedThroughPage: confirmedThrough,
  assignmentDate: DateTime(2026, 7, 20),
  assignmentStartPage: 22,
  assignmentEndPage: 45,
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

final class _Analytics implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
