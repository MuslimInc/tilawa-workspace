import 'dart:ui';

import 'app_colors.dart';

/// Brand accent and scheme-role helpers.
///
/// Production default is green global accent ([AppColors.brandActionGreen],
/// `#1DAB61`) with matching Home micro-accents on the same green family.
abstract final class AppBrandProbe {
  AppBrandProbe._();

  /// Production global accent green (`#1DAB61`).
  static const Color actionGreen = AppColors.brandActionGreen;

  /// Compatibility alias — prefer [actionGreen].
  static const Color actionOrange = actionGreen;

  /// Whether [primary] uses brand-locked neutral containers + white onPrimary.
  static bool usesBrandLockedSchemeRoles(int primaryArgb) {
    return primaryArgb == AppColors.brandActionGreen.toARGB32();
  }
}
