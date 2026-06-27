import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/home/presentation/widgets/home_featured_tutor_card.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/screen_scope_test_support.dart';

int _countSemanticsButtons(SemanticsNode node) {
  var count = 0;
  if (node.getSemanticsData().hasFlag(SemanticsFlag.isButton)) {
    count++;
  }
  node.visitChildren((child) {
    count += _countSemanticsButtons(child);
    return true;
  });
  return count;
}

Future<void> _pumpCard(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: HomeFeaturedTutorCard()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async {
    if (getIt.isRegistered<AppLaunchConfig>()) {
      await getIt.unregister<AppLaunchConfig>();
    }
  });

  testWidgets('English home featured card shows Learn Quran not QuranTutor', (
    tester,
  ) async {
    await resetScopeGetIt();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(quranSessionsEnabled: true),
    );

    await _pumpCard(tester);

    expect(find.text('Learn Quran'), findsOneWidget);
    expect(find.text('Experimental'), findsOneWidget);
    expect(find.byType(TilawaExperimentalBadge), findsOneWidget);

    final theme = AppTheme.getLightTheme(
      primaryColor: AppColors.defaultPrimary,
    );
    final badgeText = tester.widget<Text>(find.text('Experimental'));
    expect(badgeText.style?.color, theme.colorScheme.onSurface);

    expect(find.text('Featured'), findsNothing);
    expect(find.text('Start learning'), findsOneWidget);
    expect(find.text('QuranTutor'), findsNothing);
    expect(find.text('Quran Tutor'), findsNothing);
  });

  testWidgets('Arabic home featured card keeps long marketing title', (
    tester,
  ) async {
    await resetScopeGetIt();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(quranSessionsEnabled: true),
    );

    await _pumpCard(tester, locale: const Locale('ar'));

    expect(find.text('تعلّم القرآن مع محفظك'), findsOneWidget);
    expect(find.text('تجريبي'), findsOneWidget);
    expect(find.byType(TilawaExperimentalBadge), findsOneWidget);
    expect(find.text('مميّز'), findsNothing);
    expect(find.text('ابدأ التعلّم'), findsOneWidget);
    expect(find.text('تلاوة'), findsNothing);
  });

  testWidgets(
    'featured tutor card uses one kit interactive surface without ink wells',
    (tester) async {
      await resetScopeGetIt();
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(quranSessionsEnabled: true),
      );

      await _pumpCard(tester);

      expect(find.byType(TilawaInteractiveSurface), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(TilawaButton), findsNothing);
    },
  );

  testWidgets('featured tutor card exposes one button semantics target', (
    tester,
  ) async {
    await resetScopeGetIt();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(quranSessionsEnabled: true),
    );

    await _pumpCard(tester);

    expect(find.byType(TilawaButton), findsNothing);

    final handle = tester.ensureSemantics();
    final root =
        tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
    expect(_countSemanticsButtons(root), 1);

    final cardSemantics = tester.getSemantics(find.text('Learn Quran'));
    expect(cardSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(cardSemantics.hint, 'Start learning');
    handle.dispose();
  });
}
