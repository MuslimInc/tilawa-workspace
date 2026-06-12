import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_footer_bar.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_page_indicator.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations ar;

  setUpAll(() {
    en = lookupAppLocalizations(const Locale('en'));
    ar = lookupAppLocalizations(const Locale('ar'));
  });

  Future<void> pumpFooterBar(
    WidgetTester tester, {
    required Locale locale,
    required int currentPage,
    bool useOnboardingScreenSplit = false,
  }) async {
    final AppLocalizations l10n = locale.languageCode == 'ar' ? ar : en;
    final OnboardingFooterBar footer = OnboardingFooterBar(
      pageCount: 3,
      currentPage: currentPage,
      backLabel: l10n.previous,
      nextLabel: l10n.next,
      completeLabel: l10n.startJourney,
      onBack: () {},
      onNext: () {},
      onComplete: () {},
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: locale,
        home: Scaffold(
          body: useOnboardingScreenSplit
              ? TilawaThumbReachLayout(
                  content: const SizedBox.shrink(),
                  actions: footer,
                )
              : footer,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder primaryButtonFinder(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(TextButton),
    );
  }

  Finder contentColumnFinder() {
    return find.descendant(
      of: find.byType(OnboardingFooterBar),
      matching: find.byType(Column),
    );
  }

  group('OnboardingFooterBar thumb-reach placement', () {
    testWidgets('uses a full-width primary action in English', (
      WidgetTester tester,
    ) async {
      await pumpFooterBar(tester, locale: const Locale('en'), currentPage: 0);

      final Rect primary = tester.getRect(primaryButtonFinder(en.next));
      final Rect content = tester.getRect(contentColumnFinder());

      expect(primary.width, content.width);
    });

    testWidgets('uses a full-width primary action in Arabic RTL', (
      WidgetTester tester,
    ) async {
      await pumpFooterBar(tester, locale: const Locale('ar'), currentPage: 0);

      final Rect primary = tester.getRect(primaryButtonFinder(ar.next));
      final Rect content = tester.getRect(contentColumnFinder());

      expect(primary.width, content.width);
    });

    testWidgets('places primary above the back action in the lower stack', (
      WidgetTester tester,
    ) async {
      await pumpFooterBar(tester, locale: const Locale('en'), currentPage: 1);

      final Rect back = tester.getRect(primaryButtonFinder(en.previous));
      final Rect primary = tester.getRect(primaryButtonFinder(en.next));

      expect(primary.bottom, lessThan(back.top));
      expect(primary.center.dy, lessThan(back.center.dy));
    });

    testWidgets('uses a full-width back action when previous page is available', (
      WidgetTester tester,
    ) async {
      await pumpFooterBar(tester, locale: const Locale('ar'), currentPage: 1);

      final Rect back = tester.getRect(primaryButtonFinder(ar.previous));
      final Rect content = tester.getRect(contentColumnFinder());

      expect(back.width, content.width);
    });

    testWidgets('starts the action band near 72% of the screen height', (
      WidgetTester tester,
    ) async {
      await pumpFooterBar(
        tester,
        locale: const Locale('en'),
        currentPage: 0,
        useOnboardingScreenSplit: true,
      );

      final Rect screen = tester.getRect(find.byType(Scaffold));
      final Rect indicator = tester.getRect(
        find.byType(OnboardingPageIndicator),
      );

      final double bandStart =
          screen.height * TilawaThumbReachLayout.actionBandStartFraction();

      expect(indicator.top, greaterThanOrEqualTo(bandStart - 1));
      expect(indicator.top, lessThan(bandStart + screen.height * 0.08));
    });
  });
}
