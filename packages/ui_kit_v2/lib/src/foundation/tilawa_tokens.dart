import 'package:flutter/material.dart';

import 'tilawa_colors.dart';

/// 4-point spacing scale used across the design system.
abstract final class TilawaSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
  static const double s20 = 80;
  static const double s24 = 96;

  /// Mobile horizontal page padding (`--pad-x` in mobile.css).
  static const double padX = 20;

  /// Mobile section vertical padding (`--pad-section-y`).
  static const double padSectionY = 24;

  /// Minimum tappable target (iOS HIG / Material).
  static const double tapMin = 44;
}

/// Corner radii. Matches the design system's `--radius-*` tokens.
abstract final class TilawaRadii {
  static const Radius xs = Radius.circular(6);
  static const Radius sm = Radius.circular(8);
  static const Radius md = Radius.circular(12);
  static const Radius lg = Radius.circular(16);
  static const Radius xl = Radius.circular(20);
  static const Radius xl2 = Radius.circular(32);
  static const Radius xl3 = Radius.circular(40);

  // Convenience BorderRadius values for the common shapes.
  static const BorderRadius brXs = BorderRadius.all(xs);
  static const BorderRadius brSm = BorderRadius.all(sm);
  static const BorderRadius brMd = BorderRadius.all(md);
  static const BorderRadius brLg = BorderRadius.all(lg);
  static const BorderRadius brXl = BorderRadius.all(xl);
  static const BorderRadius brXl2 = BorderRadius.all(xl2);
  static const BorderRadius brXl3 = BorderRadius.all(xl3);

  /// Pill-shaped radius; pair with `999`-effective shape via [StadiumBorder].
  static const Radius pill = Radius.circular(999);
  static const BorderRadius brPill = BorderRadius.all(pill);
}

/// Elevation / shadow tokens. The brand stays warm and quiet — no harsh edges.
abstract final class TilawaShadows {
  /// `--shadow-xs` — sticky nav.
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x08000000),
      offset: Offset(0, 2),
      blurRadius: 10,
    ),
  ];

  /// `--shadow-sm` — primary button (tinted with brand green).
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x332D5C3F),
      offset: Offset(0, 4),
      blurRadius: 20,
    ),
  ];

  /// `--shadow-md` — resting cards.
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 10),
      blurRadius: 40,
    ),
  ];

  /// `--shadow-lg` — card hover, phone mockup.
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 20),
      blurRadius: 60,
    ),
  ];

  /// Mobile `--el-1`. Restrained ambient elevation.
  static const List<BoxShadow> el1 = [
    BoxShadow(
      color: Color(0x0A0F172A),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x0A0F172A),
      offset: Offset(0, 4),
      blurRadius: 14,
    ),
  ];

  /// Mobile `--el-2`. Two-layer ambient elevation.
  static const List<BoxShadow> el2 = [
    BoxShadow(
      color: Color(0x0F0F172A),
      offset: Offset(0, 4),
      blurRadius: 14,
    ),
    BoxShadow(
      color: Color(0x0F0F172A),
      offset: Offset(0, 12),
      blurRadius: 32,
    ),
  ];

  /// Mobile `--el-glow`. Tinted shadow used under primary buttons.
  static const List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x382D5C3F),
      offset: Offset(0, 6),
      blurRadius: 20,
    ),
  ];
}

/// Motion durations + easings. The brand is "pace-of-prayer", not bounce-and-pop.
abstract final class TilawaMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration veryslow = Duration(milliseconds: 600);

  /// Hero float used on the phone mockup.
  static const Duration float = Duration(seconds: 6);

  static const Curve easeOut = Cubic(0.22, 0.61, 0.36, 1);
  static const Curve standard = Curves.easeOut;
}

/// Bundle of token tables, available through [TilawaTheme.of(context)].
class TilawaTokens {
  const TilawaTokens({required this.colors});

  /// Default light tokens (current design system snapshot).
  factory TilawaTokens.light() =>
      TilawaTokens(colors: TilawaColors.light());

  final TilawaColors colors;
}
