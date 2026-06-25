import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/env.dart';
import 'package:tilawa/features/theme/domain/app_theme_mode.dart';
import 'package:tilawa/features/theme/domain/entities/app_theme_preset.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:tilawa/features/theme/presentation/theme_state_material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('ThemeStateMaterial.primaryColor', () {
    test(
      'returns brand-locked preset when color picker is disabled',
      () {
        if (Env.kShowColorPicker) {
          return;
        }

        const state = ThemeState(
          mode: AppThemeMode.light,
          primaryColorArgb: 0xFFE60023,
          primaryColorSource: PrimaryColorSource.custom,
        );

        expect(
          state.primaryColor,
          PrimaryColorPreset.brandLocked.value,
        );
      },
      skip: Env.kShowColorPicker
          ? 'run without TILAWA_SHOW_COLOR_PICKER to assert brand lock'
          : false,
    );

    test(
      'returns stored ARGB when color picker is enabled',
      () {
        if (!Env.kShowColorPicker) {
          return;
        }

        const customArgb = 0xFFE60023;
        const state = ThemeState(
          mode: AppThemeMode.light,
          primaryColorArgb: customArgb,
          primaryColorSource: PrimaryColorSource.custom,
        );

        expect(state.primaryColor, const Color(customArgb));
      },
      skip: !Env.kShowColorPicker
          ? 'run with --dart-define=TILAWA_SHOW_COLOR_PICKER=true'
          : false,
    );
  });

  group('ThemeStateMaterial.themeMode', () {
    test('maps light mode to ThemeMode.light', () {
      const state = ThemeState(mode: AppThemeMode.light);

      expect(state.themeMode, ThemeMode.light);
    });

    test('maps dark mode to ThemeMode.dark', () {
      const state = ThemeState(mode: AppThemeMode.dark);

      expect(state.themeMode, ThemeMode.dark);
    });

    test('useSystemTheme overrides mode with ThemeMode.system', () {
      const state = ThemeState(
        mode: AppThemeMode.dark,
        useSystemTheme: true,
      );

      expect(state.themeMode, ThemeMode.system);
    });
  });

  group('ThemeStateMaterial with AppTheme', () {
    test('resolved primary color builds a light theme with extensions', () {
      const state = ThemeState(mode: AppThemeMode.light);
      final theme = AppTheme.getLightTheme(primaryColor: state.primaryColor);

      expect(theme.extension<MeMuslimDesignTokens>(), isNotNull);
      expect(theme.extension<MeMuslimComponentTokens>(), isNotNull);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('trueBlack preset builds OLED scaffold in dark theme', () {
      const state = ThemeState(
        mode: AppThemeMode.dark,
        preset: AppThemePreset.trueBlack,
      );
      final theme = AppTheme.getDarkTheme(
        primaryColor: state.primaryColor,
        isDefaultPreset: true,
        darkIsTrueBlack: state.preset == AppThemePreset.trueBlack,
      );

      expect(theme.scaffoldBackgroundColor, Colors.black);
    });
  });
}
