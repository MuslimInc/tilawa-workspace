import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Frosted glass panel for readable hero chrome over photography.
class HomeHeroGlassSurface extends StatelessWidget {
  const HomeHeroGlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final TilawaHomeNextPrayerHeroTokens heroTokens =
        theme.componentTokens.homeNextPrayerHero;
    final BorderRadius resolvedRadius =
        borderRadius ?? BorderRadius.circular(tokens.radiusLarge);
    final Color fill = heroTokens.foregroundColor.withValues(
      alpha: heroTokens.locationChipFillOpacity,
    );
    final Color border = heroTokens.foregroundColor.withValues(
      alpha: heroTokens.locationChipBorderOpacity,
    );

    final Widget panel = ClipRRect(
      borderRadius: resolvedRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.blurGlass,
          sigmaY: tokens.blurGlass,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: resolvedRadius,
            border: Border.all(
              color: border,
              width: tokens.borderWidthThin,
            ),
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.all(tokens.spaceMedium),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) {
      return panel;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: resolvedRadius,
        splashColor: heroTokens.foregroundColor.withValues(
          alpha: heroTokens.locationChipSplashOpacity,
        ),
        highlightColor: heroTokens.foregroundColor.withValues(
          alpha: heroTokens.locationChipHighlightOpacity,
        ),
        child: panel,
      ),
    );
  }
}
