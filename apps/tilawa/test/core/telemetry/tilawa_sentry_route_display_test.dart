import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/telemetry/tilawa_sentry_route_display.dart';

void main() {
  group('TilawaSentryRouteDisplay', () {
    testWidgets('reporter child stays mounted while waiting', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TilawaSentryRouteDisplay(
            child: TilawaSentryRouteReporter(
              when: false,
              child: const Text('content'),
            ),
          ),
        ),
      );

      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('reportFullyDisplayed is safe outside display scope', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Text('outside')),
      );

      await TilawaSentryRouteDisplay.reportFullyDisplayed(
        tester.element(find.text('outside')),
      );
    });
  });
}
