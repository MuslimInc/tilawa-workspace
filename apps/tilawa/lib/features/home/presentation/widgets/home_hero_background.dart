import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/constants/home_hero_assets.dart';
import 'home_dashboard_hero_sliver.dart';

/// Kaaba hero wallpaper with cinematic scrims and a clean sheet handoff.
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
        Image.asset(
          HomeHeroAssets.wallpaper,
          fit: BoxFit.cover,
          alignment: HomeHeroAssets.wallpaperAlignment,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: const Alignment(0, 0.42),
              colors: <Color>[
                Colors.black.withValues(alpha: 0.42),
                Colors.black.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              stops: const <double>[0, 0.55, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(0, 0.38),
              end: Alignment.bottomCenter,
              stops: const <double>[0, 0.5, 0.82, 1],
              colors: <Color>[
                Colors.transparent,
                Colors.black.withValues(alpha: 0.12),
                Colors.black.withValues(alpha: 0.34),
                canvasColor.withValues(alpha: 0.96),
              ],
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
