import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Tinted icon well for Home dashboard tiles.
///
/// Locked to [TilawaRadiusFamily.chip] (sharp rounded square) so prayer,
/// primary tiles, quick tools, Learn, and resume rows share one silhouette —
/// never a circle / stadium.
class HomeDashboardIconWell extends StatelessWidget {
  const HomeDashboardIconWell({
    super.key,
    required this.child,
    this.accent,
    this.extent,
    this.fillAlpha = 0.10,
  });

  final Widget child;
  final Color? accent;

  /// Well width/height. Defaults to [TilawaDesignTokens.iconBoxSize].
  final double? extent;

  /// Well fill opacity. Use [HomeFeaturePastel.solidIconWellFillAlpha] for
  /// Ngajii-style solid chips on white cards, or [HomeFeaturePastel.iconWellFillAlpha]
  /// for soft tints (Learn / resume).
  final double fillAlpha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final Color iconAccent =
        accent ?? theme.componentTokens.homeScreen.homePrayerHeroAccent;
    final double size = extent ?? tokens.iconBoxSize;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.chip),
        ),
        color: iconAccent.withValues(alpha: fillAlpha),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}
