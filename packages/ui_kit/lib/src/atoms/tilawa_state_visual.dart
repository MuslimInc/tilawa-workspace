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
/// The visual intentionally avoids feature-specific imagery. It combines a
/// soft geometric field with a centered icon so product screens can feel more
/// intentional without adding random assets or childish illustration.
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

  /// Overall square size. Defaults to a token-derived comfortable size.
  final double? size;

  /// Optional semantic label when the visual itself carries meaning.
  ///
  /// Leave null when the surrounding state already has a semantic label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final accent = accentColor ?? _resolveAccent(colorScheme);
    final dimension =
        size ?? tokens.iconSizeExtraLarge + tokens.spaceExtraLarge * 2;
    final iconSize = tokens.iconSizeLarge;

    final visual = SizedBox.square(
      dimension: dimension,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(tokens.spaceMedium),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              accent.withValues(alpha: tokens.opacitySubtle),
              colorScheme.surface,
            ),
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            border: Border.all(
              color: accent.withValues(alpha: tokens.opacityMedium),
              width: 1.0,
            ),
            boxShadow: [
              // Ambient layer — lifts the icon container off the background.
              BoxShadow(
                color: accent.withValues(alpha: tokens.opacitySubtle * 0.6),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
              // Coloured glow — ties the shadow hue to the accent so the
              // visual feels intentional rather than generic dark grey.
              BoxShadow(
                color: accent.withValues(alpha: tokens.opacitySubtle),
                blurRadius: tokens.blurShadow,
                offset: tokens.shadowOffsetSmall,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ?? accent,
          ),
        ),
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
      TilawaStateVisualTone.neutral => colorScheme.outline,
      TilawaStateVisualTone.error => colorScheme.error,
    };
  }
}
