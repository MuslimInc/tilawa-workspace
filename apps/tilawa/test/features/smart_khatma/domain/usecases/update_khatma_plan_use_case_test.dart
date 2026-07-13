import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa_core/services/analytics_service.dart';

void main() {
  group('UpdateKhatmaPlanUseCase', () {
    test(
      'previews a longer duration while preserving progress fields',
      () async {
        final repository = _Repository(_activePlan());
        final useCase = _useCase(repository, now: () => DateTime(2026, 7, 20));

        final preview = (await useCase.previewDurationChange(
          plan: _activePlan(),
          durationDays: 45,
        )).getOrElse(() => throw StateError('expected preview'));

        expect(preview.durationDays, 45);
        expect(preview.confirmedCompletedThroughPage, 21);
        expect(preview.startPage, 1);
        expect(preview.targetPage, 604);
        expect(repository.plan?.durationDays, 30);
      },
    );

    test('persists duration edits without clearing progress', () async {
      final repository = _Repository(_activePlan());
      final useCase = _useCase(repository, now: () => DateTime(2026, 7, 20));

      await useCase.confirmDurationChange(
        plan: _activePlan(),
        durationDays: 45,
      );

      expect(repository.plan?.durationDays, 45);
      expect(repository.plan?.confirmedCompletedThroughPage, 21);
    });

    test('rejects durations shorter than elapsed plan days', () async {
      final useCase = _useCase(
        _Repository(_activePlan()),
        now: () {
          return DateTime(2026, 7, 20);
        },
      );

      final result = await useCase.confirmDurationChange(
        plan: _activePlan(),
        durationDays: 5,
      );

      expect(result.isLeft(), isTrue);
    });
  });
}

UpdateKhatmaPlanUseCase _useCase(
  _Repository repository, {
  required DateTime Function() now,
}) => UpdateKhatmaPlanUseCase(repository, _Analytics(), now: now);

KhatmaPlan _activePlan() => KhatmaPlan(
  id: 'plan-1',
  createdAt: DateTime(2026, 7, 12),
  startDate: DateTime(2026, 7, 12),
  durationDays: 30,
  startPage: 1,
  targetPage: 604,
  confirmedCompletedThroughPage: 21,
  assignmentDate: DateTime(2026, 7, 20),
  assignmentStartPage: 22,
  assignmentEndPage: 42,
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
