import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit_v2/tilawa_ui_kit_v2.dart';

import 'golden_constraints.dart';
import 'preview_wrapper.dart';

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.name});

  final Color color;
  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: TilawaRadii.brSm,
              border: Border.all(color: TilawaPalette.hairline),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontFamily: TilawaFontFamily.ui,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.swatches});

  final List<_Swatch> swatches;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 16,
      children: swatches,
    );
  }
}

class _TypeSpecimen extends StatelessWidget {
  const _TypeSpecimen({
    required this.name,
    required this.style,
    required this.sample,
  });

  final String name;
  final TextStyle style;
  final String sample;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: TilawaFontFamily.ui,
              fontSize: 10,
              color: TilawaPalette.inkMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(sample, style: style),
        ],
      ),
    );
  }
}

class _RadiusSpecimen extends StatelessWidget {
  const _RadiusSpecimen({required this.label, required this.radius});

  final String label;
  final Radius radius;

  @override
  Widget build(BuildContext context) {
    final r = (radius.x == 999) ? 36.0 : radius.x;
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: TilawaPalette.green100,
              borderRadius: BorderRadius.circular(r),
              border: Border.all(color: TilawaPalette.green600.withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: TilawaFontFamily.ui,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShadowSpecimen extends StatelessWidget {
  const _ShadowSpecimen({required this.label, required this.shadow});

  final String label;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Container(
            height: 56,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: TilawaPalette.card,
              borderRadius: TilawaRadii.brSm,
              boxShadow: shadow,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: TilawaFontFamily.ui,
              fontSize: 10,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SpacingSpecimen extends StatelessWidget {
  const _SpacingSpecimen({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: TilawaFontFamily.ui,
                fontSize: 11,
                color: TilawaPalette.inkMuted,
              ),
            ),
          ),
          Container(
            width: size,
            height: 12,
            color: TilawaPalette.green600,
          ),
          const SizedBox(width: 8),
          Text(
            '${size.toInt()}px',
            style: const TextStyle(
              fontFamily: TilawaFontFamily.ui,
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
              color: TilawaPalette.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('v2 foundation specimens', () {
    goldenTest(
      'Brand palette',
      fileName: 'foundation/palette',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2ScreenConstraints,
        children: [
          GoldenTestScenario(
            name: 'Emerald · 50–900',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 360,
                child: _PaletteRow(
                  swatches: [
                    _Swatch(color: TilawaPalette.green50, name: 'green50'),
                    _Swatch(color: TilawaPalette.green100, name: 'green100'),
                    _Swatch(color: TilawaPalette.green200, name: 'green200'),
                    _Swatch(color: TilawaPalette.green300, name: 'green300'),
                    _Swatch(color: TilawaPalette.green400, name: 'green400'),
                    _Swatch(color: TilawaPalette.green500, name: 'green500'),
                    _Swatch(color: TilawaPalette.green600, name: 'green600 ★'),
                    _Swatch(color: TilawaPalette.green700, name: 'green700'),
                    _Swatch(color: TilawaPalette.green800, name: 'green800'),
                    _Swatch(color: TilawaPalette.green900, name: 'green900'),
                  ],
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Gold + Sky',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 360,
                child: _PaletteRow(
                  swatches: [
                    _Swatch(color: TilawaPalette.gold100, name: 'gold100'),
                    _Swatch(color: TilawaPalette.gold300, name: 'gold300'),
                    _Swatch(color: TilawaPalette.gold500, name: 'gold500 ★'),
                    _Swatch(color: TilawaPalette.gold700, name: 'gold700'),
                    _Swatch(color: TilawaPalette.sky50, name: 'sky50'),
                    _Swatch(color: TilawaPalette.sky100, name: 'sky100'),
                    _Swatch(color: TilawaPalette.sky200, name: 'sky200'),
                  ],
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Neutrals + Semantic',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 360,
                child: _PaletteRow(
                  swatches: [
                    _Swatch(color: TilawaPalette.ink, name: 'ink'),
                    _Swatch(color: TilawaPalette.inkMuted, name: 'inkMuted'),
                    _Swatch(color: TilawaPalette.paper, name: 'paper'),
                    _Swatch(color: TilawaPalette.card, name: 'card'),
                    _Swatch(color: TilawaPalette.success, name: 'success'),
                    _Swatch(color: TilawaPalette.warning, name: 'warning'),
                    _Swatch(color: TilawaPalette.danger, name: 'danger'),
                    _Swatch(color: TilawaPalette.info, name: 'info'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'Typography ramp',
      fileName: 'foundation/typography',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2ScreenConstraints,
        children: [
          GoldenTestScenario(
            name: 'marketing ramp',
            child: Builder(
              builder: (context) {
                return V2PreviewWrapper(
                  child: SizedBox(
                    width: 360,
                    child: Builder(
                      builder: (context) {
                        final t = TilawaTheme.of(context).typography;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TypeSpecimen(
                              name: 'DISPLAY · 56',
                              style: t.display.copyWith(fontSize: 36),
                              sample: 'Tilāwa',
                            ),
                            _TypeSpecimen(
                              name: 'H1 · 42',
                              style: t.h1.copyWith(fontSize: 28),
                              sample: 'Recitation',
                            ),
                            _TypeSpecimen(
                              name: 'H2 · 32',
                              style: t.h2.copyWith(fontSize: 22),
                              sample: 'Continue listening',
                            ),
                            _TypeSpecimen(
                              name: 'H3 · 22',
                              style: t.h3,
                              sample: 'Surah Al-Mulk',
                            ),
                            _TypeSpecimen(
                              name: 'LEAD · 20',
                              style: t.lead,
                              sample:
                                  'A modern audio Quran player.',
                            ),
                            _TypeSpecimen(
                              name: 'BODY · 16',
                              style: t.body,
                              sample:
                                  'Bring peace and tranquility into everyday life.',
                            ),
                            _TypeSpecimen(
                              name: 'CAPTION · 14',
                              style: t.caption,
                              sample: 'Last read 2 hours ago',
                            ),
                            _TypeSpecimen(
                              name: 'OVERLINE · 12',
                              style: t.overline,
                              sample: 'CHAPTER 36',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          GoldenTestScenario(
            name: 'mobile ramp',
            child: V2PreviewWrapper(
              child: SizedBox(
                width: 360,
                child: Builder(
                  builder: (context) {
                    final t = TilawaTheme.of(context).typography;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TypeSpecimen(
                          name: 'HERO · 26',
                          style: t.heroMobile,
                          sample: 'Assalamu alaikum',
                        ),
                        _TypeSpecimen(
                          name: 'H2 MOBILE · 17',
                          style: t.h2Mobile,
                          sample: 'Continue listening',
                        ),
                        _TypeSpecimen(
                          name: 'H3 MOBILE · 15',
                          style: t.h3Mobile,
                          sample: 'Al-Fatihah',
                        ),
                        _TypeSpecimen(
                          name: 'BODY MOBILE · 14',
                          style: t.bodyMobile,
                          sample:
                              'Tap a verse to hear it recited.',
                        ),
                        _TypeSpecimen(
                          name: 'CAPTION MOBILE · 12',
                          style: t.captionMobile,
                          sample: 'Meccan · 7 verses',
                        ),
                        _TypeSpecimen(
                          name: 'OVERLINE · 11',
                          style: t.overlineMobile,
                          sample: 'NOW RECITING',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'arabic specimens',
            child: V2PreviewWrapper(
              child: SizedBox(
                width: 360,
                child: Builder(
                  builder: (context) {
                    final t = TilawaTheme.of(context).typography;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
                            style: t.arabicDisplay.copyWith(fontSize: 32),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            'وَنَزَّلْنَا عَلَيْكَ ٱلْكِتَٰبَ تِبْيَٰنًا لِّكُلِّ شَىْءٍ',
                            style: t.arabic,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'Radii',
      fileName: 'foundation/radii',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2ScreenConstraints,
        children: [
          GoldenTestScenario(
            name: 'corner radii',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 360,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 16,
                  children: [
                    _RadiusSpecimen(label: 'xs · 6', radius: TilawaRadii.xs),
                    _RadiusSpecimen(label: 'sm · 8', radius: TilawaRadii.sm),
                    _RadiusSpecimen(label: 'md · 12', radius: TilawaRadii.md),
                    _RadiusSpecimen(label: 'lg · 16', radius: TilawaRadii.lg),
                    _RadiusSpecimen(label: 'xl · 20', radius: TilawaRadii.xl),
                    _RadiusSpecimen(label: '2xl · 32', radius: TilawaRadii.xl2),
                    _RadiusSpecimen(label: '3xl · 40', radius: TilawaRadii.xl3),
                    _RadiusSpecimen(label: 'pill', radius: TilawaRadii.pill),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'Shadows',
      fileName: 'foundation/shadows',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2ScreenConstraints,
        children: [
          GoldenTestScenario(
            name: 'elevation tokens',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 360,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 16,
                  children: [
                    _ShadowSpecimen(label: 'xs', shadow: TilawaShadows.xs),
                    _ShadowSpecimen(label: 'md', shadow: TilawaShadows.md),
                    _ShadowSpecimen(label: 'lg', shadow: TilawaShadows.lg),
                    _ShadowSpecimen(label: 'el1', shadow: TilawaShadows.el1),
                    _ShadowSpecimen(label: 'el2', shadow: TilawaShadows.el2),
                    _ShadowSpecimen(
                      label: 'glow (brand)',
                      shadow: TilawaShadows.glow,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'Spacing scale',
      fileName: 'foundation/spacing',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2ScreenConstraints,
        children: [
          GoldenTestScenario(
            name: '4pt scale',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SpacingSpecimen(name: 's1', size: TilawaSpacing.s1),
                    _SpacingSpecimen(name: 's2', size: TilawaSpacing.s2),
                    _SpacingSpecimen(name: 's3', size: TilawaSpacing.s3),
                    _SpacingSpecimen(name: 's4', size: TilawaSpacing.s4),
                    _SpacingSpecimen(name: 's5', size: TilawaSpacing.s5),
                    _SpacingSpecimen(name: 's6', size: TilawaSpacing.s6),
                    _SpacingSpecimen(name: 's8', size: TilawaSpacing.s8),
                    _SpacingSpecimen(name: 's10', size: TilawaSpacing.s10),
                    _SpacingSpecimen(name: 's12', size: TilawaSpacing.s12),
                    _SpacingSpecimen(name: 's16', size: TilawaSpacing.s16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
