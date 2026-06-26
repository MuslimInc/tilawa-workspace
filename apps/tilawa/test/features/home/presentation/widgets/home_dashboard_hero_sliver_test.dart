import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/debug/home_hero_variant_debug.dart';
import 'package:tilawa/features/home/domain/home_hijri_date_formatter.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_sliver.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  setUp(() {
    HomeHeroVariantDebug.resetForTests();
    HomeHeroVariantDebug.variant.value = HomeHeroDesignVariant.a;
  });

  testWidgets('collapses on a narrow Android viewport without flex overflow', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);

    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_HomeHeroHarness(controller: controller));
    expect(tester.takeException(), isNull);

    final BuildContext scrollContext = tester.element(
      find.byType(CustomScrollView),
    );
    final l10n = AppLocalizations.of(scrollContext);
    final String hijriDateLine = formatHomeHijriDate(
      date: DateTime.now(),
      languageCode: 'ar',
    );
    expect(find.text(hijriDateLine), findsOneWidget);
    expect(find.text('Cairo'), findsOneWidget);
    expect(find.text(l10n.homeHeroLocationContext), findsNothing);
    expect(find.text(l10n.nextPrayer), findsOneWidget);
    expect(find.byType(ClipPath), findsNothing);
    _expectHeroBottomBorder(scrollContext);
    expect(find.byType(SliverPersistentHeader), findsOneWidget);

    final double collapseExtent = HomeDashboardHeroSliver.collapseScrollExtent(
      scrollContext,
    );
    expect(
      collapseExtent,
      greaterThan(kToolbarHeight),
    );

    controller.jumpTo(collapseExtent * 0.8);
    await tester.pump();

    expect(tester.takeException(), isNull);

    const offsets = <double>[8, 40, 72, 120, 160, 176];
    for (final offset in offsets) {
      controller.jumpTo(
        math.min(offset, controller.position.maxScrollExtent),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Home hero overflowed at scroll offset $offset.',
      );
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('location context row shows city without stretching full width', (
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
      _HomeHeroHarness(
        controller: controller,
        locationLabel: 'Abha',
      ),
    );
    await tester.pump();

    expect(find.text('Abha'), findsOneWidget);

    final RenderBox locationBox = tester.renderObject<RenderBox>(
      find.text('Abha'),
    );
    final RenderBox viewportBox = tester.renderObject(
      find.byType(CustomScrollView),
    );

    expect(locationBox.size.width, lessThan(viewportBox.size.width * 0.75));
  });

  testWidgets('collapsed toolbar keeps location and prayer summary', (
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
      _HomeHeroHarness(
        controller: controller,
        locationLabel: 'Cairo',
      ),
    );
    await tester.pump();

    final BuildContext scrollContext = tester.element(
      find.byType(CustomScrollView),
    );
    final double collapseExtent = HomeDashboardHeroSliver.collapseScrollExtent(
      scrollContext,
    );
    controller.jumpTo(collapseExtent);
    await tester.pump();

    expect(find.text('Cairo'), findsWidgets);
    expect(find.byIcon(FluentIcons.location_24_regular), findsWidgets);
    _expectCollapsedPremiumPinnedBar(scrollContext);
  });
}

void _expectCollapsedPremiumPinnedBar(BuildContext context) {
  final TilawaHomeScreenTokens screenTokens = Theme.of(
    context,
  ).componentTokens.homeScreen;

  expect(
    find.byWidgetPredicate((widget) {
      if (widget is! DecoratedBox || widget.decoration is! BoxDecoration) {
        return false;
      }
      final BoxDecoration decoration = widget.decoration as BoxDecoration;
      return decoration.color == screenTokens.homeCollapsedHeaderFill;
    }),
    findsWidgets,
  );
}

void _expectHeroBottomBorder(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  expect(
    find.byWidgetPredicate((widget) {
      if (widget is! DecoratedBox || widget.decoration is! BoxDecoration) {
        return false;
      }
      final BorderSide? bottom =
          (widget.decoration as BoxDecoration).border?.bottom;
      if (bottom == null) {
        return false;
      }
      return bottom.color == theme.colorScheme.outlineVariant &&
          bottom.width ==
              theme.componentTokens.bottomSheetScaffold.footerTopBorderWidth;
    }),
    findsWidgets,
  );
}

class _HomeHeroHarness extends StatelessWidget {
  const _HomeHeroHarness({
    required this.controller,
    this.locationLabel = 'Cairo',
  });

  final ScrollController controller;
  final String locationLabel;

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
              ...HomeDashboardHeroSliver.buildSlivers(
                context: context,
                state: _homeDashboardState(locationLabel),
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

HomeDashboardState _homeDashboardState(String locationLabel) =>
    HomeDashboardLoaded(
      HomeDashboard(
        generatedAt: DateTime(2026, 6, 16, 17, 57),
        displayName: 'Muhammad Kamel',
        locationLabel: locationLabel,
        nextPrayer: HomeNextPrayer(
          type: PrayerType.maghrib,
          time: DateTime.now().add(const Duration(hours: 2, minutes: 1)),
          timeUntil: const Duration(hours: 2, minutes: 1),
        ),
      ),
    );
