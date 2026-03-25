import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.surface, colorScheme.surfaceContainerLow],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        size: 18,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        scheduledLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prayerTime,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              prayerName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              timeRemainingText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _TimerSegment(
                    value: hours.toString().padLeft(2, '0'),
                    label: context.l10n.hours,
                    accentColor: accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimerSegment(
                    value: minutes.toString().padLeft(2, '0'),
                    label: context.l10n.minutes,
                    accentColor: accentColor,
                  ),
                ),
                const SizedBox(width: 12),
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
