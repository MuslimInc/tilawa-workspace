import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

enum TilawaNumBadgeVariant {
  /// Soft brand-tinted star — used in surah-list rows.
  soft,

  /// Gold-filled star — emphasised, used in Quranic verse markers.
  gold,

  /// Brand-emerald-filled star — used in PlayerHeader and now-playing dock.
  solid,
}

/// 8-point star ayah marker. A reusable Quranic motif appearing as both the
/// surah-list number badge and inline within verse text.
class TilawaNumBadge extends StatelessWidget {
  const TilawaNumBadge({
    required this.number,
    this.size = 36,
    this.variant = TilawaNumBadgeVariant.soft,
    super.key,
  });

  final int number;
  final double size;
  final TilawaNumBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final (fill, stroke, fg) = switch (variant) {
      TilawaNumBadgeVariant.soft => (
        const Color(0x142D5C3F), // ~0.08 alpha
        const Color(0x282D5C3F), // ~0.16
        TilawaPalette.green700,
      ),
      TilawaNumBadgeVariant.gold => (
        TilawaPalette.gold100,
        TilawaPalette.gold500,
        TilawaPalette.gold700,
      ),
      TilawaNumBadgeVariant.solid => (
        TilawaPalette.green600,
        TilawaPalette.green700,
        Colors.white,
      ),
    };

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _StarPainter(fill: fill, stroke: stroke),
          ),
          Text(
            '$number',
            style: TextStyle(
              fontFamily: TilawaFontFamily.ui,
              fontSize: size * 0.32,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rOuter = size.width * 0.48;
    final rInner = rOuter * 0.74;
    final path = Path();
    const points = 8;
    for (int i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? rOuter : rInner;
      // Start from the top and go clockwise.
      final angle = -math.pi / 2 + i * math.pi / points;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.fill != fill || old.stroke != stroke;
}
