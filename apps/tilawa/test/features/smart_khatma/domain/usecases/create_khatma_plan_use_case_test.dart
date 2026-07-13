import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa_core/services/analytics_service.dart';

void main() {
  group('CreateKhatmaPlanUseCase', () {
    test('previews the full Quran without saving', () async {
      final repository = _Repository();
      final plan = (await _useCase(repository).preview(
        durationDays: 30,
        startPage: 1,
        targetPage: 604,
        now: DateTime(2026, 7, 12),
      )).getOrElse(() => throw StateError('expected preview'));

      expect(plan.startPage, 1);
      expect(plan.targetPage, 604);
      expect(plan.totalPages, 604);
      expect(plan.assignmentEndPage, 21);
      expect(repository.plan, isNull);
    });

    test('previews an arbitrary explicit page range', () async {
      final plan = (await _useCase(_Repository()).preview(
        durationDays: 30,
        startPage: 80,
        targetPage: 200,
        now: DateTime(2026, 7, 12),
      )).getOrElse(() => throw StateError('expected preview'));

      expect(plan.startPage, 80);
      expect(plan.targetPage, 200);
      expect(plan.totalPages, 121);
      expect(plan.assignmentStartPage, 80);
    });

    test('rejects reversed boundaries', () async {
      final result = await _useCase(_Repository()).preview(
        durationDays: 30,
        startPage: 200,
        targetPage: 80,
      );

      expect(result.isLeft(), isTrue);
    });

    test('previews surah-derived page boundaries', () async {
      final int startPage = KhatmaPlanBoundaries.pageForSurahAyah(2, 142)!;
      final int targetPage = KhatmaPlanBoundaries.pageForSurahAyah(6, 94)!;

      final plan = (await _useCase(_Repository()).preview(
        durationDays: 5,
        startPage: startPage,
        targetPage: targetPage,
        now: DateTime(2026, 7, 12),
      )).getOrElse(() => throw StateError('expected preview'));

      expect(plan.startPage, startPage);
      expect(plan.targetPage, targetPage);
      expect(plan.totalPages, targetPage - startPage + 1);
    });

    test('allocates first-day pages from selected range only', () async {
      final plan = (await _useCase(_Repository()).preview(
        durationDays: 5,
        startPage: 22,
        targetPage: 139,
        now: DateTime(2026, 7, 12),
      )).getOrElse(() => throw StateError('expected preview'));

      expect(plan.assignmentStartPage, 22);
      expect(plan.assignedTodayPages, 24);
      expect(plan.assignmentEndPage, 45);
    });

    test('one-page range saves only after confirmation', () async {
      final repository = _Repository();
      final useCase = _useCase(repository);
      final preview = (await useCase.preview(
        durationDays: 30,
        startPage: 604,
        targetPage: 604,
        now: DateTime(2026, 7, 12),
      )).getOrElse(() => throw StateError('expected preview'));

      expect(preview.assignmentStartPage, 604);
      expect(preview.assignmentEndPage, 604);
      expect(repository.plan, isNull);

      await useCase.confirm(preview);
      expect(repository.plan?.targetPage, 604);
    });
  });
}

CreateKhatmaPlanUseCase _useCase(_Repository repository) =>
    CreateKhatmaPlanUseCase(repository, _Analytics());

final class _Repository implements KhatmaPlanRepository {
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
