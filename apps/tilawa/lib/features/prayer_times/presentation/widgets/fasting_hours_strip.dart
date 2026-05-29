import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';

class FastingHoursStrip extends StatelessWidget {
  const FastingHoursStrip({super.key, required this.prayerTimes});

  final PrayerTimeEntity prayerTimes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final isArabic = context.isArabic;

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
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceSmall,
      ),
      child: TilawaCard(
        surface: TilawaCardSurface.flat,
        backgroundColor: colorScheme.surfaceContainerLow,
        borderRadius: tokens.radiusLarge,
        borderColor: colorScheme.outlineVariant.withValues(
          alpha: tokens.opacityMedium,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLarge,
          vertical: tokens.spaceMedium,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: tokens.spaceSmall,
                children: [
                  Icon(Icons.restaurant_outlined, color: activeColor, size: 20),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.spaceSmall),
            Text(
              formattedDuration,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: activeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
