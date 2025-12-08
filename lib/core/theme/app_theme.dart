import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

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
  static ThemeData getLightTheme(FlexScheme scheme) {
    return FlexThemeData.light(
      scheme: scheme,
      surfaceMode: _lightSurfaceMode,
      blendLevel: _lightBlendLevel,
      appBarStyle: _lightAppBarStyle,
      appBarOpacity: _lightAppBarOpacity,
      appBarElevation: _lightAppBarElevation,
      tabBarStyle: _lightTabBarStyle,
      tooltipsMatchBackground: _tooltipsMatchBackground,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3ErrorColors: _useMaterial3ErrorColors,
    );
  }

  /// Get the dark theme for the given color scheme
  static ThemeData getDarkTheme(FlexScheme scheme) {
    return FlexThemeData.dark(
      scheme: scheme,
      surfaceMode: _darkSurfaceMode,
      blendLevel: _darkBlendLevel,
      appBarStyle: _darkAppBarStyle,
      appBarOpacity: _darkAppBarOpacity,
      appBarElevation: _darkAppBarElevation,
      tabBarStyle: _darkTabBarStyle,
      tooltipsMatchBackground: _tooltipsMatchBackground,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3ErrorColors: _useMaterial3ErrorColors,
    );
  }

  /// Get available color schemes for the app
  static List<FlexScheme> getAvailableSchemes() {
    return [FlexScheme.green];
  }
}
