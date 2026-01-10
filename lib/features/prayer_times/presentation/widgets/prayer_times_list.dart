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

    return Card(
      color: isNext
          ? theme.colorScheme.primaryContainer
          : hasPassed
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Prayer icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isNext
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                _getPrayerIcon(prayer.type),
                color: isNext
                    ? theme.colorScheme.onPrimary
                    : hasPassed
                    ? theme.colorScheme.outline
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
                      fontWeight: isNext ? FontWeight.bold : null,
                      color: hasPassed ? theme.colorScheme.outline : null,
                    ),
                  ),
                  if (isNext)
                    Text(
                      context.l10n.nextPrayer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
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
                fontWeight: FontWeight.bold,
                color: hasPassed ? theme.colorScheme.outline : null,
              ),
            ),

            // Passed indicator
            if (hasPassed)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle,
                  size: 20,
                  color: theme.colorScheme.primary,
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
