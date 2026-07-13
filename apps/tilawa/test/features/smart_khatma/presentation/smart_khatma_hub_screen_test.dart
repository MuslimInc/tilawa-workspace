import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets(
    'creation review is usable on a narrow screen at 1.4 text scale',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Repository();
      final bloc = _bloc(repository);

      await tester.pumpWidget(
        BlocProvider<KhatmaPlanBloc>.value(
          value: bloc,
          child: MaterialApp(
            theme: AppTheme.getLightTheme(
              primaryColor: AppColors.defaultPrimary,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.4),
              ),
              child: child!,
            ),
            home: const SmartKhatmaHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Khatma'), findsOneWidget);
      expect(find.bySemanticsLabel('Create Khatma'), findsWidgets);
      await tester.tap(find.text('Create Khatma'));
      await tester.pumpAndSettle();
      expect(find.text('Surah range'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Page range'));
      await tester.pumpAndSettle();
      expect(find.text('Start page'), findsOneWidget);
      expect(find.text('End page'), findsOneWidget);
      expect(tester.takeException(), isNull);

      bloc.add(
        const KhatmaPlanPreviewRequested(
          durationDays: 30,
          startPage: 1,
          targetPage: 604,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review your Khatma plan'), findsOneWidget);
      expect(repository.plan, isNull);
      expect(tester.takeException(), isNull);

      final confirm = find.text('Start this Khatma', skipOffstage: false);
      await tester.ensureVisible(confirm);
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(repository.plan, isNotNull);
      semantics.dispose();
    },
  );

  for (final (name, plan, expected) in <(String, KhatmaPlan, String)>[
    ('no progress today', _plan(), 'Start today’s Wird'),
    ('partial progress', _plan(confirmedThrough: 5), 'Resume today’s Wird'),
    (
      'today completed',
      _plan(confirmedThrough: 21),
      'Today’s Wird is complete',
    ),
  ]) {
    testWidgets('active state: $name', (tester) async {
      await _pumpHub(tester, _bloc(_Repository(plan)));

      expect(find.text(expected), findsOneWidget);
      expect(find.text('Pages 1–21'), findsWidgets);
      expect(find.textContaining('Expected completion:'), findsOneWidget);
    });
  }

  testWidgets('full completion exposes both required actions', (tester) async {
    await _pumpHub(
      tester,
      _bloc(_Repository(_plan(confirmedThrough: 604))),
    );

    expect(find.text('Start another Khatma'), findsOneWidget);
    expect(find.text('Return to Quran'), findsOneWidget);
  });

  testWidgets('recoverable error exposes retry and confirmed reset entry', (
    tester,
  ) async {
    await _pumpHub(tester, _bloc(_FailingRepository()));

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Reset Khatma'), findsOneWidget);
  });
}

Future<void> _pumpHub(WidgetTester tester, KhatmaPlanBloc bloc) async {
  await tester.pumpWidget(
    BlocProvider<KhatmaPlanBloc>.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SmartKhatmaHubScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

KhatmaPlanBloc _bloc(KhatmaPlanRepository repository) {
  final analytics = _Analytics();
  return KhatmaPlanBloc(
    GetActiveKhatmaPlanUseCase(repository),
    GetKhatmaTodayTargetUseCase(repository),
    CreateKhatmaPlanUseCase(repository, analytics),
    UpdateKhatmaPlanUseCase(repository, analytics),
    UpdateKhatmaProgressUseCase(repository, analytics),
    ExtendKhatmaPlanUseCase(repository, analytics),
    ResetKhatmaPlanUseCase(repository, analytics),
    () async {},
  )..add(const KhatmaPlanStarted());
}

KhatmaPlan _plan({int? confirmedThrough}) => KhatmaPlan(
  id: 'plan-1',
  createdAt: DateTime.now(),
  startDate: DateTime.now(),
  durationDays: 30,
  startPage: 1,
  targetPage: 604,
  confirmedCompletedThroughPage: confirmedThrough,
  assignmentDate: DateTime.now(),
  assignmentStartPage: 1,
  assignmentEndPage: 21,
);

final class _Repository implements KhatmaPlanRepository {
  _Repository([this.plan]);

  KhatmaPlan? plan;

  @override
  Future<void> clearActivePlan() async => plan = null;

  @override
  Future<KhatmaPlan?> getActivePlan() async => plan;

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) async => this.plan = plan;
}

final class _FailingRepository implements KhatmaPlanRepository {
  @override
  Future<void> clearActivePlan() async {}

  @override
  Future<KhatmaPlan?> getActivePlan() => throw const FormatException('corrupt');

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) async {}
}

final class _Analytics implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
