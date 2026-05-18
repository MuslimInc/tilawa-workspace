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

/// Fixed “studio” palette for the **share audio / reel composer** (dark
/// gradient shell). Intentionally **not** derived from [ColorScheme] — a
/// documented exception to DESIGN.md §9 for cohesive marketing-style UI.
abstract final class AppShareComposerColors {
  static const Color deepGreen = Color(0xFF0D3933);
  static const Color forestGreen = Color(0xFF165147);
  static const Color gold = Color(0xFFE1C17B);
  static const Color mint = Color(0xFF8FDFC0);
  static const Color cream = Color(0xFFF7F1E1);

  /// Error callout background (composer-only).
  static const Color feedbackErrorBackground = Color(0xFF5B1F1F);

  /// Error callout border / icon tint (composer-only).
  static const Color feedbackErrorOutline = Color(0xFFFFB4AB);
}

/// Poster gradient shell for multi-surah **page passage** share cards.
///
/// Greens are tuned for this variant (slightly different from
/// [AppShareComposerColors]); [gold], [mint], and [parchment] match the share
/// composer palette for consistency across share surfaces.
abstract final class AppPagePassagePosterColors {
  static const Color deepGreen = Color(0xFF0B342E);
  static const Color forestGreen = Color(0xFF145247);

  static const Color gold = AppShareComposerColors.gold;
  static const Color mint = AppShareComposerColors.mint;
  static const Color parchment = AppShareComposerColors.cream;

  /// Warmer secondary stop in the parchment gradient.
  static const Color warmParchment = Color(0xFFEFE1C2);
}

/// Default colors for **static export** screenshots (e.g. branded Quran page PNG
/// footer). Not for in-scaffold UI.
abstract final class AppExportScreenshotColors {
  static const Color footerBackground = Color(0xFF1B4060);
  static const Color footerForeground = Color(0xFFFFFFFF);
}

/// Fallback reel frame colors when the app does not build a
/// theme-derived palette. Prefer runtime [ColorScheme] / reader theme in
/// product paths; these preserve legacy mushaf-inspired defaults for tests.
abstract final class AppVideoReelDesignDefaults {
  static const Color mushafBackgroundColor = Color(0xFFFFF8ED);
  static const Color mushafTextColor = Color(0xF52E2116);
  static const Color verseHighlightColor = Color(0x3DF57C00);
  static const Color frameTextColor = Color(0xFF6B5B4F);
  static const Color frameSecondaryTextColor = Color(0xFF8B7355);
  static const Color frameStrongTextColor = Color(0xFF5D4037);
  static const Color frameAccentColor = Color(0xFFC5A358);
  static const Color frameSurfaceColor = Color(0xFFFFF9F2);
}

/// Legacy static palette for [QuranReaderTheme] light/dark defaults in the app.
///
/// The reader resolves most chrome from [ColorScheme] at runtime via
/// `QuranReaderTheme.fromTheme`; these values preserve the historical presets
/// for the static `QuranReaderTheme.light` / `.dark` extensions.
abstract final class AppQuranReaderLegacyColors {
  // --- Light ---

  static const Color lightPageBackground = Color(0xFFFFF9F1);
  static const Color lightOnSurface = Color(0xFF000000);
  static const Color lightPrimary = Color(0xFF8B6B23);
  static const Color lightHeaderBackground = Color(0xFFF4EAD2);
  static const Color lightSystemBar = Color(0xFFFFF9F1);

  /// ~60% black — slider range labels and secondary reader text.
  static const Color lightMutedOnSurface = Color(0x99000000);

  // --- Dark ---

  static const Color darkPageBackground = Color(0xFF0E0E0E);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkPrimary = Color(0xFF9E9E9E);
  static const Color darkHeaderBackground = Color(0xFF1A1A1A);
  static const Color darkHeaderOnSurface = Color(0xE6FFFFFF);
  static const Color darkSystemBar = Color(0xFF0E0E0E);

  /// Muted caption gray for slider range in dark mode.
  static const Color darkMutedCaption = Color(0xA6E0E0E0);

  static const Color darkPillSurah = Color(0xFFE0E0E0);
  static const Color darkSurahTileName = Color(0xFFE0E0E0);

  /// Accent for Arabic surah names on tiles in dark reader preset.
  static const Color darkArabicAccent = Color(0xFFD4AF37);
}
