import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Mushaf-oriented colours for the standalone [quran_image] package.
///
/// Prefer [ThemeData.productColors] when a [BuildContext] is available.
/// These constants delegate to [AppQuranReaderLegacyColors] so hex values stay
/// in `packages/ui_kit` only.
abstract final class QuranImageColors {
  QuranImageColors._();

  static Color pageBackground(Brightness brightness) =>
      brightness == Brightness.dark
      ? AppQuranReaderLegacyColors.darkPageBackground
      : AppQuranReaderLegacyColors.lightPageBackground;

  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.dark
      ? AppQuranReaderLegacyColors.darkOnSurface
      : AppQuranReaderLegacyColors.lightOnSurface;

  static const Color sliderBackground =
      AppQuranReaderLegacyColors.lightPageBackground;

  static Color shadow(ColorScheme scheme) => scheme.shadow;
}
