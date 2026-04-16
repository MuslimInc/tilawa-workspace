import 'package:flutter/material.dart';

/// Color design tokens for the application.
///
/// All colors are defined as Color constants for consistency.
class AppColors {
  // Prevent instantiation
  AppColors._();

  /// Primary colors
  static const Color primary = Color(0xFF8B6914);
  static const Color primaryLight = Color(0xFFB8956A);
  static const Color primaryDark = Color(0xFF5C440E);

  /// Background colors
  static const Color pageBackground = Color(0xFFFFF9F2);
  static const Color sliderBackground = Color(0xFFFFFFFF);
  static const Color sliderBackgroundDark = Color(0xFF2D2D2D);

  /// Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Marker colors
  static const Color markerBorder = Color(0xFF8B6914);
  static const Color markerBackground = Color(0xFFF5ECD8);
  static const Color markerNumber = Color(0xFF5C440E);

  /// UI element colors
  static const Color shadow = Color(0x40000000);
  static const Color overlay = Color(0x80000000);
  static const Color divider = Color(0xFFE0E0E0);

  /// Slider specific colors
  static const Color sliderTrack = Color(0xFFE0E0E0);
  static const Color sliderActiveTrack = Color(0xFF8B6914);
  static const Color sliderThumb = Color(0xFF8B6914);
  static const Color sliderThumbBorder = Color(0xFFFFFFFF);
}
