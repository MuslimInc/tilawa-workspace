import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';
import '../foundation/tilawa_icons.dart';

/// Circular app mark with [TilawaIcons.quran] for welcome and auth heroes.
///
/// Uses [MeMuslimDesignTokens.minInteractiveDimension] for the glyph and a
/// subtle primary-tinted disc so login, language welcome, and loader screens
/// share one brand presentation.
class TilawaAppBrandBadge extends StatelessWidget {
  const TilawaAppBrandBadge({super.key, this.accentColor});

  /// Disc and glyph tint; defaults to [ColorScheme.primary].
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final Color accent = accentColor ?? theme.colorScheme.primary;
    final double badgeSize =
        tokens.minInteractiveDimension * 2 + tokens.spaceExtraSmall;
    final double iconSize = tokens.minInteractiveDimension;

    return SizedBox(
      width: badgeSize,
      height: badgeSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: tokens.opacitySubtle),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: TilawaIcons.quran.svg(
            size: iconSize,
            color: accent,
          ),
        ),
      ),
    );
  }
}
