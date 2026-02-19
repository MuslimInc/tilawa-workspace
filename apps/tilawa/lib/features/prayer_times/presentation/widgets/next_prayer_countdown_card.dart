import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tilawa/core/extensions.dart';

import '../../domain/entities/entities.dart';

class NextPrayerCountdownCard extends StatelessWidget {
  const NextPrayerCountdownCard({
    super.key,
    required this.nextPrayer,
    required this.timeUntil,
    this.use24HourFormat = true,
  });

  final PrayerTimeItem nextPrayer;
  final Duration timeUntil;
  final bool use24HourFormat;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final int hours = timeUntil.inHours;
    final int minutes = timeUntil.inMinutes.remainder(60);
    final int seconds = timeUntil.inSeconds.remainder(60);

    final String prayerName = isArabic
        ? nextPrayer.type.displayNameAr
        : nextPrayer.type.displayName;
    final String timeRemainingText = isArabic
        ? 'يتبقى على صلاة $prayerName'
        : 'Remaining until $prayerName';

    final String timerText =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // Top Row: Prayer Name & Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                prayerName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
              Text(
                use24HourFormat
                    ? nextPrayer.formattedTime
                    : nextPrayer.getFormattedTime12Hour(isArabic: isArabic),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Remaining Text
          Text(
            timeRemainingText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16.sp,
            ),
          ),

          SizedBox(height: 8.h),

          // Digital Timer
          Text(
            timerText,
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w300,
              fontSize: 48.sp,
              letterSpacing: 2.0,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
