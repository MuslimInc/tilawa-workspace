import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final double progressPercent = history.progressPercentage;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceExtraSmall,
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: TilawaCard(
          onTap: onTap,
          surface: TilawaCardSurface.flat,
          backgroundColor: colorScheme.surfaceContainerLow,
          borderColor: colorScheme.outlineVariant.withValues(
            alpha: tokens.opacityMedium,
          ),
          borderWidth: tokens.borderWidthThin,
          borderRadius: tokens.radiusLarge,
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Row(
            children: [
              // Surah artwork or icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tokens.radiusSmall),
                  color: colorScheme.primaryContainer,
                ),
                child: history.artworkUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(
                          tokens.radiusSmall,
                        ),
                        child: Image.network(
                          history.artworkUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildDefaultIcon(theme),
                        ),
                      )
                    : _buildDefaultIcon(theme),
              ),

              SizedBox(width: tokens.spaceMedium),

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
                            color: colorScheme.primary,
                          ),
                      ],
                    ),

                    SizedBox(height: tokens.spaceTiny),

                    // Reciter name
                    Text(
                      history.reciterName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: tokens.spaceExtraSmall),

                    // Progress and time info
                    Row(
                      children: [
                        // Play count
                        if (history.playCount > 1) ...[
                          Icon(
                            Icons.replay,
                            size: 12,
                            color: colorScheme.secondary,
                          ),
                          SizedBox(width: tokens.spaceTiny),
                          Text(
                            '${history.playCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.secondary,
                            ),
                          ),
                          SizedBox(width: tokens.spaceSmall),
                        ],

                        // Duration info
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: tokens.spaceTiny),
                        Text(
                          '${history.formattedLastPosition} / ${history.formattedDuration}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),

                        const Spacer(),

                        // Played time ago
                        Text(
                          history.formattedPlayedAt,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: tokens.spaceSmall),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(tokens.radiusSmall),
                      child: LinearProgressIndicator(
                        value: history.completed ? 1.0 : progressPercent / 100,
                        minHeight: tokens.progressHeight,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          history.completed
                              ? colorScheme.primary
                              : colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: tokens.spaceSmall),

              // Play button
              IconButton(
                onPressed: onTap,
                icon: Icon(
                  history.completed ? Icons.replay : Icons.play_arrow,
                  color: colorScheme.primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                ),
                tooltip: history.completed
                    ? context.l10n.play
                    : context.l10n.resume,
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
