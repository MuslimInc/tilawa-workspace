import 'package:flutter/material.dart';

import '../../../../core/extensions.dart';
import '../../domain/entities/entities.dart';

class NextPrayerCountdownCard extends StatelessWidget {
  const NextPrayerCountdownCard({
    super.key,
    required this.nextPrayer,
    required this.timeUntil,
  });

  final PrayerTimeItem nextPrayer;
  final Duration timeUntil;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final int hours = timeUntil.inHours;
    final int minutes = timeUntil.inMinutes.remainder(60);
    final int seconds = timeUntil.inSeconds.remainder(60);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Next prayer label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              context.l10n.nextPrayer.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Prayer name
          Text(
            isArabic
                ? nextPrayer.type.displayNameAr
                : nextPrayer.type.displayName,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 8),

          // Prayer time
          Text(
            '${context.l10n.at} ${nextPrayer.formattedTime12Hour}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),

          const SizedBox(height: 24),

          // Countdown timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountdownUnit(
                value: hours.toString().padLeft(2, '0'),
                label: context.l10n.hours,
                theme: theme,
              ),
              _CountdownSeparator(theme: theme),
              _CountdownUnit(
                value: minutes.toString().padLeft(2, '0'),
                label: context.l10n.minutes,
                theme: theme,
              ),
              _CountdownSeparator(theme: theme),
              _CountdownUnit(
                value: seconds.toString().padLeft(2, '0'),
                label: context.l10n.seconds,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({
    required this.value,
    required this.label,
    required this.theme,
  });

  final String value;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64, // Fixed width for alignment
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _CountdownSeparator extends StatelessWidget {
  const _CountdownSeparator({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
      child: Text(
        ':',
        style: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}
