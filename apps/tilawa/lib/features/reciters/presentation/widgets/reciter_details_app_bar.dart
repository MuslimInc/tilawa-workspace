import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

class ReciterDetailsAppBar extends StatelessWidget {
  const ReciterDetailsAppBar({super.key, required this.reciter});

  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.h, // Increased height for more breathing room
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).primaryColor,
      leading: const BackButton(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        centerTitle: true,
        titlePadding: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
        title: Text(
          reciter.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp, // Slightly larger
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Premium Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    Theme.of(context).colorScheme.secondary,
                  ],
                  stops: const [0.0, 0.5, 1.0], // Adjusted stops
                ),
              ),
            ),
            // Decorative Pattern (Curved lines or circles could go here, staying simple for now)
            Positioned(
              left: -50.w,
              top: -50.h,
              child: Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              right: -30.w,
              bottom: 20.h,
              child: Container(
                width: 150.w,
                height: 150.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Decorative Icon
            Positioned(
              right: -20.w,
              bottom: -20.h,
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  Icons.mic_none_outlined,
                  size: 180.sp,
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ), // Slightly more visible
                ),
              ),
            ),
            // Shadow Gradient for text legibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4), // Darker at bottom
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            // Avatar with Glow Effect
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40.h),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        // Inner glow-like effect via outer shadow
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40.r, // Larger
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      reciter.name[0],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
