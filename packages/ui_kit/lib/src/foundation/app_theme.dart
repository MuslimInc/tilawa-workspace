import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Centralized app theme configuration
class AppTheme {
  AppTheme._();

  /// Toggle for using Google Fonts, can be disabled in tests
  static bool useGoogleFonts = true;

  // Light theme configuration constants
  static const FlexSurfaceMode _lightSurfaceMode =
      FlexSurfaceMode.levelSurfacesLowScaffold;
  static const int _lightBlendLevel = 3;
  static const FlexAppBarStyle _lightAppBarStyle = FlexAppBarStyle.surface;
  static const double _lightAppBarOpacity = 1;
  static const double _lightAppBarElevation = 0;
  static const FlexTabBarStyle _lightTabBarStyle = FlexTabBarStyle.forAppBar;

  // Dark theme configuration constants
  static const FlexSurfaceMode _darkSurfaceMode =
      FlexSurfaceMode.levelSurfacesLowScaffold;
  static const int _darkBlendLevel = 7;
  static const FlexAppBarStyle _darkAppBarStyle = FlexAppBarStyle.surface;
  static const double _darkAppBarOpacity = 1;
  static const double _darkAppBarElevation = 0;
  static const FlexTabBarStyle _darkTabBarStyle = FlexTabBarStyle.forAppBar;

  // Shared configuration constants
  static const bool _tooltipsMatchBackground = true;
  static const bool _useMaterial3ErrorColors = true;

  // Shared text theme with slightly reduced sizes for a minimized look
  static TextTheme _getTextTheme(bool useFonts) {
    // Use Alexandria if enabled, otherwise default to a standard text theme base
    if (!useFonts) return const TextTheme();
    return GoogleFonts.alexandriaTextTheme();
  }

  static FlexSchemeColor _lightScheme(Color primaryColor) {
    return FlexSchemeColor.from(
      primary: primaryColor,
      primaryContainer: const Color(0xFFD8F0EC),
      secondary: AppColors.brandSecondary,
      secondaryContainer: const Color(0xFFE4EBD5),
      tertiary: AppColors.brandTertiary,
      tertiaryContainer: const Color(0xFFF3E3BD),
      appBarColor: AppColors.lightSurface,
      error: AppColors.error,
      brightness: Brightness.light,
    );
  }

  static FlexSchemeColor _darkScheme(Color primaryColor) {
    final darkPrimary = primaryColor == AppColors.defaultPrimary
        ? const Color(0xFF70C8BD)
        : _liftForDarkTheme(primaryColor);

    return FlexSchemeColor.from(
      primary: darkPrimary,
      primaryContainer: const Color(0xFF143E39),
      primaryLightRef: primaryColor,
      secondary: const Color(0xFFB8C69A),
      secondaryContainer: const Color(0xFF2E3A28),
      secondaryLightRef: AppColors.brandSecondary,
      tertiary: const Color(0xFFD8B76C),
      tertiaryContainer: const Color(0xFF4B3B18),
      tertiaryLightRef: AppColors.brandTertiary,
      appBarColor: AppColors.darkSurface,
      error: const Color(0xFFFFB4AB),
      brightness: Brightness.dark,
    );
  }

  static Color _liftForDarkTheme(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + 0.36).clamp(0.56, 0.78))
        .withSaturation((hsl.saturation * 0.82).clamp(0.24, 0.72))
        .toColor();
  }

  static ColorScheme _refineLightColorScheme(ColorScheme scheme) {
    return scheme.copyWith(
      surface: AppColors.lightSurface,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.lightBackground,
      surfaceContainer: AppColors.lightSurfaceContainer,
      surfaceContainerHigh: const Color(0xFFEAE6DC),
      surfaceContainerHighest: const Color(0xFFE2DDD1),
      outline: AppColors.lightOutline,
      outlineVariant: const Color(0xFFE6DED0),
      shadow: const Color(0xFF1F2926),
      scrim: const Color(0xFF1F2926),
    );
  }

  static ColorScheme _refineDarkColorScheme(ColorScheme scheme) {
    return scheme.copyWith(
      surface: AppColors.darkSurface,
      surfaceContainerLowest: const Color(0xFF0B1210),
      surfaceContainerLow: AppColors.darkBackground,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: const Color(0xFF24332F),
      surfaceContainerHighest: const Color(0xFF2D3E39),
      outline: AppColors.darkOutline,
      outlineVariant: const Color(0xFF2F3E39),
      shadow: Colors.black,
      scrim: Colors.black,
    );
  }

  /// Get the light theme for the given primary color.
  ///
  /// [useGoogleFontsOverride] is a foundation API extension for
  /// preview/golden stability. It allows disabling font loading in headless
  /// test environments without modifying the production [useGoogleFonts] default.
  ///
  /// [density] controls the overall UI density. Defaults to [TilawaDensity.comfortable]
  /// which matches all pre-density UI Kit values.
  static ThemeData getLightTheme({
    required Color primaryColor,
    bool? useGoogleFontsOverride,
    TilawaDensity density = TilawaDensity.comfortable,
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
      textTheme: _getTextTheme(useFonts),
    );
    final colorScheme = _refineLightColorScheme(theme.colorScheme);

    return theme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightBackground,
      dividerColor: colorScheme.outlineVariant,
      cardColor: colorScheme.surface,
      extensions: [
        TilawaDesignTokens.light(density: density),
        TilawaComponentTokens.light(density: density),
        ...extensions,
      ],
    );
  }

  /// Get the dark theme for the given primary color.
  ///
  /// [useGoogleFontsOverride] is a foundation API extension for
  /// preview/golden stability. It allows disabling font loading in headless
  /// test environments without modifying the production [useGoogleFonts] default.
  ///
  /// [density] controls the overall UI density. Defaults to [TilawaDensity.comfortable]
  /// which matches all pre-density UI Kit values.
  static ThemeData getDarkTheme({
    required Color primaryColor,
    bool? useGoogleFontsOverride,
    bool darkIsTrueBlack = false,
    TilawaDensity density = TilawaDensity.comfortable,
    List<ThemeExtension<dynamic>> extensions = const [],
  }) {
    final useFonts = useGoogleFontsOverride ?? useGoogleFonts;
    final scheme = _darkScheme(primaryColor);

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
      textTheme: _getTextTheme(useFonts),
    );
    final colorScheme = _refineDarkColorScheme(theme.colorScheme);

    return theme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      dividerColor: colorScheme.outlineVariant,
      cardColor: colorScheme.surface,
      extensions: [
        TilawaDesignTokens.dark(density: density),
        TilawaComponentTokens.dark(density: density),
        ...extensions,
      ],
    );
  }
}
