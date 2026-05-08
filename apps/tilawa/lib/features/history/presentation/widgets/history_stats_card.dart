import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class HistoryStatsCard extends StatelessWidget {
  const HistoryStatsCard({
    super.key,
    required this.totalItems,
    required this.totalListeningTimeMs,
  });

  final int totalItems;
  final int totalListeningTimeMs;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Row(
          children: [
            // Total items
            Expanded(
              child: _StatItem(
                icon: Icons.library_music,
                value: '$totalItems',
                label: context.l10n.totalSurahs,
                theme: theme,
              ),
            ),

            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.2,
              ),
            ),

            // Total listening time
            Expanded(
              child: _StatItem(
                icon: Icons.access_time_filled,
                value: _formatDuration(totalListeningTimeMs),
                label: context.l10n.totalListeningTime,
                theme: theme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);

    final int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final String value;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
            SizedBox(width: theme.tokens.spaceSmall),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
        SizedBox(height: theme.tokens.spaceExtraSmall),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
