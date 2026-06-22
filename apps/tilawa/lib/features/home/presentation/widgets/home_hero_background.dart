import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_hero_sliver.dart';

/// Prayer-period gradient hero surface with a soft sheet handoff (no photo).
class HomeHeroBackground extends StatelessWidget {
  const HomeHeroBackground({
    super.key,
    required this.heroTokens,
  });

  final TilawaHomeNextPrayerHeroTokens heroTokens;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final Color canvasColor = context.scaffoldCanvasColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: heroTokens.backgroundGradient),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topCenter,
              end: AlignmentDirectional.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.06),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.08),
              ],
              stops: const <double>[0, 0.45, 1],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: HomeDashboardHeroSliver.sheetOverlap + tokens.spaceLarge,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  canvasColor.withValues(alpha: 0),
                  canvasColor,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
