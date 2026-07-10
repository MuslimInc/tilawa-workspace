import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/home/presentation/widgets/home_featured_tutor_card.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/screen_scope_test_support.dart';

Future<void> _pumpHomeCard(
  WidgetTester tester, {
  required AppLaunchConfig config,
  Locale locale = const Locale('ar'),
}) async {
  await resetScopeGetIt();
  getIt.registerSingleton<AppLaunchConfig>(config);

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

  testWidgets('hides student learn card when student feature disabled', (
    tester,
  ) async {
    await _pumpHomeCard(
      tester,
      config: const AppLaunchConfig(),
    );

    expect(find.text('Learn Quran'), findsNothing);
    expect(find.text('تعلّم القرآن مع محفظك'), findsNothing);
  });

  testWidgets('never shows teacher application card even when flag enabled', (
    tester,
  ) async {
    await _pumpHomeCard(
      tester,
      config: const AppLaunchConfig(),
    );

    expect(find.text('التقديم كمعلّم قرآن'), findsNothing);
    expect(find.text('فتح نموذج التقديم'), findsNothing);
    expect(find.text('تعلّم القرآن مع محفظك'), findsOneWidget);
  });
}
