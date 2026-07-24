import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/telemetry/sentry_report_bug_tile.dart';
import 'package:tilawa/core/telemetry/sentry_user_feedback.dart';
import 'package:tilawa/core/telemetry/tilawa_feedback_screenshot_capture.dart';
import 'package:tilawa/core/telemetry/tilawa_sentry_feedback_form.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'sentry_test_support.dart';

final Uint8List _k1x1TransparentPng = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x62,
  0x00,
  0x00,
  0x00,
  0x02,
  0x00,
  0x01,
  0xE5,
  0x27,
  0xDE,
  0xFC,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  setUp(() async {
    await getIt.reset();
    TilawaFeedbackScreenshotCapture.resetTestConfiguration();
    TilawaFeedbackScreenshotCapture.readyFrameCount = 0;
    TilawaFeedbackScreenshotCapture.boundaryReadyFrames = 0;
    TilawaFeedbackScreenshotCapture.maxCaptureAttempts = 1;
    TilawaFeedbackScreenshotCapture.renderBoundaryOverride = (_) async =>
        _k1x1TransparentPng;
  });

  tearDown(() async {
    TilawaFeedbackScreenshotCapture.resetTestConfiguration();
    await getIt.reset();
  });

  Future<void> pumpTile(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SentryReportBugTile()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hides when Sentry is disabled', (tester) async {
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(reportBugEnabled: true),
    );
    await pumpTile(tester);
    expect(find.byType(SentryReportBugTile), findsOneWidget);
    expect(find.byType(TilawaSettingsTile), findsNothing);
  });

  testWidgets('hides when report bug launch flag is off', (tester) async {
    await ensureSentryInitializedForTests();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(reportBugEnabled: false),
    );
    await pumpTile(tester);

    expect(find.byType(TilawaSettingsTile), findsNothing);
  });

  testWidgets('shows settings tile when Sentry and flag are enabled', (
    tester,
  ) async {
    await ensureSentryInitializedForTests();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(reportBugEnabled: true),
    );
    await pumpTile(tester);

    expect(find.byType(TilawaSettingsTile), findsOneWidget);
    expect(find.text('Report a bug'), findsOneWidget);
  });

  testWidgets('opens feedback form when tile is tapped', (tester) async {
    await ensureSentryInitializedForTests();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(reportBugEnabled: true),
    );
    final SentryFlutterOptions options = SentryFlutterOptions();
    SentryUserFeedback.bindFlutterOptions(options);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            SentryUserFeedback.applyLocalizedLabels(
              AppLocalizations.of(context),
            );
            return const Scaffold(body: SentryReportBugTile());
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report a bug'));
    await tester.pumpAndSettle();

    expect(find.byType(TilawaSentryFeedbackForm), findsOneWidget);
  });
}
