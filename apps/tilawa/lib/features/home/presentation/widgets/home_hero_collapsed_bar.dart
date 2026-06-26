import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_glass_surface.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Gradient-aware frosted surface for the pinned Home hero bar.
///
/// [reveal] drives fill alpha directly — never wraps the panel in [Opacity],
/// so scrolling content cannot bleed through a semi-transparent overlay.
class HomeHeroCollapsedBar extends StatelessWidget {
  const HomeHeroCollapsedBar({super.key, required this.reveal});

  /// Collapsed-bar visibility from 0 (hidden) to 1 (fully pinned).
  final double reveal;

  static const double _opaqueRevealThreshold = 0.22;

  static double surfaceAlpha(double reveal) {
    if (reveal <= 0) {
      return 0;
    }
    final double ramp = Curves.easeOutCubic.transform(
      (reveal * 1.35).clamp(0.0, 1.0),
    );
    if (reveal >= _opaqueRevealThreshold) {
      return 1;
    }
    return math.max(ramp, 0.97);
  }

  @override
  Widget build(BuildContext context) {
    if (reveal <= 0) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final ColorScheme colorScheme = theme.colorScheme;
    final double fillAlpha = surfaceAlpha(reveal);
    final double chromeAlpha = (reveal * 1.6).clamp(0.0, 1.0);
    final Color fillColor = screenTokens.homeCollapsedHeaderFill.withValues(
      alpha: fillAlpha,
    );
    final BoxDecoration decoration = BoxDecoration(
      color: fillColor,
      border: Border(
        bottom: BorderSide(
          color: screenTokens.homeCollapsedHeaderBorder.withValues(
            alpha: chromeAlpha,
          ),
          width: tokens.borderWidthThin,
        ),
      ),
      boxShadow: chromeAlpha > 0
          ? <BoxShadow>[
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha:
                      screenTokens.homeCollapsedHeaderShadowOpacity *
                      chromeAlpha,
                ),
                offset: tokens.shadowOffsetSmall,
                blurRadius: tokens.spaceSmall.toDouble(),
              ),
            ]
          : null,
    );

    final Widget surface = DecoratedBox(decoration: decoration);

    if (!HomeHeroGlassSurface.useBackdropBlur) {
      return surface;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.blurGlass * 0.45,
          sigmaY: tokens.blurGlass * 0.45,
        ),
        child: surface,
      ),
    );
  }
}
