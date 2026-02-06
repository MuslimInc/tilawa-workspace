import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../domain/entities/athkar_item.dart';

class ItemCountWidget extends StatelessWidget {
  const ItemCountWidget({
    super.key,
    required this.item,
    required this.currentCount,
    required this.isDone,
  });

  final AthkarItem item;
  final int currentCount;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Enhanced colors for better visibility and premium feel
    final Color activeColor = isDone
        ? const Color(0xFF4CAF50) // Vibrant Green for success
        : colorScheme.primary;

    final double progress = item.count > 0 ? (currentCount / item.count) : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120.w,
          height: 120.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer decorative glow/shadow
              Container(
                width: 110.w,
                height: 110.h,
                decoration: BoxDecoration(shape: BoxShape.circle),
              ),

              // Animated Progress Ring
              SizedBox(
                width: 100.w,
                height: 100.w,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: progress, end: progress),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),
              // Inner Circle Button
              Container(
                width: 78.w,
                height: 78.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isDone
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        )
                      : null,
                  gradient: isDone
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF66BB6A), // Balanced Green 400
                            Color(0xFF43A047), // Balanced Green 600
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            activeColor,
                            activeColor.withValues(alpha: 0.8),
                          ],
                        ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: isDone
                        ? Icon(
                            key: const ValueKey('done'),
                            FluentIcons.checkmark_24_filled,
                            color: Colors.white,
                            size: 50.sp,
                          )
                        : Text(
                            key: ValueKey(currentCount),
                            '$currentCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 36.sp,
                              height: 1.0,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        // Progress Text
        AnimatedOpacity(
          opacity: isDone ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$currentCount / ${item.count}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
