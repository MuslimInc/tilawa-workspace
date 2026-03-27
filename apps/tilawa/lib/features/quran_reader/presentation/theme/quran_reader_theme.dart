import 'package:flutter/material.dart';

/// Theme extension for the Quran Reader feature.
///
/// Provides distinct colors for the Mushaf pages and the navigation UI
/// that work across both Light and Dark modes via Flutter's theme system.
class QuranReaderTheme extends ThemeExtension<QuranReaderTheme> {
  const QuranReaderTheme({
    required this.pageBackground,
    required this.textColor,
    required this.headerBackground,
    required this.headerTextColor,
    required this.headerImageFilter,
    required this.systemBarColor,
    required this.statusBarIconBrightness,
    required this.statusBarBrightness,
  });

  /// Pre-built light-mode instance.
  static const QuranReaderTheme light = QuranReaderTheme(
    pageBackground: Color(0xFFFFF9F1),
    textColor: Color(0xFF000000),
    headerBackground: Color(0xFFF4EAD2),
    headerTextColor: Color(0xFF4E342E), // Colors.brown.shade800
    headerImageFilter: null,
    systemBarColor: Color(0xFFFFF9F1),
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  /// Pre-built dark-mode instance.
  ///
  /// The header image filter converts the light beige/gold banner into a
  /// dark variant that blends with the dark page background (#1A1A1A).
  ///
  /// The banner image is mostly light beige (~RGB 230,220,210) with
  /// gold/brown ornamental patterns (~RGB 170,155,135). This low-contrast
  /// inversion maps the beige background to near-black and the ornaments
  /// to subtle warm highlights just above the page background.
  static const QuranReaderTheme dark = QuranReaderTheme(
    pageBackground: Color(0xFF1A1A1A),
    textColor: Color(0xFFE0E0E0),
    headerBackground: Color(0xFF2C2C2C),
    headerTextColor: Color(0xE6FFFFFF), // white with ~90% opacity
    headerImageFilter: ColorFilter.matrix([
      // Low-contrast inversion: R' = -0.32·R + 100
      // Beige bg (230) → 26, ornament (170) → 46 — subtle warm highlight.
      // Slight warm bias: R offset +4, B offset -4 over neutral.
      -0.32, 0, 0, 0, 104, //
      0, -0.32, 0, 0, 100,
      0, 0, -0.32, 0, 96,
      0, 0, 0, 1, 0,
    ]),
    systemBarColor: Color(0xFF1A1A1A),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  /// Background color for the Mushaf page.
  final Color pageBackground;

  /// Color for the Quran text glyphs.
  final Color textColor;

  /// Background color for the Surah header banner.
  final Color headerBackground;

  /// Text color for the Surah name inside the banner.
  final Color headerTextColor;

  /// Color filter for the Surah header banner image (inverts in dark mode).
  final ColorFilter? headerImageFilter;

  /// Color for the system status bar area.
  final Color systemBarColor;

  /// Icon brightness for the status bar (dark icons on light, light on dark).
  final Brightness statusBarIconBrightness;

  /// Status bar brightness hint (opposite of icon brightness).
  final Brightness statusBarBrightness;

  /// Convenience accessor: `QuranReaderTheme.of(context)`.
  static QuranReaderTheme of(BuildContext context) {
    return Theme.of(context).extension<QuranReaderTheme>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  QuranReaderTheme copyWith({
    Color? pageBackground,
    Color? textColor,
    Color? headerBackground,
    Color? headerTextColor,
    ColorFilter? headerImageFilter,
    Color? systemBarColor,
    Brightness? statusBarIconBrightness,
    Brightness? statusBarBrightness,
  }) {
    return QuranReaderTheme(
      pageBackground: pageBackground ?? this.pageBackground,
      textColor: textColor ?? this.textColor,
      headerBackground: headerBackground ?? this.headerBackground,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      headerImageFilter: headerImageFilter ?? this.headerImageFilter,
      systemBarColor: systemBarColor ?? this.systemBarColor,
      statusBarIconBrightness:
          statusBarIconBrightness ?? this.statusBarIconBrightness,
      statusBarBrightness: statusBarBrightness ?? this.statusBarBrightness,
    );
  }

  @override
  QuranReaderTheme lerp(covariant QuranReaderTheme? other, double t) {
    if (other == null) return this;
    return QuranReaderTheme(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      headerBackground: Color.lerp(
        headerBackground,
        other.headerBackground,
        t,
      )!,
      headerTextColor: Color.lerp(headerTextColor, other.headerTextColor, t)!,
      headerImageFilter: t < 0.5 ? headerImageFilter : other.headerImageFilter,
      systemBarColor: Color.lerp(systemBarColor, other.systemBarColor, t)!,
      statusBarIconBrightness: t < 0.5
          ? statusBarIconBrightness
          : other.statusBarIconBrightness,
      statusBarBrightness: t < 0.5
          ? statusBarBrightness
          : other.statusBarBrightness,
    );
  }
}
