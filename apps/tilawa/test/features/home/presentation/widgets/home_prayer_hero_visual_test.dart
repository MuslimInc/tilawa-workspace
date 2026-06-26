import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/home/debug/home_hero_variant_debug.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_body.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_variant_b.dart';
import 'package:tilawa/features/home/presentation/widgets/home_screen_background.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa/screens/cubit/main_screen_state.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockHomeListeningResumeCubit extends MockCubit<HomeListeningResumeState>
    implements HomeListeningResumeCubit {}

class _MockMainScreenCubit extends MockCubit<MainScreenState>
    implements MainScreenCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(HomeHeroVariantDebug.resetForTests);

  group('Home Prayer Hero visual captures', () {
    testWidgets('expanded state', (tester) async {
      await _pumpHome(
        tester,
        size: const Size(393, 852),
        textScale: 1,
      );
      await _expectGolden(tester, 'home_hero_expanded');
    });

    testWidgets('mid scroll state', (tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      await _pumpHome(
        tester,
        size: const Size(393, 852),
        textScale: 1,
        controller: controller,
      );

      final double mid = HomeDashboardHeroVariantB.collapseScrollExtent(
        tester.element(find.byType(CustomScrollView)),
      );
      controller.jumpTo(mid * 0.45);
      await tester.pump();

      await _expectGolden(tester, 'home_hero_mid_scroll');
    });

    testWidgets('fully collapsed state', (tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      await _pumpHome(
        tester,
        size: const Size(393, 852),
        textScale: 1,
        controller: controller,
      );

      final double collapseExtent =
          HomeDashboardHeroVariantB.collapseScrollExtent(
            tester.element(find.byType(CustomScrollView)),
          );
      controller.jumpTo(collapseExtent);
      await tester.pump();

      await _expectGolden(tester, 'home_hero_collapsed');
    });

    testWidgets('small screen', (tester) async {
      await _pumpHome(
        tester,
        size: const Size(320, 568),
        textScale: 1,
      );
      await _expectGolden(tester, 'home_hero_small_screen');
    });

    testWidgets('text scale 1.4', (tester) async {
      await _pumpHome(
        tester,
        size: const Size(393, 852),
        textScale: 1.4,
      );
      await _expectGolden(tester, 'home_hero_text_scale_1_4');
    });
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Size size,
  required double textScale,
  ScrollController? controller,
}) async {
  final listeningCubit = _MockHomeListeningResumeCubit();
  when(
    () => listeningCubit.state,
  ).thenReturn(const HomeListeningResumeState());
  when(() => listeningCubit.stream).thenAnswer((_) => const Stream.empty());

  final mainScreenCubit = _MockMainScreenCubit();
  when(() => mainScreenCubit.state).thenReturn(const MainScreenState());
  when(() => mainScreenCubit.stream).thenAnswer((_) => const Stream.empty());

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale),
        size: size,
      ),
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor: Theme.of(
                context,
              ).componentTokens.homeScreen.backgroundGradientEnd,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(child: HomeScreenBackground()),
                  CustomScrollView(
                    controller: controller,
                    slivers: [
                      ...HomeDashboardHeroVariantB.buildSlivers(
                        context: context,
                        state: _homeDashboardState(),
                        onOpenPrayer: () {},
                      ),
                      SliverToBoxAdapter(
                        child: MultiBlocProvider(
                          providers: [
                            BlocProvider<HomeListeningResumeCubit>.value(
                              value: listeningCubit,
                            ),
                            BlocProvider<MainScreenCubit>.value(
                              value: mainScreenCubit,
                            ),
                          ],
                          child: const HomeDashboardBody(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _expectGolden(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(Scaffold),
    matchesGoldenFile('goldens/$name.png'),
  );
}

HomeDashboardState _homeDashboardState() => HomeDashboardLoaded(
  HomeDashboard(
    generatedAt: DateTime(2026, 6, 16, 17, 57),
    displayName: 'Muhammad Kamel',
    locationLabel: 'العيسوية',
    nextPrayer: HomeNextPrayer(
      type: PrayerType.fajr,
      time: DateTime(2026, 6, 26, 4, 9),
      timeUntil: const Duration(hours: 2, minutes: 1),
    ),
  ),
);
