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

    double gapAfterTitle(String title, Finder sectionFinder) {
      final Offset titleBottom = tester.getBottomLeft(find.text(title));
      final Finder content = find.descendant(
        of: sectionFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is HomeDashboardCard ||
              widget.runtimeType.toString() == 'HomePrimaryActionTile',
        ),
      );
      final Offset contentTop = tester.getTopLeft(content.first);
      return contentTop.dy - titleBottom.dy;
    }

    final double primaryGap = gapAfterTitle(
      l10n.homeMainActionsTitle,
      find.byType(HomePrimaryActionsSection),
    );
    final double moreGap = gapAfterTitle(
      l10n.moreOptions,
      find.byType(HomeMoreActionsGroup),
    );
    final double inspirationGap = gapAfterTitle(
      l10n.homeInspirationTitle,
      find.byType(HomeDailyInspirationSection),
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
