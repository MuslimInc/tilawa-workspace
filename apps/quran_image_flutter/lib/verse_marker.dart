import 'package:flutter/material.dart';

import 'qcf_marker_path.dart';

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

  String _getGlyphMarker(int number) {
    // quran_numbers.ttf contains exactly 286 pre-composed ligatures starting from U+E900.
    // 1 -> U+E900, 2 -> U+E901 ... 286 -> U+EA1D.
    final int clamped = number.clamp(1, 286);
    final int baseCodepoint = 0xE900;
    final int targetCodepoint = baseCodepoint + clamped - 1;
    return String.fromCharCode(targetCodepoint);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: _QcfMarkerPainter(verseNumber: verseNumber),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text(
                _getGlyphMarker(verseNumber),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'QuranNumbers',
                  fontSize: width,
                  color: const Color(0xFF5D4037),
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QcfMarkerPainter extends CustomPainter {
  final int verseNumber;
  const _QcfMarkerPainter({required this.verseNumber});

  @override
  void paint(Canvas canvas, Size size) {
    final path = getQcfMarkerPath(size);

    // Provide a subtle shadow behind the glyph without expensive blurring
    canvas.drawPath(
      path.shift(Offset(size.width * 0.02, size.width * 0.02)),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Draw the main QCF marker with a premium golden color
    final fillPaint = Paint()
      ..color = const Color(0xFFC5A358)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
