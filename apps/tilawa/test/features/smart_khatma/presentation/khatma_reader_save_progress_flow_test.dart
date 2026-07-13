import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa/features/smart_khatma/presentation/widgets/smart_khatma_plan_actions.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('KhatmaReaderRoute save progress flow', () {
    late _MemoryRepository repository;
    late KhatmaPlanBloc bloc;
    late _FakeQuranReaderRepository quranReader;
    late KhatmaPlan plan;

    setUp(() async {
      plan = _plan();
      repository = _MemoryRepository(plan);
      quranReader = _FakeQuranReaderRepository(10);
      if (getIt.isRegistered<QuranReaderRepository>()) {
        getIt.unregister<QuranReaderRepository>();
      }
      getIt.registerSingleton<QuranReaderRepository>(quranReader);
      bloc = _bloc(repository);
      await bloc.stream.firstWhere((state) => state is KhatmaPlanLoaded);
      plan = repository.plan!;
    });

    tearDown(() {
      bloc.close();
      if (getIt.isRegistered<QuranReaderRepository>()) {
        getIt.unregister<QuranReaderRepository>();
      }
    });

    Future<void> pumpHarness(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      ThemeMode themeMode = ThemeMode.light,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => _Harness(plan: plan),
          ),
          GoRoute(
            path: '/khatma-reader/:initialPage',
            builder: (context, state) {
              final page = state.pathParameters['initialPage'];
              return Scaffold(
                key: const ValueKey('khatma-reader-stub'),
                appBar: AppBar(
                  leading: BackButton(onPressed: () => context.pop()),
                ),
                body: Text('Reader at page $page'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<KhatmaPlanBloc>.value(
          value: bloc,
          child: MaterialApp.router(
            locale: locale,
            theme: AppTheme.getLightTheme(
              primaryColor: AppColors.defaultPrimary,
            ).copyWith(splashFactory: InkRipple.splashFactory),
            darkTheme: AppTheme.getDarkTheme(
              primaryColor: AppColors.defaultPrimary,
            ).copyWith(splashFactory: InkRipple.splashFactory),
            themeMode: themeMode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> openReaderAndReturn(
      WidgetTester tester, {
      String sheetTitle = 'Save your Khatma progress',
    }) async {
      await tester.tap(find.text('Open reader flow'));
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find
            .byKey(const ValueKey('khatma-reader-stub'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
      expect(find.byKey(const ValueKey('khatma-reader-stub')), findsOneWidget);
      expect(
        const KhatmaReaderRoute(initialPage: 1).location,
        '/khatma-reader/1',
      );
      final readerContext = tester.element(
        find.byKey(const ValueKey('khatma-reader-stub')),
      );
      GoRouter.of(readerContext).pop();
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text(sheetTitle, skipOffstage: false).evaluate().isNotEmpty) {
          break;
        }
      }
    }

    test('bloc persists user-confirmed progress', () async {
      final updated = bloc.stream.firstWhere(
        (state) =>
            state is KhatmaPlanLoaded &&
            state.plan?.confirmedCompletedThroughPage == 10,
      );
      bloc.add(const KhatmaProgressConfirmed(10));
      await updated;
      expect(repository.plan?.confirmedCompletedThroughPage, 10);
    });

    testWidgets(
      'KhatmaReaderRoute return opens Save Progress with reader page',
      (tester) async {
        await pumpHarness(tester);
        await openReaderAndReturn(tester);

        expect(find.text('Save your Khatma progress'), findsOneWidget);
        expect(find.text('I completed through page 10'), findsOneWidget);
        expect(find.text('Save through page 10'), findsOneWidget);
      },
    );

    testWidgets('reader return can suggest completing today assignment', (
      tester,
    ) async {
      plan = _plan(assignmentEndPage: 21);
      repository.plan = plan;
      quranReader.page = 21;
      await pumpHarness(tester);
      await openReaderAndReturn(tester);

      expect(find.text('I completed through page 21'), findsOneWidget);
      expect(find.text('I completed today’s Wird'), findsOneWidget);
    });

    testWidgets('Arabic RTL save progress sheet', (tester) async {
      await pumpHarness(tester, locale: const Locale('ar'));
      await openReaderAndReturn(
        tester,
        sheetTitle: 'احفظ تقدّم الختمة',
      );

      expect(find.text('احفظ تقدّم الختمة'), findsOneWidget);
      expect(find.text('حفظ التقدّم حتى الصفحة 10'), findsOneWidget);
    });

    testWidgets('dark mode save progress sheet renders', (tester) async {
      await pumpHarness(tester, themeMode: ThemeMode.dark);
      await openReaderAndReturn(tester);

      expect(find.text('Save your Khatma progress'), findsOneWidget);
    });
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.plan});

  final KhatmaPlan plan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TilawaButton(
          text: 'Open reader flow',
          onPressed: () => openKhatmaReaderAndRefresh(context, plan),
        ),
      ),
    );
  }
}

KhatmaPlanBloc _bloc(_MemoryRepository repository) {
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

KhatmaPlan _plan({int? confirmedThrough, int assignmentEndPage = 604}) =>
    KhatmaPlan(
      id: 'plan-1',
      createdAt: DateTime(2026, 7, 13),
      startDate: DateTime(2026, 7, 13),
      durationDays: 30,
      startPage: 1,
      targetPage: 604,
      confirmedCompletedThroughPage: confirmedThrough,
      assignmentDate: DateTime(2026, 7, 13),
      assignmentStartPage: 1,
      assignmentEndPage: assignmentEndPage,
    );

final class _MemoryRepository implements KhatmaPlanRepository {
  _MemoryRepository(this.plan);

  KhatmaPlan? plan;

  @override
  Future<void> clearActivePlan() async => plan = null;

  @override
  Future<KhatmaPlan?> getActivePlan() async => plan;

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) async => this.plan = plan;
}

final class _FakeQuranReaderRepository implements QuranReaderRepository {
  _FakeQuranReaderRepository(this.page);

  int? page;

  @override
  Future<({int? ayahNumber, int? page, int? surahNumber})>
  getLastReadPosition() async {
    return (surahNumber: 2, ayahNumber: 1, page: page);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Analytics implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
