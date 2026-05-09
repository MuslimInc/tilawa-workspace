import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('AppTheme color roles', () {
    const customAndroidGreen = Color(0xFF87CC23);
    const paletteCases = <String, Color>{
      'default teal': AppColors.defaultPrimary,
      'custom android green': customAndroidGreen,
      'muted gold': AppColors.primaryGold,
      'purple': AppColors.primaryPurple,
      'warm brown': AppColors.primaryBrown,
      // Pathological custom HEX values — protected by _safePrimaryForLight.
      'pure white': Color(0xFFFFFFFF),
      'pure black': Color(0xFF000000),
      'mid gray': Color(0xFF888888),
      'light pink': Color(0xFFFFB3D9),
    };

    const presetNoOpCases = <String, Color>{
      'teal': AppColors.primaryTeal,
      'sage': AppColors.primarySage,
      'brown': AppColors.primaryBrown,
      'purple': AppColors.primaryPurple,
    };

    test('light themes keep accessible contrast on core color roles', () {
      for (final entry in paletteCases.entries) {
        final theme = AppTheme.getLightTheme(
          primaryColor: entry.value,
          useGoogleFontsOverride: false,
        );

        _expectCoreContrast(theme.colorScheme, label: entry.key);
        _expectSecondaryTextContrast(theme.colorScheme, label: entry.key);
      }
    });

    test('dark themes keep accessible contrast on core color roles', () {
      for (final entry in paletteCases.entries) {
        final theme = AppTheme.getDarkTheme(
          primaryColor: entry.value,
          isDefaultPreset: entry.value == AppColors.defaultPrimary,
          useGoogleFontsOverride: false,
        );

        _expectCoreContrast(theme.colorScheme, label: entry.key);
        _expectSecondaryTextContrast(theme.colorScheme, label: entry.key);
      }
    });

    test('light-mode clamp is a no-op for every PrimaryColorPreset value', () {
      for (final entry in presetNoOpCases.entries) {
        final theme = AppTheme.getLightTheme(
          primaryColor: entry.value,
          useGoogleFontsOverride: false,
        );

        expect(
          theme.colorScheme.primary,
          entry.value,
          reason:
              '${entry.key} preset must pass through the light-mode clamp '
              'unchanged',
        );
      }
    });

    test('custom primary colors derive matching primary containers', () {
      final greenTheme = AppTheme.getLightTheme(
        primaryColor: customAndroidGreen,
        useGoogleFontsOverride: false,
      );
      final colorScheme = greenTheme.colorScheme;

      expect(colorScheme.primary, customAndroidGreen);
      expect(colorScheme.primaryContainer, isNot(AppColors.defaultPrimary));
      expect(
        _hueDistance(colorScheme.primary, colorScheme.primaryContainer),
        lessThanOrEqualTo(8),
      );
      _expectContrast(
        colorScheme.onPrimaryContainer,
        colorScheme.primaryContainer,
        minRatio: 4.5,
        label: 'custom green onPrimaryContainer',
      );
    });

    test('component tokens receive the finalized theme color scheme', () {
      final theme = AppTheme.getLightTheme(
        primaryColor: customAndroidGreen,
        useGoogleFontsOverride: false,
      );
      final tokens = theme.extension<TilawaComponentTokens>();

      expect(tokens, isNotNull);
      expect(
        tokens!.skeleton.baseColor,
        theme.colorScheme.surfaceContainerHighest,
      );
      expect(
        tokens.skeleton.highlightColor,
        theme.colorScheme.surfaceContainerHigh,
      );
    });

    test('true black dark theme keeps chrome surfaces on black scaffold', () {
      final theme = AppTheme.getDarkTheme(
        primaryColor: AppColors.defaultPrimary,
        isDefaultPreset: true,
        darkIsTrueBlack: true,
        useGoogleFontsOverride: false,
      );
      final colorScheme = theme.colorScheme;

      expect(theme.scaffoldBackgroundColor, Colors.black);
      expect(theme.canvasColor, Colors.black);
      expect(colorScheme.surfaceContainerLowest, Colors.black);
      expect(colorScheme.surfaceContainerLow, Colors.black);
      expect(colorScheme.surface, const Color(0xFF050807));
      expect(theme.cardColor, colorScheme.surface);
      expect(theme.appBarTheme.backgroundColor, colorScheme.surface);
      expect(theme.dialogTheme.backgroundColor, colorScheme.surface);
      expect(theme.bottomSheetTheme.backgroundColor, colorScheme.surface);
    });
  });
}

void _expectCoreContrast(ColorScheme colorScheme, {required String label}) {
  final checks = <String, (Color foreground, Color background)>{
    'onPrimary / primary': (colorScheme.onPrimary, colorScheme.primary),
    'onPrimaryContainer / primaryContainer': (
      colorScheme.onPrimaryContainer,
      colorScheme.primaryContainer,
    ),
    'onSecondary / secondary': (colorScheme.onSecondary, colorScheme.secondary),
    'onSecondaryContainer / secondaryContainer': (
      colorScheme.onSecondaryContainer,
      colorScheme.secondaryContainer,
    ),
    'onTertiary / tertiary': (colorScheme.onTertiary, colorScheme.tertiary),
    'onTertiaryContainer / tertiaryContainer': (
      colorScheme.onTertiaryContainer,
      colorScheme.tertiaryContainer,
    ),
    'onSurface / surface': (colorScheme.onSurface, colorScheme.surface),
    'onSurface / surfaceContainerLow': (
      colorScheme.onSurface,
      colorScheme.surfaceContainerLow,
    ),
    'onError / error': (colorScheme.onError, colorScheme.error),
  };

  for (final entry in checks.entries) {
    _expectContrast(
      entry.value.$1,
      entry.value.$2,
      minRatio: 4.5,
      label: '$label ${entry.key}',
    );
  }
}

void _expectSecondaryTextContrast(
  ColorScheme colorScheme, {
  required String label,
}) {
  final checks = <String, Color>{
    'surface': colorScheme.surface,
    'surfaceContainerLow': colorScheme.surfaceContainerLow,
    'surfaceContainer': colorScheme.surfaceContainer,
    'surfaceContainerHigh': colorScheme.surfaceContainerHigh,
    'surfaceContainerHighest': colorScheme.surfaceContainerHighest,
  };

  for (final entry in checks.entries) {
    _expectContrast(
      colorScheme.onSurfaceVariant,
      entry.value,
      minRatio: 3.0,
      label: '$label onSurfaceVariant / ${entry.key}',
    );
  }
}

void _expectContrast(
  Color foreground,
  Color background, {
  required double minRatio,
  required String label,
}) {
  expect(
    _contrastRatio(foreground, background),
    greaterThanOrEqualTo(minRatio),
    reason: label,
  );
}

double _contrastRatio(Color a, Color b) {
  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();
  final lighter = math.max(luminanceA, luminanceB);
  final darker = math.min(luminanceA, luminanceB);

  return (lighter + 0.05) / (darker + 0.05);
}

double _hueDistance(Color a, Color b) {
  final hueA = HSLColor.fromColor(a).hue;
  final hueB = HSLColor.fromColor(b).hue;
  final distance = (hueA - hueB).abs();

  return math.min(distance, 360 - distance);
}
