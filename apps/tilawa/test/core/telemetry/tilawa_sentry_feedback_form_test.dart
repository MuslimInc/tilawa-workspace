import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/sentry_user_feedback.dart';
import 'package:tilawa/core/telemetry/tilawa_feedback_screenshot_capture.dart';
import 'package:tilawa/core/telemetry/tilawa_sentry_feedback_form.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _FakeFeedbackHub implements Hub {
  _FakeFeedbackHub({SentryFlutterOptions? options, this.sentryUser})
    : _options = options ?? SentryFlutterOptions();

  final SentryFlutterOptions _options;
  final SentryUser? sentryUser;
  int captureFeedbackCalls = 0;

  @override
  void configureScope(void Function(Scope scope) callback) {
    final Scope scope = Scope(_options);
    if (sentryUser != null) {
      scope.setUser(sentryUser);
    }
    callback(scope);
  }

  @override
  Future<SentryId> captureFeedback(
    SentryFeedback feedback, {
    Hint? hint,
    ScopeCallback? withScope,
  }) async {
    captureFeedbackCalls++;
    return SentryId.newId();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

  Future<void> pumpForm(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    SentryAttachment? screenshot,
  }) async {
    final SentryFlutterOptions options = SentryFlutterOptions();
    SentryUserFeedback.bindFlutterOptions(options);

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            SentryUserFeedback.applyLocalizedLabels(
              AppLocalizations.of(context),
            );
            return Scaffold(
              body: TilawaSentryFeedbackForm(
                flutterOptions: options,
                screenshot: screenshot,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('TilawaSentryFeedbackForm', () {
    testWidgets('uses kit text fields and sticky footer actions', (
      tester,
    ) async {
      await pumpForm(tester);

      expect(find.byType(TilawaTextField), findsNWidgets(3));
      expect(find.byType(TilawaBottomActionArea), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tilawa_sentry_feedback_submit')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('tilawa_sentry_feedback_cancel')),
        findsOneWidget,
      );
      expect(find.text('Send report'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('renders outlined inputs from kit input style', (tester) async {
      await pumpForm(tester);

      final Finder firstField = find.byKey(
        const ValueKey('tilawa_sentry_feedback_name'),
      );
      final InputDecorator decorator = tester.widget<InputDecorator>(
        find.descendant(of: firstField, matching: find.byType(InputDecorator)),
      );

      expect(decorator.decoration.filled, isTrue);
      expect(decorator.decoration.enabledBorder, isA<OutlineInputBorder>());
    });

    testWidgets('shows validation when message is empty', (tester) async {
      await pumpForm(tester);

      await tester.tap(
        find.byKey(const ValueKey('tilawa_sentry_feedback_submit')),
      );
      await tester.pumpAndSettle();

      expect(find.text('This field is required.'), findsOneWidget);
    });

    testWidgets('cancel closes the form route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              final SentryFlutterOptions options = SentryFlutterOptions();
              SentryUserFeedback.bindFlutterOptions(options);
              SentryUserFeedback.applyLocalizedLabels(
                AppLocalizations.of(context),
              );

              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => TilawaSentryFeedbackForm.show(
                      context,
                      flutterOptions: options,
                    ),
                    child: const Text('open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(TilawaSentryFeedbackForm), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('tilawa_sentry_feedback_cancel')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TilawaSentryFeedbackForm), findsNothing);
    });

    testWidgets('lays out in RTL with localized labels', (tester) async {
      await pumpForm(tester, locale: const Locale('ar'));

      expect(find.text('إرسال البلاغ'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(
        tester
            .widget<Directionality>(find.byType(Directionality).first)
            .textDirection,
        TextDirection.rtl,
      );
    });

    testWidgets('shows attach from another screen action', (tester) async {
      await pumpForm(tester);

      expect(
        find.byKey(
          const ValueKey(
            'tilawa_sentry_feedback_capture_screenshot_other_screen',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Attach from another screen'), findsOneWidget);
    });

    testWidgets('opens and closes full-screen screenshot preview', (
      tester,
    ) async {
      final SentryAttachment screenshot = SentryAttachment.fromUint8List(
        _k1x1TransparentPng,
        'screenshot.png',
        contentType: 'image/png',
      );

      await pumpForm(tester, screenshot: screenshot);

      expect(
        find.byKey(
          const ValueKey('tilawa_sentry_feedback_screenshot_thumbnail'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('tilawa_sentry_feedback_screenshot_thumbnail'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TilawaSentryScreenshotPreview), findsOneWidget);
      expect(find.text('Screenshot'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('tilawa_sentry_feedback_screenshot_preview_image'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(TilawaSentryScreenshotPreview),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TilawaSentryScreenshotPreview), findsNothing);
      expect(find.byType(TilawaSentryFeedbackForm), findsOneWidget);
    });

    testWidgets('restores draft field values from constructor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              final SentryFlutterOptions options = SentryFlutterOptions();
              SentryUserFeedback.bindFlutterOptions(options);
              SentryUserFeedback.applyLocalizedLabels(
                AppLocalizations.of(context),
              );

              return Scaffold(
                body: TilawaSentryFeedbackForm(
                  flutterOptions: options,
                  initialName: 'Tilawa User',
                  initialEmail: 'user@example.com',
                  initialMessage: 'draft message',
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TilawaTextField>(
              find.byKey(const ValueKey('tilawa_sentry_feedback_name')),
            )
            .controller
            ?.text,
        'Tilawa User',
      );
      expect(
        tester
            .widget<TilawaTextField>(
              find.byKey(const ValueKey('tilawa_sentry_feedback_email')),
            )
            .controller
            ?.text,
        'user@example.com',
      );
      expect(
        tester
            .widget<TilawaTextField>(
              find.byKey(const ValueKey('tilawa_sentry_feedback_message')),
            )
            .controller
            ?.text,
        'draft message',
      );
    });

    testWidgets('submits valid feedback through injected hub', (tester) async {
      final SentryFlutterOptions options = SentryFlutterOptions();
      final _FakeFeedbackHub hub = _FakeFeedbackHub(options: options);
      SentryUserFeedback.bindFlutterOptions(options);

      await tester.pumpWidget(
        MaterialApp(
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
                    onPressed: () => TilawaSentryFeedbackForm.show(
                      context,
                      hub: hub,
                      flutterOptions: options,
                    ),
                    child: const Text('open-form'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-form'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('tilawa_sentry_feedback_message')),
        'Something broke on the home screen.',
      );
      await tester.tap(
        find.byKey(const ValueKey('tilawa_sentry_feedback_submit')),
      );
      await tester.pumpAndSettle();

      expect(hub.captureFeedbackCalls, 1);
      expect(find.byType(TilawaSentryFeedbackForm), findsNothing);
    });

    testWidgets('remove screenshot clears preview controls', (tester) async {
      final SentryAttachment screenshot = SentryAttachment.fromUint8List(
        _k1x1TransparentPng,
        'screenshot.png',
        contentType: 'image/png',
      );

      await pumpForm(tester, screenshot: screenshot);
      expect(
        find.byKey(
          const ValueKey('tilawa_sentry_feedback_remove_screenshot'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('tilawa_sentry_feedback_remove_screenshot')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('tilawa_sentry_feedback_remove_screenshot'),
        ),
        findsNothing,
      );
    });

    testWidgets('prefills name and email from sentry user scope', (
      tester,
    ) async {
      final SentryFlutterOptions options = SentryFlutterOptions();
      final _FakeFeedbackHub hub = _FakeFeedbackHub(
        options: options,
        sentryUser: SentryUser(name: 'Tilawa User', email: 'user@example.com'),
      );
      SentryUserFeedback.bindFlutterOptions(options);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              SentryUserFeedback.applyLocalizedLabels(
                AppLocalizations.of(context),
              );
              return Scaffold(
                body: TilawaSentryFeedbackForm(
                  hub: hub,
                  flutterOptions: options,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TilawaTextField>(
              find.byKey(const ValueKey('tilawa_sentry_feedback_name')),
            )
            .controller
            ?.text,
        'Tilawa User',
      );
      expect(
        tester
            .widget<TilawaTextField>(
              find.byKey(const ValueKey('tilawa_sentry_feedback_email')),
            )
            .controller
            ?.text,
        'user@example.com',
      );
    });

    testWidgets('shows success snackbar after submit when enabled', (
      tester,
    ) async {
      final SentryFlutterOptions options = SentryFlutterOptions()
        ..feedback.showSuccessMessage = true;
      final _FakeFeedbackHub hub = _FakeFeedbackHub(options: options);
      SentryUserFeedback.bindFlutterOptions(options);

      await tester.pumpWidget(
        MaterialApp(
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
                    onPressed: () => TilawaSentryFeedbackForm.show(
                      context,
                      hub: hub,
                      flutterOptions: options,
                    ),
                    child: const Text('open-form'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-form'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('tilawa_sentry_feedback_message')),
        'Captured a layout glitch.',
      );
      await tester.tap(
        find.byKey(const ValueKey('tilawa_sentry_feedback_submit')),
      );
      await tester.pumpAndSettle();

      expect(hub.captureFeedbackCalls, 1);
      expect(find.text('Thank you for your report.'), findsOneWidget);
      expect(find.byType(TilawaSentryFeedbackForm), findsNothing);
    });

    testWidgets('submits feedback with screenshot attachment', (tester) async {
      final SentryFlutterOptions options = SentryFlutterOptions();
      final _FakeFeedbackHub hub = _FakeFeedbackHub(options: options);
      SentryUserFeedback.bindFlutterOptions(options);
      final SentryAttachment screenshot = SentryAttachment.fromUint8List(
        _k1x1TransparentPng,
        'screenshot.png',
        contentType: 'image/png',
      );

      await tester.pumpWidget(
        MaterialApp(
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
                    onPressed: () => TilawaSentryFeedbackForm.show(
                      context,
                      hub: hub,
                      flutterOptions: options,
                      screenshot: screenshot,
                    ),
                    child: const Text('open-form'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-form'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('tilawa_sentry_feedback_message')),
        'Screen froze after opening player.',
      );
      await tester.tap(
        find.byKey(const ValueKey('tilawa_sentry_feedback_submit')),
      );
      await tester.pumpAndSettle();

      expect(hub.captureFeedbackCalls, 1);
    });

    testWidgets('captures screenshot from current screen and reopens form', (
      tester,
    ) async {
      final SentryFlutterOptions options = SentryFlutterOptions()
        ..feedback.showCaptureScreenshot = true
        ..navigatorKey = AppRouter.navigatorKey;
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
                    onPressed: () => TilawaSentryFeedbackForm.show(
                      context,
                      flutterOptions: options,
                    ),
                    child: const Text('open-form'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-form'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('tilawa_sentry_feedback_message')),
        'draft while capturing',
      );
      await tester.tap(
        find.byKey(
          const ValueKey('tilawa_sentry_feedback_capture_screenshot'),
        ),
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
        tester
            .widget<TilawaTextField>(
              find.byKey(const ValueKey('tilawa_sentry_feedback_message')),
            )
            .controller
            ?.text,
        'draft while capturing',
      );
    });
  });
}
