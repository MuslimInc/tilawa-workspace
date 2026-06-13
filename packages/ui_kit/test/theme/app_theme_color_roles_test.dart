import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('AppTheme color roles', () {
    const customAndroidGreen = Color(0xFF87CC23);
    const paletteCases = <String, Color>{
      'default coral': AppColors.defaultPrimary,
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
      'coral': AppColors.primaryCoral,
      'teal': AppColors.primaryTeal,
      'sage': AppColors.primarySage,
      'gold': AppColors.primaryGold,
      'brown': AppColors.primaryBrown,
      'purple': AppColors.primaryPurple,
    };

    test('light themes keep accessible contrast on core color roles', () {
      for (final entry in paletteCases.entries) {
        final theme = AppTheme.getLightTheme(
          primaryColor: entry.value,
        );

        _expectCoreContrast(theme.colorScheme, label: entry.key);
        _expectForegroundOnAllSurfaces(theme.colorScheme, label: entry.key);
        _expectSecondaryTextContrast(theme.colorScheme, label: entry.key);
        _expectStatusContrast(theme.colorScheme, label: entry.key);
        _expectDisabledUiContrast(theme.colorScheme, label: entry.key);
      }
    });

    test('dark themes keep accessible contrast on core color roles', () {
      for (final entry in paletteCases.entries) {
        final theme = AppTheme.getDarkTheme(
          primaryColor: entry.value,
          isDefaultPreset: entry.value == AppColors.defaultPrimary,
        );

        _expectCoreContrast(theme.colorScheme, label: entry.key);
        _expectForegroundOnAllSurfaces(theme.colorScheme, label: entry.key);
        _expectSecondaryTextContrast(theme.colorScheme, label: entry.key);
        _expectStatusContrast(theme.colorScheme, label: entry.key);
        _expectDisabledUiContrast(theme.colorScheme, label: entry.key);
      }
    });

    test(
      'true-black dark themes keep accessible contrast on core color roles',
      () {
        for (final entry in paletteCases.entries) {
          final theme = AppTheme.getDarkTheme(
            primaryColor: entry.value,
            isDefaultPreset: entry.value == AppColors.defaultPrimary,
            darkIsTrueBlack: true,
          );

          _expectCoreContrast(
            theme.colorScheme,
            label: '${entry.key} true-black',
          );
          _expectForegroundOnAllSurfaces(
            theme.colorScheme,
            label: '${entry.key} true-black',
          );
          _expectSecondaryTextContrast(
            theme.colorScheme,
            label: '${entry.key} true-black',
          );
          _expectStatusContrast(
            theme.colorScheme,
            label: '${entry.key} true-black',
          );
          _expectDisabledUiContrast(
            theme.colorScheme,
            label: '${entry.key} true-black',
          );
        }
      },
    );

    test(
      'light surfaceContainerHigh is Pinterest neutral for every preset',
      () {
        for (final entry in presetNoOpCases.entries) {
          final theme = AppTheme.getLightTheme(
            primaryColor: entry.value,
          );

          expect(
            theme.colorScheme.surfaceContainerHigh,
            AppColors.catalogFilterUnselectedLight,
            reason:
                '${entry.key} preset must not tint idle control surfaces '
                'toward primary',
          );
        }
      },
    );

    test(
      'light scaffold and surfaces use cool porcelain canvas not primary',
      () {
        final theme = AppTheme.getLightTheme(
          primaryColor: AppColors.primaryCoral,
        );
        final scheme = theme.colorScheme;

        expect(theme.scaffoldBackgroundColor, AppColors.lightCanvas);
        expect(scheme.surface, AppColors.lightSurface);
        expect(scheme.surfaceContainerLowest, AppColors.lightCanvas);
        expect(scheme.surfaceContainerLow, AppColors.lightSurface);
        expect(scheme.onSurface, AppColors.lightInk);
        expect(
          scheme.surfaceContainerHigh,
          AppColors.catalogFilterUnselectedLight,
        );
        expect(scheme.surfaceTint, Colors.transparent);
        expect(scheme.primary, isNot(equals(theme.scaffoldBackgroundColor)));
        expect(scheme.secondary, AppColors.catalogFilterUnselectedLight);
      },
    );

    test('default sage light theme matches brand ColorScheme roles', () {
      final scheme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      ).colorScheme;

      expect(scheme.primary, AppColors.primarySage);
      expect(scheme.onPrimary, AppColors.lightSchemeOnPrimary);
      expect(scheme.secondary, AppColors.catalogFilterUnselectedLight);
      expect(scheme.onSecondary, AppColors.lightSchemeOnSecondary);
      expect(scheme.error, AppColors.error);
      expect(scheme.onError, AppColors.lightSchemeOnError);
      expect(scheme.surface, AppColors.lightSurface);
      expect(scheme.onSurface, AppColors.lightInk);
      expect(scheme.primaryContainer, AppColors.lightSchemePrimaryContainer);
      expect(
        scheme.onPrimaryContainer,
        AppColors.lightSchemeOnPrimaryContainer,
      );
      expect(
        scheme.secondaryContainer,
        AppColors.lightSchemeSecondaryContainer,
      );
      expect(
        scheme.onSecondaryContainer,
        AppColors.lightSchemeOnSecondaryContainer,
      );
      expect(scheme.outline, AppColors.lightOutline);
    });

    test('light-mode clamp is a no-op for presets except saturated coral', () {
      for (final entry in presetNoOpCases.entries) {
        if (entry.key == 'coral') {
          continue;
        }
        final theme = AppTheme.getLightTheme(
          primaryColor: entry.value,
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
      );
      final tokens = theme.extension<TilawaComponentTokens>();

      expect(tokens, isNotNull);
      expect(
        tokens!.alphabetScrollbar.overlayBackgroundColor,
        theme.colorScheme.surfaceContainerHighest,
      );
    });

    test('true black dark theme keeps chrome surfaces on black scaffold', () {
      final theme = AppTheme.getDarkTheme(
        primaryColor: AppColors.defaultPrimary,
        isDefaultPreset: true,
        darkIsTrueBlack: true,
      );
      final colorScheme = theme.colorScheme;

      expect(theme.scaffoldBackgroundColor, Colors.black);
      expect(theme.canvasColor, Colors.black);
      expect(colorScheme.surfaceContainerLowest, Colors.black);
      expect(colorScheme.surfaceContainerLow, Colors.black);
      expect(colorScheme.surface, const Color(0xFF050807));
      expect(theme.cardColor, colorScheme.surface);
      expect(
        theme.appBarTheme.backgroundColor,
        theme.colorScheme.surface,
      );
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      expect(theme.dialogTheme.backgroundColor, colorScheme.surface);
      expect(theme.bottomSheetTheme.backgroundColor, colorScheme.surface);
    });
  });
}

const double _kDisabledForegroundOpacity = 0.38;

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
    final bool brandOnPrimary =
        entry.key == 'onPrimary / primary' &&
        colorScheme.primary == AppColors.defaultPrimary;
    _expectContrast(
      entry.value.$1,
      entry.value.$2,
      minRatio: brandOnPrimary ? 3.0 : 4.5,
      label: '$label ${entry.key}',
    );
  }
}

void _expectForegroundOnAllSurfaces(
  ColorScheme colorScheme, {
  required String label,
}) {
  final surfaces = <String, Color>{
    'surface': colorScheme.surface,
    'surfaceContainerLow': colorScheme.surfaceContainerLow,
    'surfaceContainerLowest': colorScheme.surfaceContainerLowest,
    'surfaceContainer': colorScheme.surfaceContainer,
    'surfaceContainerHigh': colorScheme.surfaceContainerHigh,
    'surfaceContainerHighest': colorScheme.surfaceContainerHighest,
  };

  for (final entry in surfaces.entries) {
    _expectContrast(
      colorScheme.onSurface,
      entry.value,
      minRatio: 4.5,
      label: '$label onSurface / ${entry.key}',
    );
  }
}

void _expectStatusContrast(ColorScheme colorScheme, {required String label}) {
  // Light success (`#43A047`) clears 3:1 on white cards only; dark tones are
  // lifted for green-tinted containers (see `TilawaStatusColors`).
  final surfaces = colorScheme.brightness == Brightness.dark
      ? <String, Color>{
          'surface': colorScheme.surface,
          'surfaceContainer': colorScheme.surfaceContainer,
          'surfaceContainerHigh': colorScheme.surfaceContainerHigh,
        }
      : <String, Color>{
          'surface': colorScheme.surface,
        };

  for (final entry in surfaces.entries) {
    _expectContrast(
      colorScheme.success,
      entry.value,
      minRatio: 3.0,
      label: '$label success / ${entry.key}',
    );
    _expectContrast(
      colorScheme.warning,
      entry.value,
      minRatio: 3.0,
      label: '$label warning / ${entry.key}',
    );
    _expectContrast(
      colorScheme.error,
      entry.value,
      minRatio: 3.0,
      label: '$label error / ${entry.key}',
    );
  }
}

void _expectDisabledUiContrast(
  ColorScheme colorScheme, {
  required String label,
}) {
  final disabledOnSurface = colorScheme.onSurface.withValues(
    alpha: _kDisabledForegroundOpacity,
  );
  final surfaces = <String, Color>{
    'surface': colorScheme.surface,
    'surfaceContainerLow': colorScheme.surfaceContainerLow,
    'surfaceContainer': colorScheme.surfaceContainer,
  };

  for (final entry in surfaces.entries) {
    _expectContrast(
      disabledOnSurface,
      entry.value,
      minRatio: 3.0,
      label: '$label disabled onSurface / ${entry.key}',
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
