import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';

/// Tone roles for [TilawaStateVisual].
enum TilawaStateVisualTone {
  /// Uses the theme primary role.
  primary,

  /// Uses the theme secondary role.
  secondary,

  /// Uses the theme tertiary role.
  tertiary,

  /// Uses the theme outline role for low-emphasis states.
  neutral,

  /// Uses the theme error role.
  error,
}

/// A quiet non-figurative visual for empty, permission, and error states.
///
/// Concentric halo rings carry the accent without a boxed icon tile, border,
/// and shadow stack. Product screens stay calm while empty moments still feel
/// intentional.
class TilawaStateVisual extends StatelessWidget {
  /// Creates a reusable state visual.
  const TilawaStateVisual({
    super.key,
    required this.icon,
    this.tone = TilawaStateVisualTone.primary,
    this.accentColor,
    this.iconColor,
    this.size,
    this.semanticLabel,
  });

  /// The symbolic icon shown in the center.
  final IconData icon;

  /// Semantic tone used when [accentColor] is not provided.
  final TilawaStateVisualTone tone;

  /// Optional accent override. Prefer passing theme-derived colors.
  final Color? accentColor;

  /// Optional icon override. Defaults to the resolved accent color.
  final Color? iconColor;

  /// Overall square size. Defaults to [resolveDefaultSize].
  final double? size;

  /// Optional semantic label when the visual itself carries meaning.
  ///
  /// Leave null when the surrounding state already has a semantic label.
  final String? semanticLabel;

  /// Token-backed diameter shared by [TilawaIllustratedState] and
  /// [TilawaEmptyState] so every empty moment uses the same visual scale.
  static double resolveDefaultSize(MeMuslimDesignTokens tokens) {
    return tokens.iconSizeExtraLarge + tokens.spaceExtraLarge * 2.5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final accent = accentColor ?? _resolveAccent(colorScheme);
    final dimension = size ?? resolveDefaultSize(tokens);
    final iconSize = tokens.iconSizeExtraLarge;
    final haloStrength = _haloStrengthForTone(tone);

    final visual = SizedBox.square(
      dimension: dimension,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _StateHalo(
            diameter: dimension,
            color: accent.withValues(
              alpha: tokens.opacitySubtle * haloStrength,
            ),
          ),
          Icon(
            icon,
            size: iconSize,
            color: iconColor ?? accent,
          ),
        ],
      ),
    );

    if (semanticLabel == null) {
      return ExcludeSemantics(child: visual);
    }

    return Semantics(label: semanticLabel, image: true, child: visual);
  }

  Color _resolveAccent(ColorScheme colorScheme) {
    return switch (tone) {
      TilawaStateVisualTone.primary => colorScheme.primary,
      TilawaStateVisualTone.secondary => colorScheme.secondary,
      TilawaStateVisualTone.tertiary => colorScheme.tertiary,
      TilawaStateVisualTone.neutral => colorScheme.onSurfaceVariant,
      TilawaStateVisualTone.error => colorScheme.error,
    };
  }
}

double _haloStrengthForTone(TilawaStateVisualTone tone) {
  return switch (tone) {
    TilawaStateVisualTone.error => 1.4,
    TilawaStateVisualTone.neutral => 1.1,
    _ => 1.75,
  };
}

class _StateHalo extends StatelessWidget {
  const _StateHalo({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
