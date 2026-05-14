import 'package:flutter/material.dart';

/// Centralized app color constants.
///
/// The Tilawa palette is intentionally **small and calm**:
/// one brand accent (user-selectable), a quiet neutral surface ramp,
/// and a handful of semantic colors. Decorative tones, parallel "category
/// hues", and gradient stops have been removed so the UI feels premium
/// without competing with content.
///
/// All hex values used by `AppTheme` to assemble `ColorScheme` live here
/// so there is exactly one source of truth. Product widgets should read
/// from `ColorScheme` / `TilawaComponentTokens`, not from this file
/// directly (see `docs/design/colors.md`).
abstract final class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand presets — user-selectable primary tones.
  // ---------------------------------------------------------------------------

  /// Default primary / brand teal-cyan.
  ///
  /// Matches Android `launch_background` in `apps/tilawa/android/.../colors.xml`
  /// (`#1AADC5`) so the native splash frame and `defaultPrimary` align.
  static const Color primaryTeal = Color(0xFF1AADC5);

  /// Teal/cyan compatibility alias retained for saved theme migration.
  static const Color primaryCyan = primaryTeal;

  /// Sage theme option — calm, scholarly green.
  static const Color primarySage = Color(0xFF6F7F58);

  /// Muted gold theme option — Mushaf-inspired warm accent.
  static const Color primaryGold = Color(0xFF8C681F);

  /// Warm brown theme option.
  static const Color primaryBrown = Color(0xFF7B5E3B);

  /// Green alias retained for saved theme migration.
  static const Color primaryGreen = primarySage;

  /// Purple alias retained for saved theme migration.
  static const Color primaryPurple = Color(0xFF7A5C89);

  /// Default primary color used throughout the app.
  static const Color defaultPrimary = primaryTeal;

  // ---------------------------------------------------------------------------
  // Light neutral ramp — quiet, near-monochrome surfaces.
  // ---------------------------------------------------------------------------

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Light elevated/contained surface (near-white neutral).
  static const Color lightSurfaceContainer = Color(0xFFF4F4F4);

  /// Upper elevation tier (e.g. bottom nav chrome) before light-theme primary
  /// harmonization in [AppTheme].
  static const Color lightSurfaceContainerHighBase = Color(0xFFEFEFEF);

  /// Top elevation tier before light-theme primary harmonization in [AppTheme].
  static const Color lightSurfaceContainerHighestBase = Color(0xFFE8E8E8);

  /// Light outline/divider color. Calibrated for visibility on real-device
  /// DPIs (~400 ppi); avoid going lighter than this.
  static const Color lightOutline = Color(0xFFC0C0C0);

  // ---------------------------------------------------------------------------
  // Dark neutral ramp.
  // ---------------------------------------------------------------------------

  static const Color darkBackground = Color(0xFF101816);
  static const Color darkSurface = Color(0xFF16201D);
  static const Color darkSurfaceContainer = Color(0xFF1C2925);

  /// Dark upper container tier **base** before optional primary harmonization
  /// in [AppTheme].
  static const Color darkSurfaceContainerHighBase = Color(0xFF2A3A35);

  /// Dark top container tier **base** before optional primary harmonization
  /// in [AppTheme].
  static const Color darkSurfaceContainerHighestBase = Color(0xFF34463F);

  /// Dark [ColorScheme] error tone for Material dark scheme.
  static const Color darkSchemeError = Color(0xFFFFB4AB);

  /// Dark outline/divider color. Calibrated for visibility on real-device
  /// DPIs (~400 ppi); avoid going darker than this.
  static const Color darkOutline = Color(0xFF4B5B55);

  // ---------------------------------------------------------------------------
  // AppTheme — light Flex scheme refinement.
  // ---------------------------------------------------------------------------

  /// Historical reference: hand-tuned light primary container for the default
  /// teal preset. [AppTheme] derives `ColorScheme.primaryContainer` from the
  /// selected primary instead; unused at runtime.
  static const Color lightDefaultPrimaryContainer = Color(0xFFD8F0EC);

  static const Color lightSecondaryContainer = Color(0xFFE4EBD5);
  static const Color lightTertiaryContainer = Color(0xFFF0F4F3);
  static const Color lightSurfaceContainerMid = Color(0xFFF6F6F6);
  static const Color lightOutlineVariant = Color(0xFFE8E8E8);
  static const Color lightShadow = Color(0xFF1F2926);

  // ---------------------------------------------------------------------------
  // AppTheme — dark Flex scheme refinement.
  // ---------------------------------------------------------------------------

  /// Lighter screen of [primaryTeal] for contrast on dark surfaces.
  static const Color darkDefaultPrimary = Color(0xFF5DD3EB);

  /// Historical reference: dark primary container paired with
  /// [darkDefaultPrimary]. [AppTheme] derives it from selected primary instead.
  static const Color darkDefaultPrimaryContainer = Color(0xFF143E39);

  static const Color darkSecondary = Color(0xFFB8C69A);
  static const Color darkSecondaryContainer = Color(0xFF2E3A28);
  static const Color darkTertiary = Color(0xFFD8B76C);
  static const Color darkTertiaryContainer = Color(0xFF4B3B18);

  // ---------------------------------------------------------------------------
  // True-black mode (OLED-friendly dark refinement).
  // ---------------------------------------------------------------------------

  static const Color darkTrueBlackSurface = Color(0xFF050807);
  static const Color darkTrueBlackSurfaceContainer = Color(0xFF080D0B);
  static const Color darkTrueBlackSurfaceContainerHigh = Color(0xFF101714);
  static const Color darkTrueBlackSurfaceContainerHighest = Color(0xFF19211D);
  static const Color darkTrueBlackOutlineVariant = Color(0xFF2B3934);

  // ---------------------------------------------------------------------------
  // AppTheme — dark refinement (non-true-black).
  // ---------------------------------------------------------------------------

  static const Color darkSurfaceContainerLowest = Color(0xFF0B1210);
  static const Color darkOutlineVariant = Color(0xFF2F3E39);

  // ---------------------------------------------------------------------------
  // Semantic colors — meaning, not decoration.
  // ---------------------------------------------------------------------------

  /// Error / failure.
  static const Color error = Color(0xFFE53935);

  /// Success.
  static const Color success = Color(0xFF43A047);

  /// Warning.
  static const Color warning = Color(0xFFFFA000);

  // ---------------------------------------------------------------------------
  // Platform-fixed accents — used outside Flutter's `ColorScheme`
  // (Android notification channels) where reading the theme is not possible.
  // ---------------------------------------------------------------------------

  /// Static accent for system notification icons. Notifications render in the
  /// OS shade and cannot resolve runtime theme; this constant locks the brand
  /// tone so notification chrome stays recognisable.
  static const Color notificationAccent = primaryTeal;

  /// Brand secondary used by FlexColorScheme assembly only.
  static const Color brandSecondary = Color(0xFF65734F);

  /// Brand tertiary used by FlexColorScheme assembly only.
  static const Color brandTertiary = primaryGold;
}
