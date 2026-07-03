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

    testWidgets('reporter reports once when when flips to true', (
      tester,
    ) async {
      var ready = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TilawaSentryRouteDisplay(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    TilawaSentryRouteReporter(
                      when: ready,
                      child: const Text('ready-content'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => ready = true),
                      child: const Text('mark-ready'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('mark-ready'));
      await tester.pump();
      expect(find.text('ready-content'), findsOneWidget);
    });

    test('reportFullyDisplayed returns early when unmounted', () async {
      await TilawaSentryRouteDisplay.reportFullyDisplayed(
        _UnmountedContext(),
      );
    });
  });
}

class _UnmountedContext implements BuildContext {
  @override
  bool get mounted => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
