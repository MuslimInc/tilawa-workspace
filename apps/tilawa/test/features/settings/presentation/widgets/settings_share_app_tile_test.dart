import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/data/config/app_review_store_config.dart';
import 'package:tilawa/features/settings/presentation/formatters/settings_share_text_formatter.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

const String _iosStoreUrl =
    'https://apps.apple.com/app/id${AppReviewStoreConfig.kProductionAppStoreId}';
const String _androidStoreUrl =
    'https://play.google.com/store/apps/details?id=${AppReviewStoreConfig.kProductionAndroidPackageId}';
const String _expectedShareText =
    'Check out MeMuslim:\n'
    'iOS: $_iosStoreUrl\n'
    'Android: $_androidStoreUrl';

Widget _buildHarness({
  required Future<void> Function() onShareRequested,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.getLightTheme(
      primaryColor: AppColors.primaryCoral,
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

    expect(find.text('Share MeMuslim'), findsOneWidget);
  });

  testWidgets('tap shares both production store links', (
    WidgetTester tester,
  ) async {
    String? sharedText;
    final l10n = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(
      _buildHarness(
        onShareRequested: () async {
          sharedText = buildSettingsShareAppText(l10n);
        },
      ),
    );

    await tester.tap(find.text('Share MeMuslim'));
    await tester.pumpAndSettle();

    expect(sharedText, _expectedShareText);
  });

  group('settingsShareStoreUrls', () {
    test('returns App Store link without country segment', () {
      final urls = settingsShareStoreUrls();

      expect(urls.iosStoreUrl, _iosStoreUrl);
      expect(urls.iosStoreUrl, isNot(contains('/us/')));
    });

    test('returns production Play Store link', () {
      expect(settingsShareStoreUrls().androidStoreUrl, _androidStoreUrl);
    });
  });

  test('buildSettingsShareAppText includes both production store links', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    final shareText = buildSettingsShareAppText(l10n);

    expect(shareText, _expectedShareText);
    expect(shareText, contains(_iosStoreUrl));
    expect(shareText, contains(_androidStoreUrl));
    expect(shareText, isNot(contains('.dev')));
    expect(shareText, isNot(contains('.staging')));
  });

  test(
    'buildSettingsShareAppText ignores flavor package overrides by default',
    () {
      final l10n = lookupAppLocalizations(const Locale('en'));

      // Call site no longer passes AppInfo; production IDs are always used.
      final shareText = buildSettingsShareAppText(l10n);

      expect(
        shareText,
        contains('id=${AppReviewStoreConfig.kProductionAndroidPackageId}'),
      );
      expect(
        shareText,
        isNot(contains('com.tilawa.app.dev')),
      );
    },
  );

  test('buildSettingsShareAppText Arabic includes both store links', () {
    final l10n = lookupAppLocalizations(const Locale('ar'));

    final shareText = buildSettingsShareAppText(l10n);

    expect(
      shareText,
      'جرّب MeMuslim:\n'
      'iOS: $_iosStoreUrl\n'
      'Android: $_androidStoreUrl',
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

    await tester.tap(find.text('Share MeMuslim'));
    await tester.pump();

    expect(find.byType(TilawaLoadingIndicator), findsOneWidget);

    await tester.tap(find.text('Share MeMuslim'));
    await tester.pump();

    expect(shareCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();
  });
}
