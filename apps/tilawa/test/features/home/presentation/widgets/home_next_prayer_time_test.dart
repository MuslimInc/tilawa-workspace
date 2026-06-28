import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/startup_blur_shader_warmup.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/home_hijri_date_formatter.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_content_sliver.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_next_prayer_time.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  setUp(StartupBlurShaderWarmup.completeForTest);

  tearDown(StartupBlurShaderWarmup.resetForTest);

  testWidgets('renders scrollable next-prayer card on neutral canvas', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);

    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_HomeNextPrayerTimeHarness(controller: controller));
    await tester.pump();
    expect(tester.takeException(), isNull);

    final BuildContext scrollContext = tester.element(
      find.byType(CustomScrollView),
    );
    final l10n = AppLocalizations.of(scrollContext);
    final String hijriDateLine = formatHomeHijriDate(
      date: DateTime.now(),
      languageCode: 'ar',
    );

    expect(find.text(l10n.homeHeroLocationContext), findsNothing);
    expect(find.text('Cairo'), findsOneWidget);
    expect(find.text(hijriDateLine), findsOneWidget);
    expect(find.text(l10n.nextPrayer), findsOneWidget);
    expect(find.byType(SliverPersistentHeader), findsNothing);
    expect(find.byType(SliverToBoxAdapter), findsWidgets);
    expect(find.byIcon(Icons.mosque_outlined), findsNothing);
    expect(find.byIcon(FluentIcons.location_24_regular), findsOneWidget);

    final screenTokens = Theme.of(
      scrollContext,
    ).componentTokens.homeScreen;
    expect(find.byType(HomeDashboardCard), findsOneWidget);
    expect(find.byType(TilawaCard), findsOneWidget);
    final TilawaCard prayerCard = tester.widget<TilawaCard>(
      find.byType(TilawaCard).first,
    );
    expect(prayerCard.surface, TilawaCardSurface.flat);
    expect(prayerCard.backgroundColor, screenTokens.homeContentSheetSurface);
  });

  testWidgets('hero has no collapse scroll extent', (tester) async {
    await tester.pumpWidget(
      _HomeNextPrayerTimeHarness(controller: ScrollController()),
    );

    final BuildContext scrollContext = tester.element(
      find.byType(CustomScrollView),
    );

    expect(HomeNextPrayerTime.collapseScrollExtent(scrollContext), 0);
  });

  testWidgets('scrolls without overflow on narrow viewport', (tester) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);

    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_HomeNextPrayerTimeHarness(controller: controller));
    await tester.pump();

    final BuildContext scrollContext = tester.element(
      find.byType(CustomScrollView),
    );
    final double heroExtent = HomeNextPrayerTime.expandedLayoutExtent(
      scrollContext,
    );

    controller.jumpTo(heroExtent);
    await tester.pump();

    expect(tester.takeException(), isNull);

    const offsets = <double>[0, 8, 40];
    for (final offset in offsets) {
      controller.jumpTo(
        math.min(offset, controller.position.maxScrollExtent),
      );
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'HomeNextPrayerTime overflowed at scroll offset $offset.',
      );
    }
  });

  testWidgets('shows sunrise neutral label when Shurooq is due now', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Builder(
          builder: (context) {
            return CustomScrollView(
              slivers: [
                ...HomeNextPrayerTime.buildSlivers(
                  context: context,
                  state: HomeDashboardLoaded(
                    HomeDashboard(
                      generatedAt: DateTime(2026, 6, 16, 5, 29),
                      locationLabel: 'Cairo',
                      nextPrayer: HomeNextPrayer(
                        type: PrayerType.sunrise,
                        time: DateTime.now().add(const Duration(seconds: 30)),
                        timeUntil: const Duration(seconds: 30),
                      ),
                    ),
                  ),
                  onOpenPrayer: () {},
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();

    final BuildContext scrollContext = tester.element(
      find.byType(CustomScrollView),
    );
    final l10n = AppLocalizations.of(scrollContext);

    expect(find.text(l10n.homePrayerNow), findsNothing);
    expect(find.text(l10n.homeSunriseNow), findsOneWidget);
  });

  testWidgets('content sliver follows hero in scroll order', (tester) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);

    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Builder(
          builder: (context) {
            return CustomScrollView(
              controller: controller,
              slivers: [
                ...HomeNextPrayerTime.buildSlivers(
                  context: context,
                  state: _homeDashboardState(),
                  onOpenPrayer: () {},
                ),
                HomeDashboardContentSliver(
                  child: Container(
                    key: const Key('quick_actions_probe'),
                    height: 72,
                    color: Colors.blue,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();

    final BuildContext scrollContext = tester.element(
      find.byType(CustomScrollView),
    );
    final double heroExtent = HomeNextPrayerTime.expandedLayoutExtent(
      scrollContext,
    );

    final MeMuslimDesignTokens tokens = Theme.of(scrollContext).tokens;

    controller.jumpTo(heroExtent);
    await tester.pump();

    final Offset probeTop = tester.getTopLeft(
      find.byKey(const Key('quick_actions_probe')),
    );
    expect(
      probeTop.dy,
      lessThanOrEqualTo(
        MediaQuery.paddingOf(scrollContext).top + tokens.spaceMedium + 1,
      ),
    );
  });
}

class _HomeNextPrayerTimeHarness extends StatelessWidget {
  const _HomeNextPrayerTimeHarness({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      home: Builder(
        builder: (context) {
          return CustomScrollView(
            controller: controller,
            slivers: [
              ...HomeNextPrayerTime.buildSlivers(
                context: context,
                state: _homeDashboardState(),
                onOpenPrayer: () {},
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 1200),
              ),
            ],
          );
        },
      ),
    );
  }
}

HomeDashboardState _homeDashboardState() => HomeDashboardLoaded(
  HomeDashboard(
    generatedAt: DateTime(2026, 6, 16, 17, 57),
    displayName: 'Muhammad Kamel',
    locationLabel: 'Cairo',
    nextPrayer: HomeNextPrayer(
      type: PrayerType.maghrib,
      time: DateTime.now().add(const Duration(hours: 2, minutes: 1)),
      timeUntil: const Duration(hours: 2, minutes: 1),
    ),
  ),
);
