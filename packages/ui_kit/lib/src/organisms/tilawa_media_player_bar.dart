import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/src/foundation/component_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';

/// UI-only widget for the bottom player that can be used in previews
/// without any bloc dependencies.
class TilawaMediaPlayerBar extends StatelessWidget {
  const TilawaMediaPlayerBar({
    super.key,
    required this.title,
    this.subtitle,
    this.artwork,
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

  final String title;
  final String? subtitle;
  final Widget? artwork;
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
    final colorScheme = theme.colorScheme;
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.mediaPlayerBar;
    final disabledControlColor = colorScheme.onSurfaceVariant.withValues(
      alpha: componentTokens.disabledControlOpacity,
    );

    final TextStyle titleStyle =
        (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontWeight: componentTokens.titleFontWeight,
          color: colorScheme.onSurface,
          decoration: .none,
          decorationColor: Colors.transparent,
        );
    final TextStyle subtitleStyle =
        (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: componentTokens.subtitleOpacity,
          ),
          decoration: .none,
          decorationColor: Colors.transparent,
        );
    final borderRadius = BorderRadius.circular(componentTokens.borderRadius);

    return Container(
      decoration: BoxDecoration(
        color: componentTokens.shellBackgroundColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: componentTokens.shadowOpacity,
            ),
            blurRadius: designTokens.blurShadow,
            offset: designTokens.shadowOffsetMedium,
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: designTokens.opacitySubtle,
          ),
          width: designTokens.borderWidthThin,
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
                    backgroundColor: componentTokens.progressTrackBackgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                    minHeight: designTokens.progressHeight,
                  ),
              Padding(
                padding: componentTokens.contentPadding,
                child: Row(
                  children: [
                    // Album Art
                    Material(
                      type: .transparency,
                      child: Container(
                        width: componentTokens.artworkSize,
                        height: componentTokens.artworkSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            componentTokens.artworkRadius,
                          ),
                          color: componentTokens.artworkPlaceholderColor,
                        ),
                        child: artwork == null
                            ? _buildDefaultIcon(context)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  componentTokens.artworkRadius,
                                ),
                                child: artwork,
                              ),
                      ),
                    ),

                    SizedBox(width: componentTokens.artworkInfoGap),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        mainAxisAlignment: .center,
                        spacing: componentTokens.infoGap,
                        children: [
                          Text(
                            title,
                            style: titleStyle,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty)
                            Text(
                              subtitle!,
                              style: subtitleStyle,
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                        ],
                      ),
                    ),

                    SizedBox(width: componentTokens.infoControlsGap),

                    // Controls
                    Directionality(
                      textDirection: .ltr,
                      child: Row(
                        mainAxisSize: .min,
                        spacing: componentTokens.controlsGap,
                        children: [
                          // Previous
                          SizedBox(
                            width: componentTokens.controlButtonSize,
                            height: componentTokens.controlButtonSize,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                FluentIcons.previous_20_filled,
                                size: designTokens.iconSizeMedium,
                                color: canGoPrevious
                                    ? colorScheme.onSurfaceVariant
                                    : disabledControlColor,
                              ),
                              onPressed: canGoPrevious ? onPrevious : null,
                            ),
                          ),

                          // Play/Pause
                          Container(
                            width: componentTokens.playPauseButtonSize,
                            height: componentTokens.playPauseButtonSize,
                            decoration: BoxDecoration(
                              shape: .circle,
                              color: colorScheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha:
                                        componentTokens.playPauseShadowOpacity,
                                  ),
                                  blurRadius:
                                      componentTokens.playPauseShadowBlur,
                                  offset: designTokens.shadowOffsetSmall,
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isPlaying
                                    ? FluentIcons.pause_16_filled
                                    : FluentIcons.play_16_filled,
                                color: colorScheme.onPrimary,
                                size: componentTokens.playPauseIconSize,
                              ),
                              onPressed: onPlayPause,
                            ),
                          ),

                          // Next
                          SizedBox(
                            width: componentTokens.controlButtonSize,
                            height: componentTokens.controlButtonSize,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                FluentIcons.next_20_filled,
                                size: designTokens.iconSizeMedium,
                                color: canGoNext
                                    ? colorScheme.onSurfaceVariant
                                    : disabledControlColor,
                              ),
                              onPressed: canGoNext ? onNext : null,
                            ),
                          ),

                          // Sleep Timer
                          if (isSleepTimerEnabled)
                            SizedBox(
                              width: componentTokens.controlButtonSize,
                              height: componentTokens.controlButtonSize,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  isSleepTimerActive
                                      ? FluentIcons.timer_20_filled
                                      : FluentIcons.timer_20_regular,
                                  size: designTokens.iconSizeMedium,
                                  color: isSleepTimerActive
                                      ? colorScheme.primary
                                      : disabledControlColor,
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
    final theme = Theme.of(context);
    return Center(
      child: Icon(
        FluentIcons.music_note_2_24_filled,
        color: theme.colorScheme.onPrimaryContainer,
        size: theme.componentTokens.mediaPlayerBar.defaultIconSize,
      ),
    );
  }
}
