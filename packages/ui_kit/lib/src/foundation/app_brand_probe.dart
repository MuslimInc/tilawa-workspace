import 'dart:ui';

import 'app_colors.dart';

/// Brand accent and scheme-role helpers.
///
/// Production default is orange global accent ([AppColors.brandActionOrange],
/// `#FA5B2E`) with matching Home micro-accents on the same orange family.
abstract final class AppBrandProbe {
  AppBrandProbe._();

  /// Production global accent orange (`#FA5B2E`).
  static const Color actionOrange = AppColors.brandActionOrange;

  /// Compatibility alias for [actionOrange].
  static const Color actionGreen = actionOrange;

  /// Whether [primary] uses brand-locked neutral containers + white onPrimary.
  static bool usesBrandLockedSchemeRoles(int primaryArgb) {
    return primaryArgb == AppColors.brandActionOrange.toARGB32();
  }
}
