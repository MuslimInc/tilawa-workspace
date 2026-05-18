import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// The big centered Quranic verse view used on the player screen.
/// Mirrors `.tw-verseview` — Bismillah → ornamental rule → counter → verse →
/// translation.
class TilawaVerseView extends StatelessWidget {
  const TilawaVerseView({
    required this.verseArabic,
    required this.translation,
    required this.counterLabel,
    this.showBismillah = true,
    super.key,
  });

  final String verseArabic;
  final String translation;
  final String counterLabel;
  final bool showBismillah;

  static const String _bismillah =
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showBismillah) ...[
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                _bismillah,
                textAlign: TextAlign.center,
                style: theme.typography.arabic.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  height: 1.6,
                  color: TilawaPalette.green700,
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
          const _Ornament(),
          const SizedBox(height: 22),
          Text(
            counterLabel.toUpperCase(),
            style: theme.typography.overlineMobile.copyWith(
              fontWeight: FontWeight.w700,
              color: c.fg2,
              letterSpacing: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 22),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              verseArabic,
              textAlign: TextAlign.center,
              style: theme.typography.arabic.copyWith(
                fontSize: 28,
                height: 2.2,
                color: c.fg1,
              ),
            ),
          ),
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              translation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: TilawaFontFamily.ui,
                fontSize: 13,
                height: 1.7,
                color: c.fg2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ornament extends StatelessWidget {
  const _Ornament();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x00D4AF37),
                  TilawaPalette.gold500,
                  Color(0x00D4AF37),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: TilawaPalette.surfaceApp,
            child: const Text(
              '✦',
              style: TextStyle(
                fontSize: 11,
                color: TilawaPalette.gold500,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
