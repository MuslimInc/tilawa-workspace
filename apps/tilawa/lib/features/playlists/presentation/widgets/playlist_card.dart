import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/playlist.dart';

class PlaylistCard extends StatelessWidget {
  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onPlay,
  });

  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    // PopupMenuButton must be a sibling of TilawaCard, not a child.
    // TilawaCard's onTap overlay (Positioned.fill InkWell rendered last in
    // the Stack) intercepts all taps before they reach any nested widget.
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: tokens.spaceTiny),
                  Text(
                    playlist.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: tokens.spaceSmall),
                  Row(
                    children: [
                      Icon(
                        Icons.music_note,
                        size: tokens.iconSizeSmall,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: tokens.spaceTiny),
                      Text(
                        '${playlist.itemCount} ${l10n.playlistItemCount}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(width: tokens.spaceMedium),
                      Icon(
                        Icons.access_time,
                        size: tokens.iconSizeSmall,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: tokens.spaceTiny),
                      Text(
                        _formatDuration(playlist.totalDuration),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (playlist.isPublic)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spaceSmall,
                            vertical: tokens.spaceTiny,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(
                              tokens.radiusMedium,
                            ),
                          ),
                          child: Text(
                            l10n.public,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'delete':
                  onDelete();
                case 'favorite':
                  onToggleFavorite();
                case 'play':
                  onPlay();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'play',
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow),
                    SizedBox(width: tokens.spaceSmall),
                    Expanded(child: Text(l10n.playPlaylist)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit),
                    SizedBox(width: tokens.spaceSmall),
                    Expanded(child: Text(l10n.editPlaylist)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'favorite',
                child: Row(
                  children: [
                    Icon(
                      playlist.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: playlist.isFavorite ? colorScheme.error : null,
                    ),
                    SizedBox(width: tokens.spaceSmall),
                    Expanded(
                      child: Text(
                        playlist.isFavorite
                            ? l10n.favorites
                            : l10n.addToFavorites,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: colorScheme.error),
                    SizedBox(width: tokens.spaceSmall),
                    Expanded(
                      child: Text(
                        l10n.deletePlaylist,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
