import 'dart:math' as math;

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'component_tokens.dart';
import 'design_tokens.dart';

/// Centralized app theme configuration
class AppTheme {
  AppTheme._();

  /// Toggle for using Google Fonts, can be disabled in tests
  static bool useGoogleFonts = true;

  // Light theme configuration constants
  static const FlexSurfaceMode _lightSurfaceMode =
      FlexSurfaceMode.levelSurfacesLowScaffold;
  static const int _lightBlendLevel = 0;
  static const FlexAppBarStyle _lightAppBarStyle = FlexAppBarStyle.surface;
  static const double _lightAppBarOpacity = 1;
  // Flat chrome. The brand rule (tilawa_brand.md §5) is that only the Mushaf
  // page gets a shadow; app bars are flat. `_applySurfaceScale` re-asserts
  // this at the end of theme assembly — keeping it consistent here avoids a
  // transient elevated bar before the override takes effect (visible in
  // hot-reload, Flex sub-theme inspection, and any consumer that reads the
  // intermediate ThemeData before `_applySurfaceScale`).
  static const double _lightAppBarElevation = 0;
  static const FlexTabBarStyle _lightTabBarStyle = FlexTabBarStyle.forAppBar;

  // Dark theme configuration constants
  static const FlexSurfaceMode _darkSurfaceMode =
      FlexSurfaceMode.levelSurfacesLowScaffold;
  static const int _darkBlendLevel = 0;
  static const FlexAppBarStyle _darkAppBarStyle = FlexAppBarStyle.surface;
  static const double _darkAppBarOpacity = 1;
  static const double _darkAppBarElevation = 0;
  static const FlexTabBarStyle _darkTabBarStyle = FlexTabBarStyle.forAppBar;

  // Shared configuration constants
  static const bool _tooltipsMatchBackground = true;
  static const bool _useMaterial3ErrorColors = true;

  // Shared text theme: M3 typography base, optionally Alexandria.
  static TextTheme _material3TypographyBase(Brightness brightness) {
    final typography = Typography.material2021(
      platform: defaultTargetPlatform,
    );
    return brightness == Brightness.dark ? typography.white : typography.black;
  }

  static TextTheme _getTextTheme(bool useFonts, Brightness brightness) {
    final base = _material3TypographyBase(brightness);
    if (!useFonts) return base;
    return GoogleFonts.alexandriaTextTheme(base);
  }

  static FlexSchemeColor _lightScheme(Color primaryColor) {
    final safePrimary = _safePrimaryForLight(primaryColor);
    final primaryContainer = _containerForPrimary(
      safePrimary,
      brightness: Brightness.light,
    );

    return FlexSchemeColor.from(
      primary: safePrimary,
      primaryContainer: primaryContainer,
      secondary: AppColors.lightSurfaceContainerHighBase,
      secondaryContainer: AppColors.lightSecondaryContainer,
      tertiary: AppColors.lightBody,
      tertiaryContainer: AppColors.lightTertiaryContainer,
      appBarColor: AppColors.lightBackground,
      error: AppColors.error,
      brightness: Brightness.light,
    );
  }

  /// Pulls pathological custom HEX values back into a renderable band so the
  /// light theme's primary stays visible against light neutral surfaces and
  /// produces readable on-primary contrast.
  ///
  /// This is **intentionally a no-op** for every curated primary preset swatch
  /// in the app and for any reasonable custom color — only colors that would
  /// render as near-white, near-black, or pure gray are pulled into the band. The user's stored color is never mutated; only the value handed
  /// to FlexColorScheme for the light theme is adjusted.
  ///
  /// Thresholds (chosen so every current preset passes through unchanged):
  /// - saturation floor: 0.16
  /// - lightness band:   0.18 – 0.50
  /// - co-clamp:         when input saturation > 0.85 AND input lightness >
  ///                     0.40, saturation is also pulled down to 0.65 so the
  ///                     result is not a fully-saturated mid-tone (which
  ///                     defeats `onPrimary` contrast). No preset triggers
  ///                     this — the default teal preset sits at S≈0.75.
  ///
  /// Do not loosen these without re-running the contrast tests in
  /// `app_theme_color_roles_test.dart`.
  static Color _safePrimaryForLight(Color color) {
    final hsl = HSLColor.fromColor(color);
    final coClampSaturation = hsl.saturation > 0.85 && hsl.lightness > 0.40;
    final saturation = coClampSaturation
        ? 0.65
        : hsl.saturation < 0.16
        ? 0.16
        : hsl.saturation;
    final lightness = hsl.lightness > 0.50
        ? 0.50
        : hsl.lightness < 0.18
        ? 0.18
        : hsl.lightness;
    if (saturation == hsl.saturation && lightness == hsl.lightness) {
      return color;
    }
    return hsl.withSaturation(saturation).withLightness(lightness).toColor();
  }

  static FlexSchemeColor _darkScheme(
    Color primaryColor, {
    required bool isDefaultPreset,
  }) {
    final darkPrimary = isDefaultPreset
        ? AppColors.darkDefaultPrimary
        : _liftForDarkTheme(primaryColor);
    final primaryContainer = _containerForPrimary(
      primaryColor,
      brightness: Brightness.dark,
    );

    return FlexSchemeColor.from(
      primary: darkPrimary,
      primaryContainer: primaryContainer,
      primaryLightRef: primaryColor,
      secondary: AppColors.darkSecondary,
      secondaryContainer: AppColors.darkSecondaryContainer,
      secondaryLightRef: AppColors.brandSecondary,
      tertiary: AppColors.darkTertiary,
      tertiaryContainer: AppColors.darkTertiaryContainer,
      tertiaryLightRef: AppColors.brandTertiary,
      appBarColor: AppColors.darkSurface,
      error: AppColors.darkSchemeError,
      brightness: Brightness.dark,
    );
  }

  static Color _liftForDarkTheme(Color color) {
    final hsl = HSLColor.fromColor(color);
    final lightnessLift = hsl.lightness > 0.5 ? 0.18 : 0.32;
    final saturationScale = hsl.saturation > 0.65 ? 0.68 : 0.82;
    return hsl
        .withLightness((hsl.lightness + lightnessLift).clamp(0.50, 0.72))
        .withSaturation((hsl.saturation * saturationScale).clamp(0.22, 0.58))
        .toColor();
  }

  static Color _containerForPrimary(
    Color primaryColor, {
    required Brightness brightness,
  }) {
    final hsl = HSLColor.fromColor(primaryColor);
    if (brightness == Brightness.dark) {
      return hsl
          .withLightness((hsl.lightness * 0.42).clamp(0.16, 0.28))
          .withSaturation((hsl.saturation * 0.74).clamp(0.22, 0.62))
          .toColor();
    }

    return hsl
        .withLightness((hsl.lightness + 0.38).clamp(0.84, 0.93))
        .withSaturation((hsl.saturation * 0.52).clamp(0.18, 0.58))
        .toColor();
  }

  /// Picks white or near-black label color on [background] for ≥ 4.5:1 contrast.
  static Color _accessibleOnColor(Color background) {
    const Color white = Colors.white;
    const Color black = Color(0xFF1A1A1A);
    final double whiteRatio = _contrastRatio(white, background);
    final double blackRatio = _contrastRatio(black, background);
    if (whiteRatio >= blackRatio && whiteRatio >= 4.5) {
      return white;
    }
    if (blackRatio >= 4.5) {
      return black;
    }
    return whiteRatio >= blackRatio ? white : black;
  }

  static double _contrastRatio(Color foreground, Color background) {
    final double luminanceA = foreground.computeLuminance();
    final double luminanceB = background.computeLuminance();
    final double lighter = math.max(luminanceA, luminanceB);
    final double darker = math.min(luminanceA, luminanceB);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static ColorScheme _refineLightColorScheme(ColorScheme scheme) {
    final Color primary = scheme.primary;
    return scheme.copyWith(
      onPrimary: _accessibleOnColor(primary),
      onSurface: AppColors.lightInk,
      onSurfaceVariant: AppColors.lightMute,
      surface: AppColors.lightSurface,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: AppColors.lightBackground,
      surfaceContainerLow: AppColors.lightBackground,
      // Warm neutral container ramp (Pinterest). Fixed hexes — not harmonized
      // toward [primary] — so chrome stays white / #E5E5E0 / black.
      surfaceContainer: AppColors.lightSurfaceContainer,
      surfaceContainerHigh: AppColors.lightSurfaceContainerHighBase,
      surfaceContainerHighest: AppColors.lightSurfaceContainerHighestBase,
      secondary: AppColors.lightSurfaceContainerHighBase,
      onSecondary: AppColors.lightInk,
      secondaryContainer: AppColors.lightSecondaryContainer,
      onSecondaryContainer: AppColors.lightInk,
      tertiary: AppColors.lightBody,
      onTertiary: AppColors.lightSurface,
      tertiaryContainer: AppColors.lightTertiaryContainer,
      onTertiaryContainer: AppColors.lightInk,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineVariant,
      shadow: AppColors.lightShadow.withValues(alpha: 0.12),
      scrim: AppColors.lightShadow.withValues(alpha: 0.24),
    );
  }

  static ColorScheme _refineDarkColorScheme(
    ColorScheme scheme, {
    required bool trueBlack,
  }) {
    if (trueBlack) {
      return scheme.copyWith(
        surface: AppColors.darkTrueBlackSurface,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: Colors.black,
        surfaceContainer: AppColors.darkTrueBlackSurfaceContainer,
        surfaceContainerHigh: AppColors.darkTrueBlackSurfaceContainerHigh,
        surfaceContainerHighest: AppColors.darkTrueBlackSurfaceContainerHighest,
        outline: AppColors.darkOutline,
        outlineVariant: AppColors.darkTrueBlackOutlineVariant,
        shadow: Colors.black,
        scrim: Colors.black,
      );
    }

    return scheme.copyWith(
      surface: AppColors.darkSurface,
      surfaceContainerLowest: AppColors.darkSurfaceContainerLowest,
      surfaceContainerLow: AppColors.darkBackground,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceContainerHighBase,
      surfaceContainerHighest: AppColors.darkSurfaceContainerHighestBase,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      shadow: Colors.black,
      scrim: Colors.black,
    );
  }

  /// M3 switch: OFF track uses a neutral outline tint on [ColorScheme.surfaceContainerLow]
  /// instead of primary-colored `surfaceContainerHighest` (avoids a muddy lavender
  /// track when the user picks a purple or teal primary). ON/disabled tracks stay
  /// Flex defaults.
  static SwitchThemeData _switchTheme(ColorScheme colorScheme) {
    final SwitchThemeData base = FlexSubThemes.switchTheme(
      colorScheme: colorScheme,
      unselectedIsColored: false,
      useMaterial3: true,
    );
    final WidgetStateProperty<Color?>? origTrack = base.trackColor;
    if (origTrack == null) return base;

    Color offTrack({required bool interaction}) => Color.alphaBlend(
      colorScheme.outline.withValues(alpha: interaction ? 0.16 : 0.11),
      colorScheme.surfaceContainerLow,
    );

    return base.copyWith(
      trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled) ||
            states.contains(WidgetState.selected)) {
          return origTrack.resolve(states);
        }
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return offTrack(interaction: true);
        }
        return offTrack(interaction: false);
      }),
    );
  }

  static final WidgetStateProperty<Size?> _buttonMinimumTouchSize =
      WidgetStateProperty.all(
        const Size(
          kTilawaMinInteractiveDimension,
          kTilawaMinInteractiveDimension,
        ),
      );

  static ButtonStyle? _buttonStyleWithMinTouchTarget(ButtonStyle? base) {
    if (base == null) {
      return const ButtonStyle().copyWith(
        minimumSize: _buttonMinimumTouchSize,
      );
    }
    return base.copyWith(minimumSize: _buttonMinimumTouchSize);
  }

  static ThemeData _applySurfaceScale({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
  }) {
    const Color componentSurfaceTint = Colors.transparent;

    return theme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      canvasColor: scaffoldBackgroundColor,
      dividerColor: colorScheme.outlineVariant,
      cardColor: colorScheme.surface,
      switchTheme: _switchTheme(colorScheme),
      appBarTheme: theme.appBarTheme.copyWith(
        // Pinterest-style chrome: white bar, black title (vellum uses grey via
        // [TilawaAppBarChrome] when needed).
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        actionsPadding: TilawaDesignTokens.light().appBarActionsPadding,
      ),
      cardTheme: theme.cardTheme.copyWith(
        color: colorScheme.surface,
        surfaceTintColor: componentSurfaceTint,
      ),
      dialogTheme: theme.dialogTheme.copyWith(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: componentSurfaceTint,
      ),
      bottomSheetTheme: theme.bottomSheetTheme.copyWith(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: componentSurfaceTint,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyleWithMinTouchTarget(
          theme.elevatedButtonTheme.style,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyleWithMinTouchTarget(theme.filledButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyleWithMinTouchTarget(
          theme.outlinedButtonTheme.style,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _buttonStyleWithMinTouchTarget(theme.textButtonTheme.style),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: _buttonStyleWithMinTouchTarget(theme.iconButtonTheme.style),
      ),
    );
  }

  /// Get the light theme for the given primary color.
  ///
  /// [useGoogleFontsOverride] is a foundation API extension for
  /// preview/golden stability. It allows disabling font loading in headless
  /// test environments without modifying the production [useGoogleFonts] default.
  static ThemeData getLightTheme({
    required Color primaryColor,
    bool? useGoogleFontsOverride,
    List<ThemeExtension<dynamic>> extensions = const [],
  }) {
    final useFonts = useGoogleFontsOverride ?? useGoogleFonts;
    final scheme = _lightScheme(primaryColor);

    final theme = FlexThemeData.light(
      colors: scheme,
      surfaceMode: _lightSurfaceMode,
      blendLevel: _lightBlendLevel,
      appBarStyle: _lightAppBarStyle,
      appBarOpacity: _lightAppBarOpacity,
      appBarElevation: _lightAppBarElevation,
      tabBarStyle: _lightTabBarStyle,
      tooltipsMatchBackground: _tooltipsMatchBackground,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3ErrorColors: _useMaterial3ErrorColors,
      fontFamily: useFonts ? GoogleFonts.alexandria().fontFamily : null,
      textTheme: _getTextTheme(useFonts, Brightness.light),
    );
    final colorScheme = _refineLightColorScheme(theme.colorScheme);
    final themedSurfaces = _applySurfaceScale(
      theme: theme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
    );

    return themedSurfaces.copyWith(
      extensions: [
        TilawaDesignTokens.light(),
        TilawaComponentTokens.light(colorScheme: colorScheme),
        ...extensions,
      ],
    );
  }

  /// Get the dark theme for the given primary color.
  ///
  /// [useGoogleFontsOverride] is a foundation API extension for
  /// preview/golden stability. It allows disabling font loading in headless
  /// test environments without modifying the production [useGoogleFonts] default.
  static ThemeData getDarkTheme({
    required Color primaryColor,
    bool isDefaultPreset = false,
    bool? useGoogleFontsOverride,
    bool darkIsTrueBlack = false,
    List<ThemeExtension<dynamic>> extensions = const [],
  }) {
    final useFonts = useGoogleFontsOverride ?? useGoogleFonts;
    final scheme = _darkScheme(primaryColor, isDefaultPreset: isDefaultPreset);

    final theme = FlexThemeData.dark(
      colors: scheme,
      surfaceMode: _darkSurfaceMode,
      blendLevel: _darkBlendLevel,
      appBarStyle: _darkAppBarStyle,
      appBarOpacity: _darkAppBarOpacity,
      appBarElevation: _darkAppBarElevation,
      tabBarStyle: _darkTabBarStyle,
      tooltipsMatchBackground: _tooltipsMatchBackground,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3ErrorColors: _useMaterial3ErrorColors,
      fontFamily: useFonts ? GoogleFonts.alexandria().fontFamily : null,
      textTheme: _getTextTheme(useFonts, Brightness.dark),
    );
    final colorScheme = _refineDarkColorScheme(
      theme.colorScheme,
      trueBlack: darkIsTrueBlack,
    );
    final scaffoldBackgroundColor = darkIsTrueBlack
        ? colorScheme.surfaceContainerLowest
        : colorScheme.surfaceContainerLow;
    final themedSurfaces = _applySurfaceScale(
      theme: theme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
    );

    return themedSurfaces.copyWith(
      extensions: [
        TilawaDesignTokens.dark(),
        TilawaComponentTokens.dark(colorScheme: colorScheme),
        ...extensions,
      ],
    );
  }
}
