import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Tinted icon well for Home dashboard tiles.
///
/// Uses [TilawaRadiusFamily.decorative] — the same rounded-square treatment as
/// [TilawaIconBox] in grouped Home list rows.
class HomeDashboardIconWell extends StatelessWidget {
  const HomeDashboardIconWell({
    super.key,
    required this.child,
    this.accent,
    this.extent,
  });

  final Widget child;
  final Color? accent;

  /// Well width/height. Defaults to [TilawaDesignTokens.iconBoxSize].
  final double? extent;

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
          tokens.resolveRadius(family: TilawaRadiusFamily.decorative),
        ),
        color: iconAccent.withValues(alpha: 0.10),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}
