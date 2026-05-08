import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/qibla_direction_entity.dart';
import '../constants/qibla_constants.dart';

// /// The outer size of the compass widget including text labels.
// const double _kCompassOuterSize = 380;

// /// The inner dial circle size.
// const double _kCompassDialSize = 300;

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

    final tokens = theme.tokens;
    final size = MediaQuery.sizeOf(context);
    final compassSize = size.shortestSide * kCompassSizeRatio;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: compassSize,
          height: compassSize,
          child: Semantics(
            label: 'Qibla Compass',
            hint: 'Rotate your device to align the arrow with the Qibla',
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The Dial (Rotates with device heading)
                Transform.rotate(
                  angle: qiblaDirection.direction * (math.pi / 180) * -1,
                  child: _CompassDial(qiblaDirection: qiblaDirection),
                ),

                // Center Indicator (Fixed on Screen) - Acts as the cap
                _CenterIndicator(isAligned: isAligned),

                // 3. Qibla Pointer (Central Arrow)
                Transform.rotate(
                  angle:
                      (qiblaDirection.offset - qiblaDirection.direction) *
                      (math.pi / 180),
                  child: _QiblaPointer(isAligned: isAligned),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: tokens.spaceExtraLarge),
        _AngleDisplay(
          angle: qiblaDirection.direction,
          isAligned: isAligned,
          alignedColor: alignedColor,
          unalignedColor: unalignedColor,
        ),
      ],
    );
  }
}

class _CompassDial extends StatelessWidget {
  const _CompassDial({required this.qiblaDirection});

  final QiblaDirectionEntity qiblaDirection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final size = MediaQuery.sizeOf(context);
    final dialSize = size.shortestSide * kDialSizeRatio;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. The Dial Circle and Ticks
        SizedBox(
          width: dialSize,
          height: dialSize,
          child: CustomPaint(
            size: Size(dialSize, dialSize),
            painter: _CompassDialPainter(
              colorScheme: colorScheme,
              tokens: tokens,
              tickInset: tokens.spaceExtraSmall + kTickInsetOffset,
              majorTickLength: tokens.spaceMedium,
              minorTickLength: tokens.spaceSmall,
              smallTickLength: tokens.spaceExtraSmall + kTickInsetOffset,
              borderWidth: tokens.borderWidthThin * kBorderWidthMultiplier,
            ),
          ),
        ),
        // 2. Cardinal Directions
        _CompassText(
          text: context.l10n.north,
          angleDeg: 0,
          heading: qiblaDirection.direction,
          isVertical: true,
        ),
        _CompassText(
          text: context.l10n.east,
          angleDeg: 90,
          heading: qiblaDirection.direction,
          isVertical: false,
        ),
        _CompassText(
          text: context.l10n.south,
          angleDeg: 180,
          heading: qiblaDirection.direction,
          isVertical: true,
        ),
        _CompassText(
          text: context.l10n.west,
          angleDeg: 270,
          heading: qiblaDirection.direction,
          isVertical: false,
        ),
      ],
    );
  }
}

class _CenterIndicator extends StatelessWidget {
  const _CenterIndicator({required this.isAligned});

  final bool isAligned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final Color color = isAligned ? colorScheme.primary : colorScheme.onSurface;

    return Container(
      width: tokens.spaceSmall + kCenterIndicatorSizeOffset,
      height: tokens.spaceSmall + kCenterIndicatorSizeOffset,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: tokens.opacityEmphasis),
            blurRadius: tokens.blurShadow,
            spreadRadius: kCenterIndicatorShadowSpread,
          ),
        ],
      ),
    );
  }
}

class _AngleDisplay extends StatelessWidget {
  const _AngleDisplay({
    required this.angle,
    required this.isAligned,
    required this.alignedColor,
    required this.unalignedColor,
  });

  final double angle;
  final bool isAligned;
  final Color alignedColor;
  final Color unalignedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Column(
      children: [
        Text(
          '${_displayAngle(angle)}°',
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: kAngleDisplayFontSize,
            fontWeight: kAngleDisplayFontWeight,
            color: isAligned ? alignedColor : unalignedColor,
            shadows: [
              Shadow(
                color: (isAligned ? alignedColor : Colors.black).withValues(
                  alpha: tokens.opacityMedium,
                ),
                blurRadius: tokens.blurShadow,
                offset: tokens.shadowOffsetMedium,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        Text(
          context.l10n.toQibla,
          style: theme.textTheme.titleMedium?.copyWith(
            color: unalignedColor.withValues(alpha: tokens.opacityEmphasis),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  int _displayAngle(double value) {
    final double normalized =
        (value % kFullCircleDegrees + kFullCircleDegrees) % kFullCircleDegrees;
    return normalized.round() % kFullCircleDegrees;
  }
}

class _CompassText extends StatelessWidget {
  const _CompassText({
    required this.text,
    required this.angleDeg,
    required this.heading,
    required this.isVertical,
  });

  final String text;
  final double angleDeg;
  final double heading;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Transform.rotate(
      angle: angleDeg * (math.pi / 180),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: isVertical
              ? EdgeInsets.symmetric(vertical: tokens.spaceSmall)
              : EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
          child: Transform.rotate(
            angle: (heading - angleDeg) * (math.pi / 180),
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: kAngleDisplayFontWeight,
                letterSpacing: kCompassTextLetterSpacing,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final Color alignedColor = colorScheme.primary;
    final Color unalignedColor = colorScheme.tertiary;

    return Container(
      padding: EdgeInsets.all(tokens.spaceLarge),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface.withValues(alpha: tokens.opacitySubtle),
      ),
      child: Icon(
        Icons.arrow_upward_rounded,
        color: isAligned ? alignedColor : unalignedColor,
        size: kQiblaPointerIconSize,
        shadows: [
          Shadow(
            color: (isAligned ? alignedColor : unalignedColor).withValues(
              alpha: tokens.opacityEmphasis,
            ),
            blurRadius: tokens.blurShadow * kQiblaPointerBlurMultiplier,
          ),
        ],
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  _CompassDialPainter({
    required this.colorScheme,
    required this.tokens,
    required this.tickInset,
    required this.majorTickLength,
    required this.minorTickLength,
    required this.smallTickLength,
    required this.borderWidth,
  });

  final ColorScheme colorScheme;
  final TilawaDesignTokens tokens;
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
      ..color = colorScheme.onSurface.withValues(alpha: tokens.opacitySubtle)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawCircle(center, radius, borderPaint);

    // Ticks
    final tickPaint = Paint()
      ..color = colorScheme.outline.withValues(alpha: tokens.opacityEmphasis)
      ..strokeWidth = kThinTickStrokeWidth
      ..strokeCap = StrokeCap.round;

    final majorTickPaint = Paint()
      ..color = colorScheme.onSurface
      ..strokeWidth = kThickTickStrokeWidth
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < kFullCircleDegrees; i += kTickAngleIncrement) {
      // Every 5 degrees
      final isMajor = i % kMajorTickInterval == 0;
      final isMinor = i % kMinorTickInterval == 0;

      final double angle = (i + kCompassAngleOffset) * (math.pi / 180);
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
