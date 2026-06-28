import 'app_colors.dart';

/// Brand accent and scheme-role helpers.
///
/// Production default is green global accent ([AppColors.brandActionGreen]) with
/// matching Home micro-accents on the same green family.
abstract final class AppBrandProbe {
  AppBrandProbe._();

  /// Production global accent green (`#2B8659`).
  static const actionGreen = AppColors.brandActionGreen;

  /// Whether [primary] uses brand-locked neutral containers + white onPrimary.
  static bool usesBrandLockedSchemeRoles(int primaryArgb) {
    return primaryArgb == AppColors.brandActionGreen.toARGB32();
  }
}
