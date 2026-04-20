import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import 'prayer_time_localizations.dart';

/// A card displaying a specific prayer time with status and supporting info.
///
/// Follows Atomic Design by decomposing into atoms: icon, status chip, labels.
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
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Thresholds for compact mode to avoid overflows on small screens
        final bool compact =
            constraints.maxWidth < 180 || constraints.maxHeight < 194;

        final Color accentColor = colorScheme.primary;
        final Color emphasisColor = colorScheme.onSurface;

        return Container(
          decoration: BoxDecoration(
            color: isNext
                ? colorScheme.surfaceContainerLow
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
            border: Border.all(
              color: isNext
                  ? accentColor.withValues(alpha: tokens.opacityMedium)
                  : colorScheme.outlineVariant.withValues(
                      alpha: tokens.opacityMedium,
                    ),
              width: isNext ? 1.4 : 1.0,
            ),
            boxShadow: isNext
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: tokens.blurShadow,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? tokens.spaceMedium : tokens.spaceMedium,
              compact ? tokens.spaceMedium : tokens.spaceMedium,
              compact ? tokens.spaceMedium : tokens.spaceMedium,
              compact ? tokens.spaceSmall : tokens.spaceSmall + 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderRow(
                  prayer: prayer,
                  isNext: isNext,
                  hasPassed: hasPassed,
                  compact: compact,
                ),
                const Spacer(),
                _PrayerTimeLabel(
                  prayer: prayer,
                  hasPassed: hasPassed,
                  compact: compact,
                  emphasisColor: emphasisColor,
                ),
                SizedBox(
                  height: compact
                      ? tokens.spaceExtraSmall
                      : tokens.spaceExtraSmall + 2,
                ),
                _PrayerTimeValue(
                  prayer: prayer,
                  isNext: isNext,
                  hasPassed: hasPassed,
                  use24HourFormat: use24HourFormat,
                  isArabic: isArabic,
                  accentColor: accentColor,
                ),
                SizedBox(
                  height: compact ? tokens.spaceSmall - 2 : tokens.spaceSmall,
                ),
                _PrayerIqamahLabel(
                  prayer: prayer,
                  isNext: isNext,
                  hasPassed: hasPassed,
                  compact: compact,
                  use24HourFormat: use24HourFormat,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.prayer,
    required this.isNext,
    required this.hasPassed,
    required this.compact,
  });

  final PrayerTimeItem prayer;
  final bool isNext;
  final bool hasPassed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrayerIcon(type: prayer.type, isNext: isNext, compact: compact),
        const Spacer(),
        _PrayerStatusChip(
          isNext: isNext,
          hasPassed: hasPassed,
          compact: compact,
        ),
      ],
    );
  }
}

class _PrayerIcon extends StatelessWidget {
  const _PrayerIcon({
    required this.type,
    required this.isNext,
    required this.compact,
  });

  final PrayerType type;
  final bool isNext;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final double boxSize = compact ? 40 : 44;
    final double iconSize = compact ? tokens.iconSizeMedium : 22;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: isNext
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          compact ? tokens.radiusMedium : tokens.radiusLarge,
        ),
      ),
      child: Icon(
        _iconForPrayerType(type),
        size: iconSize,
        color: isNext
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
      ),
    );
  }

  IconData _iconForPrayerType(PrayerType type) {
    return switch (type) {
      PrayerType.fajr => Icons.dark_mode_rounded,
      PrayerType.sunrise => Icons.wb_sunny_outlined,
      PrayerType.dhuhr => Icons.light_mode_rounded,
      PrayerType.asr => Icons.wb_sunny_rounded,
      PrayerType.maghrib => Icons.nights_stay_rounded,
      PrayerType.isha => Icons.bedtime_rounded,
      PrayerType.midnight => Icons.dark_mode_outlined,
      PrayerType.lastThird => Icons.schedule_rounded,
    };
  }
}

class _PrayerStatusChip extends StatelessWidget {
  const _PrayerStatusChip({
    required this.isNext,
    required this.hasPassed,
    required this.compact,
  });

  final bool isNext;
  final bool hasPassed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final String label = isNext
        ? context.l10n.next
        : hasPassed
        ? context.l10n.prayerTimesPassed
        : context.l10n.prayerTimesUpcoming;

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
        horizontal: compact ? tokens.spaceSmall : tokens.spaceSmall,
        vertical: compact ? tokens.spaceExtraSmall : tokens.spaceExtraSmall + 1,
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

class _PrayerTimeLabel extends StatelessWidget {
  const _PrayerTimeLabel({
    required this.prayer,
    required this.hasPassed,
    required this.compact,
    required this.emphasisColor,
  });

  final PrayerTimeItem prayer;
  final bool hasPassed;
  final bool compact;
  final Color emphasisColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double baseFontSize = theme.textTheme.titleMedium?.fontSize ?? 18;
    final double fontSize = compact ? baseFontSize - 1 : baseFontSize;

    return Text(
      prayer.type.localizedName(context),
      maxLines: compact ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleLarge?.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: emphasisColor.withValues(alpha: hasPassed ? 0.70 : 1.0),
      ),
    );
  }
}

class _PrayerTimeValue extends StatelessWidget {
  const _PrayerTimeValue({
    required this.prayer,
    required this.isNext,
    required this.hasPassed,
    required this.use24HourFormat,
    required this.isArabic,
    required this.accentColor,
  });

  final PrayerTimeItem prayer;
  final bool isNext;
  final bool hasPassed;
  final bool use24HourFormat;
  final bool isArabic;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double fontSize =
        (theme.textTheme.titleLarge?.fontSize ?? 22) -
        (theme.tokens.spaceExtraSmall / 2);

    return Text(
      use24HourFormat
          ? prayer.formattedTime
          : prayer.getFormattedTime12Hour(isArabic: isArabic),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: isNext
            ? accentColor
            : theme.colorScheme.onSurface.withValues(
                alpha: hasPassed ? 0.76 : 1.0,
              ),
      ),
    );
  }
}

class _PrayerIqamahLabel extends StatelessWidget {
  const _PrayerIqamahLabel({
    required this.prayer,
    required this.isNext,
    required this.hasPassed,
    required this.compact,
    required this.use24HourFormat,
  });

  final PrayerTimeItem prayer;
  final bool isNext;
  final bool hasPassed;
  final bool compact;
  final bool use24HourFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final double baseFontSize = theme.textTheme.labelSmall?.fontSize ?? 11;
    final double fontSize = compact ? baseFontSize : baseFontSize + 1;

    final Color secondaryColor = hasPassed
        ? colorScheme.onSurfaceVariant.withValues(alpha: tokens.opacityEmphasis)
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? tokens.spaceSmall : tokens.spaceSmall + 2,
        vertical: compact ? tokens.spaceExtraSmall : tokens.spaceSmall - 1,
      ),
      decoration: BoxDecoration(
        color: isNext
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          compact ? tokens.radiusMedium : tokens.radiusLarge - 2,
        ),
      ),
      child: Text(
        _supportingText(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: isNext ? colorScheme.onPrimaryContainer : secondaryColor,
        ),
      ),
    );
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

    if (use24HourFormat) {
      return '${secondaryTime.hour.toString().padLeft(2, '0')}:${secondaryTime.minute.toString().padLeft(2, '0')}';
    }

    final int hour12 = secondaryTime.hour > 12
        ? secondaryTime.hour - 12
        : secondaryTime.hour;
    final String formattedHour = hour12 == 0 ? '12' : hour12.toString();
    final String formattedMinute = secondaryTime.minute.toString().padLeft(
      2,
      '0',
    );

    return '$formattedHour:$formattedMinute';
  }
}
