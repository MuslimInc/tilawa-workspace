import 'package:flutter/material.dart';

/// Centralized app color constants.
///
/// The Tilawa palette is intentionally **small and calm**:
/// soft neutral canvas ([tripGlideCanvas] `#FAFAFA`), brown primary ink
/// ([primaryBrown] `#8B5E3C`), neutral text ink ([tripGlideInk] `#30343C`),
/// and restrained gold featured surfaces.
///
/// Some `tripGlide*` names remain as compatibility aliases for the current
/// travel-inspired Home layout. Their values now resolve to Tilawa's warm
/// brand palette.
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

  /// Warm brown — the brand-locked mockup accent (`#8B5E3C`).
  static const Color primaryBrown = Color(0xFF8B5E3C);

  /// Pressed / strong brown for shadows and emphasis (`#6B4A2E`).
  static const Color primaryBrownDark = Color(0xFF6B4A2E);

  /// Green alias retained for saved theme migration.
  static const Color primaryGreen = primarySage;

  /// Purple alias retained for saved theme migration.
  static const Color primaryPurple = Color(0xFF7A5C89);

  /// Default primary color used throughout the app.
  ///
  /// Warm brown brand ink (`#8B5E3C`) for CTAs, active nav, and selected
  /// controls.
  static const Color defaultPrimary = primaryBrown;

  /// Warm neutral text ink for headings and body copy (`#30343C`).
  ///
  /// Compatibility alias retained for existing travel-inspired Home widgets.
  static const Color tripGlideInk = Color(0xFF30343C);

  /// Soft neutral screen canvas (`#FAFAFA`).
  ///
  /// Compatibility alias retained for existing travel-inspired Home widgets.
  static const Color tripGlideCanvas = Color(0xFFFAFAFA);

  /// Elevated surfaces — cards, search (`#FFFFFF`).
  static const Color tripGlideSurface = Color(0xFFFFFFFF);

  /// Warm secondary copy (`#78736E`).
  static const Color tripGlideMuted = Color(0xFF78736E);

  /// Warm beige idle tier for chips, search rests, and header bands.
  static const Color tripGlideCanvasElevated = Color(0xFFF1F1EF);

  /// Warm hairline / highest surface tier.
  static const Color tripGlideCanvasDusk = Color(0xFFE5E5E2);

  /// Deeper warm night/dim surface tier.
  static const Color tripGlideCanvasNight = Color(0xFFD6D6D1);

  /// Top stop for the brand launch gradient.
  static const Color brandGradientTop = tripGlideCanvas;

  /// Bottom stop for the brand launch gradient.
  static const Color brandGradientBottom = primaryBrown;

  /// Featured-card gold surface — ceremonial, not paywall chrome.
  static const Color featuredGradientStart = Color(0xFFFFD28E);

  /// Featured-card gold surface lower stop.
  static const Color featuredGradientEnd = Color(0xFFFF9E44);

  /// Foreground on featured / elevated cards.
  static const Color featuredGradientForeground = tripGlideInk;

  /// Surah header banner — top neutral band.
  static const Color surahHeaderGradientTop = tripGlideCanvasElevated;

  /// Surah header banner — bottom neutral band.
  static const Color surahHeaderGradientBottom = tripGlideCanvas;

  /// Qibla compass radial glow — neutral grey.
  static const Color qiblaCompassGlow = tripGlideCanvasElevated;

  /// Instruction chip fill — neutral canvas.
  static const Color instructionChipFill = tripGlideCanvas;

  /// Travel-layout destination header tint — warm beige.
  static const Color homeTravelDestinationTintNeutral = tripGlideCanvasElevated;

  /// Neutral sheet on the Home travel-inspired dashboard (`#FAFAFA`).
  static const Color homeTravelSheetSurface = tripGlideCanvas;

  /// White search field on the Home travel dashboard (`#FFFFFF`).
  static const Color homeTravelSearchFill = tripGlideSurface;

  /// Warm header bands for discover / carousel destination cards.
  static const List<Color> homeTravelDestinationHeaderTints = <Color>[
    tripGlideCanvas,
    tripGlideCanvasElevated,
    tripGlideCanvasDusk,
  ];

  /// Icons on travel destination header bands.
  static const Color homeTravelDestinationIcon = primaryBrown;

  /// Section links (See all) on the travel Home dashboard.
  static const Color homeTravelSectionLink = primaryBrown;

  /// Top-start stop for the Home hero **day** phase — flat neutral canvas.
  static const Color homeNextPrayerGradientTop = tripGlideCanvas;

  /// Bottom-end stop for the Home hero **day** phase.
  static const Color homeNextPrayerGradientBottom = tripGlideCanvas;

  /// Foreground on the Home hero neutral canvas (day/dusk/night).
  static const Color homeNextPrayerGradientForeground = tripGlideInk;

  /// Top-start stop for the Home hero **dusk** phase.
  static const Color homeNextPrayerGradientDuskTop = tripGlideCanvasDusk;

  /// Bottom-end stop for the Home hero **dusk** phase.
  static const Color homeNextPrayerGradientDuskBottom = tripGlideCanvasDusk;

  /// Top-start stop for the Home hero **night** phase.
  static const Color homeNextPrayerGradientNightTop = tripGlideCanvasNight;

  /// Bottom-end stop for the Home hero **night** phase.
  static const Color homeNextPrayerGradientNightBottom = tripGlideCanvasNight;

  /// Foreground on the Home hero **night** canvas.
  static const Color homeNextPrayerGradientNightForeground = tripGlideInk;

  /// Launch / splash canvas — warm brown brand ink.
  static const Color launchSplashBackground = primaryBrown;

  /// Wordmark and progress on launch surfaces (`#FFFFFF`).
  static const Color launchSplashForeground = Color(0xFFFFFFFF);

  /// Logo box on Flutter launch surfaces — must match Android
  /// `@dimen/splash_logo_size` (288dp) and `splash_icon` drawable.
  static const double launchSplashLogoSize = 288;

  // ---------------------------------------------------------------------------
  // Light neutral ramp — soft neutral canvas + white cards
  // (#FAFAFA / #FFFFFF / warm neutral ink). One temperature family end-to-end.
  // ---------------------------------------------------------------------------

  /// App canvas / scaffold — soft neutral (`#FAFAFA`).
  ///
  /// Cards use [lightSurface] (`#FFFFFF`) for quiet lift with soft shadows.
  static const Color lightCanvas = tripGlideCanvas;

  /// Alias for scaffold assembly — same as [lightCanvas].
  static const Color lightBackground = lightCanvas;

  /// Raised cards, sheets, dialogs, and app bars on the neutral canvas.
  static const Color lightSurface = tripGlideSurface;

  /// Primary ink on surfaces (`#30343C`).
  static const Color lightInk = tripGlideInk;

  /// Body / secondary labels (`#30343C`).
  static const Color lightBody = tripGlideInk;

  /// Muted labels (`#78736E`).
  static const Color lightMute = tripGlideMuted;

  /// Ash icons / hints — muted neutral.
  static const Color lightAsh = tripGlideMuted;

  /// Light upper container / idle chip — quiet neutral (`#F1F1EF`).
  ///
  /// Mapped to [ColorScheme.surfaceContainerHigh] in [AppTheme] without
  /// primary harmonization so unselected controls stay neutral.
  static const Color lightSurfaceContainerHighBase = tripGlideCanvasElevated;

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

  /// Light top container tier — quiet neutral hairline (`#E5E5E2`).
  static const Color lightSurfaceContainerHighestBase = tripGlideCanvasDusk;

  /// Hairline dividers — warm neutral.
  static const Color lightHairline = tripGlideCanvasDusk;

  /// Default outline for fields and dividers (`#D6D6D1`).
  static const Color lightOutline = tripGlideCanvasNight;

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

  /// Light [ColorScheme.primaryContainer] for the default ink primary.
  static const Color lightSchemePrimaryContainer = tripGlideCanvasElevated;

  /// Light [ColorScheme.onPrimaryContainer] for the default ink primary.
  static const Color lightSchemeOnPrimaryContainer = tripGlideInk;

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
  static const Color lightShadow = tripGlideInk;

  /// Legacy alias — use [lightSchemeSecondaryContainer] for scheme assembly.
  static const Color lightSecondaryContainer = lightSchemeSecondaryContainer;

  // ---------------------------------------------------------------------------
  // AppTheme — dark Flex scheme refinement.
  // ---------------------------------------------------------------------------

  /// Lifted warm companion of [defaultPrimary] for contrast on dark surfaces.
  static const Color darkDefaultPrimary = Color(0xFFD6B08A);

  /// Historical reference: dark primary container paired with
  /// [darkDefaultPrimary]. [AppTheme] derives it from selected primary instead.
  static const Color darkDefaultPrimaryContainer = Color(0xFF3D2A1D);

  static const Color darkSecondary = Color(0xFF9DB5A8);
  static const Color darkSecondaryContainer = Color(0xFF2A3530);
  static const Color darkTertiary = Color(0xFFD6B86A);
  static const Color darkTertiaryContainer = Color(0xFF3D3015);

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
  static const Color brandTertiary = Color(0xFF8C681F);
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
