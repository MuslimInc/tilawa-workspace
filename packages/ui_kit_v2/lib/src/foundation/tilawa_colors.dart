import 'package:flutter/material.dart';

/// Tilawa brand color palette.
///
/// Mirrors `colors_and_type.css` from the design system bundle. Use the
/// scale colors (`green600`, `gold500`, ...) for one-off brand surfaces; use
/// the semantic aliases on [TilawaColors] (or [Theme.of(context).colorScheme])
/// when wiring widgets.
abstract final class TilawaPalette {
  // Emerald green — spiritual core of the brand.
  static const Color green50 = Color(0xFFEAF2EC);
  static const Color green100 = Color(0xFFCFE0D4);
  static const Color green200 = Color(0xFFA7C4B1);
  static const Color green300 = Color(0xFF7AA68D);
  static const Color green400 = Color(0xFF54896D);
  static const Color green500 = Color(0xFF3D7C5F); // primary-light
  static const Color green600 = Color(0xFF2D5C3F); // PRIMARY
  static const Color green700 = Color(0xFF234731);
  static const Color green800 = Color(0xFF1D3C2F); // primary-dark
  static const Color green900 = Color(0xFF122618);

  // Gold — used sparingly: footer headings, accents, decorative dividers.
  static const Color gold100 = Color(0xFFF7ECC8);
  static const Color gold300 = Color(0xFFE9CF85);
  static const Color gold500 = Color(0xFFD4AF37); // ACCENT
  static const Color gold700 = Color(0xFFA8861F);

  // Sky — cool, soft gradient backdrop behind hero & section pads.
  static const Color sky50 = Color(0xFFF0F9FF);
  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky200 = Color(0xFFBAE3FD);

  // Neutrals.
  static const Color ink = Color(0xFF1A1A1A);
  static const Color inkMuted = Color(0xFF6B7280);
  static const Color paper = Color(0xFFFAFAFA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceApp = Color(0xFFFAFBFC);

  // Semantic — feedback. Muted/desaturated to fit the calm tone.
  static const Color success = Color(0xFF3D7C5F);
  static const Color warning = Color(0xFFD4AF37);
  static const Color danger = Color(0xFFB04545);
  static const Color info = Color(0xFF4D7BB5);

  // Hairline + glass.
  static const Color hairline = Color(0x0F0F172A); // rgba(15,23,42,0.06)
  static const Color line = Color(0x0D000000); // rgba(0,0,0,0.05)
  static const Color lineCard = Color(0x0A000000); // rgba(0,0,0,0.04)

  // Brand gradients.
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green600, green500],
  );

  static const Gradient skyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sky50, sky100],
  );

  /// Vertical fade used for header backdrops in the mobile kit.
  static const Gradient softSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sky50, Color(0x00F0F9FF)],
  );
}

/// Semantic role-based color tokens. Prefer these in widget code so a future
/// dark-mode rollout only has to swap one source.
class TilawaColors {
  const TilawaColors({
    required this.fg1,
    required this.fg2,
    required this.fgOnPrimary,
    required this.fgAccent,
    required this.bgPage,
    required this.bgCard,
    required this.bgSoft,
    required this.bgPrimary,
    required this.bgFooter,
    required this.hairline,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.brand,
    required this.brandLight,
    required this.brandDark,
    required this.brandSoft,
  });

  /// Default light-mode role tokens.
  factory TilawaColors.light() => const TilawaColors(
    fg1: TilawaPalette.ink,
    fg2: TilawaPalette.inkMuted,
    fgOnPrimary: Color(0xFFFFFFFF),
    fgAccent: TilawaPalette.gold500,
    bgPage: TilawaPalette.paper,
    bgCard: TilawaPalette.card,
    bgSoft: TilawaPalette.sky50,
    bgPrimary: TilawaPalette.green600,
    bgFooter: TilawaPalette.ink,
    hairline: TilawaPalette.hairline,
    success: TilawaPalette.success,
    warning: TilawaPalette.warning,
    danger: TilawaPalette.danger,
    info: TilawaPalette.info,
    brand: TilawaPalette.green600,
    brandLight: TilawaPalette.green500,
    brandDark: TilawaPalette.green800,
    brandSoft: Color(0x0F2D5C3F), // ~0.06 alpha
  );

  final Color fg1;
  final Color fg2;
  final Color fgOnPrimary;
  final Color fgAccent;
  final Color bgPage;
  final Color bgCard;
  final Color bgSoft;
  final Color bgPrimary;
  final Color bgFooter;
  final Color hairline;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color brand;
  final Color brandLight;
  final Color brandDark;
  final Color brandSoft;
}
