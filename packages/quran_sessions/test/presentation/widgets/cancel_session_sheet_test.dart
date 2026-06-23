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
                onPressed: () => showCancelSessionSheet(
                  context,
                  sessionStartsAt: DateTime.utc(2026, 7, 1, 10),
                  pricingType: SessionPricingType.free,
                ),
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

  testWidgets('cancel sheet uses kit scaffold with keep as primary', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.byType(TilawaBottomSheetScaffold), findsOneWidget);
    expect(find.text('Keep session'), findsOneWidget);
    expect(find.text('Cancel session'), findsOneWidget);
  });

  testWidgets('cancel sheet requires reason before confirming cancel', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Cancel session'));
    await tester.pump();

    expect(find.text('Please enter at least 3 characters.'), findsOneWidget);
  });
}
