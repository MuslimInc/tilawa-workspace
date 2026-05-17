import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Bottom padding for prayer-times scrollables.
///
/// When the screen is hosted in [MainScreen], [TilawaShellPadding] already
/// insets the tab body — only content spacing is added here. Standalone
/// routes (e.g. debug `/prayer-times`) get safe-area padding as well.
double prayerTimesScrollBottomPadding(BuildContext context) {
  final tokens = Theme.of(context).tokens;
  if (TilawaShellPadding.of(context) > 0) {
    return tokens.spaceExtraLarge;
  }

  return tokens.spaceExtraLarge + MediaQuery.paddingOf(context).bottom;
}

/// Narrow-width thresholds for Prayer Times presentation layout.
///
/// [TilawaWindowSize.narrow] spans all phones (< 600dp); this flag splits
/// typical small phones (~360dp logical) from larger handsets in portrait.
class PrayerTimesLayout {
  const PrayerTimesLayout._();

  /// Max width for the **content** box (e.g. [LayoutBuilder] constraints),
  /// below which stacked layouts apply.
  static const double narrowContentWidth = 400;

  static bool isNarrowWidth(double maxWidth) =>
      maxWidth > 0 && maxWidth < narrowContentWidth;
}
