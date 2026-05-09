import 'package:flutter/material.dart';

/// Centralized app color constants
///
/// All app colors should be defined here to maintain consistency
/// and make it easy to update colors across the app.
abstract final class AppColors {
  AppColors._();

  // Primary colors
  /// Default primary color (deep teal).
  static const Color primaryTeal = Color(0xFF0F766E);

  /// Teal/cyan compatibility theme option.
  static const Color primaryCyan = primaryTeal;

  /// Sage theme option.
  static const Color primarySage = Color(0xFF6F7F58);

  /// Muted gold theme option.
  static const Color primaryGold = Color(0xFF8C681F);

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
  static const Color brandSecondary = Color(0xFF65734F);

  /// Tertiary brand color for respectful Quran/prayer highlights.
  static const Color brandTertiary = primaryGold;

  /// Light app background.
  static const Color lightBackground = Color(0xFFF8F7F2);

  /// Light default surface.
  static const Color lightSurface = Color(0xFFFFFCF7);

  /// Light elevated/contained surface.
  static const Color lightSurfaceContainer = Color(0xFFF1EEE6);

  /// Upper elevation tier (e.g. bottom nav chrome) before light-theme primary
  /// harmonization in [AppTheme].
  static const Color lightSurfaceContainerHighBase = Color(0xFFE2DBC7);

  /// Top elevation tier before light-theme primary harmonization in [AppTheme].
  static const Color lightSurfaceContainerHighestBase = Color(0xFFD7CFB9);

  /// Light outline/divider color. Calibrated for visibility on real-device
  /// DPIs (~400 ppi); avoid going lighter than this.
  static const Color lightOutline = Color(0xFFC8BDA8);

  /// Dark app background.
  static const Color darkBackground = Color(0xFF101816);

  /// Dark default surface.
  static const Color darkSurface = Color(0xFF16201D);

  /// Dark elevated/contained surface.
  static const Color darkSurfaceContainer = Color(0xFF1C2925);

  /// Dark upper container tier **base** before optional primary harmonization in
  /// [AppTheme]. Same value as stable dark bottom nav chrome in kit tokens.
  static const Color darkSurfaceContainerHighBase = Color(0xFF2A3A35);

  /// Dark top container tier **base** before optional primary harmonization in
  /// [AppTheme].
  static const Color darkSurfaceContainerHighestBase = Color(0xFF34463F);

  /// Dark [ColorScheme] error tone used in [AppTheme] dark Flex scheme (Material
  /// dark error), distinct from [error] used for light scheme / UI semantics.
  static const Color darkSchemeError = Color(0xFFFFB4AB);

  /// Dark outline/divider color. Calibrated for visibility on real-device
  /// DPIs (~400 ppi); avoid going darker than this.
  static const Color darkOutline = Color(0xFF4B5B55);

  // --- AppTheme: light FlexSchemeColor / refinement (single source of truth) ---

  /// Historical reference: hand-tuned light primary container for the default
  /// teal preset. [AppTheme] derives `ColorScheme.primaryContainer` from the
  /// selected primary instead; unused at runtime.
  static const Color lightDefaultPrimaryContainer = Color(0xFFD8F0EC);

  /// Light [FlexSchemeColor.secondaryContainer].
  static const Color lightSecondaryContainer = Color(0xFFE4EBD5);

  /// Light [FlexSchemeColor.tertiaryContainer].
  static const Color lightTertiaryContainer = Color(0xFFF3E3BD);

  /// Light [ColorScheme.surfaceContainer] base before primary harmonization.
  static const Color lightSurfaceContainerMid = Color(0xFFEBE6D7);

  /// Light [ColorScheme.outlineVariant] after refinement.
  static const Color lightOutlineVariant = Color(0xFFE6DED0);

  /// Light [ColorScheme.shadow] and [ColorScheme.scrim].
  static const Color lightShadow = Color(0xFF1F2926);

  // --- AppTheme: dark FlexSchemeColor (single source of truth) ---

  /// Dark preset primary on surface when [isDefaultPreset] (Flex dark scheme).
  static const Color darkDefaultPrimary = Color(0xFF70C8BD);

  /// Historical reference: dark primary container paired with [darkDefaultPrimary].
  /// [AppTheme] derives `ColorScheme.primaryContainer` from the selected primary
  /// instead; unused at runtime.
  static const Color darkDefaultPrimaryContainer = Color(0xFF143E39);

  /// Dark [FlexSchemeColor.secondary].
  static const Color darkSecondary = Color(0xFFB8C69A);

  /// Dark [FlexSchemeColor.secondaryContainer].
  static const Color darkSecondaryContainer = Color(0xFF2E3A28);

  /// Dark [FlexSchemeColor.tertiary].
  static const Color darkTertiary = Color(0xFFD8B76C);

  /// Dark [FlexSchemeColor.tertiaryContainer].
  static const Color darkTertiaryContainer = Color(0xFF4B3B18);

  // --- AppTheme: true-black dark refinement ---

  /// True-black mode [ColorScheme.surface].
  static const Color darkTrueBlackSurface = Color(0xFF050807);

  /// True-black mode [ColorScheme.surfaceContainer].
  static const Color darkTrueBlackSurfaceContainer = Color(0xFF080D0B);

  /// True-black mode [ColorScheme.surfaceContainerHigh].
  static const Color darkTrueBlackSurfaceContainerHigh = Color(0xFF101714);

  /// True-black mode [ColorScheme.surfaceContainerHighest].
  static const Color darkTrueBlackSurfaceContainerHighest = Color(0xFF19211D);

  /// True-black mode [ColorScheme.outlineVariant].
  static const Color darkTrueBlackOutlineVariant = Color(0xFF2B3934);

  // --- AppTheme: dark refinement (non-true-black) ---

  /// Dark [ColorScheme.surfaceContainerLowest] after refinement.
  static const Color darkSurfaceContainerLowest = Color(0xFF0B1210);

  /// Dark [ColorScheme.outlineVariant] after refinement.
  static const Color darkOutlineVariant = Color(0xFF2F3E39);

  // Status colors
  /// Error/failure color
  static const Color error = Color(0xFFE53935);

  /// Success color
  static const Color success = Color(0xFF43A047);

  /// Warning color
  static const Color warning = Color(0xFFFFA000);

  // Settings Category Colors
  /// Color for theme settings
  static const Color settingsTheme = primaryTeal;

  /// Color for color picker settings
  static const Color settingsColor = Color(0xFF2D8C80);

  /// Color for language settings
  static const Color settingsLanguage = Color(0xFF5E6F82);

  /// Color for playback settings
  static const Color settingsPlayback = Color(0xFF4F8F8A);

  /// Color for duration settings
  static const Color settingsDuration = Color(0xFF9D6B3A);

  /// Color for bookmarks settings
  static const Color settingsBookmarks = primaryGold;

  /// Color for history settings
  static const Color settingsHistory = primaryPurple;

  /// Color for prayer times settings
  static const Color settingsPrayer = Color(0xFF3D7D73);

  /// Color for Quran reader settings
  static const Color settingsQuran = Color(0xFF8B6F47);

  /// Color for storage settings
  static const Color settingsStorage = Color(0xFF9C7A3E);

  /// Color for downloads settings
  static const Color settingsDownloads = primarySage;

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
