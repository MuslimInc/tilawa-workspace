import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';

class PrayerTimeCard extends StatelessWidget {
  const PrayerTimeCard({
    super.key,
    required this.prayer,
    this.isNext = false,
    this.hasPassed = false,
    this.use24HourFormat = true,
  });

  final PrayerTimeItem prayer;
  final bool isNext;
  final bool hasPassed;
  final bool use24HourFormat;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Active color from theme to ensure good contrast
    final Color activeColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNext
              ? activeColor.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: isNext ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Prayer name
                Text(
                  isArabic
                      ? prayer.type.displayNameAr
                      : prayer.type.displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                    color: isNext
                        ? activeColor
                        : theme.colorScheme.onSurface.withValues(
                            alpha: hasPassed ? 0.6 : 1.0,
                          ),
                  ),
                ),
                SizedBox(height: 8),

                // Prayer time
                Text(
                  use24HourFormat
                      ? prayer.formattedTime
                      : prayer.getFormattedTime12Hour(isArabic: isArabic),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isNext
                        ? activeColor
                        : theme.colorScheme.onSurface.withValues(
                            alpha: hasPassed ? 0.6 : 1.0,
                          ),
                  ),
                ),
                SizedBox(height: 8),

                // Iqamah Time
                _buildIqamahText(theme, isArabic, activeColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIqamahText(ThemeData theme, bool isArabic, Color activeColor) {
    int minutesToAdd = 0;
    String prefix = isArabic ? 'الإقامة: ' : 'Iqamah: ';

    switch (prayer.type) {
      case PrayerType.fajr:
        minutesToAdd = 25;
        break;
      case PrayerType.sunrise:
        minutesToAdd = 20;
        prefix = isArabic ? 'بداية الإشراق: ' : 'Ishraq: ';
        break;
      case PrayerType.dhuhr:
      case PrayerType.asr:
      case PrayerType.isha:
        minutesToAdd = 20;
        break;
      case PrayerType.maghrib:
        minutesToAdd = 5;
        break;
      case PrayerType.midnight:
      case PrayerType.lastThird:
        // No Iqamah or Ishraq for these night segments
        return const SizedBox.shrink();
    }

    final DateTime iqamahTime = prayer.time.add(
      Duration(minutes: minutesToAdd),
    );

    // Format Iqamah Time (usually same formatting as prayer.type, but omit AM/PM if redundant)
    // The screenshot drops AM/PM for Iqamah, e.g. "الإقامة: 5:29"
    final int hour12 = iqamahTime.hour > 12
        ? iqamahTime.hour - 12
        : iqamahTime.hour;
    final String formattedHour = hour12 == 0 ? '12' : hour12.toString();
    final String formattedMinute = iqamahTime.minute.toString().padLeft(2, '0');
    final String timeStr = use24HourFormat
        ? '${iqamahTime.hour.toString().padLeft(2, '0')}:$formattedMinute'
        : '$formattedHour:$formattedMinute';

    return Text(
      '$prefix$timeStr',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isNext
            ? activeColor.withValues(alpha: 0.8)
            : theme.colorScheme.onSurfaceVariant.withValues(
                alpha: hasPassed ? 0.5 : 0.8,
              ),
      ),
    );
  }
}
