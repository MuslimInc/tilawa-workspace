import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('TilawaSegmentedControl', () {
    testWidgets('disabled segment ignores taps and exposes semantics', (
      tester,
    ) async {
      var changes = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: Scaffold(
            body: TilawaSegmentedControl<String>(
              segments: const [
                TilawaSegment(value: 'on', label: 'On'),
                TilawaSegment(
                  value: 'off',
                  label: 'Off',
                  enabled: false,
                  semanticsHint: 'Unavailable',
                ),
              ],
              selectedValue: 'on',
              onValueChanged: (_) => changes++,
            ),
          ),
        ),
      );

      final offSemantics = tester.getSemantics(find.text('Off'));
      expect(offSemantics.flagsCollection.isEnabled, Tristate.isFalse);
      expect(offSemantics.hint, 'Unavailable');
      expect(
        find.ancestor(of: find.text('Off'), matching: find.byType(Opacity)),
        findsOneWidget,
      );

      await tester.tap(find.text('Off'));
      await tester.pump();
      expect(changes, 0);

      await tester.tap(find.text('On'));
      await tester.pump();
      expect(changes, 0);
    });

    testWidgets('enabled segment still selects', (tester) async {
      String? selected = 'a';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: Scaffold(
            body: TilawaSegmentedControl<String>(
              segments: const [
                TilawaSegment(value: 'a', label: 'A'),
                TilawaSegment(value: 'b', label: 'B'),
              ],
              selectedValue: selected,
              onValueChanged: (value) => selected = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('B'));
      await tester.pump();
      expect(selected, 'b');
    });
  });
}
