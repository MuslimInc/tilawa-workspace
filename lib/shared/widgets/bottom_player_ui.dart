import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../core/entities/audio.dart';
import '../models/position_data.dart';

/// UI-only widget for the bottom player that can be used in previews
/// without any bloc dependencies.
class BottomPlayerUi extends StatelessWidget {
  const BottomPlayerUi({
    super.key,
    required this.audio,
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

  final AudioEntity audio;
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16.r,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress Bar (Slim at top)
              LinearProgressIndicator(
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

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                child: Row(
                  children: [
                    // Album Art
                    Hero(
                      tag: 'audio_player',
                      createRectTween: (begin, end) {
                        return MaterialRectCenterArcTween(
                          begin: begin,
                          end: end,
                        );
                      },
                      placeholderBuilder: (context, heroSize, child) {
                        return Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                          ),
                        );
                      },
                      child: Material(
                        type: MaterialType.transparency,
                        child: Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                          ),
                          child: audio.artUri != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: CachedNetworkImage(
                                    imageUrl: audio.artUri.toString(),
                                    fit: BoxFit.cover,
                                    errorWidget: (context, error, stackTrace) =>
                                        _buildDefaultIcon(context),
                                    placeholder: (context, url) =>
                                        _buildDefaultIcon(context),
                                  ),
                                )
                              : _buildDefaultIcon(context),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            audio.title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            audio.artist ?? 'Unknown Reciter',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // Controls
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Previous
                          SizedBox(
                            width: 32.w,
                            height: 32.w,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                FluentIcons.previous_20_filled,
                                size: 20.sp,
                                color: canGoPrevious
                                    ? Theme.of(context).iconTheme.color
                                    : Colors.grey.withValues(alpha: 0.3),
                              ),
                              onPressed: canGoPrevious ? onPrevious : null,
                            ),
                          ),

                          SizedBox(width: 4.w),

                          // Play/Pause
                          Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8.r,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isPlaying
                                    ? FluentIcons.pause_16_filled
                                    : FluentIcons.play_16_filled,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                              onPressed: onPlayPause,
                            ),
                          ),

                          SizedBox(width: 4.w),

                          // Next
                          SizedBox(
                            width: 32.w,
                            height: 32.w,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                FluentIcons.next_20_filled,
                                size: 20.sp,
                                color: canGoNext
                                    ? Theme.of(context).iconTheme.color
                                    : Colors.grey.withValues(alpha: 0.3),
                              ),
                              onPressed: canGoNext ? onNext : null,
                            ),
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
