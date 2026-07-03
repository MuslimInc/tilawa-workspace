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
  });

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final Color iconAccent =
        accent ?? theme.componentTokens.homeScreen.homePrayerHeroAccent;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.decorative),
        ),
        color: iconAccent.withValues(alpha: 0.10),
      ),
      child: SizedBox(
        width: tokens.iconBoxSize,
        height: tokens.iconBoxSize,
        child: Center(child: child),
      ),
    );
  }
}
