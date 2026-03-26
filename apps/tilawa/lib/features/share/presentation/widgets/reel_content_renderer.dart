import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart';

/// A widget that renders a specific range of ayahs for a reel,
/// matching the styling of the Quran Reader.
class ReelContentRenderer extends StatelessWidget {
  const ReelContentRenderer({
    super.key,
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    this.showBasmalah = true,
  });

  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final bool showBasmalah;

  String get _surahName => getSurahNameArabic(surahNumber);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        color: Color(0xFFFDF9F0), // Mushaf-like cream
      ),
      child: Stack(
        children: [
          // Subtle texture/noise would go here if we had an asset, 
          // but we can simulate with a very faint gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 120),
            child: Column(
              children: [
                // Branding Header
                const _ReelBrandingHeader(),
                const Spacer(flex: 1),
                
                // Surah Header (Exact Reader Style)
                _SurahHeader(name: _surahName, number: surahNumber),
                const SizedBox(height: 80),
                
                // Basmalah (If applicable)
                if (showBasmalah && surahNumber != 1 && surahNumber != 9 && fromAyah == 1) ...[
                  Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                    style: GoogleFonts.amiri(
                      fontSize: 64,
                      color: Colors.black.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 80),
                ],
                
                // Content (Continuous text like Reader)
                Expanded(
                  flex: 10,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: _AyahFlow(
                      surahNumber: surahNumber,
                      fromAyah: fromAyah,
                      toAyah: toAyah,
                    ),
                  ),
                ),
                
                const Spacer(flex: 1),
                // Footer
                const _ReelFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelBrandingHeader extends StatelessWidget {
  const _ReelBrandingHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.auto_stories, color: Colors.amber[900], size: 48),
        const SizedBox(height: 12),
        Text(
          'Tilawa',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: Colors.brown[900],
          ),
        ),
      ],
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.name, required this.number});
  final String name;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EAD2),
        border: Border.all(color: Colors.brown.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'سورة $name',
          style: GoogleFonts.amiri(
            fontSize: 54,
            fontWeight: FontWeight.bold,
            color: Colors.brown[800],
          ),
        ),
      ),
    );
  }
}

class _AyahFlow extends StatelessWidget {
  const _AyahFlow({
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
  });

  final int surahNumber;
  final int fromAyah;
  final int toAyah;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    
    // Scaled style to match Reader aesthetics at Reel resolution
    final textStyle = GoogleFonts.amiri(
      fontSize: 62,
      height: 2.2,
      color: Colors.black.withValues(alpha: 0.85),
    );

    for (int i = fromAyah; i <= toAyah; i++) {
      final text = getVerse(surahNumber, i, verseEndSymbol: true);
      spans.add(
        TextSpan(
          text: '$text ',
          style: textStyle,
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }
}

class _ReelFooter extends StatelessWidget {
  const _ReelFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 200,
          height: 1,
          color: Colors.brown.withValues(alpha: 0.2),
          margin: const EdgeInsets.only(bottom: 16),
        ),
        Text(
          'Shared via Tilawa App',
          style: GoogleFonts.outfit(
            fontSize: 24,
            color: Colors.brown[400],
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
