import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tilawa/core/extensions.dart';

import '../../domain/entities/qibla_direction_entity.dart';

/// The outer size of the compass widget including text labels.
const double _kCompassOuterSize = 380;

/// The inner dial circle size.
const double _kCompassDialSize = 300;

class QiblaCompassWidget extends StatelessWidget {
  const QiblaCompassWidget({super.key, required this.qiblaDirection});

  final QiblaDirectionEntity qiblaDirection;

  @override
  Widget build(BuildContext context) {
    // Guard against invalid sensor data.
    if (qiblaDirection.direction.isNaN || qiblaDirection.direction.isInfinite) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isAligned = qiblaDirection.isAligned;
    final Color alignedColor = colorScheme.primary;
    final Color unalignedColor = colorScheme.onSurface;

    // Use the offset (Qibla angle - Device heading)
    // The device heading (direction.direction) rotates the dial
    // The qibla arrow should point to Qibla relative to North

    // Logic:
    // 1. We rotate the whole dial by -heading. This makes "North" on the dial point to real North.
    // 2. We place the Qibla arrow on the dial at the Qibla angle.
    // Result: Qibla arrow points to Qibla.

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _kCompassOuterSize.r,
          height: _kCompassOuterSize.r,
          child: Semantics(
            label: 'Qibla Compass',
            hint: 'Rotate your device to align the arrow with the Qibla',
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The Dial (Rotates with device heading)
                Transform.rotate(
                  angle: qiblaDirection.direction * (math.pi / 180) * -1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. The Dial Circle and Ticks (Constrained to 300)
                      SizedBox(
                        width: _kCompassDialSize.r,
                        height: _kCompassDialSize.r,
                        child: CustomPaint(
                          size: Size(_kCompassDialSize.r, _kCompassDialSize.r),
                          painter: _CompassDialPainter(
                            colorScheme: colorScheme,
                            tickInset: 5.r,
                            majorTickLength: 12.r,
                            minorTickLength: 8.r,
                            smallTickLength: 5.r,
                            borderWidth: 2.r,
                          ),
                        ),
                      ),
                      // 2. Cardinal Directions (Static relative to Dial)
                      _CompassText(
                        text: context.l10n.north,
                        angleDeg: 0,
                        heading: qiblaDirection.direction,
                      ), // N
                      _CompassText(
                        text: context.l10n.east,
                        angleDeg: 90,
                        heading: qiblaDirection.direction,
                      ), // E
                      _CompassText(
                        text: context.l10n.south,
                        angleDeg: 180,
                        heading: qiblaDirection.direction,
                      ), // S
                      _CompassText(
                        text: context.l10n.west,
                        angleDeg: 270,
                        heading: qiblaDirection.direction,
                      ), // W
                    ],
                  ),
                ),

                // Center Indicator (Fixed on Screen) - Acts as the cap
                Container(
                  width: 10.r,
                  height: 10.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAligned ? alignedColor : unalignedColor,
                    boxShadow: [
                      BoxShadow(
                        color: (isAligned ? alignedColor : unalignedColor)
                            .withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // 3. Qibla Pointer (Central Arrow) - Independent rotation based on manual calculation
                Transform.rotate(
                  angle: (qiblaDirection.offset - qiblaDirection.direction) *
                      (math.pi / 180),
                  child: _QiblaPointer(isAligned: qiblaDirection.isAligned),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          '${(qiblaDirection.direction % 360).toStringAsFixed(0)}°',
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 48.sp,
            fontWeight: FontWeight.bold,
            color: isAligned ? alignedColor : unalignedColor,
            shadows: [
              Shadow(
                color: (isAligned ? alignedColor : Colors.black).withValues(
                  alpha: 0.5,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          context.l10n.toQibla,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16.sp,
            color: unalignedColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _CompassText extends StatelessWidget {
  const _CompassText({
    required this.text,
    required this.angleDeg,
    required this.heading,
  });

  final String text;
  final double angleDeg;
  final double heading;

  @override
  Widget build(BuildContext context) {
    // Position text around circle
    // We use a Container located at the top center, then rotated
    return Transform.rotate(
      angle: angleDeg * (math.pi / 180),
      child: Container(
        alignment: Alignment.topCenter,
        height: _kCompassOuterSize.r,
        child: Padding(
          padding: EdgeInsets.only(top: 10.r),
          child: Transform.rotate(
            angle: (heading - angleDeg) * (math.pi / 180), // Counter-rotate
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QiblaPointer extends StatelessWidget {
  const _QiblaPointer({required this.isAligned});

  final bool isAligned;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color alignedColor = colorScheme.primary;
    // Using tertiary for the gold-ish accent if available, otherwise secondary
    final Color unalignedColor = colorScheme.tertiary;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.onSecondary,
      ),
      child: Icon(
        Icons.arrow_upward_rounded,
        color: isAligned ? alignedColor : unalignedColor,
        size: 100.r,
        shadows: [
          Shadow(
            color: (isAligned ? alignedColor : unalignedColor).withValues(
              alpha: 0.5,
            ),
            blurRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  _CompassDialPainter({
    required this.colorScheme,
    required this.tickInset,
    required this.majorTickLength,
    required this.minorTickLength,
    required this.smallTickLength,
    required this.borderWidth,
  });

  final ColorScheme colorScheme;
  final double tickInset;
  final double majorTickLength;
  final double minorTickLength;
  final double smallTickLength;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    // Background Circle
    final bgPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawCircle(center, radius, borderPaint);

    // Ticks
    final tickPaint = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final majorTickPaint = Paint()
      ..color = colorScheme.onSurface
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 360; i += 5) {
      // Every 5 degrees
      final isMajor = i % 90 == 0;
      final isMinor = i % 30 == 0;

      final double angle = (i - 90) * (math.pi / 180);
      final length = isMajor
          ? majorTickLength
          : (isMinor ? minorTickLength : smallTickLength);

      final p1 = Offset(
        center.dx + (radius - tickInset) * math.cos(angle),
        center.dy + (radius - tickInset) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - tickInset - length) * math.cos(angle),
        center.dy + (radius - tickInset - length) * math.sin(angle),
      );

      canvas.drawLine(p1, p2, isMajor ? majorTickPaint : tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) =>
      colorScheme.surfaceContainerHighest !=
          oldDelegate.colorScheme.surfaceContainerHighest ||
      colorScheme.onSurface != oldDelegate.colorScheme.onSurface ||
      colorScheme.outline != oldDelegate.colorScheme.outline ||
      tickInset != oldDelegate.tickInset ||
      majorTickLength != oldDelegate.majorTickLength ||
      borderWidth != oldDelegate.borderWidth;
}
