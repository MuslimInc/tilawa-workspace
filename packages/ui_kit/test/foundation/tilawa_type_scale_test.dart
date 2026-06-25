import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_type_scale.dart';

void main() {
  const double factor = kTilawaGlobalTextScaleFactor;

  group('tilawaScaledFontSize', () {
    test('applies the global readability factor', () {
      expect(tilawaScaledFontSize(16), closeTo(16 * factor, 0.001));
      expect(tilawaScaledFontSize(14), closeTo(14 * factor, 0.001));
    });
  });

  group('meMuslimScaleTextTheme', () {
    test('scales explicit font sizes and preserves hierarchy', () {
      const base = TextTheme(
        titleLarge: TextStyle(fontSize: 22),
        bodyLarge: TextStyle(fontSize: 16),
        labelSmall: TextStyle(fontSize: 11),
      );
      final scaled = meMuslimScaleTextTheme(base);

      expect(scaled.titleLarge?.fontSize, closeTo(22 * factor, 0.01));
      expect(scaled.bodyLarge?.fontSize, closeTo(16 * factor, 0.01));
      expect(scaled.labelSmall?.fontSize, closeTo(11 * factor, 0.01));

      // Hierarchy is preserved after scaling.
      expect(
        scaled.titleLarge!.fontSize! > scaled.bodyLarge!.fontSize!,
        isTrue,
      );
      expect(
        scaled.bodyLarge!.fontSize! > scaled.labelSmall!.fontSize!,
        isTrue,
      );
    });

    test('leaves styles without an explicit size untouched', () {
      const base = TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
      );
      final scaled = meMuslimScaleTextTheme(base);

      expect(scaled.titleLarge?.fontSize, isNull);
      expect(scaled.titleLarge?.fontWeight, FontWeight.w600);
    });
  });
}
