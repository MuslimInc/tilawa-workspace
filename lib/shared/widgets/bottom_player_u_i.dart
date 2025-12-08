import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../models/position_data.dart';

/// UI-only widget for the bottom player that can be used in previews
/// without any bloc dependencies.
class BottomPlayerUI extends StatelessWidget {
  const BottomPlayerUI({
    super.key,
    required this.mediaItem,
    required this.positionData,
    required this.isPlaying,
    required this.canGoPrevious,
    required this.canGoNext,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onTap,
    this.onClose,
  });

  final MediaItem mediaItem;
  final PositionData positionData;
  final bool isPlaying;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Bar (Slim at top)
            ClipRRect(
              child: LinearProgressIndicator(
                value: positionData.duration.inMilliseconds > 0
                    ? positionData.position.inMilliseconds /
                          positionData.duration.inMilliseconds
                    : 0.0,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                minHeight: 3.h,
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  // Album Art
                  Hero(
                    tag: 'audio_player',
                    child: Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10.r,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: mediaItem.artUri != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: Image.network(
                                mediaItem.artUri.toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultIcon(context),
                              ),
                            )
                          : _buildDefaultIcon(context),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mediaItem.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          mediaItem.artist ?? 'Unknown Reciter',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Controls
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Previous
                        IconButton(
                          icon: Icon(
                            FluentIcons.previous_24_filled,
                            size: 24.sp,
                            color: canGoPrevious
                                ? Theme.of(context).iconTheme.color
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                          onPressed: canGoPrevious ? onPrevious : null,
                        ),

                        SizedBox(width: 8.w),

                        // Play/Pause
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.3),
                                blurRadius: 12.r,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              isPlaying
                                  ? FluentIcons.pause_24_filled
                                  : FluentIcons.play_24_filled,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                            onPressed: onPlayPause,
                          ),
                        ),

                        SizedBox(width: 8.w),

                        // Next
                        IconButton(
                          icon: Icon(
                            FluentIcons.next_24_filled,
                            size: 24.sp,
                            color: canGoNext
                                ? Theme.of(context).iconTheme.color
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                          onPressed: canGoNext ? onNext : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon(BuildContext context) {
    return Center(
      child: Icon(
        FluentIcons.music_note_2_24_filled,
        color: Theme.of(context).primaryColor,
        size: 24.sp,
      ),
    );
  }
}
