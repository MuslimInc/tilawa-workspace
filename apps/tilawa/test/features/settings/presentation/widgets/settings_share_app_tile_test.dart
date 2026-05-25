import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/settings/presentation/formatters/settings_share_text_formatter.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/entities/app_info.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

const AppInfo _testAppInfo = AppInfo(
  version: '1.0.0',
  buildNumber: '1',
  appName: 'Tilawa',
  packageName: 'com.tilawa.app',
);

Widget _buildHarness({
  required Future<void> Function() onShareRequested,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.getLightTheme(
      primaryColor: AppColors.primaryCoral,
      useGoogleFontsOverride: false,
    ),
    home: Scaffold(
      body: SettingsShareAppTile(
        onShareRequested: onShareRequested,
      ),
    ),
  );
}

void main() {
  testWidgets('shows localized share row', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildHarness(
        onShareRequested: () async {},
      ),
    );

    expect(find.text('Share Tilawa'), findsOneWidget);
  });

  testWidgets('tap shares the Play Store link', (WidgetTester tester) async {
    String? sharedText;
    final l10n = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(
      _buildHarness(
        onShareRequested: () async {
          sharedText = buildSettingsShareAppText(
            l10n,
            appInfo: _testAppInfo,
            platform: TargetPlatform.android,
          );
        },
      ),
    );

    await tester.tap(find.text('Share Tilawa'));
    await tester.pumpAndSettle();

    expect(
      sharedText,
      'Check out Tilawa:\n'
      'https://play.google.com/store/apps/details?id=com.tilawa.app',
    );
  });

  test('buildSettingsShareAppText uses App Store link on iOS', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    final shareText = buildSettingsShareAppText(
      l10n,
      appInfo: _testAppInfo,
      platform: TargetPlatform.iOS,
      appStoreId: '123456789',
    );

    expect(
      shareText,
      'Check out Tilawa:\nhttps://apps.apple.com/app/id123456789',
    );
  });

  testWidgets('shows loading state and ignores repeat taps', (
    WidgetTester tester,
  ) async {
    final completer = Completer<void>();
    var shareCalls = 0;

    await tester.pumpWidget(
      _buildHarness(
        onShareRequested: () {
          shareCalls++;
          return completer.future;
        },
      ),
    );

    await tester.tap(find.text('Share Tilawa'));
    await tester.pump();

    expect(find.byType(TilawaLoadingIndicator), findsOneWidget);

    await tester.tap(find.text('Share Tilawa'));
    await tester.pump();

    expect(shareCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();
  });
}
