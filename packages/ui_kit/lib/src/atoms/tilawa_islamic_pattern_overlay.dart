import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Placement for [TilawaIslamicPatternOverlay].
enum TilawaIslamicPatternPlacement {
  /// Full-bleed subtle lattice across the host bounds.
  fullField,

  /// Bottom-trailing corner accent for compact tiles.
  cornerTrailing,
}

/// Procedural 8-point star lattice for premium spiritual surfaces.
///
/// Token-driven color and opacity — no bitmap assets.
class TilawaIslamicPatternOverlay extends StatelessWidget {
  /// Creates a pattern overlay.
  const TilawaIslamicPatternOverlay({
    super.key,
    required this.color,
    required this.opacity,
    this.cellSize = 28,
    this.placement = TilawaIslamicPatternPlacement.fullField,
  });

  final Color color;
  final double opacity;
  final double cellSize;
  final TilawaIslamicPatternPlacement placement;

  @override
  Widget build(BuildContext context) {
    final Widget field = CustomPaint(
      painter: _IslamicStarLatticePainter(
        color: color.withValues(alpha: opacity),
        cellSize: cellSize,
      ),
    );

    if (placement == TilawaIslamicPatternPlacement.fullField) {
      return field;
    }

    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: FractionallySizedBox(
        widthFactor: 0.52,
        heightFactor: 0.52,
        child: field,
      ),
    );
  }
}

class _IslamicStarLatticePainter extends CustomPainter {
  _IslamicStarLatticePainter({
    required this.color,
    required this.cellSize,
  });

  final Color color;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) {
      return;
    }

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    final double step = cellSize;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        _drawEightPointStar(canvas, Offset(x, y), step * 0.34, stroke);
      }
    }
  }

  void _drawEightPointStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final Path path = Path();
    for (var i = 0; i < 8; i++) {
      final double angle = (math.pi / 4) * i - math.pi / 2;
      final Offset point =
          center +
          Offset(
            math.cos(angle) * radius,
            math.sin(angle) * radius,
          );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    final double inner = radius * 0.42;
    final Path innerSquare = Path();
    for (var i = 0; i < 4; i++) {
      final double angle = (math.pi / 2) * i + math.pi / 4;
      final Offset point =
          center +
          Offset(
            math.cos(angle) * inner,
            math.sin(angle) * inner,
          );
      if (i == 0) {
        innerSquare.moveTo(point.dx, point.dy);
      } else {
        innerSquare.lineTo(point.dx, point.dy);
      }
    }
    innerSquare.close();
    canvas.drawPath(innerSquare, paint);
  }

  @override
  bool shouldRepaint(covariant _IslamicStarLatticePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.cellSize != cellSize;
  }
}
