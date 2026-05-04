import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('TilawaSkeletonTokens', () {
    test('defaults factory creates valid tokens', () {
      final colorScheme = const ColorScheme.light();
      final tokens = TilawaSkeletonTokens.defaults(
        colorScheme: colorScheme,
      );

      expect(tokens.baseColor, colorScheme.surfaceContainerHighest);
      expect(tokens.highlightColor, colorScheme.surfaceContainerHigh);
      expect(tokens.borderRadius, 12.0); // Comfortable default
      expect(tokens.animationDuration, const Duration(milliseconds: 1500));
      expect(tokens.pulseDuration, const Duration(milliseconds: 1000));
    });

    test('density changes borderRadius', () {
      final colorScheme = const ColorScheme.light();

      final comfortable = TilawaSkeletonTokens.defaults(
        colorScheme: colorScheme,
        density: TilawaDensity.comfortable,
      );

      final compact = TilawaSkeletonTokens.defaults(
        colorScheme: colorScheme,
        density: TilawaDensity.compact,
      );

      expect(comfortable.borderRadius, 12.0);
      expect(compact.borderRadius, 8.0);
    });

    test('colors derive from ColorScheme', () {
      final colorScheme = const ColorScheme.dark().copyWith(
        surfaceContainerHighest: Colors.grey.shade800,
        surfaceContainerHigh: Colors.grey.shade700,
      );

      final tokens = TilawaSkeletonTokens.defaults(
        colorScheme: colorScheme,
      );

      expect(tokens.baseColor, Colors.grey.shade800);
      expect(tokens.highlightColor, Colors.grey.shade700);
    });

    test('copyWith preserves values', () {
      final colorScheme = const ColorScheme.light();
      final original = TilawaSkeletonTokens.defaults(
        colorScheme: colorScheme,
      );

      final copy = original.copyWith();

      expect(copy.baseColor, original.baseColor);
      expect(copy.highlightColor, original.highlightColor);
      expect(copy.borderRadius, original.borderRadius);
      expect(copy.animationDuration, original.animationDuration);
      expect(copy.pulseDuration, original.pulseDuration);
    });

    test('copyWith can override values', () {
      final colorScheme = const ColorScheme.light();
      final original = TilawaSkeletonTokens.defaults(
        colorScheme: colorScheme,
      );

      final copy = original.copyWith(
        borderRadius: 20.0,
        animationDuration: const Duration(milliseconds: 2000),
      );

      expect(copy.borderRadius, 20.0);
      expect(copy.animationDuration, const Duration(milliseconds: 2000));
      // Other values preserved
      expect(copy.baseColor, original.baseColor);
    });

    test('lerp interpolates colors correctly', () {
      final colorScheme = const ColorScheme.light();
      final a = TilawaSkeletonTokens.defaults(colorScheme: colorScheme);
      final b = a.copyWith(
        borderRadius: 24.0,
      );

      final result = TilawaSkeletonTokens.lerp(a, b, 0.5);

      // Border radius should be interpolated
      expect(result.borderRadius, closeTo(18.0, 0.1));
    });

    test('lerp preserves durations at midpoint by switching', () {
      final colorScheme = const ColorScheme.light();
      final a = TilawaSkeletonTokens.defaults(colorScheme: colorScheme);
      final b = a.copyWith(
        animationDuration: const Duration(milliseconds: 2000),
        pulseDuration: const Duration(milliseconds: 1500),
      );

      // At t < 0.5, should use a's values
      final result1 = TilawaSkeletonTokens.lerp(a, b, 0.3);
      expect(result1.animationDuration, a.animationDuration);
      expect(result1.pulseDuration, a.pulseDuration);

      // At t >= 0.5, should use b's values
      final result2 = TilawaSkeletonTokens.lerp(a, b, 0.5);
      expect(result2.animationDuration, b.animationDuration);
      expect(result2.pulseDuration, b.pulseDuration);
    });

    test('const constructor creates identical instances', () {
      const tokens1 = TilawaSkeletonTokens(
        baseColor: Colors.grey,
        highlightColor: Colors.white,
        borderRadius: 12.0,
        animationDuration: Duration(milliseconds: 1500),
        pulseDuration: Duration(milliseconds: 1000),
      );

      const tokens2 = TilawaSkeletonTokens(
        baseColor: Colors.grey,
        highlightColor: Colors.white,
        borderRadius: 12.0,
        animationDuration: Duration(milliseconds: 1500),
        pulseDuration: Duration(milliseconds: 1000),
      );

      expect(identical(tokens1, tokens2), isTrue);
    });
  });
}
