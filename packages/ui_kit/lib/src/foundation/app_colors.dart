import 'package:flutter/material.dart';

/// Centralized app color constants.
///
/// The Tilawa palette is intentionally **small and calm**:
/// white canvas ([tripGlideCanvas] `#FFFFFF`), warm brown primary
/// ([defaultPrimary] `#8B5E3C`), neutral text ink ([tripGlideInk] `#212121`),
/// and restrained category accent hues for hub tiles.
///
/// Some `tripGlide*` names remain as compatibility aliases for the current
/// travel-inspired Home layout. Their values now resolve to Tilawa's warm
/// brand palette.
///
/// All hex values used by `AppTheme` to assemble `ColorScheme` live here
/// so there is exactly one source of truth. Product widgets should read
/// from `ColorScheme` / `MeMuslimComponentTokens` / `ThemeData.productColors`,
/// not from this file directly (see `docs/design/color_architecture.md`).
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

  /// Reference teal preset (`#00897B`) — user-selectable in dev/QA picker.
  static const Color primaryTeal = Color(0xFF00897B);

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

  /// High-emphasis text ink for headings and body copy (`#212121`).
  ///
  /// Compatibility alias retained for existing travel-inspired Home widgets.
  static const Color tripGlideInk = Color(0xFF212121);

  /// Screen canvas (`#FFFFFF`).
  ///
  /// Compatibility alias retained for existing travel-inspired Home widgets.
  static const Color tripGlideCanvas = Color(0xFFFFFFFF);

  /// Elevated surfaces — cards, search (`#FFFFFF`).
  static const Color tripGlideSurface = Color(0xFFFFFFFF);

  /// Medium-emphasis secondary copy (`#757575`).
  static const Color tripGlideMuted = Color(0xFF757575);

  /// Idle tier for chips, search rests, and header bands (`#F5F5F5`).
  static const Color tripGlideCanvasElevated = Color(0xFFF5F5F5);

  /// Hairline / highest surface tier (`#EEEEEE`).
  static const Color tripGlideCanvasDusk = Color(0xFFEEEEEE);

  /// Divider / outline surface tier (`#E0E0E0`).
  static const Color tripGlideCanvasNight = Color(0xFFE0E0E0);

  /// Top stop for the brand launch gradient.
  static const Color brandGradientTop = tripGlideCanvas;

  /// Bottom stop for the brand launch gradient.
  static const Color brandGradientBottom = defaultPrimary;

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

  /// Soft beige tints for Home feature category grid tiles (Talabat-style).
  static const List<Color> homeFeatureCategoryTileTints = <Color>[
    tripGlideCanvasElevated,
    tripGlideCanvas,
    tripGlideCanvasDusk,
    tripGlideSurface,
    tripGlideCanvasElevated,
    tripGlideCanvas,
    tripGlideCanvasDusk,
    tripGlideSurface,
  ];

  /// Icons on travel destination header bands.
  static const Color homeTravelDestinationIcon = defaultPrimary;

  /// Section links (See all) on the travel Home dashboard.
  static const Color homeTravelSectionLink = defaultPrimary;

  /// Day hero top — warm ivory parchment with a soft gold cast.
  static const Color homeNextPrayerGradientTop = Color(0xFFFCF8F0);

  /// Day hero mid — intentional warm gold between parchment and sage mist.
  static const Color homeNextPrayerGradientDayMid = Color(0xFFF2E6C9);

  /// Day hero bottom — sage mist with stronger green presence (V3).
  static const Color homeNextPrayerGradientBottom = Color(0xFFC0E0D1);

  /// Pre-dawn hero top — cool mist ivory (Fajr, not forest night).
  static const Color homeNextPrayerGradientPreDawnTop = Color(0xFFF4F7F5);

  /// Pre-dawn hero bottom — blue-grey sage haze easing into day cream.
  static const Color homeNextPrayerGradientPreDawnBottom = Color(0xFFDBE9E3);

  /// Foreground on the Home hero day/dusk/pre-dawn gradients.
  static const Color homeNextPrayerGradientForeground = tripGlideInk;

  /// Dusk hero top — luminous gold cream (Maghrib warmth).
  static const Color homeNextPrayerGradientDuskTop = Color(0xFFF8E8CC);

  /// Dusk hero bottom — warm gold with restrained sage depth.
  static const Color homeNextPrayerGradientDuskBottom = Color(0xFFD8D2A7);

  /// Night hero top — muted teal twilight (Isha through midnight).
  static const Color homeNextPrayerGradientNightTop = Color(0xFF5E857C);

  /// Night hero bottom — deeper teal emerald with a visible ramp.
  static const Color homeNextPrayerGradientNightBottom = Color(0xFF3F635A);

  /// Foreground on the Home hero night gradient — warm cream ink.
  static const Color homeNextPrayerGradientNightForeground = Color(0xFFF5F0E6);

  /// Home screen canvas — flat neutral dashboard background.
  static const Color homeBackgroundGradientStart = homeDashboardCanvas;

  /// Home screen canvas — flat neutral dashboard background.
  static const Color homeBackgroundGradientMiddle = homeDashboardCanvas;

  /// Home screen canvas — flat neutral dashboard background.
  static const Color homeBackgroundGradientEnd = homeDashboardCanvas;

  /// Radial glow accent behind the Home hero / next-prayer area.
  static const Color homeBackgroundGlow = Color(0xFFE8DCC8);

  /// Home screen canvas — dark theme top.
  static const Color homeBackgroundGradientStartDark = Color(0xFF1E2826);

  /// Home screen canvas — dark theme middle.
  static const Color homeBackgroundGradientMiddleDark = Color(0xFF161F1D);

  /// Home screen canvas — dark theme bottom.
  static const Color homeBackgroundGradientEndDark = darkBackground;

  /// Radial glow accent on dark Home canvas.
  static const Color homeBackgroundGlowDark = Color(0xFF2A3D38);

  /// Neutral dashboard canvas — lifestyle reference (#FAFAFA).
  static const Color homeDashboardCanvas = lightCanvas;

  /// Elevated card surface on the Home dashboard.
  static const Color homeDashboardCardSurface = tripGlideCanvas;

  /// Dashboard accent — warm brown brand ink for Home CTAs and icons.
  static const Color homeDashboardAccent = defaultPrimary;

  /// White content area and elevated cards on the Home dashboard.
  static const Color homeContentSheetSurface = tripGlideCanvas;

  /// Dashboard canvas — dark theme.
  static const Color homeDashboardCanvasDark = darkBackground;

  /// Elevated card surface — dark theme.
  static const Color homeDashboardCardSurfaceDark = Color(0xFF1A2220);

  /// Dashboard accent — dark theme.
  static const Color homeDashboardAccentDark = Color(0xFFC9A07A);

  /// White content sheet — dark theme.
  static const Color homeContentSheetSurfaceDark = Color(0xFF121A18);

  /// Frosted next-prayer card fill — warm semi-transparent white.
  static const Color homePrayerCardBackground = Color(0xE8FFFFFF);

  /// Frosted next-prayer card hairline border.
  static const Color homePrayerCardBorder = Color(0x40D6CFC4);

  /// Next-prayer card drop shadow tint.
  static const Color homePrayerCardShadow = tripGlideInk;

  /// Mosque watermark on the next-prayer card (alpha applied in widgets).
  static const Color homePrayerCardWatermark = primarySage;

  /// Frosted next-prayer card fill — dark theme.
  static const Color homePrayerCardBackgroundDark = Color(0xCC1A2624);

  /// Frosted next-prayer card border — dark theme.
  static const Color homePrayerCardBorderDark = Color(0x33FFFFFF);

  /// Next-prayer card shadow — dark theme.
  static const Color homePrayerCardShadowDark = Color(0xFF000000);

  /// Mosque watermark — dark theme.
  static const Color homePrayerCardWatermarkDark = Color(0xFF4A7A6E);

  /// Prayer Hero fill — frosted warm white on the Home canvas gradient.
  static const Color homePrayerHeroBackground = homePrayerCardBackground;

  /// Prayer Hero hairline border — alias of [homePrayerCardBorder].
  static const Color homePrayerHeroBorder = homePrayerCardBorder;

  /// Prayer Hero drop shadow tint — alias of [homePrayerCardShadow].
  static const Color homePrayerHeroShadow = homePrayerCardShadow;

  /// Prayer Hero sage/gold accent for countdown and emphasis.
  static const Color homePrayerHeroAccent = homeDashboardAccent;

  /// Prayer Hero mosque watermark — alias of [homePrayerCardWatermark].
  static const Color homePrayerHeroWatermark = homePrayerCardWatermark;

  /// Prayer Hero fill — dark theme frosted surface.
  static const Color homePrayerHeroBackgroundDark =
      homePrayerCardBackgroundDark;

  /// Prayer Hero border — dark theme.
  static const Color homePrayerHeroBorderDark = homePrayerCardBorderDark;

  /// Prayer Hero shadow — dark theme.
  static const Color homePrayerHeroShadowDark = homePrayerCardShadowDark;

  /// Prayer Hero accent — dark theme.
  static const Color homePrayerHeroAccentDark = homeDashboardAccentDark;

  /// Prayer Hero watermark — dark theme.
  static const Color homePrayerHeroWatermarkDark = homePrayerCardWatermarkDark;

  /// Location chip fill on the Home hero header row.
  static const Color homeHeaderChipBackground = Color(0xFFF3F1EE);

  /// Hijri and secondary header copy on the Home hero.
  static const Color homeHeaderSecondaryText = Color(0xFF6B6560);

  /// Location chip fill — dark theme.
  static const Color homeHeaderChipBackgroundDark = Color(0x33FFFFFF);

  /// Secondary header copy — dark theme.
  static const Color homeHeaderSecondaryTextDark = Color(0xFFB8B0A8);

  /// Pinned collapsed hero bar — white dashboard chrome.
  static const Color homeCollapsedHeaderFill = tripGlideCanvas;

  /// Pinned collapsed hero bar hairline.
  static const Color homeCollapsedHeaderBorder = Color(0xFFE8E4DE);

  /// Pinned collapsed hero bar — dark theme wash.
  static const Color homeCollapsedHeaderFillDark = Color(0xFF161F1D);

  /// Featured tutor card — warm white on neutral canvas.
  static const Color homeFeaturedTutorGradientStart = Color(0xFFFDFCFB);

  /// Featured tutor card — soft beige wash.
  static const Color homeFeaturedTutorGradientEnd = Color(0xFFF5F0E8);

  /// Featured tutor card accent — badge, CTA, glyph.
  static const Color homeFeaturedTutorAccent = homeDashboardAccent;

  /// Featured tutor filled CTA label on brown pill.
  static const Color homeFeaturedTutorCtaForeground = Color(0xFFFFFFFF);

  /// Hero geometric pattern ink — brown micro-accent.
  static const Color homeHeroPatternInk = homeDashboardAccent;

  /// Content sheet top hairline — unused on flat canvas; kept for API compat.
  static const Color homeContentSheetTopBorder = Color(0xFFE8E4DE);

  /// Featured tutor card ramp start — dark theme.
  static const Color homeFeaturedTutorGradientStartDark = Color(0xFF243028);

  /// Featured tutor card ramp end — dark theme.
  static const Color homeFeaturedTutorGradientEndDark = Color(0xFF2A2620);

  /// Featured tutor card accent — dark theme.
  static const Color homeFeaturedTutorAccentDark = homeDashboardAccentDark;

  /// Featured tutor CTA label — dark theme.
  static const Color homeFeaturedTutorCtaForegroundDark = Color(0xFF0F1412);

  /// Hero geometric pattern ink — dark theme.
  static const Color homeHeroPatternInkDark = homeDashboardAccentDark;

  /// Content sheet top hairline — dark theme.
  static const Color homeContentSheetTopBorderDark = Color(0x33FFFFFF);

  /// Pinned collapsed hero bar border — dark theme.
  static const Color homeCollapsedHeaderBorderDark = Color(0x28FFFFFF);

  /// Action tile fill — white cards on neutral canvas.
  static const Color homeQuickActionTileBackground = tripGlideCanvas;

  /// Action tile fill — dark theme.
  static const Color homeQuickActionTileBackgroundDark = Color(0xFF1C2422);

  /// Launch / splash canvas — warm brown brand ink.
  static const Color launchSplashBackground = defaultPrimary;

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

  /// Ash icons / hints — low-emphasis neutral (`#BDBDBD`).
  static const Color lightAsh = Color(0xFFBDBDBD);

  /// Light upper container / idle chip — quiet neutral (`#F1F1EF`).
  ///
  /// Mapped to [ColorScheme.surfaceContainerHigh] in [AppTheme] without
  /// primary harmonization so unselected controls stay neutral.
  static const Color lightSurfaceContainerHighBase = tripGlideCanvasElevated;

  /// Alias for catalog chips and docs (same as [lightSurfaceContainerHighBase]).
  static const Color catalogFilterUnselectedLight =
      lightSurfaceContainerHighBase;

  /// Dark charcoal for bottom nav bar background (`#212528`).
  ///
  /// Used as the floating pill background in both light and dark themes
  /// for a premium, grounded chrome that separates from the content canvas.
  static const Color bottomNavBackground = Color(0xFF212528);

  /// Dark idle chip / upper container — teal-grey aligned with dark ramp.
  ///
  /// Replaced warm `#3A3936` outlier (2026-06-11); hue aligned to teal
  /// surfaces (2026-06-24 reference palette).
  static const Color catalogFilterUnselectedDark = Color(0xFF2A3432);

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

  static const Color darkBackground = Color(0xFF0E1413);
  static const Color darkSurface = Color(0xFF141D1B);
  static const Color darkSurfaceContainer = Color(0xFF1A2624);

  /// Dark upper container tier (neutral; no primary harmonization in [AppTheme]).
  static const Color darkSurfaceContainerHighBase = catalogFilterUnselectedDark;

  /// Dark top container tier **base** before optional primary harmonization
  /// in [AppTheme].
  static const Color darkSurfaceContainerHighestBase = Color(0xFF2E3F3B);

  /// Dark [ColorScheme] error tone for Material dark scheme.
  static const Color darkSchemeError = Color(0xFFFFB4AB);

  /// Dark outline/divider color. Calibrated for visibility on real-device
  /// DPIs (~400 ppi); avoid going darker than this.
  static const Color darkOutline = Color(0xFF4A5C57);

  // ---------------------------------------------------------------------------
  // AppTheme — light ColorScheme roles (brand-locked M3 palette).
  // ---------------------------------------------------------------------------

  /// Light [ColorScheme.onPrimary] on brand green (`#FFFFFF`).
  static const Color lightSchemeOnPrimary = Color(0xFFFFFFFF);

  /// Light [ColorScheme.secondary] — neutral chrome (`#E5E5E0`).
  static const Color lightSchemeSecondary = lightSurfaceContainerHighBase;

  /// Light [ColorScheme.onSecondary].
  static const Color lightSchemeOnSecondary = lightInk;

  /// Light [ColorScheme.primaryContainer] — pale desaturated teal (`#E0F2F1`).
  static const Color lightSchemePrimaryContainer = tripGlideCanvasElevated;

  /// Light [ColorScheme.onPrimaryContainer].
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
  static const Color darkTertiary = Color(0xFFCE93D8);
  static const Color darkTertiaryContainer = Color(0xFF3D2A4A);

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

  static const Color darkSurfaceContainerLowest = Color(0xFF0A100F);
  static const Color darkOutlineVariant = Color(0xFF2D3B37);

  // ---------------------------------------------------------------------------
  // Category accent hues — reference mock icon backgrounds (hub / explore).
  // ---------------------------------------------------------------------------

  /// Purple accent — generators / fan icon family.
  static const Color categoryAccentPurple = Color(0xFF7E57C2);

  /// Blue accent — water / conditions icon family.
  static const Color categoryAccentBlue = Color(0xFF42A5F5);

  /// Orange accent — map pin / points-of-interest family.
  static const Color categoryAccentOrange = Color(0xFFFF7043);

  /// Green accent — plants / nature icon family.
  static const Color categoryAccentGreen = Color(0xFF66BB6A);

  /// Indigo accent — secondary hub glyph.
  static const Color categoryAccentIndigo = Color(0xFF5C6BC0);

  /// Lighter teal accent — support / secondary brand tone.
  static const Color categoryAccentTealLight = Color(0xFF26A69A);

  /// Amber accent — featured / ceremonial hub glyph.
  static const Color categoryAccentAmber = Color(0xFFFFA726);

  /// Blue-grey accent — sessions / neutral category glyph.
  static const Color categoryAccentBlueGrey = Color(0xFF78909C);

  // ---------------------------------------------------------------------------
  // Semantic colors — meaning, not decoration.
  // ---------------------------------------------------------------------------

  /// Reference soft red/pink for inactive status surfaces (`#E57373`).
  static const Color errorSoft = Color(0xFFE57373);

  /// Error / failure — maps to light [ColorScheme.error] (`#D32F2F`).
  ///
  /// Slightly deeper than [errorSoft] so icons and [onError] pass contrast on
  /// white surfaces while staying in the reference red family.
  static const Color error = Color(0xFFD32F2F);

  /// Light [ColorScheme.errorContainer] — pale soft red from the reference mock.
  static const Color lightSchemeErrorContainer = errorSoft;

  /// Light [ColorScheme.onErrorContainer].
  static const Color lightSchemeOnErrorContainer = tripGlideInk;

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
  static const Color brandTertiary = categoryAccentPurple;
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

  /// Primary copy on the dark gradient shell.
  static const Color onShell = Color(0xFFFFFFFF);

  /// Muted shell copy (~70% white).
  static const Color onShellMuted = Color(0xB3FFFFFF);

  /// Secondary shell copy (~84% white).
  static const Color onShellSecondary = Color(0xD6FFFFFF);

  /// Tertiary shell copy (~72% white).
  static const Color onShellTertiary = Color(0xB8FFFFFF);

  /// Sheet drag handle on the gradient shell (~24% white).
  static const Color sheetHandle = Color(0x3DFFFFFF);

  /// Card elevation shadow on the shell (~18% black).
  static const Color shellElevationShadow = Color(0x2E000000);

  /// Soft frame shadow on the shell (~16% black).
  static const Color shellSoftShadow = Color(0x29000000);

  /// Faint tint behind nested previews (~12% black).
  static const Color shellFaintTint = Color(0x1F000000);

  /// Frosted panel fill on the shell (~7% white).
  static const Color glassFill = Color(0x12FFFFFF);

  /// Frosted panel border (~8% white).
  static const Color glassBorder = Color(0x14FFFFFF);

  /// Stronger frosted border (~12% white).
  static const Color glassBorderStrong = Color(0x1FFFFFFF);

  /// Ghost button fill on shell (~8% white).
  static const Color glassButtonFill = Color(0x14FFFFFF);

  /// Outline on shell CTAs (~20% white).
  static const Color buttonOnShellBorder = Color(0x33FFFFFF);
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

  /// Translucent reader frame behind embedded mushaf (~42% white).
  static const Color readerFrameFill = Color(0x6BFFFFFF);
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

  /// Warm brown highlight for searched / selected verses (light mushaf).
  static const Color lightVerseHighlight = Color(0xFF9A7A57);

  /// Verse highlight tuned for dark reader preset.
  static const Color darkVerseHighlight = Color(0xFF8B6F47);

  /// Surah metadata and footer copy on light pages.
  static const Color lightPageMetaText = lightVerseHighlight;

  /// Page number pill fill on light mushaf.
  static const Color lightPageNumberBackground = Color(0xFFE8DDD0);

  /// Page number pill border on light mushaf.
  static const Color lightPageNumberBorder = Color(0xFFD2C0AE);

  static const Color darkPillSurah = Color(0xFFE0E0E0);
  static const Color darkSurahTileName = Color(0xFFE0E0E0);

  /// Accent for Arabic surah names on tiles in dark reader preset.
  static const Color darkArabicAccent = Color(0xFFD4AF37);
}

/// Near-transparent fills used only during bootstrap shader warm-up.
abstract final class AppBootstrapShaderWarmupColors {
  static const Color blurPanelFill = Color(0x01FFFFFF);

  /// Matches light-chrome bottom-nav shadow in [TilawaAdaptiveShellTokens].
  static const Color navShadow = Color(0x0A000000);
}

/// Debug-only Quran line-guide paints (behind `_kDebugQuranLineGuides`).
abstract final class AppQuranDebugGuideColors {
  static const Color lineFill = Color(0x140000FF);
  static const Color lineStroke = Color(0xB34B0082);
  static const Color baseline = Color(0xA6FF0000);
}

/// Dev perf overlay severity fills for [PerfLogger] slow-frame banners.
abstract final class AppPerfLoggerColors {
  static const Color buildSlowBackground = Color(0xEECC0000);
  static const Color rasterSlowBackground = Color(0xEEBB4400);
  static const Color totalSlowBackground = Color(0xEE886600);
  static const Color bannerForeground = Color(0xFFFFFFFF);
}

/// Fully transparent — prefer [Colors.transparent] in widgets; this alias is
/// for const constructor defaults that must not reference Material palette.
abstract final class AppPalettePrimitives {
  static const Color fullyTransparent = Color(0x00000000);
}
