import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
    expect(find.byType(ClipPath), findsNothing);
    _expectHeroBottomBorder(scrollContext);
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
    expect(find.byType(ClipPath), findsNothing);
    _expectHeroBottomBorder(scrollContext);
    expect(find.byIcon(FluentIcons.location_24_regular), findsOneWidget);
    _expectCollapsedPremiumChrome(scrollContext);
    _expectCollapsedPremiumPinnedBar(scrollContext);
  });
}

void _expectCollapsedPremiumPinnedBar(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final TilawaCapabilityActionCardTokens cardTokens =
      theme.componentTokens.capabilityActionCard;
  final TilawaDesignTokens tokens = theme.tokens;

  expect(
    find.byWidgetPredicate((widget) {
      if (widget is! DecoratedBox || widget.decoration is! BoxDecoration) {
        return false;
      }
      final BoxDecoration decoration = widget.decoration as BoxDecoration;
      final Gradient? gradient = decoration.gradient;
      if (gradient is! LinearGradient) {
        return false;
      }
      final List<Color> gradientColors = gradient.colors;
      if (gradientColors.length != 2 ||
          gradientColors.first != cardTokens.gradientStart ||
          gradientColors.last != cardTokens.gradientEnd) {
        return false;
      }
      final List<BoxShadow>? shadows = decoration.boxShadow;
      if (shadows == null || shadows.isEmpty) {
        return false;
      }
      final BoxShadow shadow = shadows.first;
      return shadow.blurRadius == tokens.spaceSmall &&
          shadow.offset == tokens.shadowOffsetSmall;
    }),
    findsWidgets,
  );
}

void _expectCollapsedPremiumChrome(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final Color gildingFill = theme.colorScheme.semanticTintBackground(
    TilawaSemanticTint.gilding,
  );
  expect(
    find.byWidgetPredicate((widget) {
      if (widget is! DecoratedBox || widget.decoration is! BoxDecoration) {
        return false;
      }
      return (widget.decoration as BoxDecoration).color == gildingFill;
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
