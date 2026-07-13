import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/startup_blur_shader_warmup.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/home_hijri_date_formatter.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_content_sliver.dart';
import 'package:tilawa/features/home/presentation/widgets/home_next_prayer_time.dart';
import 'package:tilawa/features/home/presentation/widgets/home_prayer_hero_image_backdrop.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  setUp(StartupBlurShaderWarmup.completeForTest);

  tearDown(StartupBlurShaderWarmup.resetForTest);

  testWidgets('shows shimmer skeleton while dashboard is loading', (
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
                  state: const HomeDashboardLoading(),
                  onOpenPrayer: () {},
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TilawaSkeleton), findsOneWidget);
    expect(find.text('Cairo'), findsNothing);

    final HomeDashboardCard prayerCard = tester.widget<HomeDashboardCard>(
      find.byType(HomeDashboardCard),
    );
    expect(prayerCard.onTap, isNull);
  });

  testWidgets('keeps prayer content visible during pull-to-refresh', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);

    final HomeDashboardLoaded loadedState =
        _homeDashboardState() as HomeDashboardLoaded;

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
                    loadedState.dashboard,
                    isRefreshing: true,
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

    expect(find.byType(TilawaSkeleton), findsNothing);
    expect(find.text('Cairo'), findsOneWidget);
  });

  testWidgets('does not open prayer while dashboard is loading', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);

    var openPrayerTapped = false;

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
                  state: const HomeDashboardLoading(),
                  onOpenPrayer: () => openPrayerTapped = true,
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(HomeDashboardCard));
    await tester.pump();

    expect(openPrayerTapped, isFalse);
  });

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
    expect(find.byIcon(FluentIcons.location_24_regular), findsOneWidget);

    expect(find.byType(HomeDashboardCard), findsOneWidget);
    final HomeDashboardCard prayerCard = tester.widget<HomeDashboardCard>(
      find.byType(HomeDashboardCard).first,
    );
    expect(prayerCard.padding, EdgeInsets.zero);
    expect(find.byType(TilawaCard), findsOneWidget);
    expect(find.byType(HomePrayerHeroImageBackdrop), findsOneWidget);
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
