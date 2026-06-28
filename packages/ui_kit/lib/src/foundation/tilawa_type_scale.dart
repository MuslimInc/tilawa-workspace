import 'package:flutter/material.dart';

/// Global readability scale for Tilawa product chrome typography.
///
/// Applied centrally in [AppTheme] via [meMuslimScaleTextTheme] only. Component
/// tokens reference [TilawaTextRole] so this scale flows through
/// [ThemeData.textTheme] automatically.
///
/// Quran reader mushaf rendering uses dedicated reader settings — not this scale.
const double kTilawaGlobalTextScaleFactor = 1.25;

/// Scales a design-spec font size by [kTilawaGlobalTextScaleFactor].
double tilawaScaledFontSize(double designSize) =>
    designSize * kTilawaGlobalTextScaleFactor;

TextStyle? _scaleTextStyle(TextStyle? style) {
  if (style == null) return null;
  final double? size = style.fontSize;
  if (size == null) return style;
  return style.copyWith(fontSize: size * kTilawaGlobalTextScaleFactor);
}

/// Scales every non-null [TextStyle.fontSize] in [base] by
/// [kTilawaGlobalTextScaleFactor]. Skips styles without an explicit size so M3
/// inherited sizes are unchanged.
TextTheme meMuslimScaleTextTheme(TextTheme base) {
  return base.copyWith(
    displayLarge: _scaleTextStyle(base.displayLarge),
    displayMedium: _scaleTextStyle(base.displayMedium),
    displaySmall: _scaleTextStyle(base.displaySmall),
    headlineLarge: _scaleTextStyle(base.headlineLarge),
    headlineMedium: _scaleTextStyle(base.headlineMedium),
    headlineSmall: _scaleTextStyle(base.headlineSmall),
    titleLarge: _scaleTextStyle(base.titleLarge),
    titleMedium: _scaleTextStyle(base.titleMedium),
    titleSmall: _scaleTextStyle(base.titleSmall),
    bodyLarge: _scaleTextStyle(base.bodyLarge),
    bodyMedium: _scaleTextStyle(base.bodyMedium),
    bodySmall: _scaleTextStyle(base.bodySmall),
    labelLarge: _scaleTextStyle(base.labelLarge),
    labelMedium: _scaleTextStyle(base.labelMedium),
    labelSmall: _scaleTextStyle(base.labelSmall),
  );
}
