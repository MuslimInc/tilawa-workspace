import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// Qibla compass rose. Outer dashed ring, inner soft ring, brand needle,
/// emerald hub with a gold mosque glyph. Mirrors `.tw-compass`.
class TilawaCompassRose extends StatelessWidget {
  const TilawaCompassRose({
    required this.headingDegrees,
    this.size = 240,
    super.key,
  });

  /// Where the needle points, in degrees clockwise from north (0–360).
  final double headingDegrees;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background plate with gradient + ring shadow.
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFFFFF), TilawaPalette.sky50],
              ),
              boxShadow: TilawaShadows.el2,
              border: Border.all(color: TilawaPalette.hairline),
            ),
          ),
          // Outer dashed ring.
          Padding(
            padding: const EdgeInsets.all(14),
            child: CustomPaint(
              painter: _DashedRingPainter(
                color: const Color(0x2E2D5C3F),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          // Inner soft ring.
          Padding(
            padding: const EdgeInsets.all(40),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x142D5C3F),
                ),
              ),
            ),
          ),
          // Cardinal marks.
          const _Mark(text: 'N', alignment: Alignment.topCenter, highlight: true),
          const _Mark(text: 'S', alignment: Alignment.bottomCenter),
          const _Mark(text: 'E', alignment: Alignment.centerRight),
          const _Mark(text: 'W', alignment: Alignment.centerLeft),
          // Needle.
          Transform.rotate(
            angle: headingDegrees * math.pi / 180,
            child: _Needle(height: size * 0.4),
          ),
          // Center hub.
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: TilawaPalette.green700,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x592D5C3F),
                  offset: Offset(0, 6),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'ﷲ',
                style: TextStyle(
                  fontFamily: TilawaFontFamily.arabic,
                  color: TilawaPalette.gold300,
                  fontSize: 22,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Needle extends StatelessWidget {
  const _Needle({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.5),
      child: Container(
        width: 4,
        height: height,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0x002D5C3F), TilawaPalette.green600],
          ),
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({
    required this.text,
    required this.alignment,
    this.highlight = false,
  });

  final String text;
  final Alignment alignment;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: TilawaFontFamily.ui,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: highlight
                ? TilawaPalette.green700
                : TilawaPalette.inkMuted,
          ),
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 0.5;
    const dashCount = 60;
    const sweep = (2 * math.pi) / dashCount;
    const dashSweep = sweep * 0.45;

    for (int i = 0; i < dashCount; i++) {
      final start = i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dashSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}
