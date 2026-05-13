import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class AthkarAmbientBackground extends StatelessWidget {
  const AthkarAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExcludeSemantics(
      child: CustomPaint(
        painter: _AthkarAmbientPainter(
          colorScheme: theme.colorScheme,
          tokens: theme.tokens,
        ),
      ),
    );
  }
}

class _AthkarAmbientPainter extends CustomPainter {
  const _AthkarAmbientPainter({
    required this.colorScheme,
    required this.tokens,
  });

  final ColorScheme colorScheme;
  final TilawaDesignTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final upperCenter = Offset(size.width * 0.12, size.height * 0.1);
    final lowerCenter = Offset(size.width * 0.88, size.height * 0.72);

    final primaryStroke = Paint()
      ..color = colorScheme.primary.withValues(
        alpha: tokens.opacitySubtle * 0.34,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.borderWidthThin;
    final tertiaryStroke = Paint()
      ..color = colorScheme.tertiary.withValues(
        alpha: tokens.opacitySubtle * 0.26,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.borderWidthThin;

    for (final factor in <double>[0.42, 0.66]) {
      canvas.drawArc(
        Rect.fromCircle(center: upperCenter, radius: shortest * factor),
        -math.pi * 0.08,
        math.pi * 0.5,
        false,
        primaryStroke,
      );
    }

    for (final factor in <double>[0.48, 0.76]) {
      canvas.drawArc(
        Rect.fromCircle(center: lowerCenter, radius: shortest * factor),
        math.pi * 0.9,
        math.pi * 0.46,
        false,
        tertiaryStroke,
      );
    }
  }

  @override
  bool shouldRepaint(_AthkarAmbientPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.tokens != tokens;
  }
}
