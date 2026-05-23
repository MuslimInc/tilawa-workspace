import 'package:flutter/material.dart';

import '../support_tier_visual.dart';

/// Open-corner ambient arcs for support tier cards (reciters-style restraint).
class SupportTierArcPainter extends CustomPainter {
  SupportTierArcPainter({
    required this.color,
    required this.variant,
    required this.textDirection,
  });

  final Color color;
  final SupportTierArcVariant variant;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;

    final bool rtl = textDirection == TextDirection.rtl;
    final double w = size.width;
    final double h = size.height;
    final Offset origin = rtl ? Offset(w, 0) : Offset.zero;
    final double sign = rtl ? -1 : 1;

    switch (variant) {
      case SupportTierArcVariant.light:
        final Path single = Path()
          ..moveTo(origin.dx + sign * w * 0.55, h * 0.08)
          ..quadraticBezierTo(
            origin.dx + sign * w * 0.15,
            h * 0.35,
            origin.dx + sign * w * 0.35,
            h * 0.55,
          );
        canvas.drawPath(single, paint);
      case SupportTierArcVariant.balanced:
        final Path upper = Path()
          ..moveTo(origin.dx + sign * w * 0.6, h * 0.06)
          ..quadraticBezierTo(
            origin.dx + sign * w * 0.2,
            h * 0.28,
            origin.dx + sign * w * 0.4,
            h * 0.48,
          );
        final Path lower = Path()
          ..moveTo(origin.dx + sign * w * 0.72, h * 0.18)
          ..quadraticBezierTo(
            origin.dx + sign * w * 0.38,
            h * 0.42,
            origin.dx + sign * w * 0.52,
            h * 0.62,
          );
        canvas.drawPath(upper, paint);
        canvas.drawPath(lower, paint);
      case SupportTierArcVariant.full:
        final Path wave = Path()
          ..moveTo(origin.dx + sign * w * 0.65, h * 0.05)
          ..quadraticBezierTo(
            origin.dx + sign * w * 0.25,
            h * 0.22,
            origin.dx + sign * w * 0.45,
            h * 0.4,
          )
          ..quadraticBezierTo(
            origin.dx + sign * w * 0.62,
            h * 0.55,
            origin.dx + sign * w * 0.3,
            h * 0.68,
          );
        canvas.drawPath(wave, paint);
    }
  }

  @override
  bool shouldRepaint(SupportTierArcPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.variant != variant ||
        oldDelegate.textDirection != textDirection;
  }
}
