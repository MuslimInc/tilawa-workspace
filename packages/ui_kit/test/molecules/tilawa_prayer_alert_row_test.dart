import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('TilawaPrayerAlertRow lays out title and trailing controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            TilawaDesignTokens.light(),
            TilawaComponentTokens.light(),
          ],
        ),
        home: const Scaffold(
          body: TilawaPrayerAlertRow(
            title: 'Fajr',
            primaryControl: Icon(Icons.notifications_active_outlined),
            secondaryControl: Icon(Icons.volume_up_outlined),
          ),
        ),
      ),
    );

    expect(find.text('Fajr'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
  });

  testWidgets('TilawaPrayerAlertRow omits secondary spacing when absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            TilawaDesignTokens.light(),
            TilawaComponentTokens.light(),
          ],
        ),
        home: const Scaffold(
          body: TilawaPrayerAlertRow(
            title: 'Sunrise',
            primaryControl: Icon(Icons.notifications_active_outlined),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.volume_up_outlined), findsNothing);
  });
}
