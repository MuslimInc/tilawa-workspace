import 'package:flutter/material.dart';

class VerseMarker extends StatelessWidget {
  final int verseNumber;
  final double width;
  final double height;

  const VerseMarker({
    super.key,
    required this.verseNumber,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final double borderW = (width * 0.08).clamp(1.0, 2.0);
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width / 2),
          border: Border.all(
            color: const Color(0xFFC5A358), // Gold/Bronze border
            width: borderW,
          ),
          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC5A358).withValues(alpha: 0.3),
              blurRadius: width * 0.2,
              spreadRadius: width * 0.05,
            ),
          ],
        ),
        child: Center(
          child: Text(
            verseNumber.toString(),
            textAlign: TextAlign.center,
            overflow: TextOverflow.clip,
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'QuranNumbers',
              fontSize: width * 0.46,
              height: 1.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4037),
            ),
          ),
        ),
      ),
    );
  }
}
