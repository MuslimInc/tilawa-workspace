import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/startup_blur_shader_warmup.dart';
import 'package:tilawa/features/home/debug/home_hero_variant_debug.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/home_hijri_date_formatter.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_content_sliver.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_variant_b.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_collapsed_bar.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  setUp(() {
    HomeHeroVariantDebug.resetForTests();
    StartupBlurShaderWarmup.completeForTest();
  });

  tearDown(StartupBlurShaderWarmup.resetForTest);

  testWidgets(
    'renders sliver hero with elevated prayer card on neutral canvas',
    (
      tester,
    ) async {
      final view = tester.view;
      view.devicePixelRatio = 1;
      view.physicalSize = const Size(360, 640);
      addTearDown(view.resetDevicePixelRatio);
      addTearDown(view.resetPhysicalSize);

      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_VariantBHarness(controller: controller));
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
      expect(find.byType(SliverPersistentHeader), findsOneWidget);
      expect(find.byIcon(Icons.mosque_outlined), findsNothing);
      expect(find.byIcon(FluentIcons.location_24_regular), findsOneWidget);

      final screenTokens = Theme.of(
        scrollContext,
      ).componentTokens.homeScreen;
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  screenTokens.homeContentSheetSurface &&
              (widget.decoration as BoxDecoration).boxShadow?.isNotEmpty ==
                  true,
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  screenTokens.homePrayerHeroBackground,
        ),
        findsNothing,
      );
    },
  );

  testWidgets('compact hero height is shorter than legacy B dimensions', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);

    await tester.pumpWidget(_VariantBHarness(controller: ScrollController()));

    final BuildContext scrollContext = tester.element(
      find.byType(CustomScrollView),
    );
    final double compactHeight = HomeDashboardHeroVariantB.collapseScrollExtent(
      scrollContext,
    );

    expect(compactHeight, lessThan(225));
  });

  testWidgets('collapses without overflow on narrow viewport', (tester) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);

    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_VariantBHarness(controller: controller));
    await tester.pump();

    final BuildContext scrollContext = tester.element(
      find.byType(CustomScrollView),
    );
    final double collapseExtent =
        HomeDashboardHeroVariantB.collapseScrollExtent(
          scrollContext,
        );

    controller.jumpTo(collapseExtent);
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
        reason: 'Variant B hero overflowed at scroll offset $offset.',
      );
    }

    controller.jumpTo(collapseExtent);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(FluentIcons.location_24_regular), findsWidgets);
    _expectCollapsedCanvasBar(tester);
  });

  testWidgets('content sliver keeps quick actions below pinned header', (
    tester,
  ) async {
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
                ...HomeDashboardHeroVariantB.buildSlivers(
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
    final double collapseExtent =
        HomeDashboardHeroVariantB.collapseScrollExtent(scrollContext);
    final double pinnedTop = HomeDashboardHeroVariantB.pinnedHeaderExtent(
      scrollContext,
    );

    controller.jumpTo(collapseExtent);
    await tester.pump();

    final Offset probeTop = tester.getTopLeft(
      find.byKey(const Key('quick_actions_probe')),
    );
    expect(probeTop.dy, greaterThanOrEqualTo(pinnedTop - 1));
  });

  testWidgets('collapsed bar is opaque when fully pinned', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_VariantBHarness(controller: controller));
    await tester.pump();

    final BuildContext scrollContext = tester.element(
      find.byType(CustomScrollView),
    );
    controller.jumpTo(
      HomeDashboardHeroVariantB.collapseScrollExtent(scrollContext),
    );
    await tester.pump();

    expect(
      HomeHeroCollapsedBar.surfaceAlpha(1),
      greaterThanOrEqualTo(0.97),
    );
    _expectCollapsedCanvasBar(tester);
  });
}

void _expectCollapsedCanvasBar(WidgetTester tester) {
  expect(find.byType(HomeHeroCollapsedBar), findsOneWidget);
  final HomeHeroCollapsedBar bar = tester.widget<HomeHeroCollapsedBar>(
    find.byType(HomeHeroCollapsedBar),
  );
  expect(bar.reveal, greaterThan(0.85));
  expect(
    HomeHeroCollapsedBar.surfaceAlpha(bar.reveal),
    greaterThanOrEqualTo(0.97),
  );
}

class _VariantBHarness extends StatelessWidget {
  const _VariantBHarness({required this.controller});

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
              ...HomeDashboardHeroVariantB.buildSlivers(
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
