import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

double _contrastRatio(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('TilawaAccessibleAccents.primarySmallLabel', () {
    test('brand brown small-label contrast on light surface', () {
      final ColorScheme scheme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      ).colorScheme;

      expect(
        _contrastRatio(scheme.primarySmallLabel, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('keeps the primary hue family', () {
      final ColorScheme scheme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      ).colorScheme;

      final double primaryHue = HSLColor.fromColor(scheme.primary).hue;
      final double labelHue = HSLColor.fromColor(scheme.primarySmallLabel).hue;
      expect((labelHue - primaryHue).abs(), lessThan(8));
    });

    test('returns primary unchanged when it already passes', () {
      const ColorScheme scheme = ColorScheme.light(
        primary: Color(0xFF0D3522), // very dark green, ~12:1 on white
        surface: Color(0xFFFFFFFF),
      );
      expect(scheme.primarySmallLabel, scheme.primary);
    });

    test('passes on the dark theme as well', () {
      final ColorScheme scheme = AppTheme.getDarkTheme(
        primaryColor: AppColors.defaultPrimary,
      ).colorScheme;
      expect(
        _contrastRatio(scheme.primarySmallLabel, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('TilawaStatusColors', () {
    test('light scheme keeps canonical success and warning hexes', () {
      final ColorScheme scheme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      ).colorScheme;

      expect(scheme.success, AppColors.success);
      expect(scheme.warning, AppColors.warning);
    });

    test('dark scheme uses lifted success and warning hexes', () {
      final ColorScheme scheme = AppTheme.getDarkTheme(
        primaryColor: AppColors.defaultPrimary,
        isDefaultPreset: true,
      ).colorScheme;

      expect(scheme.success, AppColors.successDark);
      expect(scheme.warning, AppColors.warningDark);
    });

    test('dark status accents pass 3:1 on surfaceContainerHigh', () {
      final ColorScheme scheme = AppTheme.getDarkTheme(
        primaryColor: AppColors.defaultPrimary,
        isDefaultPreset: true,
      ).colorScheme;
      final Color bg = scheme.surfaceContainerHigh;

      expect(_contrastRatio(scheme.success, bg), greaterThanOrEqualTo(3.0));
      expect(_contrastRatio(scheme.warning, bg), greaterThanOrEqualTo(3.0));
    });
  });
}
