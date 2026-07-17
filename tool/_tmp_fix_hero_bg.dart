import 'dart:io';

void main() {
  // Solid white prayer card — TASA-style lift on cool canvas.
  final colors = File('packages/ui_kit/lib/src/foundation/app_colors.dart');
  var c = colors.readAsStringSync();
  c = c.replaceFirst(
    'static const Color homePrayerCardBackground = Color(0xE8FFFFFF);',
    'static const Color homePrayerCardBackground = Color(0xFFFFFFFF);',
  );
  // Soft day/preDawn bottoms — no orange mud under the glass card.
  c = c.replaceFirst(
    'static const Color homeNextPrayerGradientBottom = Color(0xFFFFE0D4);',
    'static const Color homeNextPrayerGradientBottom = Color(0xFFF4F4F4);',
  );
  c = c.replaceFirst(
    'static const Color homeNextPrayerGradientDayMid = Color(0xFFF2E6C9);',
    'static const Color homeNextPrayerGradientDayMid = Color(0xFFF7F7F7);',
  );
  c = c.replaceFirst(
    'static const Color homeNextPrayerGradientTop = Color(0xFFFCF8F0);',
    'static const Color homeNextPrayerGradientTop = Color(0xFFF4F4F4);',
  );
  c = c.replaceFirst(
    'static const Color homeNextPrayerGradientPreDawnBottom = Color(0xFFE8E8E8);',
    'static const Color homeNextPrayerGradientPreDawnBottom = Color(0xFFF4F4F4);',
  );
  // Night: keep atmospheric but softer charcoal (less muddy under white card).
  c = c.replaceFirst(
    'static const Color homeNextPrayerGradientNightTop = Color(0xFF3A3A3A);',
    'static const Color homeNextPrayerGradientNightTop = Color(0xFF2E2E2E);',
  );
  c = c.replaceFirst(
    'static const Color homeNextPrayerGradientNightBottom = Color(0xFF1F1F1F);',
    'static const Color homeNextPrayerGradientNightBottom = Color(0xFF1A1A1A);',
  );
  // Watermark → near-black at low alpha (was sage green).
  c = c.replaceFirst(
    'static const Color homePrayerCardWatermark = primarySage;',
    'static const Color homePrayerCardWatermark = tripGlideInk;',
  );
  c = c.replaceFirst(
    'static const Color homePrayerCardWatermarkDark = Color(0xFF4A7A6E);',
    'static const Color homePrayerCardWatermarkDark = Color(0xFFB0B0B0);',
  );
  // Soft glow behind hero — cool, not peach.
  c = c.replaceFirst(
    'static const Color homeBackgroundGlow = Color(0xFFFFE8E0);',
    'static const Color homeBackgroundGlow = Color(0xFFF4F4F4);',
  );
  colors.writeAsStringSync(c);

  // Drop ink vignette that reads as a dirty band under the prayer card.
  final bg = File(
    'apps/tilawa/lib/features/home/presentation/widgets/home_hero_background.dart',
  );
  var b = bg.readAsStringSync();
  b = b.replaceFirst(
    '''        DecoratedBox(
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
''',
    '',
  );
  // colorScheme may become unused — check if still used elsewhere in build.
  if (!b.contains('colorScheme.')) {
    b = b.replaceFirst(
      '    final ColorScheme colorScheme = theme.colorScheme;\n',
      '',
    );
  }
  bg.writeAsStringSync(b);

  // Soften bottom canvas fade — was stacking a second muddy band.
  final prayer = File(
    'apps/tilawa/lib/features/home/presentation/widgets/home_next_prayer_time.dart',
  );
  var p = prayer.readAsStringSync();
  p = p.replaceFirst(
    '''            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: tokens.spaceExtraLarge,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        canvasBottom.withValues(alpha: 0),
                        canvasBottom.withValues(alpha: 0.72),
                        canvasBottom,
                      ],
                      stops: const <double>[0, 0.55, 1],
                    ),
                  ),
                ),
              ),
            ),
''',
            '''            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: tokens.spaceMedium,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        canvasBottom.withValues(alpha: 0),
                        canvasBottom,
                      ],
                    ),
                  ),
                ),
              ),
            ),
''',
  );
  prayer.writeAsStringSync(p);

  stdout.writeln('Hero background cleaned');
}
