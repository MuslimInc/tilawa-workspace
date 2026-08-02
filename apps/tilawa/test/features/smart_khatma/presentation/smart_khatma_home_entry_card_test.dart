import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa/features/smart_khatma/presentation/widgets/khatma_home_destination_card.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('active Home entry shows range and confirmed remaining pages', (
    tester,
  ) async {
    final bloc = _bloc(_MemoryPlanRepository(_plan(confirmedThrough: 5)));

    await _pump(tester, bloc, const Locale('en'));

    expect(find.textContaining('1–21'), findsOneWidget);
    expect(find.textContaining('5 confirmed'), findsOneWidget);
    expect(find.textContaining('16 remaining'), findsOneWidget);
    expect(find.text('Current wird'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    final Size cardSize = tester.getSize(
      find.byType(KhatmaHomeDestinationCard),
    );
    expect(cardSize.height, greaterThanOrEqualTo(140));
  });

  testWidgets('completed plan shows calm completion in Arabic', (tester) async {
    final bloc = _bloc(
      _MemoryPlanRepository(_plan(confirmedThrough: 604)),
    );

    await _pump(tester, bloc, const Locale('ar'));

    expect(find.text('اكتملت الختمة'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('اكتملت الختمة'))),
      TextDirection.rtl,
    );
  });

  testWidgets(
    'Khatma card uses focused accents in light and dark themes',
    (
      tester,
    ) async {
      final themes = <ThemeData>[
        AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        AppTheme.getDarkTheme(primaryColor: AppColors.defaultPrimary),
      ];

      for (final theme in themes) {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            theme: theme,
            darkTheme: theme,
            themeMode: theme.brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: KhatmaHomeDestinationCard(
                  icon: Icons.auto_stories_outlined,
                  onTap: () {},
                  eyebrow: 'الورد الحالي',
                  title: 'الصفحات 582–583',
                  statusChipLabel: 'اليوم 1 من 15',
                  detail: 'اكتمل ورد اليوم',
                  progress: 9,
                  trackProgress: 0.25,
                  actionLabel: 'افتح الختمة',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Color accent =
            theme.componentTokens.homeScreen.homePrayerHeroAccent;
        final Material cardMaterial = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(KhatmaHomeDestinationCard),
                matching: find.byType(Material),
              )
              .first,
        );
        final HomeDashboardIconWell iconWell = tester
            .widget<HomeDashboardIconWell>(find.byType(HomeDashboardIconWell));
        final bool hasHeaderGradient = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(KhatmaHomeDestinationCard),
                matching: find.byType(DecoratedBox),
              ),
            )
            .any(
              (box) =>
                  box.decoration is BoxDecoration &&
                  (box.decoration as BoxDecoration).gradient != null,
            );
        final TilawaButton button = tester.widget<TilawaButton>(
          find.byType(TilawaButton),
        );
        final LinearProgressIndicator track = tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            );

        expect(cardMaterial.color, theme.colorScheme.surface);
        expect(hasHeaderGradient, isTrue);
        expect(iconWell.accent, theme.colorScheme.surface);
        expect(iconWell.fillAlpha, HomeFeaturePastel.solidIconWellFillAlpha);
        expect(button.backgroundColor, accent);
        expect(button.foregroundColor, theme.colorScheme.onPrimary);
        expect(track.color, accent);
        expect(find.text('9%'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          tester.widget<Text>(find.text('الصفحات 582–583')).maxLines,
          1,
        );
        expect(
          tester.getSize(find.byType(KhatmaHomeDestinationCard)).height,
          lessThan(280),
        );
      }
    },
  );
}

KhatmaPlanBloc _bloc(KhatmaPlanRepository repository) {
  final analytics = _FakeAnalyticsService();
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
  await tester.pumpAndSettle();
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

final class _MemoryPlanRepository implements KhatmaPlanRepository {
  _MemoryPlanRepository(this.plan);
  KhatmaPlan? plan;

  @override
  Future<void> clearActivePlan() async => plan = null;

  @override
  Future<KhatmaPlan?> getActivePlan() async => plan;

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) async => this.plan = plan;
}

final class _FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
