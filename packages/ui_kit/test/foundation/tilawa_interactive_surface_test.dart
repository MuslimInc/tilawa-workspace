import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('TilawaInteractiveSurface', () {
    testWidgets('fires onTap and exposes button semantics', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          TilawaInteractiveSurface(
            onTap: () => taps++,
            semanticLabel: 'Open',
            child: const SizedBox(width: 120, height: 48),
          ),
        ),
      );

      await tester.tap(find.byType(TilawaInteractiveSurface));
      expect(taps, 1);

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Open'),
      );
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isEnabled, Tristate.isTrue);
    });

    testWidgets('is inert and marked disabled when enabled is false', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          TilawaInteractiveSurface(
            onTap: () => taps++,
            enabled: false,
            semanticLabel: 'Open',
            child: const SizedBox(width: 120, height: 48),
          ),
        ),
      );

      // warnIfMissed: a disabled surface is intentionally not hit-testable.
      await tester.tap(
        find.byType(TilawaInteractiveSurface),
        warnIfMissed: false,
      );
      expect(taps, 0);

      final semantics = tester.getSemantics(find.bySemanticsLabel('Open'));
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('draws a focus ring when focused', (tester) async {
      // FocusableActionDetector only paints the focus highlight under
      // "traditional" (keyboard) navigation, not touch. Force it so the ring
      // is exercised the way a keyboard/switch user would see it.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
      });

      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        _host(
          TilawaInteractiveSurface(
            onTap: () {},
            focusNode: node,
            borderRadius: BorderRadius.circular(16),
            child: const SizedBox(width: 120, height: 48),
          ),
        ),
      );

      // No bordered overlay before focus.
      expect(_borderedBoxCount(tester), 0);

      node.requestFocus();
      await tester.pumpAndSettle();

      // Focus ring overlay (a DecoratedBox with a Border) is now present.
      expect(_borderedBoxCount(tester), greaterThan(0));
    });

    testWidgets('exposes selected semantics for selectable surfaces', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          TilawaInteractiveSurface(
            onTap: () {},
            selected: true,
            semanticLabel: 'Filter',
            child: const SizedBox(width: 80, height: 48),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.bySemanticsLabel('Filter'));
      expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
    });
  });
}

int _borderedBoxCount(WidgetTester tester) {
  return tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .where((b) {
        final d = b.decoration;
        return d is BoxDecoration && d.border != null;
      })
      .length;
}
