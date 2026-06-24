import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'color_scheme_ext.dart';

/// Manuscript-derived tints for hub navigation icon boxes.
///
/// Maps to existing [ColorScheme] roles — no new hex values. Use only on
/// feature-hub surfaces (Smart Khatma, Recitation Practice landing, tools).
/// Never on Quran reader, prayer times, or athkar.
enum TilawaSemanticTint {
  /// User accent — maps to [ColorScheme.primary].
  ink,

  /// Supporting metadata — maps to [ColorScheme.secondary].
  scholar,

  /// Ceremonial accent — maps to [ColorScheme.tertiary]. Hub navigation only.
  gilding,

  /// Quiet neutral — maps to [ColorScheme.surfaceContainerHigh].
  parchment,

  /// Default neutral — maps to [ColorScheme.surfaceContainer].
  neutral,

  /// Positive outcome — maps to semantic success.
  success,

  /// Caution — maps to semantic warning.
  caution,
}

/// Resolves background and foreground colours for [TilawaSemanticTint].
extension TilawaSemanticTintColors on ColorScheme {
  /// Fill behind a tinted [TilawaIconBox].
  Color semanticTintBackground(TilawaSemanticTint tint) {
    return switch (tint) {
      TilawaSemanticTint.ink => surfaceContainerHigh,
      TilawaSemanticTint.scholar => secondaryContainer,
      TilawaSemanticTint.gilding => tertiaryContainer,
      TilawaSemanticTint.parchment => surfaceContainerHigh,
      TilawaSemanticTint.neutral => surfaceContainer,
      TilawaSemanticTint.success => Color.alphaBlend(
        success.withValues(alpha: 0.14),
        surface,
      ),
      TilawaSemanticTint.caution => Color.alphaBlend(
        warning.withValues(alpha: 0.14),
        surface,
      ),
    };
  }

  /// Icon glyph colour on a tinted [TilawaIconBox].
  Color semanticTintForeground(TilawaSemanticTint tint) {
    return switch (tint) {
      TilawaSemanticTint.ink => primary,
      TilawaSemanticTint.scholar => onSecondaryContainer,
      TilawaSemanticTint.gilding => onTertiaryContainer,
      TilawaSemanticTint.parchment => onSurfaceVariant,
      TilawaSemanticTint.neutral => onSurface,
      TilawaSemanticTint.success => success,
      TilawaSemanticTint.caution => warning,
    };
  }

  /// Stronger accent wash for Home explore grid tiles.
  ///
  /// Unlike [semanticTintBackground] (neutral [surfaceContainer] roles), these
  /// blends use brand accents so each feature card reads at a glance.
  Color featureCategoryTileBackground(TilawaSemanticTint tint) {
    final double strength = brightness == Brightness.dark ? 0.22 : 0.15;

    return switch (tint) {
      TilawaSemanticTint.ink => Color.alphaBlend(
        primary.withValues(alpha: strength),
        surface,
      ),
      TilawaSemanticTint.scholar => Color.alphaBlend(
        AppColors.primarySage.withValues(alpha: strength),
        surface,
      ),
      TilawaSemanticTint.gilding => Color.alphaBlend(
        AppColors.brandTertiary.withValues(alpha: strength + 0.02),
        surface,
      ),
      TilawaSemanticTint.parchment => Color.alphaBlend(
        onSurfaceVariant.withValues(alpha: 0.12),
        surfaceContainerHigh,
      ),
      TilawaSemanticTint.neutral => AppColors.tripGlideCanvasElevated,
      TilawaSemanticTint.success => Color.alphaBlend(
        success.withValues(alpha: strength + 0.02),
        surface,
      ),
      TilawaSemanticTint.caution => Color.alphaBlend(
        warning.withValues(alpha: strength),
        surface,
      ),
    };
  }
}
