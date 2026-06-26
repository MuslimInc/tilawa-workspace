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
  });

  final TilawaHomeNextPrayerHeroTokens heroTokens;
  final TilawaHomeScreenTokens screenTokens;

  /// Scallop depth at the hero bottom; 0 keeps a flat edge.
  final double waveAmplitude;

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
        if (lightPhase)
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
        TilawaIslamicPatternOverlay(
          color: patternInk,
          opacity: screenTokens.homeHeroPatternOpacity,
          cellSize: tokens.spaceExtraLarge,
        ),
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
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topCenter,
              end: AlignmentDirectional.bottomCenter,
              colors: <Color>[
                colorScheme.shadow.withValues(
                  alpha: lightPhase ? 0.015 : 0.03,
                ),
                Colors.transparent,
                colorScheme.shadow.withValues(
                  alpha: lightPhase ? 0.025 : 0.05,
                ),
              ],
              stops: const <double>[0, 0.45, 1],
            ),
          ),
        ),
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
                      alpha: screenTokens.homePrayerHeroWatermarkOpacity * 0.45,
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
        ? (heroTokens.gradientMidStop ??
              Color.lerp(
                heroTokens.gradientTopStart,
                heroTokens.gradientBottomEnd,
                0.42,
              )!)
        : Color.lerp(
            heroTokens.gradientTopStart,
            heroTokens.gradientBottomEnd,
            0.5,
          )!;
    return LinearGradient(
      begin: AlignmentDirectional.topCenter,
      end: AlignmentDirectional.bottomCenter,
      colors: <Color>[
        heroTokens.gradientTopStart,
        midStop,
        heroTokens.gradientBottomEnd,
      ],
      stops: const <double>[0, 0.42, 1],
    );
  }
}
