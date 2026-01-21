import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Custom theme colors

  // Dark theme configuration constants
  static const FlexSurfaceMode _darkSurfaceMode =
      FlexSurfaceMode.levelSurfacesLowScaffold;
  static const int _darkBlendLevel = 13;
  static const FlexAppBarStyle _darkAppBarStyle = FlexAppBarStyle.background;
  static const double _darkAppBarOpacity = 0.90;
  static const double _darkAppBarElevation = 0;
  static const FlexTabBarStyle _darkTabBarStyle = FlexTabBarStyle.forAppBar;

  // Shared configuration constants
  static const bool _tooltipsMatchBackground = true;
  static const bool _useMaterial3ErrorColors = true;

  /// Get the light theme for the given primary color
  static ThemeData getLightTheme({required Color primaryColor}) {
    final scheme = FlexSchemeColor.from(
      primary: primaryColor,
      secondary: primaryColor,
    );

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
      fontFamily: useGoogleFonts ? GoogleFonts.alexandria().fontFamily : null,
    );
  }

  /// Get the dark theme for the given primary color
  static ThemeData getDarkTheme({
    required Color primaryColor,
    bool darkIsTrueBlack = false,
  }) {
    final scheme = FlexSchemeColor.from(
      primary: primaryColor,
      secondary: primaryColor,
    );

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
      fontFamily: useGoogleFonts ? GoogleFonts.alexandria().fontFamily : null,
    );
  }
}
