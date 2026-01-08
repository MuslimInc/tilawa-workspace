import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/quran_constants.dart';

class SurahHeader extends StatelessWidget {
  const SurahHeader({super.key, required this.surahNumber});

  final int surahNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeaderImage(),
        const SizedBox(height: 16),
        if (surahNumber != 1 && surahNumber != 9) ...[
          _buildBasmalah(),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildHeaderImage() {
    final String surahName =
        QuranConstants.surahNames[surahNumber] ?? 'Surah $surahNumber';

    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6D5).withValues(alpha: 0.5),
        border: const Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFC7B299), width: 2),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Pattern (Placeholder for now)
          const Opacity(
            opacity: 0.1,
            child: Icon(Icons.pattern, size: 60, color: Colors.brown),
          ),

          // Surah Name (Image Asset)
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.black87,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/surahNames/$surahNumber.png',
              width: double.infinity,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  'سُورَةُ $surahName',
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasmalah() {
    return Center(
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        style: GoogleFonts.amiri(fontSize: 24, color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }
}
