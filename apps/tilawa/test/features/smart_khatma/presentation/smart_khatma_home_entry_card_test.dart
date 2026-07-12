import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('completed plan shows calm completion instead of continue CTA', (
    tester,
  ) async {
    final bloc = _bloc(
      _MemoryPlanRepository(
        KhatmaPlan(
          id: 'local-plan',
          createdAt: DateTime(2026, 7),
          startDate: DateTime(2026, 7),
          durationDays: 30,
          startPage: 1,
          targetPage: 604,
          currentPage: 604,
          status: KhatmaPlanStatus.completed,
        ),
      ),
    );

    await _pump(tester, bloc, const Locale('en'));

    expect(find.text('Khatma complete'), findsOneWidget);
    expect(find.text('Continue Reading'), findsNothing);
  });

  testWidgets('failure state is localized in Arabic and hides raw errors', (
    tester,
  ) async {
    final bloc = _bloc(_FailingPlanRepository());

    await _pump(tester, bloc, const Locale('ar'));

    expect(find.textContaining('غير متاحة مؤقتًا'), findsOneWidget);
    expect(find.textContaining('storage failure'), findsNothing);
  });
}

KhatmaPlanBloc _bloc(KhatmaPlanRepository repository) {
  final reader = _FakeQuranReaderRepository();
  final analytics = _FakeAnalyticsService();
  return KhatmaPlanBloc(
    GetActiveKhatmaPlanUseCase(repository),
    GetKhatmaTodayTargetUseCase(repository, reader),
    CreateKhatmaPlanUseCase(repository, reader, analytics),
    SelectKhatmaCatchUpUseCase(repository, analytics),
    ExtendKhatmaPlanUseCase(repository, analytics),
    ResetKhatmaPlanUseCase(repository, analytics),
    () async {},
  )..add(const KhatmaPlanStarted());
}

Future<void> _pump(
  WidgetTester tester,
  KhatmaPlanBloc bloc,
  Locale locale,
) async {
  await tester.pumpWidget(
    BlocProvider<KhatmaPlanBloc>.value(
      value: bloc,
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SmartKhatmaHomeEntryCard()),
      ),
    ),
  );
  await tester.pump();
}

class _MemoryPlanRepository implements KhatmaPlanRepository {
  _MemoryPlanRepository(this.plan);

  KhatmaPlan? plan;

  @override
  Future<void> clearActivePlan() async => plan = null;

  @override
  Future<KhatmaPlan?> getActivePlan() async => plan;

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) async => this.plan = plan;
}

class _FailingPlanRepository implements KhatmaPlanRepository {
  @override
  Future<void> clearActivePlan() => throw Exception('storage failure');

  @override
  Future<KhatmaPlan?> getActivePlan() => throw Exception('storage failure');

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) =>
      throw Exception('storage failure');
}

class _FakeQuranReaderRepository implements QuranReaderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
