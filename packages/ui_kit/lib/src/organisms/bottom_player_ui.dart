import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa_core/entities/audio.dart';

import '../foundation/design_tokens.dart';

/// UI-only widget for the bottom player that can be used in previews
/// without any bloc dependencies.
class BottomPlayerUi extends StatelessWidget {
  const BottomPlayerUi({
    super.key,
    required this.audio,
    required this.progress,
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
  final double progress;
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
    final tokens = theme.tokens;

    final TextStyle titleStyle =
        (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontWeight: .w600,
          color: theme.textTheme.bodyLarge?.color,
          decoration: .none,
          decorationColor: Colors.transparent,
        );
    final TextStyle subtitleStyle =
        (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
          color: theme.textTheme.bodyMedium?.color?.withValues(
            alpha: tokens.opacityEmphasis,
          ),
          decoration: .none,
          decorationColor: Colors.transparent,
        );
    final borderRadius = BorderRadius.circular(tokens.radiusLarge);
    final controlButtonSize = tokens.iconSizeLarge + tokens.spaceSmall;
    final playPauseButtonSize = tokens.iconSizeExtraLarge - tokens.spaceMedium;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: tokens.opacitySubtle),
            blurRadius: tokens.blurShadow,
            offset: tokens.shadowOffsetMedium,
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: tokens.opacitySubtle),
          width: tokens.borderWidthThin,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: GestureDetector(
          onTap: onTap,
          behavior: .opaque,
          child: Column(
            mainAxisSize: .min,
            children: [
              // Progress Bar (Slim at top)
              progressBarOverride ??
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.primaryColor.withValues(
                      alpha: tokens.opacitySubtle,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.primaryColor,
                    ),
                    minHeight: tokens.progressHeight,
                  ),
              Padding(
                padding: EdgeInsets.all(tokens.spaceMedium),
                child: Row(
                  children: [
                    // Album Art
                    Material(
                      type: .transparency,
                      child: Container(
                        width: tokens.iconSizeExtraLarge,
                        height: tokens.iconSizeExtraLarge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            tokens.radiusMedium,
                          ),
                          color: theme.primaryColor.withValues(
                            alpha: tokens.opacitySubtle,
                          ),
                        ),
                        child: audio.artUri != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  tokens.radiusMedium,
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: audio.artUri.toString(),
                                  fit: .cover,
                                  errorWidget: (context, error, stackTrace) =>
                                      _buildDefaultIcon(context),
                                  placeholder: (context, url) =>
                                      _buildDefaultIcon(context),
                                ),
                              )
                            : _buildDefaultIcon(context),
                      ),
                    ),

                    SizedBox(width: tokens.spaceMedium),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        mainAxisAlignment: .center,
                        spacing: tokens.spaceExtraSmall / 2,
                        children: [
                          Text(
                            audio.title,
                            style: titleStyle,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                          Text(
                            audio.artist ?? 'Unknown Reciter',
                            style: subtitleStyle,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: tokens.spaceSmall),

                    // Controls
                    Directionality(
                      textDirection: .ltr,
                      child: Row(
                        mainAxisSize: .min,
                        spacing: tokens.spaceExtraSmall,
                        children: [
                          // Previous
                          SizedBox(
                            width: controlButtonSize,
                            height: controlButtonSize,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                FluentIcons.previous_20_filled,
                                size: tokens.iconSizeMedium,
                                color: canGoPrevious
                                    ? theme.iconTheme.color
                                    : Colors.grey.withValues(
                                        alpha: tokens.opacityMedium,
                                      ),
                              ),
                              onPressed: canGoPrevious ? onPrevious : null,
                            ),
                          ),

                          // Play/Pause
                          Container(
                            width: playPauseButtonSize,
                            height: playPauseButtonSize,
                            decoration: BoxDecoration(
                              shape: .circle,
                              color: theme.primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(
                                    alpha: tokens.opacityMedium,
                                  ),
                                  blurRadius: tokens.radiusSmall,
                                  offset: tokens.shadowOffsetSmall,
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
                                size: tokens.iconSizeSmall,
                              ),
                              onPressed: onPlayPause,
                            ),
                          ),

                          // Next
                          SizedBox(
                            width: controlButtonSize,
                            height: controlButtonSize,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                FluentIcons.next_20_filled,
                                size: tokens.iconSizeMedium,
                                color: canGoNext
                                    ? theme.iconTheme.color
                                    : Colors.grey.withValues(
                                        alpha: tokens.opacityMedium,
                                      ),
                              ),
                              onPressed: canGoNext ? onNext : null,
                            ),
                          ),

                          // Sleep Timer
                          if (isSleepTimerEnabled)
                            SizedBox(
                              width: controlButtonSize,
                              height: controlButtonSize,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  isSleepTimerActive
                                      ? FluentIcons.timer_20_filled
                                      : FluentIcons.timer_20_regular,
                                  size: tokens.iconSizeMedium,
                                  color: isSleepTimerActive
                                      ? theme.primaryColor
                                      : Colors.grey.withValues(
                                          alpha: tokens.opacityMedium,
                                        ),
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
    );
  }

  Widget _buildDefaultIcon(BuildContext context) {
    return Center(
      child: Icon(
        FluentIcons.music_note_2_24_filled,
        color: Theme.of(context).primaryColor,
        size: Theme.of(context).tokens.iconSizeLarge,
      ),
    );
  }
}
