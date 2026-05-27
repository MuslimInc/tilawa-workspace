import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_footer_bar.dart';
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
  }) async {
    final AppLocalizations l10n = locale.languageCode == 'ar' ? ar : en;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: locale,
        home: Scaffold(
          body: OnboardingFooterBar(
            pageCount: 3,
            currentPage: currentPage,
            backLabel: l10n.previous,
            nextLabel: l10n.next,
            completeLabel: l10n.startJourney,
            onBack: () {},
            onNext: () {},
            onComplete: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('OnboardingFooterBar primary action placement', () {
    testWidgets('places next on the physical right in English', (
      WidgetTester tester,
    ) async {
      await pumpFooterBar(tester, locale: const Locale('en'), currentPage: 1);

      final Rect back = tester.getRect(find.text(en.previous));
      final Rect next = tester.getRect(find.text(en.next));

      expect(next.center.dx, greaterThan(back.center.dx));
    });

    testWidgets('places next on the physical right in Arabic RTL', (
      WidgetTester tester,
    ) async {
      await pumpFooterBar(tester, locale: const Locale('ar'), currentPage: 1);

      final Rect back = tester.getRect(find.text(ar.previous));
      final Rect next = tester.getRect(find.text(ar.next));

      expect(next.center.dx, greaterThan(back.center.dx));
    });

    testWidgets('aligns first-page next to the physical right', (
      WidgetTester tester,
    ) async {
      await pumpFooterBar(tester, locale: const Locale('ar'), currentPage: 0);

      final Rect next = tester.getRect(find.text(ar.next));
      final Rect bounds = tester.getRect(find.byType(TilawaContentBounds));

      expect(next.center.dx, greaterThan(bounds.center.dx));
      expect(next.width, lessThan(bounds.width * 0.75));
    });
  });
}

