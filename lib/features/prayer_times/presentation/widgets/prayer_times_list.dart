import 'package:flutter/material.dart';

import '../../../../core/extensions.dart';
import '../../domain/entities/entities.dart';

class PrayerTimesList extends StatelessWidget {
  const PrayerTimesList({
    super.key,
    required this.prayerTimes,
    this.currentPrayer,
    this.use24HourFormat = true,
    this.showSunrise = false,
  });

  final PrayerTimeEntity prayerTimes;
  final PrayerTimeItem? currentPrayer;
  final bool use24HourFormat;
  final bool showSunrise;

  @override
  Widget build(BuildContext context) {
    final List<PrayerTimeItem> prayers = showSunrise
        ? prayerTimes.allPrayers
        : prayerTimes.allPrayers
              .where((p) => p.type != PrayerType.sunrise)
              .toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: prayers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final PrayerTimeItem prayer = prayers[index];
        final isNext = currentPrayer?.type == prayer.type;
        final bool hasPassed = prayerTimes.hasPrayerPassed(prayer.type);

        return PrayerTimeCard(
          prayer: prayer,
          isNext: isNext,
          hasPassed: hasPassed && !isNext,
          use24HourFormat: use24HourFormat,
        );
      },
    );
  }
}

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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isNext
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isNext
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Prayer icon
            Container(
              width: 44, // Slightly smaller
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isNext
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
              ),
              child: Icon(
                _getPrayerIcon(prayer.type),
                size: 22,
                color: isNext
                    ? theme.colorScheme.onPrimary
                    : hasPassed
                    ? theme.colorScheme.outline.withValues(
                        alpha: 0.5,
                      ) // More muted
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(width: 16),

            // Prayer name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic
                        ? prayer.type.displayNameAr
                        : prayer.type.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isNext
                          ? FontWeight.bold
                          : FontWeight.w500, // Medium for others
                      color: hasPassed
                          ? theme.colorScheme.outline.withValues(alpha: 0.7)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isNext)
                    Text(
                      context.l10n.nextPrayer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            // Prayer time
            Text(
              use24HourFormat
                  ? prayer.formattedTime
                  : prayer.formattedTime12Hour,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                color: isNext
                    ? theme.colorScheme.primary
                    : hasPassed
                    ? theme.colorScheme.outline.withValues(alpha: 0.6)
                    : theme.colorScheme.onSurface,
              ),
            ),

            // Passed indicator or active dot
            SizedBox(
              width: 32,
              child: Align(
                alignment: Alignment.centerRight,
                child: isNext
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : hasPassed
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPrayerIcon(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return Icons.nightlight_round;
      case PrayerType.sunrise:
        return Icons.wb_sunny_outlined;
      case PrayerType.dhuhr:
        return Icons.wb_sunny;
      case PrayerType.asr:
        return Icons.brightness_6;
      case PrayerType.maghrib:
        return Icons.brightness_4;
      case PrayerType.isha:
        return Icons.nights_stay;
    }
  }
}
