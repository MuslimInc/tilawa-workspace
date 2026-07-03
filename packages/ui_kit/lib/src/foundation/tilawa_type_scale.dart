import 'package:flutter/material.dart';

/// Global readability scale for Tilawa product chrome typography.
///
/// Applied through [tilawaProductTextScaler] on [MediaQueryData.textScaler]
/// (see [TilawaPreviewWrapper] and the Tilawa app shell). That scales every
/// [Text] and [RichText] — including hard-coded [TextStyle.fontSize] values in
/// UI-kit widgets — not only [ThemeData.textTheme].
///
/// [ThemeData.textTheme] stays at Material 3 base sizes; render-time scaling
/// is centralized here. Component tokens that reference [TilawaTextRole] resolve
/// from the base theme, then inherit this scaler at paint time.
///
/// Quran reader mushaf rendering uses dedicated reader settings — not this scale.
const double kTilawaGlobalTextScaleFactor = 1.0;

/// Scales a design-spec font size by [kTilawaGlobalTextScaleFactor].
///
/// Use for layout math that must track typography (heights, struts) when
/// [MediaQuery.textScaler] is unavailable.
double tilawaScaledFontSize(double designSize) =>
    designSize * kTilawaGlobalTextScaleFactor;

/// Applies the product readability scale on top of the ambient text scaler.
TextScaler tilawaProductTextScaler(TextScaler system) =>
    TextScaler.linear(system.scale(1.0) * kTilawaGlobalTextScaleFactor);

/// Text block height for layout math that must match scaled [Text] paint size.
///
/// Always pass [MediaQuery.textScalerOf] via [context] — never measure with an
/// unscaled [TextPainter] when the app applies [tilawaProductTextScaler].
double tilawaMeasureTextHeight({
  required BuildContext context,
  required TextStyle? style,
  String text = 'Hg',
  int? maxLines,
  double? maxWidth,
}) {
  if (style == null) {
    return 27.5 * MediaQuery.textScalerOf(context).scale(1.0);
  }
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    textHeightBehavior: DefaultTextHeightBehavior.maybeOf(context),
    maxLines: maxLines,
  )..layout(maxWidth: maxWidth ?? double.infinity);
  return painter.height;
}

/// Extra logical pixels for fixed-height chrome when text scale exceeds 1.0.
///
/// Absorbs font-metric drift between [TextPainter] and live [Text] layout.
double tilawaLayoutSlack(BuildContext context) {
  final double scale = MediaQuery.textScalerOf(context).scale(1.0);
  if (scale <= 1.0) {
    return 0;
  }
  return (scale - 1.0) * 10 + 1;
}

/// Ceils [logicalPixels] to the next device pixel, plus [tilawaLayoutSlack].
double tilawaLayoutHeight(BuildContext context, double logicalPixels) {
  final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
  final double adjusted = logicalPixels + tilawaLayoutSlack(context);
  return (adjusted * devicePixelRatio).ceil() / devicePixelRatio;
}

TextStyle? _scaleTextStyle(TextStyle? style) {
  if (style == null) return null;
  final double? size = style.fontSize;
  if (size == null) return style;
  return style.copyWith(fontSize: size * kTilawaGlobalTextScaleFactor);
}

/// Scales explicit [TextStyle.fontSize] values in [base].
///
/// Prefer [tilawaProductTextScaler] at the [MediaQuery] layer for app chrome.
/// Kept for tests and callers that build a pre-scaled theme in isolation.
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
