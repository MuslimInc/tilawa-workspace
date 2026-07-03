import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';
import 'package:tilawa/core/telemetry/sentry_user_feedback.dart';
import 'package:tilawa/core/telemetry/tilawa_feedback_screenshot_capture.dart';
import 'package:tilawa/core/telemetry/tilawa_sentry_feedback_form.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/l10n/generated/app_localizations_en.dart';
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
  tearDown(SentryUserFeedback.resetForTesting);

  setUp(() {
    TilawaFeedbackScreenshotCapture.resetTestConfiguration();
    TilawaFeedbackScreenshotCapture.readyFrameCount = 0;
    TilawaFeedbackScreenshotCapture.boundaryReadyFrames = 0;
    TilawaFeedbackScreenshotCapture.maxCaptureAttempts = 1;
    TilawaFeedbackScreenshotCapture.renderBoundaryOverride = (_) async =>
        _k1x1TransparentPng;
  });

  tearDown(TilawaFeedbackScreenshotCapture.resetTestConfiguration);

  group('SentryUserFeedback.bindFlutterOptions', () {
    test('stores options for localized feedback labels', () {
      final SentryFlutterOptions options = SentryFlutterOptions();
      SentryUserFeedback.bindFlutterOptions(options);

      expect(SentryUserFeedback.boundFlutterOptions, same(options));
    });
  });

  group('SentryUserFeedback.applyLocalizedLabels', () {
    test('no-ops when options are not bound', () {
      expect(
        () => SentryUserFeedback.applyLocalizedLabels(AppLocalizationsEn()),
        returnsNormally,
      );
    });

    test('applies localized labels to bound feedback options', () {
      final SentryFlutterOptions options = SentryFlutterOptions();
      SentryUserFeedback.bindFlutterOptions(options);
      final AppLocalizationsEn l10n = AppLocalizationsEn();

      SentryUserFeedback.applyLocalizedLabels(l10n);

      expect(options.feedback.title, l10n.reportBugTitle);
      expect(options.feedback.submitButtonLabel, l10n.reportBugSubmitButton);
      expect(options.feedback.useSentryUser, isTrue);
      expect(options.feedback.showBranding, isFalse);
    });
  });

  group('SentryUserFeedback.shouldPromptFeedbackForEvent', () {
    test('prompts only for release fatal events on physical devices', () {
      final SentryEvent eligible = SentryEvent(
        level: SentryLevel.fatal,
        tags: <String, String>{
          CrashReportingTagKeys.deviceKind: 'physical',
        },
      );

      final SentryEvent verifyEvent = SentryEvent(
        level: SentryLevel.fatal,
        tags: <String, String>{
          CrashReportingTagKeys.sentryVerify: 'true',
          CrashReportingTagKeys.deviceKind: 'physical',
        },
      );

      final SentryEvent recoverableError = SentryEvent(
        level: SentryLevel.error,
        tags: <String, String>{
          CrashReportingTagKeys.deviceKind: 'physical',
        },
      );

      final SentryEvent emulatorFatal = SentryEvent(
        level: SentryLevel.fatal,
        tags: <String, String>{
          CrashReportingTagKeys.deviceKind: 'emulator',
        },
      );

      final SentryEvent simulatorFatal = SentryEvent(
        level: SentryLevel.fatal,
        tags: <String, String>{
          CrashReportingTagKeys.deviceKind: 'simulator',
        },
      );

      if (kReleaseMode && !kIsWeb) {
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEvent(eligible),
          isTrue,
        );
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEvent(verifyEvent),
          isFalse,
        );
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEvent(recoverableError),
          isFalse,
        );
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEvent(emulatorFatal),
          isFalse,
        );
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEvent(simulatorFatal),
          isFalse,
        );
      } else {
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEvent(eligible),
          isFalse,
        );
      }
    });
  });

  group('SentryUserFeedback.shouldPromptFeedbackForEventInRelease', () {
    test(
      'accepts fatal physical crashes and rejects verify or virtual devices',
      () {
        final SentryEvent eligible = SentryEvent(
          level: SentryLevel.fatal,
          tags: <String, String>{
            CrashReportingTagKeys.deviceKind: 'physical',
          },
        );

        expect(
          SentryUserFeedback.shouldPromptFeedbackForEventInRelease(eligible),
          isTrue,
        );
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEventInRelease(
            SentryEvent(
              level: SentryLevel.fatal,
              tags: <String, String>{
                CrashReportingTagKeys.sentryVerify: 'true',
                CrashReportingTagKeys.deviceKind: 'physical',
              },
            ),
          ),
          isFalse,
        );
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEventInRelease(
            SentryEvent(
              level: SentryLevel.error,
              tags: <String, String>{
                CrashReportingTagKeys.deviceKind: 'physical',
              },
            ),
          ),
          isFalse,
        );
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEventInRelease(
            SentryEvent(
              level: SentryLevel.fatal,
              tags: <String, String>{
                CrashReportingTagKeys.deviceKind: 'emulator',
              },
            ),
          ),
          isFalse,
        );
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEventInRelease(
            SentryEvent(
              level: SentryLevel.fatal,
              tags: <String, String>{
                CrashReportingTagKeys.deviceKind: 'simulator',
              },
            ),
          ),
          isFalse,
        );
      },
    );
  });

  group('SentryUserFeedback.filterBeforeSend', () {
    test('returns null when crash filters drop the event', () async {
      final SentryEvent dropped = SentryEvent(
        throwable: StateError(
          '[firebase_auth/user-token-expired] credential is no longer valid',
        ),
      );

      final SentryEvent? result = await SentryUserFeedback.filterBeforeSend(
        dropped,
        Hint(),
      );

      if (kReleaseMode) {
        expect(result, isNull);
      } else {
        expect(result, isNotNull);
      }
    });

    test('returns filtered event without prompting in debug builds', () async {
      final SentryEvent event = SentryEvent(
        level: SentryLevel.error,
        tags: <String, String>{
          CrashReportingTagKeys.deviceKind: 'physical',
        },
      );

      final SentryEvent? result = await SentryUserFeedback.filterBeforeSend(
        event,
        Hint(),
      );

      expect(result, isNotNull);
    });
  });

  group('SentryUserFeedback.showManualReportBugForm', () {
    test('returns early when Sentry is disabled', () async {
      await SentryUserFeedback.showManualReportBugForm();
    });

    testWidgets('opens feedback form when navigator context exists', (
      tester,
    ) async {
      await ensureSentryInitializedForTests();
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
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: SentryUserFeedback.showManualReportBugForm,
                    child: const Text('open-report'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open-report'));
      await tester.pumpAndSettle();

      expect(find.byType(TilawaSentryFeedbackForm), findsOneWidget);
    });
  });

  group('SentryUserFeedback.presentFeedbackForEventForTesting', () {
    testWidgets('opens feedback form for fatal crash events', (tester) async {
      await ensureSentryInitializedForTests();
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
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        SentryUserFeedback.presentFeedbackForEventForTesting(
                          SentryEvent(level: SentryLevel.fatal),
                        ),
                    child: const Text('open-crash-form'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open-crash-form'));
      await tester.pumpAndSettle();

      expect(find.byType(TilawaSentryFeedbackForm), findsOneWidget);
    });
  });
}
