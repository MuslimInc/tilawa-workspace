import 'package:flutter/material.dart';

/// Centralized app color constants.
///
/// The Tilawa palette is intentionally **small and calm**:
/// one **brand-locked** accent ([primarySage] `#219653`), a quiet cool
/// neutral surface ramp anchored on [lightSurfaceContainerHighBase]
/// `#E5E7EB`, and a handful of semantic colors. Decorative tones, parallel
/// "category hues", and most decorative gradients have been removed so the UI
/// feels premium without competing with content. The launch flow keeps a
/// dedicated brand gradient via [brandGradientTop] → [brandGradientBottom].
///
/// **Brand lock.** As of the Islamic-brand initiative, the runtime primary
/// is fixed to Sage (`#219653`) for production builds. The other preset
/// hexes (`primaryCoral`, `primaryTeal`, `primaryGold`, `primaryBrown`,
/// `primaryPurple`) are retained for two reasons: (1) the in-Settings color
/// picker remains available behind `--dart-define=TILAWA_SHOW_COLOR_PICKER=true`
/// for dev/QA palette work, and (2) legacy persisted user choices still need
/// to deserialize without throwing. The runtime override lives in
/// `apps/tilawa/lib/features/theme/presentation/theme_state_material.dart`.
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

  /// Legacy Pinterest-inspired brand red (`#E60023`).
  ///
  /// Retained so previously-stored user theme choices still deserialize and
  /// so dev/QA builds with `--dart-define=TILAWA_SHOW_COLOR_PICKER=true` can
  /// still preview it. Not used by production runtime; see the class-level
  /// docstring for the brand lock.
  static const Color primaryCoral = Color(0xFFE60023);

  /// Legacy brand teal-cyan (still available in Settings).
  static const Color primaryTeal = Color(0xFF1AADC5);

  /// Teal/cyan compatibility alias retained for saved theme migration.
  static const Color primaryCyan = primaryTeal;

  /// Sage — the brand-locked Islamic accent ("scholar's cloth").
  ///
  /// This is the default runtime primary and the bottom stop of the launch
  /// gradient.
  static const Color primarySage = Color(0xFF219653);

  /// Forest green theme option (dev/QA picker; not gold).
  static const Color primaryGold = Color(0xFF2D6B47);

  /// Warm brown theme option.
  static const Color primaryBrown = Color(0xFF7B5E3B);

  /// Green alias retained for saved theme migration.
  static const Color primaryGreen = primarySage;

  /// Purple alias retained for saved theme migration.
  static const Color primaryPurple = Color(0xFF7A5C89);

  /// Default primary color used throughout the app.
  ///
  /// Brand-locked to [primarySage] per the Islamic-brand initiative. See the
  /// class-level docstring for how the legacy presets are still wired for
  /// dev/QA and persistence-compatibility purposes.
  static const Color defaultPrimary = primarySage;

  /// Top stop for the brand launch gradient.
  static const Color brandGradientTop = Color(0xFF447339);

  /// Bottom stop for the brand launch gradient.
  static const Color brandGradientBottom = defaultPrimary;

  /// Launch / splash canvas — matches adaptive icon background (`#219653`).
  static const Color launchSplashBackground = primarySage;

  /// Wordmark and progress on launch surfaces (`#FFFFFF`).
  static const Color launchSplashForeground = Color(0xFFFFFFFF);

  /// Logo box on Flutter launch surfaces — must match Android
  /// `@dimen/splash_logo_size` (288dp) and `splash_icon` drawable.
  static const double launchSplashLogoSize = 288;

  // ---------------------------------------------------------------------------
  // Light neutral ramp — cool porcelain canvas + white cards
  // (#F4F5F7 / #FFFFFF / slate ink). One temperature family end-to-end:
  // the ramp matches the slate [lightInk] / [lightOutline] that were always
  // cool. Do not mix warm and cool tones in adjacent light fills.
  // ---------------------------------------------------------------------------

  /// App canvas / scaffold — cool porcelain (`#F4F5F7`, noon/Apple-style).
  ///
  /// Replaced the warm Chaptrs cream (`#F9F7F2`, 2026-06-11): the cream read
  /// as dated paper next to white cards; a cool near-white gives the crisp
  /// commercial feel and matches the slate ink family. Same lightness, so
  /// every contrast pairing is unchanged.
  ///
  /// The page rests on this tone; cards, sheets, and app bars use
  /// [lightSurface] (`#FFFFFF`) for quiet lift without heavy shadows.
  static const Color lightCanvas = Color(0xFFF4F5F7);

  /// Alias for scaffold assembly — same as [lightCanvas].
  static const Color lightBackground = lightCanvas;

  /// Raised cards, sheets, dialogs, and app bars on the porcelain canvas.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Primary ink on surfaces (`#0F172A`).
  static const Color lightInk = Color(0xFF0F172A);

  /// Body / secondary labels (`#30343C`, cool slate — one family with
  /// [lightInk] and the porcelain ramp; replaced warm `#33332E` 2026-06-11).
  static const Color lightBody = Color(0xFF30343C);

  /// Muted labels (`#5F6470`, cool slate; replaced warm `#62625B`).
  static const Color lightMute = Color(0xFF5F6470);

  /// Ash icons / hints (`#8F949E`, cool slate; replaced warm `#91918C`).
  static const Color lightAsh = Color(0xFF8F949E);

  /// Light upper container / idle chip — cool gray (`#E5E7EB`).
  ///
  /// Same lightness as the legacy warm Pinterest `secondary-bg` (`#E5E5E0`),
  /// hue moved to the cool family with the canvas (2026-06-11).
  ///
  /// Mapped to [ColorScheme.surfaceContainerHigh] in [AppTheme] without
  /// primary harmonization so unselected controls stay neutral gray.
  static const Color lightSurfaceContainerHighBase = Color(0xFFE5E7EB);

  /// Alias for catalog chips and docs (same as [lightSurfaceContainerHighBase]).
  static const Color catalogFilterUnselectedLight =
      lightSurfaceContainerHighBase;

  /// Dark idle chip / upper container.
  ///
  /// Green-tinted to sit in the same family as the dark surface ramp
  /// ([darkSurfaceContainer] etc.); replaced the warm `#3A3936` outlier
  /// (2026-06-11) — same lightness, hue aligned.
  static const Color catalogFilterUnselectedDark = Color(0xFF353E3A);

  /// Idle background for unselected filter chips and secondary controls.
  static Color catalogFilterUnselectedBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? catalogFilterUnselectedDark
        : catalogFilterUnselectedLight;
  }

  /// Section / list canvas tier — matches [lightCanvas].
  static const Color lightSurfaceContainer = lightCanvas;

  /// Light top container tier — cool hairline (`#DBDEE3`).
  static const Color lightSurfaceContainerHighestBase = Color(0xFFDBDEE3);

  /// Hairline dividers (`#DBDEE3`, cool family with the canvas).
  static const Color lightHairline = Color(0xFFDBDEE3);

  /// Default outline for fields and dividers (`#D0D7DE`).
  static const Color lightOutline = Color(0xFFD0D7DE);

  // ---------------------------------------------------------------------------
  // Dark neutral ramp.
  // ---------------------------------------------------------------------------

  static const Color darkBackground = Color(0xFF101816);
  static const Color darkSurface = Color(0xFF16201D);
  static const Color darkSurfaceContainer = Color(0xFF1C2925);

  /// Dark upper container tier (neutral; no primary harmonization in [AppTheme]).
  static const Color darkSurfaceContainerHighBase = catalogFilterUnselectedDark;

  /// Dark top container tier **base** before optional primary harmonization
  /// in [AppTheme].
  static const Color darkSurfaceContainerHighestBase = Color(0xFF34463F);

  /// Dark [ColorScheme] error tone for Material dark scheme.
  static const Color darkSchemeError = Color(0xFFFFB4AB);

  /// Dark outline/divider color. Calibrated for visibility on real-device
  /// DPIs (~400 ppi); avoid going darker than this.
  static const Color darkOutline = Color(0xFF4B5B55);

  // ---------------------------------------------------------------------------
  // AppTheme — light ColorScheme roles (brand-locked M3 palette).
  // ---------------------------------------------------------------------------

  /// Light [ColorScheme.onPrimary] on brand green (`#FFFFFF`).
  static const Color lightSchemeOnPrimary = Color(0xFFFFFFFF);

  /// Light [ColorScheme.secondary] — neutral chrome (`#E5E5E0`).
  static const Color lightSchemeSecondary = lightSurfaceContainerHighBase;

  /// Light [ColorScheme.onSecondary].
  static const Color lightSchemeOnSecondary = lightInk;

  /// Light [ColorScheme.primaryContainer] for the default sage primary.
  static const Color lightSchemePrimaryContainer = Color(0xFFDCEFE4);

  /// Light [ColorScheme.onPrimaryContainer] for the default sage primary.
  static const Color lightSchemeOnPrimaryContainer = Color(0xFF0D3522);

  /// Light [ColorScheme.secondaryContainer].
  static const Color lightSchemeSecondaryContainer = lightSurfaceContainer;

  /// Light [ColorScheme.onSecondaryContainer].
  static const Color lightSchemeOnSecondaryContainer = lightInk;

  /// Light [ColorScheme.onError].
  static const Color lightSchemeOnError = Color(0xFFFFFFFF);

  /// Neutral Flex tertiary containers (body tone on neutral fills).
  static const Color lightTertiaryContainer = lightSurfaceContainer;
  static const Color lightSurfaceContainerMid = lightSurfaceContainer;
  static const Color lightOutlineVariant = lightHairline;
  static const Color lightShadow = lightInk;

  /// Legacy alias — use [lightSchemeSecondaryContainer] for scheme assembly.
  static const Color lightSecondaryContainer = lightSchemeSecondaryContainer;

  // ---------------------------------------------------------------------------
  // AppTheme — dark Flex scheme refinement.
  // ---------------------------------------------------------------------------

  /// Lifted companion of [defaultPrimary] for contrast on dark surfaces.
  static const Color darkDefaultPrimary = Color(0xFF8AD4A8);

  /// Historical reference: dark primary container paired with
  /// [darkDefaultPrimary]. [AppTheme] derives it from selected primary instead.
  static const Color darkDefaultPrimaryContainer = Color(0xFF143E39);

  static const Color darkSecondary = Color(0xFF9DB5A8);
  static const Color darkSecondaryContainer = Color(0xFF2A3530);
  static const Color darkTertiary = Color(0xFFB0B8B4);
  static const Color darkTertiaryContainer = Color(0xFF3A3F3C);

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

  /// Error / failure — maps to light [ColorScheme.error] (`#DC2626`).
  static const Color error = Color(0xFFDC2626);

  /// Success on light surfaces (`#43A047`).
  static const Color success = Color(0xFF43A047);

  /// Lifted success for dark green-tinted surfaces (`#6BCF7F`).
  ///
  /// Same hue family as [success]; ~2× lighter so status borders and icons
  /// clear WCAG 3:1 on `surfaceContainerHigh` (`#353E3A`) without changing
  /// the light-mode tone (2026-06-11).
  static const Color successDark = Color(0xFF6BCF7F);

  /// Warning on light surfaces (deep orange — not gold/amber, `#C2410C`).
  static const Color warning = Color(0xFFC2410C);

  /// Lifted warning for dark green-tinted surfaces (`#FB923C`).
  ///
  /// Raw [warning] sits at ≈2.1:1 on `#353E3A`; this tone passes 3:1 for
  /// UI chrome while staying in the deep-orange family (2026-06-11).
  static const Color warningDark = Color(0xFFFB923C);

  // ---------------------------------------------------------------------------
  // Platform-fixed accents — used outside Flutter's `ColorScheme`
  // (Android notification channels) where reading the theme is not possible.
  // ---------------------------------------------------------------------------

  /// Static accent for system notification icons. Notifications render in the
  /// OS shade and cannot resolve runtime theme; this constant locks the brand
  /// tone so notification chrome stays recognisable.
  static const Color notificationAccent = defaultPrimary;

  /// Brand secondary used by FlexColorScheme assembly only.
  static const Color brandSecondary = lightSchemeSecondary;

  /// Brand tertiary used by FlexColorScheme assembly only.
  static const Color brandTertiary = lightBody;
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
