import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              // Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: SizedBox(
                  width: 56.w,
                  height: 56.w,
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
              SizedBox(width: 12.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Surah name
                    Text(
                      bookmark.surahName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // Reciter name
                    Text(
                      bookmark.reciterName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // Position and label
                    Row(
                      children: [
                        Icon(
                          FluentIcons.play_circle_24_regular,
                          size: 14.sp,
                          color: colorScheme.primary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${bookmark.formattedPosition} / ${bookmark.formattedDuration}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: colorScheme.primary,
                          ),
                        ),
                        if (bookmark.label != null) ...[
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                bookmark.label!,
                                style: TextStyle(
                                  fontSize: 10.sp,
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
                    size: 20.sp,
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
        size: 24.sp,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
