import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/src/presentation/theme/quran_sessions_theme_scope.dart';
import 'package:quran_sessions/src/presentation/widgets/quran_sessions_page_header.dart';
import 'package:quran_sessions/src/presentation/widgets/quran_sessions_scaffold.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/widget_pump.dart';

Finder _appBarTitle(String text) {
  return find.descendant(
    of: find.byType(TilawaAppBar),
    matching: find.text(text),
  );
}

Future<void> _pumpShell(
  WidgetTester tester,
  Widget child, {
  Locale? locale,
  TextDirection? textDirection,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      locale: locale,
      localizationsDelegates: QuranSessionsLocalizations.localizationsDelegates,
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      home: QuranSessionsThemeScope(
        child: textDirection == null
            ? child
            : Directionality(textDirection: textDirection, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Quran Sessions app bar consistency', () {
    testWidgets('My Sessions uses short TilawaAppBar title in Arabic RTL', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        QuranSessionsScaffold(
          title: 'جلساتي',
          body: const SizedBox.shrink(),
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
      );

      expect(_appBarTitle('جلساتي'), findsOneWidget);
      expect(find.byType(TilawaAppBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Teacher profile AppBar title fits at 360dp English LTR', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        QuranSessionsScaffold(
          title: 'Teacher profile',
          body: const SizedBox.shrink(),
        ),
      );

      expect(_appBarTitle('Teacher profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Booking AppBar uses compact localized title', (tester) async {
      await _pumpShell(
        tester,
        QuranSessionsScaffold(
          title: 'Book a session',
          body: const SizedBox.shrink(),
        ),
      );

      expect(_appBarTitle('Book a session'), findsOneWidget);
      expect(find.text('Learn Quran with your teacher'), findsNothing);
    });

    testWidgets('Teachers list keeps long title out of AppBar in Arabic', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QuranSessionsScaffold(
          title: 'المحفظون',
          body: const QuranSessionsPageHeader(
            title: 'تعلّم القرآن مع محفظك',
            subtitle: 'اختر المحفظ المناسب وابدأ رحلتك في تحسين التلاوة',
          ),
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );

      expect(_appBarTitle('المحفظون'), findsOneWidget);
      expect(find.text('تعلّم القرآن مع محفظك'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TilawaAppBar),
          matching: find.text('تعلّم القرآن مع محفظك'),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Wallet AppBar uses short title key', (tester) async {
      await _pumpShell(
        tester,
        QuranSessionsScaffold(
          title: 'Wallet',
          body: const SizedBox.shrink(),
        ),
      );

      expect(_appBarTitle('Wallet'), findsOneWidget);
      expect(_appBarTitle('My wallet'), findsNothing);
    });

    testWidgets('Arabic feature home AppBar does not show misleading تلاوة', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QuranSessionsScaffold(
          title: 'المحفظون',
          body: const QuranSessionsPageHeader(
            title: 'تعلّم القرآن مع محفظك',
            subtitle: 'اختر المحفظ المناسب وابدأ رحلتك في تحسين التلاوة',
          ),
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );

      expect(_appBarTitle('المحفظون'), findsOneWidget);
      expect(_appBarTitle('تلاوة'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('English Tutors AppBar title fits at 360dp without overflow', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QuranSessionsScaffold(
          title: 'Tutors',
          actions: [
            QuranSessionsAppBarLink(label: 'My sessions', onPressed: () {}),
          ],
          body: const SizedBox.shrink(),
        ),
        surfaceSize: const Size(360, 800),
      );

      expect(_appBarTitle('Tutors'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic المحفظون AppBar title fits at 360dp without overflow', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QuranSessionsScaffold(
          title: 'المحفظون',
          actions: [
            QuranSessionsAppBarLink(label: 'جلساتي', onPressed: () {}),
          ],
          body: const SizedBox.shrink(),
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );

      expect(_appBarTitle('المحفظون'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppBar title matches global TilawaAppBar chrome '
        '(titleLarge w700)', (tester) async {
      await _pumpShell(
        tester,
        QuranSessionsScaffold(
          title: 'Tutors',
          body: const SizedBox.shrink(),
        ),
      );

      final title = tester.widget<Text>(
        find.descendant(
          of: find.byType(TilawaAppBar),
          matching: find.text('Tutors'),
        ),
      );
      final theme = Theme.of(
        tester.element(find.byType(QuranSessionsScaffold)),
      );
      // The feature must delegate to global chrome, not impose a
      // downgraded navigational title (was titleMedium / w600).
      final expected = TilawaAppBarChrome.titleTextStyle(theme);

      expect(title.style?.fontSize, expected?.fontSize);
      expect(title.style?.fontSize, theme.textTheme.titleLarge?.fontSize);
      expect(title.style?.fontWeight, FontWeight.w700);
      expect(title.style?.fontWeight, isNot(FontWeight.w600));
    });
  });
}
