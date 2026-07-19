import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Prayer-period gradient hero surface with optional bottom wave clip.
class HomeHeroBackground extends StatelessWidget {
  const HomeHeroBackground({
    super.key,
    required this.heroTokens,
    required this.screenTokens,
    this.waveAmplitude = 0,
    this.showDecorativeLayers = true,
  });

  final TilawaHomeNextPrayerHeroTokens heroTokens;
  final TilawaHomeScreenTokens screenTokens;

  /// Scallop depth at the hero bottom; 0 keeps a flat edge.
  final double waveAmplitude;

  /// When false, paints only the Figma clean green ramp (no pattern / mosque).
  final bool showDecorativeLayers;

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
    final MeMuslimDesignTokens tokens = theme.tokens;
    final bool lightPhase =
        heroTokens.gradientBottomEnd.computeLuminance() > 0.45;
    final Color patternInk = screenTokens.homeHeroPatternInk;
    final Color watermarkInk = screenTokens.homePrayerHeroWatermark;

    final Widget gradientStack = Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: _resolveBackgroundGradient(heroTokens),
          ),
        ),
        if (showDecorativeLayers && lightPhase)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: AlignmentDirectional.topCenter,
                radius: 1.05,
                colors: <Color>[
                  (heroTokens.gradientMidStop ?? heroTokens.gradientTopStart)
                      .withValues(alpha: screenTokens.homeHeroGoldGlowOpacity),
                  Colors.transparent,
                ],
                stops: const <double>[0, 0.78],
              ),
            ),
          ),
        if (showDecorativeLayers)
          TilawaIslamicPatternOverlay(
            color: patternInk,
            opacity: screenTokens.homeHeroPatternOpacity,
            cellSize: tokens.spaceExtraLarge,
          ),
        if (showDecorativeLayers)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: AlignmentDirectional.centerStart,
                radius: 0.9,
                colors: <Color>[
                  heroTokens.gradientTopStart.withValues(
                    alpha: lightPhase ? 0.18 : 0.05,
                  ),
                  Colors.transparent,
                ],
                stops: const <double>[0, 0.72],
              ),
            ),
          ),
        if (showDecorativeLayers)
          PositionedDirectional(
            end: -tokens.spaceMedium,
            bottom: -tokens.spaceSmall,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      watermarkInk.withValues(
                        alpha:
                            screenTokens.homePrayerHeroWatermarkOpacity * 0.45,
                      ),
                      Colors.transparent,
                    ],
                    stops: const <double>[0, 0.72],
                  ),
                ),
                child: Icon(
                  Icons.mosque_outlined,
                  size: tokens.iconSizeExtraLarge * 2.8,
                  color: watermarkInk.withValues(
                    alpha: screenTokens.homePrayerHeroWatermarkOpacity * 0.85,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (waveAmplitude <= 0) {
      return RepaintBoundary(child: gradientStack);
    }

    return RepaintBoundary(
      child: ClipPath(
        clipper: TilawaWaveClipper(
          amplitude: waveAmplitude,
          edge: TilawaWaveEdge.bottom,
        ),
        child: gradientStack,
      ),
    );
  }

  /// MeMuslim header-zone ramp: forest → emerald (Figma 0 / 45 / 75 / 100%).
  static LinearGradient _resolveBackgroundGradient(
    TilawaHomeNextPrayerHeroTokens heroTokens,
  ) {
    final Color top = heroTokens.gradientTopStart;
    final Color bottom = heroTokens.gradientBottomEnd;
    if (top == bottom) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[top, bottom],
      );
    }

    final Color mid =
        heroTokens.gradientMidStop ?? Color.lerp(top, bottom, 0.45)!;
    // Figma 75% stop is brand emerald `#1DAB61`.
    final Color midBright = heroTokens.gradientMidStop != null
        ? AppColors.brandActionGreen
        : Color.lerp(mid, bottom, 0.55)!;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[top, mid, midBright, bottom],
      stops: const <double>[0, 0.45, 0.75, 1],
    );
  }
}
