import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_hero_sliver.dart';

/// Prayer-period gradient hero surface with a soft sheet handoff (no photo).
class HomeHeroBackground extends StatelessWidget {
  const HomeHeroBackground({
    super.key,
    required this.heroTokens,
  });

  final TilawaHomeNextPrayerHeroTokens heroTokens;

  /// Status bar icon brightness from hero gradient luminance.
  static SystemUiOverlayStyle systemOverlayStyle(
    TilawaHomeNextPrayerHeroTokens heroTokens,
  ) {
    final Color sample = Color.lerp(
      heroTokens.gradientTopStart,
      heroTokens.gradientBottomEnd,
      0.35,
    )!;
    return sample.computeLuminance() > 0.52
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaDesignTokens tokens = theme.tokens;
    final Color sheetColor = AppColors.homeTravelSheetSurface;
    final bool lightPhase =
        heroTokens.gradientBottomEnd.computeLuminance() > 0.45;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: _resolveBackgroundGradient(heroTokens),
            ),
          ),
          if (lightPhase)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: AlignmentDirectional.topCenter,
                  radius: 1.05,
                  colors: <Color>[
                    AppColors.featuredGradientStart.withValues(alpha: 0.11),
                    Colors.transparent,
                  ],
                  stops: const <double>[0, 0.78],
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topCenter,
                end: AlignmentDirectional.bottomCenter,
                colors: <Color>[
                  colorScheme.shadow.withValues(alpha: lightPhase ? 0.015 : 0.03),
                  Colors.transparent,
                  colorScheme.shadow.withValues(alpha: lightPhase ? 0.025 : 0.05),
                ],
                stops: const <double>[0, 0.45, 1],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height:
                HomeDashboardHeroSliver.sheetOverlap +
                tokens.spaceLarge +
                tokens.spaceMedium,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    sheetColor.withValues(alpha: 0),
                    sheetColor.withValues(alpha: 0),
                    sheetColor.withValues(alpha: 0.55),
                    sheetColor,
                  ],
                  stops: const <double>[0, 0.38, 0.78, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Three-stop phase gradient with a restrained gold mid accent.
  static LinearGradient _resolveBackgroundGradient(
    TilawaHomeNextPrayerHeroTokens heroTokens,
  ) {
    if (heroTokens.gradientTopStart == heroTokens.gradientBottomEnd) {
      return LinearGradient(
        begin: AlignmentDirectional.topCenter,
        end: AlignmentDirectional.bottomCenter,
        colors: <Color>[
          heroTokens.gradientTopStart,
          heroTokens.gradientBottomEnd,
        ],
      );
    }

    final bool lightPhase =
        heroTokens.gradientBottomEnd.computeLuminance() > 0.45;
    final Color midStop = lightPhase
        ? AppColors.homeNextPrayerGradientDayMid
        : Color.lerp(
            heroTokens.gradientTopStart,
            heroTokens.gradientBottomEnd,
            0.5,
          )!;
    final double goldMix = lightPhase ? 0.14 : 0.08;
    final Color accentMid = Color.lerp(
      midStop,
      AppColors.featuredGradientStart,
      goldMix,
    )!;

    return LinearGradient(
      begin: AlignmentDirectional.topCenter,
      end: AlignmentDirectional.bottomCenter,
      colors: <Color>[
        heroTokens.gradientTopStart,
        accentMid,
        heroTokens.gradientBottomEnd,
      ],
      stops: const <double>[0, 0.42, 1],
    );
  }
}
