import 'dart:ui';

import 'package:flutter/material.dart';

import '../atoms/atoms.dart';
import '../foundation/foundation.dart';

/// Home centerpiece card. Deep-green gradient with a subtle gold glow, a gold
/// progress bar, and a glassy resume CTA. Mirrors `.tw-lastread`.
class TilawaLastReadHero extends StatelessWidget {
  const TilawaLastReadHero({
    required this.eyebrow,
    required this.title,
    required this.arabicTitle,
    required this.subtitle,
    required this.progress,
    required this.percentLabel,
    required this.onResume,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String arabicTitle;
  final String subtitle;
  final double progress;
  final String percentLabel;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final onPrimary = theme.tokens.colors.fgOnPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TilawaSpacing.padX,
        4,
        TilawaSpacing.padX,
        0,
      ),
      child: ClipRRect(
        borderRadius: TilawaRadii.brLg,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [TilawaPalette.green700, TilawaPalette.green600],
            ),
            boxShadow: TilawaShadows.el2,
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Stack(
            children: [
              // Soft white glow blob top-right.
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0x0FFFFFFF),
                        Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
              // Faint gold glow top-right per the css `radial-gradient`.
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 180,
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.7, -1),
                      radius: 0.9,
                      colors: [
                        Color(0x2ED4AF37),
                        Color(0x00D4AF37),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          eyebrow.toUpperCase(),
                          style: TextStyle(
                            fontFamily: TilawaFontFamily.ui,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: onPrimary.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        percentLabel,
                        style: const TextStyle(
                          fontFamily: TilawaFontFamily.ui,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: TilawaPalette.gold300,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: TilawaFontFamily.ui,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      arabicTitle,
                      style: TextStyle(
                        fontFamily: TilawaFontFamily.arabic,
                        fontSize: 22,
                        height: 1.3,
                        color: onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: TilawaFontFamily.ui,
                      fontSize: 11,
                      color: onPrimary.withValues(alpha: 0.7),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TilawaProgressBar(
                          value: progress,
                          trackColor: onPrimary.withValues(alpha: 0.18),
                          fillGradient: const LinearGradient(
                            colors: [
                              TilawaPalette.gold300,
                              TilawaPalette.gold500,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _GlassResumeButton(onPressed: onResume),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassResumeButton extends StatelessWidget {
  const _GlassResumeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0x38FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
