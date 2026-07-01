import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/sentry_user_feedback.dart';
import 'package:tilawa/core/telemetry/tilawa_sentry_feedback_form.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  tearDown(SentryUserFeedback.resetForTesting);

  Future<void> pumpForm(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
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
              body: TilawaSentryFeedbackForm(flutterOptions: options),
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
  });
}
