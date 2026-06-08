import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/component_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';

/// Locks key behaviors described in root [DESIGN.md] (§1, §4, §6, §7).
void main() {
  group('AppTheme DESIGN.md compliance', () {
    test(
      'light theme uses comfortable density, M3 extensions, neutral elevation tint',
      () {
        final ThemeData theme = AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        );

        expect(theme.useMaterial3, isTrue);
        expect(theme.visualDensity, FlexColorScheme.comfortablePlatformDensity);

        final TilawaDesignTokens? design = theme
            .extension<TilawaDesignTokens>();
        expect(design, isNotNull);
        expect(design!.opacityShadow, 0.18);
        expect(design.opacityShadowStrong, 0.28);
        expect(design.shadowOffsetSmall, const Offset(0, 2));
        expect(design.shadowOffsetMedium, const Offset(0, 4));

        expect(theme.extension<TilawaComponentTokens>(), isNotNull);

        expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
        expect(theme.dialogTheme.surfaceTintColor, Colors.transparent);
        expect(theme.bottomSheetTheme.surfaceTintColor, Colors.transparent);

        expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
        expect(
          theme.appBarTheme.backgroundColor,
          theme.colorScheme.surface,
        );
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.scrolledUnderElevation, 0);
      },
    );

    test(
      'dark theme uses comfortable density, M3 extensions, neutral elevation tint',
      () {
        final ThemeData theme = AppTheme.getDarkTheme(
          primaryColor: AppColors.defaultPrimary,
          isDefaultPreset: true,
          darkIsTrueBlack: false,
        );

        expect(theme.useMaterial3, isTrue);
        expect(theme.visualDensity, FlexColorScheme.comfortablePlatformDensity);

        expect(theme.extension<TilawaDesignTokens>(), isNotNull);
        expect(theme.extension<TilawaComponentTokens>(), isNotNull);

        expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
        expect(theme.dialogTheme.surfaceTintColor, Colors.transparent);
        expect(theme.bottomSheetTheme.surfaceTintColor, Colors.transparent);

        expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
        expect(
          theme.appBarTheme.backgroundColor,
          theme.colorScheme.surface,
        );
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.scrolledUnderElevation, 0);
      },
    );

    test('light theme registers design and component token extensions', () {
      final ThemeData theme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      );
      expect(theme.extension<TilawaDesignTokens>(), isNotNull);
      expect(theme.extension<TilawaComponentTokens>(), isNotNull);
    });

    test(
      'light warm canvas: cream scaffold, white cards, #E5E5E0 idle tier',
      () {
        final ThemeData theme = AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        );
        final ColorScheme scheme = theme.colorScheme;

        expect(theme.scaffoldBackgroundColor, AppColors.lightCanvas);
        expect(scheme.surface, AppColors.lightSurface);
        expect(scheme.surfaceContainerLow, AppColors.lightSurface);
        expect(scheme.onSurface, AppColors.lightInk);
        expect(
          scheme.surfaceContainerHigh,
          AppColors.catalogFilterUnselectedLight,
        );
        expect(scheme.surfaceTint, Colors.transparent);
      },
    );

    test('light search field tokens use neutral surface not primary', () {
      final ThemeData theme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      );
      final search = theme.componentTokens.searchField;

      expect(search.backgroundColor, theme.colorScheme.surface);
      expect(search.backgroundColor, isNot(theme.colorScheme.primary));
      expect(search.backgroundColor, isNot(theme.colorScheme.primaryContainer));
    });
  });
}
