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

  group('tilawaProductTextScaler', () {
    test('applies the global readability factor', () {
      expect(
        tilawaProductTextScaler(TextScaler.noScaling).scale(16),
        closeTo(16 * factor, 0.001),
      );
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

  group('tilawaMeasureTextHeight', () {
    testWidgets('uses MediaQuery textScaler', (WidgetTester tester) async {
      late double unscaledHeight;
      late double scaledHeight;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              unscaledHeight = tilawaMeasureTextHeight(
                context: context,
                style: const TextStyle(fontSize: 16),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: Builder(
              builder: (context) {
                scaledHeight = tilawaMeasureTextHeight(
                  context: context,
                  style: const TextStyle(fontSize: 16),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(scaledHeight, greaterThan(unscaledHeight));
    });
  });

  group('tilawaLayoutSlack', () {
    testWidgets('returns zero at unit scale', (WidgetTester tester) async {
      late double slack;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              slack = tilawaLayoutSlack(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(slack, 0);
    });

    testWidgets('adds slack above unit scale', (WidgetTester tester) async {
      late double slack;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: Builder(
              builder: (context) {
                slack = tilawaLayoutSlack(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(slack, closeTo(5, 0.001));
    });
  });
}
