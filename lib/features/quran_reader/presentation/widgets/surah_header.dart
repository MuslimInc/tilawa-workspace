import 'package:flutter/material.dart';

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
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFC7B299), width: 2),
        ),
      ),
      child: Center(
        child: Image.asset(
          'assets/surahNames/$surahNumber.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              'سُورَةُ $surahName',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBasmalah() {
    return const Center(
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        style: TextStyle(fontSize: 24, color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }
}
