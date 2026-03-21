import 'package:flutter/material.dart';

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
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
                  fontSize: 20,
                ),
              ),
              Text(
                use24HourFormat
                    ? nextPrayer.formattedTime
                    : nextPrayer.getFormattedTime12Hour(isArabic: isArabic),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Remaining Text
          Text(
            timeRemainingText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),

          SizedBox(height: 8),

          // Digital Timer
          Text(
            timerText,
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w300,
              fontSize: 48,
              letterSpacing: 2.0,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
