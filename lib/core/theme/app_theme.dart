import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized app theme configuration
class AppTheme {
  AppTheme._();

  // Light theme configuration constants
  static const FlexSurfaceMode _lightSurfaceMode =
      FlexSurfaceMode.levelSurfacesLowScaffold;
  static const int _lightBlendLevel = 7;
  static const FlexAppBarStyle _lightAppBarStyle = FlexAppBarStyle.primary;
  static const double _lightAppBarOpacity = 0.95;
  static const double _lightAppBarElevation = 0;
  static const FlexTabBarStyle _lightTabBarStyle = FlexTabBarStyle.forAppBar;

  // Custom theme colors
  static const Color _primaryColor = Color(0xFF1AADC5);
  static final FlexSchemeColor _customScheme = FlexSchemeColor.from(
    primary: _primaryColor,
    secondary: _primaryColor,
  );

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

  /// Get the light theme for the given color scheme
  static ThemeData getLightTheme(FlexScheme? scheme) {
    return FlexThemeData.light(
      colors: _customScheme,
      surfaceMode: _lightSurfaceMode,
      blendLevel: _lightBlendLevel,
      appBarStyle: _lightAppBarStyle,
      appBarOpacity: _lightAppBarOpacity,
      appBarElevation: _lightAppBarElevation,
      tabBarStyle: _lightTabBarStyle,
      tooltipsMatchBackground: _tooltipsMatchBackground,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3ErrorColors: _useMaterial3ErrorColors,
      fontFamily: GoogleFonts.alexandria().fontFamily,
    );
  }

  /// Get the dark theme for the given color scheme
  static ThemeData getDarkTheme(FlexScheme? scheme) {
    return FlexThemeData.dark(
      colors: _customScheme,
      surfaceMode: _darkSurfaceMode,
      blendLevel: _darkBlendLevel,
      appBarStyle: _darkAppBarStyle,
      appBarOpacity: _darkAppBarOpacity,
      appBarElevation: _darkAppBarElevation,
      tabBarStyle: _darkTabBarStyle,
      tooltipsMatchBackground: _tooltipsMatchBackground,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3ErrorColors: _useMaterial3ErrorColors,
      fontFamily: GoogleFonts.alexandria().fontFamily,
    );
  }

  /// Get available color schemes for the app
  static List<FlexScheme> getAvailableSchemes() {
    return [FlexScheme.green];
  }
}
