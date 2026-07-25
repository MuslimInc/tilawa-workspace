import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/settings/presentation/widgets/clear_app_preferences_debug_tile.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('ClearAppPreferencesDebugTile clears prefs then restarts', (
    WidgetTester tester,
  ) async {
    var cleared = false;
    var restarted = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.getLightTheme(primaryColor: const Color(0xFFE05A33)),
        home: Scaffold(
          body: ClearAppPreferencesDebugTile(
            debugMode: true,
            isLast: true,
            clearPreferences: () async {
              cleared = true;
            },
            onRestartJourney: () {
              restarted = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Clear app preferences'), findsOneWidget);

    await tester.tap(find.text('Clear app preferences'));
    await tester.pumpAndSettle();

    expect(find.text('Clear app preferences?'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(cleared, isTrue);
    expect(restarted, isTrue);
  });

  testWidgets('ClearAppPreferencesDebugTile hides when debugMode is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: const Color(0xFFE05A33)),
        home: const Scaffold(
          body: ClearAppPreferencesDebugTile(debugMode: false),
        ),
      ),
    );

    expect(find.text('Clear app preferences'), findsNothing);
  });
}
