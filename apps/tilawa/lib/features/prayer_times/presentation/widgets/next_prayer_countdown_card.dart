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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceSmall,
      ),
      child: TilawaCard(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.surface, colorScheme.surfaceContainerLow],
        ),
        borderRadius: tokens.radiusExtraLarge,
        borderColor: colorScheme.outlineVariant.withValues(alpha: 0.42),
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TilawaStatusChip(
                  label: nextPrayerLabel,
                  backgroundColor: accentColor,
                  foregroundColor: colorScheme.onPrimary,
                  icon: Icons.notifications_active_rounded,
                ),
                const Spacer(),
                TilawaStatusChip(
                  label: '$scheduledLabel • $prayerTime',
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurfaceVariant,
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

    return TilawaCard(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceSmall),
      backgroundColor: theme.colorScheme.surface,
      borderRadius: tokens.radiusMedium,
      borderColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
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
