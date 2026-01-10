import 'package:flutter/material.dart';

class QuranPageTopBar extends StatelessWidget {
  const QuranPageTopBar({
    super.key,
    required this.surahNameEnglish,
    required this.juzNumber,
  });

  final String surahNameEnglish;
  final int juzNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Surah Name (English)
          Text(
            surahNameEnglish,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA1887F),
            ),
          ),

          // Right: Part X
          Text(
            'Part $juzNumber',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA1887F),
            ),
          ),
        ],
      ),
    );
  }
}
