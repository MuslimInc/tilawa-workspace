import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/tilawa_feedback_screenshot_capture.dart';
import 'package:tilawa/core/telemetry/tilawa_feedback_screenshot_capture_overlay.dart';
import 'package:tilawa/core/telemetry/tilawa_sentry_feedback_form.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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

SentryAttachment _fakeAttachment() {
  return SentryAttachment.fromUint8List(
    _k1x1TransparentPng,
    'screenshot.png',
    contentType: 'image/png',
  );
}

void main() {
  setUp(() {
    TilawaFeedbackScreenshotCapture.resetTestConfiguration();
    TilawaFeedbackScreenshotCapture.readyFrameCount = 1;
    TilawaFeedbackScreenshotCapture.boundaryReadyFrames = 1;
    TilawaFeedbackScreenshotCapture.maxCaptureAttempts = 1;
  });

  tearDown(() {
    TilawaFeedbackScreenshotCapture.resetTestConfiguration();
    TilawaFeedbackScreenshotCaptureOverlayController.resetForTesting();
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    required GlobalKey<NavigatorState> navigatorKey,
    required Widget home,
  }) async {
    await tester.pumpWidget(
      SentryWidget(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openForm(
    WidgetTester tester,
    SentryFlutterOptions options,
  ) async {
    await tester.tap(find.text('open form'));
    await tester.pumpAndSettle();
    expect(find.byType(TilawaSentryFeedbackForm), findsOneWidget);
  }

  group('TilawaFeedbackScreenshotSession', () {
    testWidgets('attachFromCurrentScreen reopens form with screenshot', (
      tester,
    ) async {
      TilawaFeedbackScreenshotCapture.attachmentOverride = () async =>
          _fakeAttachment();

      final GlobalKey<NavigatorState> navigatorKey =
          GlobalKey<NavigatorState>();
      final SentryFlutterOptions options = SentryFlutterOptions()
        ..navigatorKey = navigatorKey;

      await pumpShell(
        tester,
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              backgroundColor: Colors.orange,
              body: Center(
                child: ElevatedButton(
                  onPressed: () => TilawaSentryFeedbackForm.show(
                    context,
                    flutterOptions: options,
                  ),
                  child: const Text('open form'),
                ),
              ),
            );
          },
        ),
      );

      await openForm(tester, options);

      await tester.enterText(
        find.byKey(const ValueKey('tilawa_sentry_feedback_message')),
        'draft while capturing',
      );

      await tester.tap(
        find.byKey(const ValueKey('tilawa_sentry_feedback_capture_screenshot')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TilawaSentryFeedbackForm), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('tilawa_sentry_feedback_screenshot_thumbnail'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TilawaTextField>(
              find.byKey(const ValueKey('tilawa_sentry_feedback_message')),
            )
            .controller
            ?.text,
        'draft while capturing',
      );
    });

    testWidgets('attachFromAnotherScreen shows overlay then reopens form', (
      tester,
    ) async {
      TilawaFeedbackScreenshotCapture.attachmentOverride = () async =>
          _fakeAttachment();

      final GlobalKey<NavigatorState> navigatorKey =
          GlobalKey<NavigatorState>();
      final SentryFlutterOptions options = SentryFlutterOptions()
        ..navigatorKey = navigatorKey;

      await pumpShell(
        tester,
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              backgroundColor: Colors.teal,
              body: Center(
                child: ElevatedButton(
                  onPressed: () => TilawaSentryFeedbackForm.show(
                    context,
                    flutterOptions: options,
                  ),
                  child: const Text('open form'),
                ),
              ),
            );
          },
        ),
      );

      await openForm(tester, options);

      await tester.tap(
        find.byKey(
          const ValueKey(
            'tilawa_sentry_feedback_capture_screenshot_other_screen',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('tilawa_feedback_screenshot_capture_overlay'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Go to the screen you want, then tap Capture.'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('tilawa_feedback_screenshot_capture_now')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TilawaSentryFeedbackForm), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('tilawa_sentry_feedback_screenshot_thumbnail'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('overlay cancel reopens form without screenshot', (
      tester,
    ) async {
      final GlobalKey<NavigatorState> navigatorKey =
          GlobalKey<NavigatorState>();
      final SentryFlutterOptions options = SentryFlutterOptions()
        ..navigatorKey = navigatorKey;

      await pumpShell(
        tester,
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => TilawaSentryFeedbackForm.show(
                    context,
                    flutterOptions: options,
                  ),
                  child: const Text('open form'),
                ),
              ),
            );
          },
        ),
      );

      await openForm(tester, options);

      await tester.tap(
        find.byKey(
          const ValueKey(
            'tilawa_sentry_feedback_capture_screenshot_other_screen',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('tilawa_feedback_screenshot_capture_cancel')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TilawaSentryFeedbackForm), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('tilawa_sentry_feedback_capture_screenshot'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('tilawa_sentry_feedback_screenshot_thumbnail'),
        ),
        findsNothing,
      );
    });

    testWidgets('failed capture shows snackbar and reopens form', (
      tester,
    ) async {
      TilawaFeedbackScreenshotCapture.attachmentOverride = () async => null;

      final GlobalKey<NavigatorState> navigatorKey =
          GlobalKey<NavigatorState>();
      final SentryFlutterOptions options = SentryFlutterOptions()
        ..navigatorKey = navigatorKey;

      await pumpShell(
        tester,
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: ElevatedButton(
                  onPressed: () => TilawaSentryFeedbackForm.show(
                    context,
                    flutterOptions: options,
                  ),
                  child: const Text('open form'),
                ),
              ),
            );
          },
        ),
      );

      await openForm(tester, options);

      await tester.tap(
        find.byKey(
          const ValueKey(
            'tilawa_sentry_feedback_capture_screenshot_other_screen',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('tilawa_feedback_screenshot_capture_now')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TilawaSentryFeedbackForm), findsOneWidget);
      expect(
        find.text(
          "We couldn't capture a screenshot. You can still send your report.",
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('tilawa_sentry_feedback_screenshot_thumbnail'),
        ),
        findsNothing,
      );
    });
  });
}
