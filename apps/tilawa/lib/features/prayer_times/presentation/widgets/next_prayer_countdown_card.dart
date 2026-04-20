import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import 'prayer_time_localizations.dart';

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
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final Duration remaining = timeUntil.isNegative ? Duration.zero : timeUntil;
    final Color accentColor = colorScheme.primary;

    final int hours = remaining.inHours;
    final int minutes = remaining.inMinutes.remainder(60);
    final int seconds = remaining.inSeconds.remainder(60);

    final String prayerName = nextPrayer.type.localizedName(context);
    final String timeRemainingText = context.l10n.prayerTimesTimeRemainingUntil(
      prayerName,
    );
    final String nextPrayerLabel = context.l10n.nextPrayer;
    final String scheduledLabel = context.l10n.prayerTimesScheduled;
    final String prayerTime = use24HourFormat
        ? nextPrayer.formattedTime
        : nextPrayer.getFormattedTime12Hour(isArabic: isArabic);

    final tokens = theme.tokens;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceSmall,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.surface, colorScheme.surfaceContainerLow],
        ),
        borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: tokens.blurShadow,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceMedium,
                    vertical: tokens.spaceSmall,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        size: 16,
                        color: colorScheme.onPrimary,
                      ),
                      SizedBox(width: tokens.spaceSmall),
                      Text(
                        nextPrayerLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceMedium,
                    vertical: tokens.spaceSmall,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  ),
                  child: Column(
                    children: [
                      Text(
                        scheduledLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: tokens.spaceExtraSmall),
                      Text(
                        prayerTime,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceLarge),
            Text(
              prayerName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: tokens.spaceExtraSmall),
            Text(
              timeRemainingText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spaceLarge),
            Row(
              children: [
                Expanded(
                  child: _TimerSegment(
                    value: hours.toString().padLeft(2, '0'),
                    label: context.l10n.hours,
                    accentColor: accentColor,
                  ),
                ),
                SizedBox(width: tokens.spaceSmall),
                Expanded(
                  child: _TimerSegment(
                    value: minutes.toString().padLeft(2, '0'),
                    label: context.l10n.minutes,
                    accentColor: accentColor,
                  ),
                ),
                SizedBox(width: tokens.spaceSmall),
                Expanded(
                  child: _TimerSegment(
                    value: seconds.toString().padLeft(2, '0'),
                    label: context.l10n.seconds,
                    accentColor: accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerSegment extends StatelessWidget {
  const _TimerSegment({
    required this.value,
    required this.label,
    required this.accentColor,
  });

  final String value;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final tokens = theme.tokens;

    return Container(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceSmall),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: tokens.spaceExtraSmall),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
