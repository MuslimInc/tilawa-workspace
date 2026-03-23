import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa_core/entities/audio.dart';

import '../models/position_data.dart';

/// UI-only widget for the bottom player that can be used in previews
/// without any bloc dependencies.
class BottomPlayerUi extends StatelessWidget {
  const BottomPlayerUi({
    super.key,
    required this.audio,
    required this.positionData,
    this.progressBarOverride,
    required this.isPlaying,
    required this.canGoPrevious,
    required this.canGoNext,
    this.isSleepTimerActive = false,
    this.isSleepTimerEnabled = true,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onSleepTimerTap,
    this.onTap,
    this.onClose,
  });

  final AudioEntity audio;
  final PositionData positionData;
  final Widget? progressBarOverride;
  final bool isPlaying;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isSleepTimerActive;
  final bool isSleepTimerEnabled;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSleepTimerTap;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TextStyle titleStyle =
        (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodyLarge?.color,
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
        );
    final TextStyle subtitleStyle =
        (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
          fontSize: 12,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
        );

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress Bar (Slim at top)
                progressBarOverride ??
                    LinearProgressIndicator(
                      value: positionData.duration.inMilliseconds > 0
                          ? positionData.position.inMilliseconds /
                                positionData.duration.inMilliseconds
                          : 0.0,
                      backgroundColor: theme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.primaryColor,
                      ),
                      minHeight: 3,
                    ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      // Album Art
                      Material(
                        type: MaterialType.transparency,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: theme.primaryColor.withValues(alpha: 0.1),
                          ),
                          child: audio.artUri != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
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

                      SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              audio.title,
                              style: titleStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              audio.artist ?? 'Unknown Reciter',
                              style: subtitleStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 8),

                      // Controls
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Previous
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  FluentIcons.previous_20_filled,
                                  size: 20,
                                  color: canGoPrevious
                                      ? theme.iconTheme.color
                                      : Colors.grey.withValues(alpha: 0.3),
                                ),
                                onPressed: canGoPrevious ? onPrevious : null,
                              ),
                            ),

                            SizedBox(width: 4),

                            // Play/Pause
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.primaryColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
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
                                  size: 16,
                                ),
                                onPressed: onPlayPause,
                              ),
                            ),

                            SizedBox(width: 4),

                            // Next
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  FluentIcons.next_20_filled,
                                  size: 20,
                                  color: canGoNext
                                      ? theme.iconTheme.color
                                      : Colors.grey.withValues(alpha: 0.3),
                                ),
                                onPressed: canGoNext ? onNext : null,
                              ),
                            ),

                            SizedBox(width: 4),

                            // Sleep Timer
                            if (isSleepTimerEnabled)
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    isSleepTimerActive
                                        ? FluentIcons.timer_20_filled
                                        : FluentIcons.timer_20_regular,
                                    size: 20,
                                    color: isSleepTimerActive
                                        ? theme.primaryColor
                                        : Colors.grey.withValues(alpha: 0.3),
                                  ),
                                  onPressed: onSleepTimerTap,
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
      ),
    );
  }

  Widget _buildDefaultIcon(BuildContext context) {
    return Center(
      child: Icon(
        FluentIcons.music_note_2_24_filled,
        color: Theme.of(context).primaryColor,
        size: 24,
      ),
    );
  }
}
