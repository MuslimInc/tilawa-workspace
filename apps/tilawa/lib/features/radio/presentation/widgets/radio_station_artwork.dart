import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Geometric artwork placeholder for radio stations (no figurative art).
class RadioStationArtwork extends StatelessWidget {
  const RadioStationArtwork({
    super.key,
    required this.stationId,
    this.size,
    this.heroTag,
    this.compact = false,
  });

  final String stationId;
  final double? size;
  final String? heroTag;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final product = Theme.of(context).productColors;
    final double extent = size ?? (compact ? tokens.iconBoxSize : 160);
    final Widget art = ClipRRect(
      borderRadius: BorderRadius.circular(
        compact ? tokens.radiusMedium : tokens.radiusLarge,
      ),
      child: SizedBox(
        width: extent,
        height: extent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                product.featuredGradientStart,
                product.featuredGradientEnd,
                colorScheme.primaryContainer,
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _RadioGeometryPainter(
                  color: colorScheme.onPrimary.withValues(alpha: 0.12),
                ),
              ),
              Center(
                child: Icon(
                  Icons.radio_rounded,
                  size: extent * 0.36,
                  color: product.featuredGradientForeground.withValues(
                    alpha: 0.9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final String tag = heroTag ?? 'radio-art-$stationId';
    return Hero(tag: tag, child: art);
  }
}

class _RadioGeometryPainter extends CustomPainter {
  _RadioGeometryPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, size.shortestSide * 0.12 * i, paint);
    }
    canvas.drawLine(
      Offset(0, size.height * 0.2),
      Offset(size.width, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadioGeometryPainter oldDelegate) =>
      oldDelegate.color != color;
}
