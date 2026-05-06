import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/bookmark_entity.dart';

class BookmarkCard extends StatelessWidget {
  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.onTap,
    this.onEdit,
  });

  final BookmarkEntity bookmark;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: tokens.opacityMedium,
          ),
          width: tokens.borderWidthThin,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Row(
            children: [
              // Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: bookmark.artworkUrl != null
                      ? CachedNetworkImage(
                          imageUrl: bookmark.artworkUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _buildPlaceholder(context),
                          errorWidget: (context, url, error) =>
                              _buildPlaceholder(context),
                        )
                      : _buildPlaceholder(context),
                ),
              ),
              SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Surah name
                    Text(
                      bookmark.surahName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: tokens.spaceExtraSmall),
                    // Reciter name
                    Text(
                      bookmark.reciterName,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: tokens.spaceExtraSmall),
                    // Position and label
                    Row(
                      children: [
                        Icon(
                          FluentIcons.play_circle_24_regular,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        SizedBox(width: tokens.spaceExtraSmall),
                        Text(
                          '${bookmark.formattedPosition} / ${bookmark.formattedDuration}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                          ),
                        ),
                        if (bookmark.label != null) ...[
                          SizedBox(width: tokens.spaceSmall),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                  tokens.radiusSmall,
                                ),
                              ),
                              child: Text(
                                bookmark.label!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Edit button
              if (onEdit != null)
                IconButton(
                  icon: Icon(
                    FluentIcons.edit_24_regular,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Icon(
        FluentIcons.bookmark_24_regular,
        size: 24,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
