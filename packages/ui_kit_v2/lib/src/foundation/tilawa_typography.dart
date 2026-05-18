import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tilawa_colors.dart';

/// Family names. Alexandria is shipped from this package (`pubspec.yaml`
/// `flutter.fonts`), Amiri is fetched on demand via [GoogleFonts].
abstract final class TilawaFontFamily {
  static const String ui = 'Alexandria';
  static const String arabic = 'Amiri'; // resolved via GoogleFonts.amiri
  static const String monospace = 'monospace';
}

/// Brand typography ramp. Names mirror the CSS `--fs-*` tokens, sizes match
/// the marketing site for the "marketing" ramp and the mobile.css locals for
/// the "mobile" ramp.
class TilawaTypography {
  TilawaTypography._({
    required this.display,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.lead,
    required this.body,
    required this.bodyLg,
    required this.bodyStrong,
    required this.caption,
    required this.overline,
    required this.eyebrow,
    required this.button,
    required this.heroMobile,
    required this.h2Mobile,
    required this.h3Mobile,
    required this.bodyMobile,
    required this.captionMobile,
    required this.overlineMobile,
    required this.numeric,
    required this.arabic,
    required this.arabicDisplay,
  });

  /// Default light-mode type system.
  factory TilawaTypography.light() {
    const ink = TilawaPalette.ink;
    const muted = TilawaPalette.inkMuted;
    const brand = TilawaPalette.green600;

    TextStyle ui(double size, FontWeight weight, {
      Color color = ink,
      double? height,
      double? letterSpacing,
    }) =>
        TextStyle(
          fontFamily: TilawaFontFamily.ui,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );

    return TilawaTypography._(
      // Marketing ramp.
      display: ui(56, FontWeight.w700, height: 1.15, letterSpacing: -1.12),
      h1: ui(42, FontWeight.w700, height: 1.25, letterSpacing: -0.63),
      h2: ui(32, FontWeight.w700, height: 1.25),
      h3: ui(22, FontWeight.w600, height: 1.35),
      h4: ui(18, FontWeight.w600, height: 1.4),
      lead: ui(20, FontWeight.w400, color: muted, height: 1.6),
      body: ui(16, FontWeight.w400, height: 1.6),
      bodyLg: ui(18, FontWeight.w400, color: muted, height: 1.8),
      bodyStrong: ui(16, FontWeight.w600, height: 1.6),
      caption: ui(14, FontWeight.w400, color: muted, height: 1.5),
      overline: ui(12, FontWeight.w700, color: muted, letterSpacing: 1.44),
      eyebrow: ui(
        11,
        FontWeight.w700,
        color: brand,
        letterSpacing: 1.32,
        height: 1.4,
      ),
      button: ui(14, FontWeight.w600, color: TilawaPalette.card),

      // Mobile ramp (mobile.css `--t-*`).
      heroMobile: ui(26, FontWeight.w700, height: 1.2, letterSpacing: -0.52),
      h2Mobile: ui(17, FontWeight.w700, letterSpacing: -0.17, height: 1.35),
      h3Mobile: ui(15, FontWeight.w600, height: 1.4),
      bodyMobile: ui(14, FontWeight.w400, height: 1.5),
      captionMobile: ui(12, FontWeight.w500, color: muted, height: 1.5),
      overlineMobile: ui(
        11,
        FontWeight.w700,
        color: muted,
        letterSpacing: 1.32,
        height: 1.4,
      ),

      numeric: ui(14, FontWeight.w700, height: 1.0).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),

      // Arabic — Amiri only. Loaded from Google Fonts on demand.
      arabic: GoogleFonts.amiri(
        fontSize: 28,
        height: 2,
        color: ink,
      ),
      arabicDisplay: GoogleFonts.amiri(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        height: 1.8,
        color: TilawaPalette.green700,
      ),
    );
  }

  // Marketing-ramp text styles.
  final TextStyle display;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle h4;
  final TextStyle lead;
  final TextStyle body;
  final TextStyle bodyLg;
  final TextStyle bodyStrong;
  final TextStyle caption;
  final TextStyle overline;
  final TextStyle eyebrow;
  final TextStyle button;

  // Mobile-ramp text styles. Mirror mobile.css `--t-hero/h2/h3/body/cap/over`.
  final TextStyle heroMobile;
  final TextStyle h2Mobile;
  final TextStyle h3Mobile;
  final TextStyle bodyMobile;
  final TextStyle captionMobile;
  final TextStyle overlineMobile;

  /// Tabular-figure numeric (timecodes, counts).
  final TextStyle numeric;

  /// Quranic verse — Naskh script. Reserved for Mushaf-style rendering only.
  final TextStyle arabic;
  final TextStyle arabicDisplay;
}
