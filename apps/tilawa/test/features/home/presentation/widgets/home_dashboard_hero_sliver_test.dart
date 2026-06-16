import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_sliver.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
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

    final theme = Theme.of(
      tester.element(find.byType(CustomScrollView)),
    );
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
    expect(appBar.expandedHeight, 276);
    expect(appBar.backgroundColor, heroTokens.gradientBottomEnd);
    expect(appBar.foregroundColor, heroTokens.foregroundColor);

    final BuildContext scrollContext = tester.element(
      find.byType(CustomScrollView),
    );
    final l10n = AppLocalizations.of(scrollContext)!;
    final double collapseExtent = HomeDashboardHeroSliver.collapseScrollExtent(
      scrollContext,
    );

    controller.jumpTo(collapseExtent * 0.8);
    await tester.pump();

    expect(
      find.text(l10n.homeTitle),
      findsOneWidget,
      reason: 'Partial hero collapse must keep an orientation title visible.',
    );
    expect(tester.takeException(), isNull);

    const offsets = <double>[8, 40, 104, 169, 251, 297];
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

  testWidgets('location chip hugs short labels instead of stretching', (
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
    await tester.pumpAndSettle();

    final chipFinder = find.ancestor(
      of: find.text('Abha'),
      matching: find.byWidgetPredicate(
        (widget) {
          if (widget is! Material) {
            return false;
          }
          final shape = widget.shape;
          return shape is RoundedRectangleBorder && shape.side.width > 0;
        },
      ),
    );
    expect(chipFinder, findsOneWidget);

    final RenderBox chipBox = tester.renderObject(chipFinder);
    final RenderBox footerRowBox = tester.renderObject(
      find.ancestor(
        of: chipFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Row &&
              widget.mainAxisAlignment == MainAxisAlignment.spaceBetween,
        ),
      ),
    );

    expect(chipBox.size.width, lessThan(footerRowBox.size.width * 0.45));
    expect(chipBox.size.height, kTilawaMinInteractiveDimension);
  });
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
                onOpenSettings: () {},
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
