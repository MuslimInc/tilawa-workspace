import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => showTutorRejectBookingSheet(context),
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('reject sheet dismisses without action on go back', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();

    expect(find.text('Decline booking request?'), findsNothing);
  });

  testWidgets('reject without reason confirms empty result', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Decline request'));
    await tester.pumpAndSettle();

    expect(find.text('Decline booking request?'), findsNothing);
  });

  testWidgets('reject with reason returns trimmed text', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(
      find.byType(TextField),
      '  This time does not work  ',
    );
    await tester.tap(find.text('Decline request'));
    await tester.pumpAndSettle();

    expect(find.text('Decline booking request?'), findsNothing);
  });

  testWidgets('text field enforces max length', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(
      find.byType(TextField),
      'x' * (tutorRejectBookingReasonMaxLength + 5),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.controller!.text.length,
      lessThanOrEqualTo(tutorRejectBookingReasonMaxLength),
    );
  });
}
