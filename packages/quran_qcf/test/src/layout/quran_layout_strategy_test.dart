import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/layout/quran_layout_strategy.dart';

void main() {
  group('QuranLayoutMetrics', () {
    test('supports value equality for const instances', () {
      const metrics1 = QuranLayoutMetrics(
        fontSize: 20,
        fontHeight: 1.5,
        isScrollable: true,
        padding: EdgeInsets.all(10),
        lineSpacing: 4.0,
      );
      const metrics2 = QuranLayoutMetrics(
        fontSize: 20,
        fontHeight: 1.5,
        isScrollable: true,
        padding: EdgeInsets.all(10),
        lineSpacing: 4.0,
      );

      expect(metrics1, equals(metrics2));
    });

    test('properties are set correctly', () {
      const metrics = QuranLayoutMetrics(
        fontSize: 24,
        fontHeight: 2.0,
        isScrollable: false,
        padding: EdgeInsets.symmetric(horizontal: 16),
        lineSpacing: 5.0,
      );

      expect(metrics.fontSize, 24);
      expect(metrics.fontHeight, 2.0);
      expect(metrics.isScrollable, false);
      expect(metrics.padding, const EdgeInsets.symmetric(horizontal: 16));
      expect(metrics.lineSpacing, 5.0);
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
              // Note: In real app, QuranDataService must be loaded.
              // For tests, we might need to mock it if calculateMetrics calls it.
              // Since it's a singleton, we'll just try to call it.

              final QuranLayoutMetrics metrics = strategy.calculateMetrics(
                context,
                const BoxConstraints(maxWidth: 392.7, maxHeight: 803.6),
                1, // Page 1
              );

              expect(metrics.isScrollable, false);
              expect(metrics.fontSize, isPositive);
              expect(metrics.fontHeight, isPositive);
              expect(metrics.padding, const EdgeInsets.only(top: 4.0));

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
                1,
              );

              expect(metrics.isScrollable, true);
              expect(metrics.fontSize, isPositive);
              expect(metrics.fontHeight, 1.85);

              expect(metrics.padding, EdgeInsets.zero);

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
