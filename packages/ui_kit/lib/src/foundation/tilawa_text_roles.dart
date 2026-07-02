import 'package:flutter/material.dart';

/// Semantic typography slot on [TextTheme].
///
/// Component tokens store these instead of raw font sizes so
/// [tilawaProductTextScaler] on [MediaQueryData.textScaler] remains the single
/// global scale point for rendered text.
enum TilawaTextRole {
  displaySmall,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

/// Resolves [role] from [textTheme].
extension TilawaTextRoleResolver on TilawaTextRole {
  TextStyle? resolve(TextTheme textTheme) {
    return switch (this) {
      TilawaTextRole.displaySmall => textTheme.displaySmall,
      TilawaTextRole.headlineSmall => textTheme.headlineSmall,
      TilawaTextRole.titleLarge => textTheme.titleLarge,
      TilawaTextRole.titleMedium => textTheme.titleMedium,
      TilawaTextRole.titleSmall => textTheme.titleSmall,
      TilawaTextRole.bodyLarge => textTheme.bodyLarge,
      TilawaTextRole.bodyMedium => textTheme.bodyMedium,
      TilawaTextRole.bodySmall => textTheme.bodySmall,
      TilawaTextRole.labelLarge => textTheme.labelLarge,
      TilawaTextRole.labelMedium => textTheme.labelMedium,
      TilawaTextRole.labelSmall => textTheme.labelSmall,
    };
  }
}

/// Picks [role] from [textTheme], falling back to [fallback] when null.
TextStyle tilawaResolveTextRole(
  TextTheme textTheme,
  TilawaTextRole role, {
  TextStyle fallback = const TextStyle(),
}) {
  return role.resolve(textTheme) ?? fallback;
}

/// Theme-transition helper — enums do not interpolate.
TilawaTextRole lerpTilawaTextRole(
  TilawaTextRole a,
  TilawaTextRole b,
  double t,
) {
  return t < 0.5 ? a : b;
}
