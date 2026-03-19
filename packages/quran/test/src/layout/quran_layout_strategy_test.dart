import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/layout/quran_layout_strategy.dart';

void main() {
  group('QuranLayoutMetrics', () {
    test('supports value equality for const instances', () {
      const metrics1 = QuranLayoutMetrics(
        fontSize: 20,
        fontHeight: 1.5,
        isScrollable: true,
        padding: EdgeInsets.all(10),
      );
      const metrics2 = QuranLayoutMetrics(
        fontSize: 20,
        fontHeight: 1.5,
        isScrollable: true,
        padding: EdgeInsets.all(10),
      );

      expect(metrics1, equals(metrics2));
    });

    test('properties are set correctly', () {
      const metrics = QuranLayoutMetrics(
        fontSize: 24,
        fontHeight: 2.0,
        isScrollable: false,
        padding: EdgeInsets.symmetric(horizontal: 16),
      );

      expect(metrics.fontSize, 24);
      expect(metrics.fontHeight, 2.0);
      expect(metrics.isScrollable, false);
      expect(metrics.padding, const EdgeInsets.symmetric(horizontal: 16));
    });

    test('default padding is EdgeInsets.zero', () {
      const metrics = QuranLayoutMetrics(
        fontSize: 24,
        fontHeight: 2.0,
        isScrollable: false,
      );
      expect(metrics.padding, EdgeInsets.zero);
    });
  });

  group('StandardQuranLayoutStrategy', () {
    late StandardQuranLayoutStrategy strategy;

    setUp(() {
      strategy = StandardQuranLayoutStrategy();
    });

    testWidgets('calculates portrait metrics correctly', (tester) async {
      const screenSize = Size(392.7, 803.6); // Approximate Pixel 4
      const padding = EdgeInsets.only(top: 24);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize, padding: padding),
          child: Builder(
            builder: (context) {
              final QuranLayoutMetrics metrics = strategy.calculateMetrics(
                context,
                const BoxConstraints(maxWidth: 392.7, maxHeight: 803.6),
              );

              // availableWidth = 392.7 * (1.0 - 0.05) = 373.065
              // fontSize = 373.065 / 16.35
              const double expectedFontSize = 373.065 / 16.35;
              // fontHeight = (803.6 / 15.0) / fontSize
              const double expectedFontHeight =
                  (803.6 / 15.0) / expectedFontSize;

              expect(metrics.isScrollable, false);
              expect(metrics.fontSize, closeTo(expectedFontSize, 0.0001));
              expect(metrics.fontHeight, closeTo(expectedFontHeight, 0.0001));
              expect(metrics.padding, EdgeInsets.zero); // Should be default

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('calculates landscape metrics correctly', (tester) async {
      const screenSize = Size(803.6, 392.7);
      const padding = EdgeInsets.only(top: 24, left: 44); // Notch/safe area

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize, padding: padding),
          child: Builder(
            builder: (context) {
              final QuranLayoutMetrics metrics = strategy.calculateMetrics(
                context,
                const BoxConstraints(maxWidth: 803.6, maxHeight: 392.7),
              );

              // availableWidth = 803.6 * (1.0 - 0.05) = 763.42
              // adaptiveFontSize = 763.42 / 16.35
              const double expectedFontSize = 763.42 / 16.35;

              // fontHeight = 1 / 0.40
              const expectedFontHeight = 2.5;

              expect(metrics.isScrollable, true);
              expect(metrics.fontSize, closeTo(expectedFontSize, 0.0001));
              expect(metrics.fontHeight, closeTo(expectedFontHeight, 0.0001));

              // Padding should have +16 on top and bottom
              expect(metrics.padding.top, padding.top + 16);
              expect(metrics.padding.bottom, padding.bottom + 16);
              // Left/Right padding is not explicitly handled in the strategy but the object is created with EdgeInsets.only(top, bottom) in the strategy?
              // The strategy returns:
              // padding: EdgeInsets.only(
              //   top: padding.top + 16,
              //   bottom: padding.bottom + 16,
              // ),
              expect(metrics.padding.left, 0);
              expect(metrics.padding.right, 0);

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
