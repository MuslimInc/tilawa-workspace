import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// Circular progress ring with an optional centered child. Used for
/// surah-read progress visualisations.
class TilawaProgressRing extends StatelessWidget {
  const TilawaProgressRing({
    required this.value,
    this.size = 56,
    this.strokeWidth = 4,
    this.child,
    this.trackColor,
    this.fillColor,
    super.key,
  }) : assert(value >= 0 && value <= 1);

  final double value;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final Color? trackColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final c = TilawaTheme.of(context).tokens.colors;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              value: value,
              strokeWidth: strokeWidth,
              track: trackColor ?? c.hairline,
              fill: fillColor ?? c.brand,
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.track,
    required this.fill,
  });

  final double value;
  final double strokeWidth;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (value > 0) {
      final fillPaint = Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.fill != fill ||
      old.track != track ||
      old.strokeWidth != strokeWidth;
}
