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
                onPressed: () => showReportConcernSheet(context),
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

  testWidgets('report concern sheet uses kit scaffold footer', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.byType(TilawaBottomSheetScaffold), findsOneWidget);
    expect(find.text('Submit report'), findsOneWidget);
  });

  testWidgets('report concern sheet requires 20 character description', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), 'too short');
    await tester.tap(find.text('Submit report'));
    await tester.pump();

    expect(
      find.text('Please provide at least 20 characters.'),
      findsOneWidget,
    );
  });
}
