import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Warm Behance catalog chrome for reciter surah rows (parchment / brown).
abstract final class ReciterCatalogChrome {
  static Color idleFill(ColorScheme scheme) => scheme.surfaceContainerHigh;

  static Color cardFill(ColorScheme scheme) => scheme.surface;

  static Color activeFill(ColorScheme scheme) => scheme.primary;

  static Color activeOnFill(ColorScheme scheme) => scheme.onPrimary;

  static Color hairline(ColorScheme scheme, TilawaDesignTokens tokens) =>
      scheme.outlineVariant.withValues(alpha: tokens.opacitySubtle);

  static Color activeRowFill(ColorScheme scheme) =>
      scheme.surfaceContainer.withValues(alpha: 0.72);

  /// Opaque pill fill for the batch-download control while active.
  ///
  /// Uses [surfaceContainerHigh] — not [surfaceContainer] — because on the
  /// light theme canvas scaffold, `surfaceContainer` is the same porcelain
  /// as the page background and the chip reads as borderless text.
  static Color downloadingFill(ColorScheme scheme) =>
      scheme.surfaceContainerHigh;
}
