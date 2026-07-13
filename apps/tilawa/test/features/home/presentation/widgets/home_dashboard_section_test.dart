import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_more_actions_group.dart';
import 'package:tilawa/features/home/presentation/widgets/home_daily_inspiration_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_actions_section.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('section headers share title-to-content spacing rhythm', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                HomePrimaryActionsSection(),
                HomeMoreActionsGroup(),
                HomeDailyInspirationSection(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomePrimaryActionsSection)),
    );

    double gapAfterHeader({
      required Finder sectionFinder,
      required String title,
      String? subtitle,
    }) {
      final Offset headerBottom = subtitle == null
          ? tester.getBottomLeft(find.text(title))
          : tester.getBottomLeft(find.text(subtitle));
      final Finder content = find.descendant(
        of: sectionFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is HomeDashboardCard ||
              widget.runtimeType.toString() == 'HomePrimaryActionTile',
        ),
      );
      final Offset contentTop = tester.getTopLeft(content.first);
      return contentTop.dy - headerBottom.dy;
    }

    final double primaryGap = gapAfterHeader(
      sectionFinder: find.byType(HomePrimaryActionsSection),
      title: l10n.homeMainActionsTitle,
    );
    final double moreGap = gapAfterHeader(
      sectionFinder: find.byType(HomeMoreActionsGroup),
      title: l10n.moreOptions,
      subtitle: l10n.homeMoreOptionsSubtitle,
    );
    final double inspirationGap = gapAfterHeader(
      sectionFinder: find.byType(HomeDailyInspirationSection),
      title: l10n.homeInspirationTitle,
      subtitle: l10n.homeInspirationSubtitle,
    );

    expect((moreGap - primaryGap).abs(), lessThan(2));
    expect((inspirationGap - moreGap).abs(), lessThan(2));
  });

  testWidgets('secondary text uses home header token at 1.4 text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: HomeMoreActionsGroup(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeMoreActionsGroup)),
    );
    final Color expected = HomeDashboardSection.secondaryTextColor(
      tester.element(find.byType(HomeMoreActionsGroup)),
    );

    final Text subtitle = tester.widget<Text>(
      find.text(l10n.homeHistoryCarouselSubtitle),
    );
    expect(subtitle.style?.color, expected);
  });
}
