import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  static const int _lightBlendLevel = 7;
  static const FlexAppBarStyle _lightAppBarStyle = FlexAppBarStyle.primary;
  static const double _lightAppBarOpacity = 0.95;
  static const double _lightAppBarElevation = 0;
  static const FlexTabBarStyle _lightTabBarStyle = FlexTabBarStyle.forAppBar;

  // Dark theme configuration constants
  static const FlexSurfaceMode _darkSurfaceMode =
      FlexSurfaceMode.levelSurfacesLowScaffold;
  static const int _darkBlendLevel = 13;
  static const FlexAppBarStyle _darkAppBarStyle = FlexAppBarStyle.primary;
  static const double _darkAppBarOpacity = 0.90;
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
    final scheme = FlexSchemeColor.from(primary: primaryColor);

    return FlexThemeData.light(
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
    ).copyWith(
      extensions: [
        TilawaDesignTokens.light(),
        TilawaComponentTokens.light(),
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
    bool? useGoogleFontsOverride,
    bool darkIsTrueBlack = false,
    List<ThemeExtension<dynamic>> extensions = const [],
  }) {
    final useFonts = useGoogleFontsOverride ?? useGoogleFonts;
    final scheme = FlexSchemeColor.from(primary: primaryColor);

    return FlexThemeData.dark(
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
    ).copyWith(
      extensions: [
        TilawaDesignTokens.dark(),
        TilawaComponentTokens.dark(),
        ...extensions,
      ],
    );
  }
}
