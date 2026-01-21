import 'package:flutter/material.dart';

/// Centralized app color constants
///
/// All app colors should be defined here to maintain consistency
/// and make it easy to update colors across the app.
abstract final class AppColors {
  // Primary colors
  /// Default primary color (Cyan/Teal)
  static const Color primaryCyan = Color(0xFF1AADC5);

  /// Green theme option
  static const Color primaryGreen = Color(0xFF4CAF50);

  /// Brown theme option
  static const Color primaryBrown = Color(0xFF795548);

  /// Purple theme option
  static const Color primaryPurple = Color(0xFF9C27B0);

  /// Default primary color used throughout the app
  static const Color defaultPrimary = primaryCyan;

  // Status colors
  /// Error/failure color
  static const Color error = Colors.red;

  /// Success color
  static const Color success = Color(0xFF4CAF50);

  /// Warning color
  static const Color warning = Color(0xFFFFC107);

  // Notification colors
  /// Color used for notification icons and accents
  static const Color notificationAccent = primaryCyan;
}
