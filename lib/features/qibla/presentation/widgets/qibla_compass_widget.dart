import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../domain/entities/qibla_direction_entity.dart';

class QiblaCompassWidget extends StatelessWidget {
  const QiblaCompassWidget({super.key, required this.direction});

  final QiblaDirectionEntity direction;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dial (Rotates based on device heading)
        Transform.rotate(
          angle: direction.direction * (math.pi / 180) * -1,
          child: Image.asset(
            'assets/images/qibla_dial.png',
            width: 300.r,
            height: 300.r,
          ),
        ),
        // Needle (Always points to Qibla relative to the dial)
        // Since the dial is rotated, we need to apply the qibla angle
        Transform.rotate(
          angle: direction.qibla * (math.pi / 180) * -1,
          child: Image.asset(
            'assets/images/qibla_needle.png',
            width: 200.r,
            height: 200.r,
          ),
        ),
        // Center decoration or text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 320.h),
            Text(
              '${direction.offset.toStringAsFixed(0)}°',
              style: TextStyle(
                fontSize: 48.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            Text(
              'To Qibla',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
