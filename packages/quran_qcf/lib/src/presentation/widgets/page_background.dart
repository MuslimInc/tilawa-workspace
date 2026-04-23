import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that renders the background of a Quran page.
///
/// Implements a subtle noise texture to add a premium, tactile feel
/// as per the project design guidelines.
class PageBackground extends StatelessWidget {
  const PageBackground({
    super.key,
    required this.color,
    this.showNoise = true,
    this.child,
  });

  /// The base background color.
  final Color color;

  /// Whether to show the subtle noise texture.
  final bool showNoise;

  /// The content to display over the background.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color),
      child: Stack(
        children: [
          if (showNoise)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _NoisePainter(seed: color.value, opacity: 0.015),
                ),
              ),
            ),
          ?child,
        ],
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter({required this.seed, required this.opacity});

  final int seed;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw a high density of tiny dots to simulate grain
    // Optimization: we don't need to cover every pixel, just enough to create texture
    for (var i = 0; i < 5000; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final int gray =
          random.nextInt(50) + 100; // 100-150 range for subtle variation

      paint.color = Color.fromARGB(
        (random.nextDouble() * 255 * opacity).toInt(),
        gray,
        gray,
        gray,
      );

      canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(_NoisePainter oldDelegate) => oldDelegate.seed != seed;
}
