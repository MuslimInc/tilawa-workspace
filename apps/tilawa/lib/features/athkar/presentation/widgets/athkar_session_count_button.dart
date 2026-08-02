import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Larger session counter: remaining count inside an arc progress ring.
///
/// Progress arc = completed fraction `(total - remaining) / total`.
class AthkarSessionCountButton extends StatelessWidget {
  const AthkarSessionCountButton({
    super.key,
    required this.currentCount,
    required this.totalCount,
    required this.isDone,
    required this.onTap,
    this.scale = kAthkarSessionCountScale,
  });

  /// Scale relative to [TilawaCountProgressRingTokens.outerSize].
  static const double kAthkarSessionCountScale = 1.45;

  final int currentCount;
  final int totalCount;
  final bool isDone;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaCountProgressRingTokens ringTokens =
        theme.componentTokens.countProgressRing;
    final ColorScheme colorScheme = theme.colorScheme;
    final double layoutSize = ringTokens.outerSize * scale;
    final double strokeWidth = ringTokens.ringStrokeWidth > 0
        ? ringTokens.ringStrokeWidth * scale
        : theme.componentTokens.loadingIndicator.defaultStrokeWidth;
    final double progress = totalCount <= 0
        ? 0
        : isDone
        ? 1
        : ((totalCount - currentCount) / totalCount).clamp(0.0, 1.0);

    return Semantics(
      button: true,
      label: isDone ? null : '$currentCount / $totalCount',
      value: isDone ? null : '$currentCount',
      child: SizedBox(
        width: layoutSize,
        height: layoutSize,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface,
                boxShadow: tokens.elevationFloating(colorScheme.shadow),
              ),
              child: CustomPaint(
                painter: _AthkarCountArcPainter(
                  progress: progress,
                  isDone: isDone,
                  strokeWidth: strokeWidth,
                  trackColor: colorScheme.outlineVariant,
                  progressColor: isDone
                      ? colorScheme.tertiary
                      : colorScheme.primary,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: tokens.durationFast,
                    switchInCurve: tokens.curveSymmetric,
                    switchOutCurve: tokens.curveSymmetric,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                    child: isDone
                        ? Icon(
                            key: const ValueKey<String>('done'),
                            TilawaIcons.check,
                            color: colorScheme.tertiary,
                            size: ringTokens.doneIconSize * scale,
                          )
                        : Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: ringTokens.countHorizontalPadding,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                key: ValueKey<int>(currentCount),
                                '$currentCount',
                                maxLines: 1,
                                style:
                                    tilawaResolveTextRole(
                                      theme.textTheme,
                                      ringTokens.countTextRole,
                                    ).copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                      height: ringTokens.countLineHeight,
                                    ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AthkarCountArcPainter extends CustomPainter {
  const _AthkarCountArcPainter({
    required this.progress,
    required this.isDone,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final bool isDone;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0 && !isDone) {
      return;
    }

    final Paint progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double sweep = isDone ? math.pi * 2 : progress * math.pi * 2;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _AthkarCountArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDone != isDone ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
