import 'package:flutter/material.dart';

import '../../domain/entities/history_entity.dart';

class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.history,
    this.onTap,
    this.onLongPress,
  });

  final HistoryEntity history;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double progressPercent = history.progressPercentage;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Surah artwork or icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.primaryContainer,
                ),
                child: history.artworkUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          history.artworkUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildDefaultIcon(theme),
                        ),
                      )
                    : _buildDefaultIcon(theme),
              ),

              const SizedBox(width: 12),

              // Surah info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Surah name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            history.surahName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (history.completed)
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Reciter name
                    Text(
                      history.reciterName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Progress and time info
                    Row(
                      children: [
                        // Play count
                        if (history.playCount > 1) ...[
                          Icon(
                            Icons.replay,
                            size: 12,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${history.playCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Duration info
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${history.formattedLastPosition} / ${history.formattedDuration}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),

                        const Spacer(),

                        // Played time ago
                        Text(
                          history.formattedPlayedAt,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: history.completed ? 1.0 : progressPercent / 100,
                        minHeight: 3,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          history.completed
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Play button
              IconButton(
                onPressed: onTap,
                icon: Icon(
                  history.completed ? Icons.replay : Icons.play_arrow,
                  color: theme.colorScheme.primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.play_circle_outline,
        size: 28,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}
