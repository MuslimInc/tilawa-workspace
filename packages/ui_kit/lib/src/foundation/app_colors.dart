import 'package:flutter/material.dart';

/// Centralized app color constants
///
/// All app colors should be defined here to maintain consistency
/// and make it easy to update colors across the app.
abstract final class AppColors {
  // Primary colors
  /// Default primary color (deep teal).
  static const Color primaryTeal = Color(0xFF0F766E);

  /// Teal/cyan compatibility theme option.
  static const Color primaryCyan = primaryTeal;

  /// Sage theme option.
  static const Color primarySage = Color(0xFF6F7F58);

  /// Muted gold theme option.
  static const Color primaryGold = Color(0xFFB88A2E);

  /// Warm brown theme option.
  static const Color primaryBrown = Color(0xFF7B5E3B);

  /// Green theme option.
  static const Color primaryGreen = primarySage;

  /// Purple theme option retained for saved theme compatibility.
  static const Color primaryPurple = Color(0xFF7A5C89);

  /// Default primary color used throughout the app
  static const Color defaultPrimary = primaryTeal;

  // Brand color roles
  /// Secondary brand color for calm supporting accents.
  static const Color brandSecondary = primarySage;

  /// Tertiary brand color for respectful Quran/prayer highlights.
  static const Color brandTertiary = primaryGold;

  /// Light app background.
  static const Color lightBackground = Color(0xFFF8F7F2);

  /// Light default surface.
  static const Color lightSurface = Color(0xFFFFFCF7);

  /// Light elevated/contained surface.
  static const Color lightSurfaceContainer = Color(0xFFF1EEE6);

  /// Light outline/divider color.
  static const Color lightOutline = Color(0xFFD6CEC0);

  /// Dark app background.
  static const Color darkBackground = Color(0xFF101816);

  /// Dark default surface.
  static const Color darkSurface = Color(0xFF16201D);

  /// Dark elevated/contained surface.
  static const Color darkSurfaceContainer = Color(0xFF1C2925);

  /// Dark outline/divider color.
  static const Color darkOutline = Color(0xFF3B4A45);

  // Status colors
  /// Error/failure color
  static const Color error = Color(0xFFE53935);

  /// Success color
  static const Color success = Color(0xFF43A047);

  /// Warning color
  static const Color warning = Color(0xFFFFA000);

  // Settings Category Colors
  /// Color for theme settings
  static const Color settingsTheme = Color(0xFF2196F3);

  /// Color for color picker settings
  static const Color settingsColor = Color(0xFF009688);

  /// Color for language settings
  static const Color settingsLanguage = Color(0xFF3F51B5);

  /// Color for playback settings
  static const Color settingsPlayback = Color(0xFF00BCD4);

  /// Color for duration settings
  static const Color settingsDuration = Color(0xFFF4511E);

  /// Color for bookmarks settings
  static const Color settingsBookmarks = Color(0xFFFFC107);

  /// Color for history settings
  static const Color settingsHistory = Color(0xFF673AB7);

  /// Color for prayer times settings
  static const Color settingsPrayer = Color(0xFF03A9F4);

  /// Color for Quran reader settings
  static const Color settingsQuran = Color(0xFF607D8B);

  /// Color for storage settings
  static const Color settingsStorage = Color(0xFFFB8C00);

  /// Color for downloads settings
  static const Color settingsDownloads = Color(0xFF4CAF50);

  // Notification colors
  /// Color used for notification icons and accents
  static const Color notificationAccent = primaryTeal;

  // Settings UI Colors
  /// Gradient start color for profile card
  static const Color profileGradientStart = primaryTeal;

  /// Gradient end color for profile card
  static const Color profileGradientEnd = Color(0xFF0D5F59);

  /// Background color for logout button card (light theme)
  static const Color logoutBackground = Color(0xFFFFF1F0);

  /// Subtle shadow color for settings cards
  static const Color settingsCardShadow = Color(0x0A000000);

  /// Color for settings dividers
  static const Color divider = lightOutline;
}
