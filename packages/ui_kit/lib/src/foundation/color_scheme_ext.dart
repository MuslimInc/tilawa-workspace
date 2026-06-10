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
/// These are deliberately brightness-agnostic constants today; if dark-mode
/// tuning is needed later, branch on [ColorScheme.brightness] here so every
/// consumer updates at once.
extension TilawaStatusColors on ColorScheme {
  /// Warning accent — deep orange, distinct from [error].
  Color get warning => AppColors.warning;

  /// Success accent — green confirmation tone.
  Color get success => AppColors.success;
}
