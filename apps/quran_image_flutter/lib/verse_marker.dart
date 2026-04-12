import 'dart:math' as math;
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
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: const _FloralMarkerPainter(),
          ),
          Padding(
            padding: EdgeInsets.only(top: width * 0.05),
            child: Text(
              verseNumber.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'QuranNumbers',
                fontSize: width * 0.42,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D4037),
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloralMarkerPainter extends CustomPainter {
  const _FloralMarkerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final petalRadius = radius * 0.95;
    final innerRadius = radius * 0.6;

    final paint =
        Paint()
          ..color = const Color(0xFFC5A358)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.05
          ..strokeCap = StrokeCap.round;

    final fillPaint =
        Paint()
          ..color = const Color(0xFFFBF4E4)
          ..style = PaintingStyle.fill;

    final path = Path();
    const int petalCount = 8;
    const double angleStep = (2 * math.pi) / petalCount;

    for (int i = 0; i < petalCount; i++) {
      final double startAngle = i * angleStep;
      final double endAngle = (i + 1) * angleStep;
      final double midAngle = (startAngle + endAngle) / 2;

      final p1 = Offset(
        center.dx + innerRadius * math.cos(startAngle),
        center.dy + innerRadius * math.sin(startAngle),
      );
      final pCtrl = Offset(
        center.dx + petalRadius * 1.4 * math.cos(midAngle),
        center.dy + petalRadius * 1.4 * math.sin(midAngle),
      );
      final p2 = Offset(
        center.dx + innerRadius * math.cos(endAngle),
        center.dy + innerRadius * math.sin(endAngle),
      );

      if (i == 0) path.moveTo(p1.dx, p1.dy);
      path.quadraticBezierTo(pCtrl.dx, pCtrl.dy, p2.dx, p2.dy);
    }
    path.close();

    // Draw shadow
    canvas.drawPath(
      path.shift(Offset(size.width * 0.02, size.width * 0.02)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.05),
    );

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Inner ring
    canvas.drawCircle(
      center,
      innerRadius * 0.85,
      paint..strokeWidth = size.width * 0.02,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
