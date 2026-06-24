import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/shared/widgets/kaaba_icon.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/qibla_direction_entity.dart';
import '../constants/qibla_constants.dart';

class QiblaCompassWidget extends StatelessWidget {
  const QiblaCompassWidget({super.key, required this.qiblaDirection});

  final QiblaDirectionEntity qiblaDirection;

  @override
  Widget build(BuildContext context) {
    if (qiblaDirection.direction.isNaN || qiblaDirection.direction.isInfinite) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isAligned = qiblaDirection.isAligned;
    final TilawaDesignTokens tokens = theme.tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = context.viewportSize;
        final boundedWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : screenSize.shortestSide;
        final baseSize = math.min(boundedWidth, screenSize.shortestSide);
        final compassSize = baseSize * kCompassSizeRatio;
        final dialSize = baseSize * kDialSizeRatio;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: compassSize,
              child: Semantics(
                label: 'Qibla Compass',
                hint:
                    'Rotate your device until the Kaaba icon reaches the top marker',
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: dialSize * 1.55,
                      height: dialSize * 1.55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colorScheme.surface,
                            colorScheme.surfaceContainerHigh.withValues(
                              alpha: tokens.opacityMedium,
                            ),
                            colorScheme.surfaceContainerHigh.withValues(
                              alpha: 0,
                            ),
                          ],
                          stops: const <double>[0.05, 0.45, 1],
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: qiblaDirection.direction * (math.pi / 180) * -1,
                      child: _CompassDial(
                        qiblaDirection: qiblaDirection,
                        dialSize: dialSize,
                      ),
                    ),
                    Positioned(
                      top:
                          (compassSize - dialSize) / 2 -
                          kQiblaBezelMarkerHeight +
                          tokens.spaceExtraSmall,
                      left: (compassSize - kQiblaBezelMarkerWidth) / 2,
                      child: const _QiblaBezelMarker(),
                    ),
                    _CompassPivot(isAligned: isAligned),
                    _QiblaNeedle(isAligned: isAligned),
                  ],
                ),
              ),
            ),
            SizedBox(height: tokens.spaceLarge),
            _AngleDisplay(
              qiblaBearing: qiblaDirection.offset,
              isAligned: isAligned,
              colorScheme: colorScheme,
            ),
          ],
        );
      },
    );
  }
}

class _CompassDial extends StatelessWidget {
  const _CompassDial({required this.qiblaDirection, required this.dialSize});

  final QiblaDirectionEntity qiblaDirection;
  final double dialSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return SizedBox(
      width: dialSize,
      height: dialSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(dialSize, dialSize),
            painter: _CompassDialPainter(
              colorScheme: colorScheme,
              tokens: tokens,
              dotInset: tokens.spaceMedium,
            ),
          ),
          _CompassDialOrbit(
            angleDeg: qiblaDirection.offset,
            heading: qiblaDirection.direction,
            tokens: tokens,
            child: const KaabaIcon(
              size: KaabaAssets.compassSize,
              semanticLabel: 'Kaaba',
            ),
          ),
          _CompassText(
            text: context.l10n.north,
            angleDeg: 0,
            heading: qiblaDirection.direction,
            isCardinal: true,
          ),
          _CompassText(
            text: context.l10n.east,
            angleDeg: 90,
            heading: qiblaDirection.direction,
          ),
          _CompassText(
            text: context.l10n.south,
            angleDeg: 180,
            heading: qiblaDirection.direction,
          ),
          _CompassText(
            text: context.l10n.west,
            angleDeg: 270,
            heading: qiblaDirection.direction,
          ),
        ],
      ),
    );
  }
}

/// Fixed qibla target marker at the top of the compass bezel (Behance reference).
class _QiblaBezelMarker extends StatelessWidget {
  const _QiblaBezelMarker();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomPaint(
      size: const Size(
        kQiblaBezelMarkerWidth,
        kQiblaBezelMarkerHeight,
      ),
      painter: _QiblaBezelMarkerPainter(color: colorScheme.tertiary),
    );
  }
}

class _QiblaBezelMarkerPainter extends CustomPainter {
  const _QiblaBezelMarkerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path triangle = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(triangle, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _QiblaBezelMarkerPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _CompassPivot extends StatelessWidget {
  const _CompassPivot({required this.isAligned});

  final bool isAligned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final double size = tokens.spaceSmall + kCenterIndicatorSizeOffset;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface,
        border: Border.all(
          color: isAligned
              ? colorScheme.tertiary
              : colorScheme.primary.withValues(alpha: tokens.opacityMedium),
          width: tokens.borderWidthThin * 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.tertiary.withValues(
              alpha: isAligned ? tokens.opacityEmphasis : tokens.opacitySubtle,
            ),
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
    required this.qiblaBearing,
    required this.isAligned,
    required this.colorScheme,
  });

  final double qiblaBearing;
  final bool isAligned;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final Color valueColor = isAligned
        ? colorScheme.primary
        : colorScheme.onSurface;

    return Column(
      children: [
        Text(
          '${_displayBearing(qiblaBearing)}°',
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: kAngleDisplayFontSize,
            fontWeight: kAngleDisplayFontWeight,
            color: valueColor,
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        Text(
          context.l10n.qiblaDeviceAngleLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  int _displayBearing(double value) {
    final double normalized =
        (value % kFullCircleDegrees + kFullCircleDegrees) % kFullCircleDegrees;
    return normalized.round() % kFullCircleDegrees;
  }
}

class _CompassDialOrbit extends StatelessWidget {
  const _CompassDialOrbit({
    required this.angleDeg,
    required this.heading,
    required this.tokens,
    required this.child,
  });

  final double angleDeg;
  final double heading;
  final TilawaDesignTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angleDeg * (math.pi / 180),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(
            top: tokens.spaceMedium + tokens.spaceExtraSmall,
          ),
          child: Transform.rotate(
            angle: (heading - angleDeg) * (math.pi / 180),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CompassText extends StatelessWidget {
  const _CompassText({
    required this.text,
    required this.angleDeg,
    required this.heading,
    this.isCardinal = false,
  });

  final String text;
  final double angleDeg;
  final double heading;
  final bool isCardinal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return _CompassDialOrbit(
      angleDeg: angleDeg,
      heading: heading,
      tokens: tokens,
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: isCardinal ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: kCompassTextLetterSpacing,
        ),
      ),
    );
  }
}

/// Charcoal compass needle (TripGlide neutral).
class _QiblaNeedle extends StatelessWidget {
  const _QiblaNeedle({required this.isAligned});

  final bool isAligned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return CustomPaint(
      size: const Size(kQiblaNeedleWidth, kQiblaNeedleHeight),
      painter: _QiblaNeedlePainter(
        isAligned: isAligned,
        tokens: tokens,
        colorScheme: theme.colorScheme,
      ),
    );
  }
}

class _QiblaNeedlePainter extends CustomPainter {
  const _QiblaNeedlePainter({
    required this.isAligned,
    required this.tokens,
    required this.colorScheme,
  });

  final bool isAligned;
  final TilawaDesignTokens tokens;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset tip = Offset(size.width / 2, tokens.spaceExtraSmall);
    final Offset left = Offset(tokens.spaceExtraSmall, size.height * 0.7);
    final Offset right = Offset(
      size.width - tokens.spaceExtraSmall,
      size.height * 0.7,
    );

    final Path needle = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(size.width / 2, size.height * 0.5)
      ..lineTo(right.dx, right.dy)
      ..close();

    final Rect shaderRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Paint fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colorScheme.onSurface,
          colorScheme.primary,
        ],
      ).createShader(shaderRect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(needle, fill);

    if (isAligned) {
      canvas.drawPath(
        needle,
        Paint()
          ..color = colorScheme.primary.withValues(
            alpha: tokens.opacityEmphasis,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = tokens.borderWidthThin,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _QiblaNeedlePainter oldDelegate) =>
      isAligned != oldDelegate.isAligned;
}

class _CompassDialPainter extends CustomPainter {
  _CompassDialPainter({
    required this.colorScheme,
    required this.tokens,
    required this.dotInset,
  });

  final ColorScheme colorScheme;
  final TilawaDesignTokens tokens;
  final double dotInset;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    final Paint bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colorScheme.surface,
          Color.alphaBlend(
            colorScheme.surfaceContainerHigh.withValues(
              alpha: tokens.opacityEmphasis,
            ),
            colorScheme.surface,
          ),
          Color.alphaBlend(
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.45),
            colorScheme.surfaceContainerLowest,
          ),
        ],
        stops: const <double>[0.2, 0.65, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, bgPaint);

    final Paint borderPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: tokens.opacitySubtle)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.borderWidthThin;

    canvas.drawCircle(center, radius, borderPaint);

    final Paint dotPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: tokens.opacityMedium)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < kFullCircleDegrees; i += kMinorTickInterval) {
      if (i % kMajorTickInterval == 0) {
        continue;
      }

      final double angle = (i + kCompassAngleOffset) * (math.pi / 180);
      final Offset dotCenter = Offset(
        center.dx + (radius - dotInset) * math.cos(angle),
        center.dy + (radius - dotInset) * math.sin(angle),
      );
      canvas.drawCircle(dotCenter, kCompassDotRadius, dotPaint);
    }

    final Paint cardinalDotPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: tokens.opacityEmphasis)
      ..style = PaintingStyle.fill;

    for (final int cardinal in <int>[0, 90, 180, 270]) {
      final double angle = (cardinal + kCompassAngleOffset) * (math.pi / 180);
      final Offset dotCenter = Offset(
        center.dx + (radius - dotInset) * math.cos(angle),
        center.dy + (radius - dotInset) * math.sin(angle),
      );
      canvas.drawCircle(
        dotCenter,
        kCompassCardinalDotRadius,
        cardinalDotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) =>
      colorScheme.surface != oldDelegate.colorScheme.surface ||
      colorScheme.primary != oldDelegate.colorScheme.primary ||
      dotInset != oldDelegate.dotInset;
}
