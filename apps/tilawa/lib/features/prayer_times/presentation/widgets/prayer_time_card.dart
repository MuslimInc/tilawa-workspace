import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';

import '../../domain/entities/entities.dart';
import 'prayer_time_localizations.dart';

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
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final Color accentColor = colorScheme.primary;
    final Color emphasisColor = colorScheme.onSurface;
    final Color secondaryColor = hasPassed
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.72)
        : colorScheme.onSurfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact =
            constraints.maxWidth < 180 || constraints.maxHeight < 194;
        final double iconBoxSize = compact ? 40 : 44;
        final double iconSize = compact ? 20 : 22;
        final double titleFontSize = compact
            ? ((theme.textTheme.titleLarge?.fontSize ?? 22) - 2)
            : (theme.textTheme.titleLarge?.fontSize ?? 22);
        final double timeFontSize = compact
            ? ((theme.textTheme.headlineSmall?.fontSize ?? 24) - 2)
            : (theme.textTheme.headlineSmall?.fontSize ?? 24);
        final double supportFontSize = compact
            ? ((theme.textTheme.bodySmall?.fontSize ?? 12) - 1)
            : (theme.textTheme.bodySmall?.fontSize ?? 12);
        final EdgeInsets contentPadding = EdgeInsets.fromLTRB(
          compact ? 14 : 16,
          compact ? 14 : 16,
          compact ? 14 : 16,
          compact ? 12 : 14,
        );

        return Container(
          decoration: BoxDecoration(
            color: isNext
                ? colorScheme.surfaceContainerLow
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isNext
                  ? accentColor.withValues(alpha: 0.28)
                  : colorScheme.outlineVariant.withValues(alpha: 0.28),
              width: isNext ? 1.4 : 1.0,
            ),
            boxShadow: isNext
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: isNext
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(compact ? 14 : 16),
                      ),
                      child: Icon(
                        _iconForPrayerType(prayer.type),
                        size: iconSize,
                        color: isNext
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    _PrayerStatusChip(
                      label: _statusLabel(context),
                      isNext: isNext,
                      hasPassed: hasPassed,
                      compact: compact,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  prayer.type.localizedName(context),
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                    color: emphasisColor.withValues(
                      alpha: hasPassed ? 0.70 : 1.0,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                Text(
                  use24HourFormat
                      ? prayer.formattedTime
                      : prayer.getFormattedTime12Hour(isArabic: isArabic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: timeFontSize,
                    fontWeight: FontWeight.w800,
                    color: isNext
                        ? accentColor
                        : colorScheme.onSurface.withValues(
                            alpha: hasPassed ? 0.76 : 1.0,
                          ),
                  ),
                ),
                SizedBox(height: compact ? 10 : 12),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 6 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: isNext
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(compact ? 12 : 14),
                  ),
                  child: Text(
                    _supportingText(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: supportFontSize,
                      fontWeight: FontWeight.w600,
                      color: isNext
                          ? colorScheme.onPrimaryContainer
                          : secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(BuildContext context) {
    if (isNext) {
      return context.l10n.next;
    }
    if (hasPassed) {
      return context.l10n.prayerTimesPassed;
    }
    return context.l10n.prayerTimesUpcoming;
  }

  String _supportingText(BuildContext context) {
    switch (prayer.type) {
      case PrayerType.fajr:
      case PrayerType.dhuhr:
      case PrayerType.asr:
      case PrayerType.maghrib:
      case PrayerType.isha:
        return context.l10n.prayerTimesIqamahAt(_secondaryTime());
      case PrayerType.sunrise:
        return context.l10n.prayerTimesIshraqAt(_secondaryTime());
      case PrayerType.midnight:
        return context.l10n.prayerTimesNightMidpointMarker;
      case PrayerType.lastThird:
        return context.l10n.prayerTimesLastThirdBegins;
    }
  }

  String _secondaryTime() {
    int minutesToAdd = 0;

    switch (prayer.type) {
      case PrayerType.fajr:
        minutesToAdd = 25;
        break;
      case PrayerType.sunrise:
        minutesToAdd = 20;
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
        return '';
    }

    final DateTime secondaryTime = prayer.time.add(
      Duration(minutes: minutesToAdd),
    );
    final int hour12 = secondaryTime.hour > 12
        ? secondaryTime.hour - 12
        : secondaryTime.hour;
    final String formattedHour = hour12 == 0 ? '12' : hour12.toString();
    final String formattedMinute = secondaryTime.minute.toString().padLeft(
      2,
      '0',
    );

    if (use24HourFormat) {
      return '${secondaryTime.hour.toString().padLeft(2, '0')}:$formattedMinute';
    }

    return '$formattedHour:$formattedMinute';
  }

  IconData _iconForPrayerType(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return Icons.dark_mode_rounded;
      case PrayerType.sunrise:
        return Icons.wb_sunny_outlined;
      case PrayerType.dhuhr:
        return Icons.light_mode_rounded;
      case PrayerType.asr:
        return Icons.wb_sunny_rounded;
      case PrayerType.maghrib:
        return Icons.nights_stay_rounded;
      case PrayerType.isha:
        return Icons.bedtime_rounded;
      case PrayerType.midnight:
        return Icons.dark_mode_outlined;
      case PrayerType.lastThird:
        return Icons.schedule_rounded;
    }
  }
}

class _PrayerStatusChip extends StatelessWidget {
  const _PrayerStatusChip({
    required this.label,
    required this.isNext,
    required this.hasPassed,
    required this.compact,
  });

  final String label;
  final bool isNext;
  final bool hasPassed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color backgroundColor = isNext
        ? colorScheme.primary
        : hasPassed
        ? colorScheme.surfaceContainerHighest
        : colorScheme.primaryContainer;
    final Color foregroundColor = isNext
        ? colorScheme.onPrimary
        : hasPassed
        ? colorScheme.onSurfaceVariant
        : colorScheme.onPrimaryContainer;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontSize: compact ? 11 : null,
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
