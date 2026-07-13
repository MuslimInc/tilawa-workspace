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

        final MeMuslimDesignTokens? design = theme
            .extension<MeMuslimDesignTokens>();
        expect(design, isNotNull);
        expect(design!.opacityShadow, 0.04 * kElevationMultiplier);
        expect(design.opacityShadowStrong, 0.08 * kElevationMultiplier);
        expect(
          design.shadowOffsetSmall,
          const Offset(0, 1.5 * kElevationMultiplier),
        );
        expect(
          design.shadowOffsetMedium,
          const Offset(0, 3.0 * kElevationMultiplier),
        );

        expect(theme.extension<MeMuslimComponentTokens>(), isNotNull);

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

        expect(theme.extension<MeMuslimDesignTokens>(), isNotNull);
        expect(theme.extension<MeMuslimComponentTokens>(), isNotNull);

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
      expect(theme.extension<MeMuslimDesignTokens>(), isNotNull);
      expect(theme.extension<MeMuslimComponentTokens>(), isNotNull);
    });

    test(
      'light parchment canvas: warm scaffold, white cards, beige idle tier',
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

    test('Material button themes use kit pill shape from tokens', () {
      final ThemeData theme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      );
      final MeMuslimDesignTokens tokens = theme
          .extension<MeMuslimDesignTokens>()!;
      final BorderRadius expected = BorderRadius.circular(
        tokens.buttonBorderRadius(),
      );

      for (final ButtonStyle? style in [
        theme.elevatedButtonTheme.style,
        theme.filledButtonTheme.style,
        theme.outlinedButtonTheme.style,
        theme.textButtonTheme.style,
      ]) {
        final OutlinedBorder shape = style!.shape!.resolve(const {})!;
        expect((shape as RoundedRectangleBorder).borderRadius, expected);
      }
    });

    test('card and dialog use semantic token radii; inputs are kit-owned', () {
      final ThemeData theme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      );
      final MeMuslimDesignTokens tokens = theme
          .extension<MeMuslimDesignTokens>()!;

      final RoundedRectangleBorder cardShape =
          theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(
        cardShape.borderRadius,
        BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.card),
        ),
      );

      final RoundedRectangleBorder dialogShape =
          theme.dialogTheme.shape! as RoundedRectangleBorder;
      expect(dialogShape.borderRadius, cardShape.borderRadius);

      expect(theme.inputDecorationTheme.border, InputBorder.none);
      expect(theme.inputDecorationTheme.enabledBorder, InputBorder.none);
      expect(theme.inputDecorationTheme.focusedBorder, InputBorder.none);
    });
  });
}
