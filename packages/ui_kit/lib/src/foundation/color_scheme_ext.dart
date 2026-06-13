import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';

extension ColorSchemeExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
}

/// Semantic status colors that Material's [ColorScheme] does not model.
///
/// `ColorScheme` ships `error` only; Tilawa also needs distinct **warning**
/// (deep orange — never gold/amber) and **success** (green) hues so that
/// status surfaces are distinguishable *by hue*, not merely by opacity of the
/// error red. Sourced from [AppColors] so there remains a single source of
/// hex (see `docs/design/colors.md`).
///
/// Light and dark surfaces use different hexes in [AppColors]; branch on
/// [ColorScheme.brightness] here so every consumer updates at once.
extension TilawaStatusColors on ColorScheme {
  /// Warning accent — deep orange, distinct from [error].
  Color get warning =>
      brightness == Brightness.dark ? AppColors.warningDark : AppColors.warning;

  /// Success accent — green confirmation tone.
  Color get success =>
      brightness == Brightness.dark ? AppColors.successDark : AppColors.success;
}

/// Accent tones guaranteed readable as **small text** (WCAG AA, ≥ 4.5:1).
///
/// [ColorScheme.primary] is tuned for fills and large text (3:1 threshold);
/// the brand sage sits at ≈ 3.8:1 on white, which fails the 4.5:1 small-text
/// threshold. This extension derives a same-hue tone that passes, so small
/// accent captions (selected bottom-nav labels) stay accessible for **every**
/// primary preset without per-preset hexes.
extension TilawaAccessibleAccents on ColorScheme {
  /// [primary], nudged darker (light schemes) or lighter (dark schemes) in
  /// small lightness steps until it reaches 4.5:1 against [surface].
  ///
  /// Returns [primary] unchanged when it already passes. Use for small accent
  /// labels only; icons and large text should keep [primary].
  Color get primarySmallLabel {
    const double targetRatio = 4.5;
    final double surfaceLuminance = surface.computeLuminance();
    final bool darken = surfaceLuminance > 0.5;

    Color candidate = primary;
    HSLColor hsl = HSLColor.fromColor(candidate);
    // Bounded walk: 0.03 lightness per step, ≤ 20 steps, so a pathological
    // primary can never loop forever or leave the hue family.
    for (
      int step = 0;
      step < 20 && _contrastRatio(candidate, surface) < targetRatio;
      step++
    ) {
      hsl = hsl.withLightness(
        (hsl.lightness + (darken ? -0.03 : 0.03)).clamp(0.0, 1.0),
      );
      candidate = hsl.toColor();
    }
    return candidate;
  }

  static double _contrastRatio(Color a, Color b) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }
}
