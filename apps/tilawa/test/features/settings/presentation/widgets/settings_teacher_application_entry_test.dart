import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_teacher_application_entry_tile.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/screen_scope_test_support.dart';

Future<void> _pumpSettingsTile(
  WidgetTester tester, {
  required AppLaunchConfig config,
}) async {
  await resetScopeGetIt();
  getIt.registerSingleton<AppLaunchConfig>(config);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SettingsTeacherApplicationEntryTile()),
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

  testWidgets('settings teacher application tile hidden when flag off', (
    tester,
  ) async {
    await _pumpSettingsTile(
      tester,
      config: const AppLaunchConfig(teacherApplicationEntryEnabled: false),
    );

    expect(find.text('التقديم كمعلّم قرآن'), findsNothing);
  });

  testWidgets('settings teacher application tile hidden when flag on', (
    tester,
  ) async {
    await _pumpSettingsTile(
      tester,
      config: const AppLaunchConfig(
        quranSessionsEnabled: true,
        teacherApplicationEntryEnabled: true,
      ),
    );

    expect(find.text('التقديم كمعلّم قرآن'), findsNothing);
  });
}
