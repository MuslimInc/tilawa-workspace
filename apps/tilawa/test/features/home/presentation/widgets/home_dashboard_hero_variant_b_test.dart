import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/debug/home_hero_variant_debug.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/home_hijri_date_formatter.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_variant_b.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  setUp(() {
    HomeHeroVariantDebug.resetForTests();
  });

  testWidgets('renders compact gold card with canvas context row', (
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
    expect(tester.takeException(), isNull);

    final BuildContext scrollContext = tester.element(
      find.byType(CustomScrollView),
    );
    final l10n = AppLocalizations.of(scrollContext);
    final String hijriDateLine = formatHomeHijriDate(
      date: DateTime.now(),
      languageCode: 'ar',
    );

    expect(find.text(l10n.homeHeroLocationContext), findsOneWidget);
    expect(find.text(hijriDateLine), findsOneWidget);
    expect(find.text(l10n.nextPrayer), findsOneWidget);
    expect(find.byType(SliverPersistentHeader), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ClipPath && widget.clipper is TilawaWaveClipper,
      ),
      findsNothing,
    );
    expect(find.byIcon(Icons.mosque_outlined), findsOneWidget);

    final cardTokens = Theme.of(
      scrollContext,
    ).componentTokens.homeDashboardCard;
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).gradient?.colors.first ==
                cardTokens.gradientStart,
      ),
      findsWidgets,
    );
  });

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

    expect(compactHeight, lessThan(200));
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
    final double collapseExtent = HomeDashboardHeroVariantB.collapseScrollExtent(
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
  });
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
