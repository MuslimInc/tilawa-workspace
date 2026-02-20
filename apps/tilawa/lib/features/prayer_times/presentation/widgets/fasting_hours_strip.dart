import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../domain/entities/entities.dart';

class FastingHoursStrip extends StatelessWidget {
  const FastingHoursStrip({super.key, required this.prayerTimes});

  final PrayerTimeEntity prayerTimes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Calculate duration
    final Duration fastingDuration = prayerTimes.maghrib.difference(
      prayerTimes.fajr,
    );
    final int hours = fastingDuration.inHours;
    final int minutes = fastingDuration.inMinutes.remainder(60);

    // Format string according to locale
    final String formattedDuration = isArabic
        ? (minutes == 0
              ? '$hours ساعة'
              : '$hours ساعة و ${minutes.toString().padLeft(2, '0')} دقيقة')
        : (minutes == 0
              ? '$hours hrs'
              : '$hours h ${minutes.toString().padLeft(2, '0')} m');

    final String label = isArabic ? 'عدد ساعات الصيام' : 'Fasting Hours';

    // Active color from theme to ensure good contrast
    final Color activeColor = theme.colorScheme.primary;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_outlined, color: activeColor, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Text(
            formattedDuration,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }
}
