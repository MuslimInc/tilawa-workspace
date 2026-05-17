import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/src/foundation/component_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';

/// Minimum horizontal space reserved for surah + reciter before the bar
/// collapses secondary transport controls (prev / next / sleep timer).
const double kTilawaMediaPlayerBarMinMetadataWidth = 96.0;

/// Artwork size on compact layouts (slightly smaller to free metadata space).
const double kTilawaMediaPlayerBarCompactArtworkSize = 40.0;

/// Typical horizontal inset outside the bar in the mini-player shell
/// ([TilawaDesignTokens.spaceLarge] × 2). Used when [layoutWidth] is null.
const double kTilawaMediaPlayerBarDefaultHorizontalInset = 32.0;

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
    this.layoutWidth,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onSleepTimerTap,
    this.onTap,
    this.onClose,
    this.openPlayerSemanticLabel,
    this.previousTooltip,
    this.playTooltip,
    this.pauseTooltip,
    this.nextTooltip,
    this.sleepTimerTooltip,
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

  /// Width available to the bar's content row. When null, inferred from
  /// [MediaQuery] minus [kTilawaMediaPlayerBarDefaultHorizontalInset].
  /// Pass explicitly for width-constrained parents (goldens) or from a parent
  /// [LayoutBuilder] in the app shell.
  final double? layoutWidth;

  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSleepTimerTap;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final String? openPlayerSemanticLabel;
  final String? previousTooltip;
  final String? playTooltip;
  final String? pauseTooltip;
  final String? nextTooltip;
  final String? sleepTimerTooltip;

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
    final String resolvedOpenPlayerLabel =
        openPlayerSemanticLabel ??
        (subtitle == null || subtitle!.isEmpty ? title : '$title, $subtitle');

    final double resolvedLayoutWidth = resolveTilawaMediaPlayerBarLayoutWidth(
      context,
      layoutWidth: layoutWidth,
    );
    final bool showSleepTimer = isSleepTimerEnabled;
    final bool useCompactControls = tilawaMediaPlayerBarNeedsCompactControls(
      maxWidth: resolvedLayoutWidth,
      tokens: componentTokens,
      showSleepTimer: showSleepTimer,
    );
    final double artworkSize = useCompactControls
        ? kTilawaMediaPlayerBarCompactArtworkSize
        : componentTokens.artworkSize;

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
          color: componentTokens.shellOutlineColor,
          width: designTokens.borderWidthThin,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Semantics(
          button: onTap != null,
          enabled: onTap != null,
          label: onTap != null ? resolvedOpenPlayerLabel : null,
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
                      backgroundColor:
                          componentTokens.progressTrackBackgroundColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                      minHeight: designTokens.progressHeight,
                    ),
                Padding(
                  padding: componentTokens.contentPadding.resolve(
                    Directionality.of(context),
                  ),
                  child: Row(
                    children: [
                      _ArtworkTile(
                        size: artworkSize,
                        radius: componentTokens.artworkRadius,
                        placeholderColor:
                            componentTokens.artworkPlaceholderColor,
                        artwork: artwork,
                        defaultIconSize: componentTokens.defaultIconSize,
                      ),
                      SizedBox(width: componentTokens.artworkInfoGap),
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
                              textAlign: TextAlign.start,
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty)
                              Text(
                                subtitle!,
                                style: subtitleStyle,
                                maxLines: 1,
                                overflow: .ellipsis,
                                textAlign: TextAlign.start,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: componentTokens.infoControlsGap),
                      _TransportControls(
                        designTokens: designTokens,
                        componentTokens: componentTokens,
                        colorScheme: colorScheme,
                        disabledControlColor: disabledControlColor,
                        isPlaying: isPlaying,
                        canGoPrevious: canGoPrevious,
                        canGoNext: canGoNext,
                        isSleepTimerActive: isSleepTimerActive,
                        showSleepTimer: showSleepTimer,
                        compact: useCompactControls,
                        onPlayPause: onPlayPause,
                        onPrevious: onPrevious,
                        onNext: onNext,
                        onSleepTimerTap: onSleepTimerTap,
                        previousTooltip: previousTooltip,
                        playTooltip: playTooltip,
                        pauseTooltip: pauseTooltip,
                        nextTooltip: nextTooltip,
                        sleepTimerTooltip: sleepTimerTooltip,
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
}

/// Resolves the width used for compact-layout decisions.
double resolveTilawaMediaPlayerBarLayoutWidth(
  BuildContext context, {
  double? layoutWidth,
}) {
  if (layoutWidth != null) {
    return layoutWidth;
  }
  return MediaQuery.sizeOf(context).width -
      kTilawaMediaPlayerBarDefaultHorizontalInset;
}

/// Returns true when the bar should hide prev/next/sleep timer so metadata
/// keeps at least [kTilawaMediaPlayerBarMinMetadataWidth] logical pixels.
bool tilawaMediaPlayerBarNeedsCompactControls({
  required double maxWidth,
  required TilawaMediaPlayerBarTokens tokens,
  required bool showSleepTimer,
}) {
  final double metadataWidth =
      maxWidth -
      _tilawaMediaPlayerBarLeadingWidth(tokens, tokens.artworkSize) -
      _tilawaMediaPlayerBarFullTransportWidth(
        tokens: tokens,
        showSleepTimer: showSleepTimer,
      );
  return metadataWidth < kTilawaMediaPlayerBarMinMetadataWidth;
}

double _tilawaMediaPlayerBarLeadingWidth(
  TilawaMediaPlayerBarTokens tokens,
  double artworkSize,
) {
  return tokens.contentPadding.horizontal +
      artworkSize +
      tokens.artworkInfoGap +
      tokens.infoControlsGap;
}

double _tilawaMediaPlayerBarFullTransportWidth({
  required TilawaMediaPlayerBarTokens tokens,
  required bool showSleepTimer,
}) {
  final int controlCount = showSleepTimer ? 4 : 3;
  return controlCount * tokens.controlButtonSize +
      (controlCount - 1) * tokens.controlsGap;
}

class _ArtworkTile extends StatelessWidget {
  const _ArtworkTile({
    required this.size,
    required this.radius,
    required this.placeholderColor,
    required this.artwork,
    required this.defaultIconSize,
  });

  final double size;
  final double radius;
  final Color placeholderColor;
  final Widget? artwork;
  final double defaultIconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: .transparency,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: placeholderColor,
        ),
        child: artwork == null
            ? Center(
                child: Icon(
                  FluentIcons.music_note_2_24_filled,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: defaultIconSize,
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: artwork,
              ),
      ),
    );
  }
}

class _TransportControls extends StatelessWidget {
  const _TransportControls({
    required this.designTokens,
    required this.componentTokens,
    required this.colorScheme,
    required this.disabledControlColor,
    required this.isPlaying,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.isSleepTimerActive,
    required this.showSleepTimer,
    required this.compact,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onSleepTimerTap,
    required this.previousTooltip,
    required this.playTooltip,
    required this.pauseTooltip,
    required this.nextTooltip,
    required this.sleepTimerTooltip,
  });

  final TilawaDesignTokens designTokens;
  final TilawaMediaPlayerBarTokens componentTokens;
  final ColorScheme colorScheme;
  final Color disabledControlColor;
  final bool isPlaying;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isSleepTimerActive;
  final bool showSleepTimer;
  final bool compact;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSleepTimerTap;
  final String? previousTooltip;
  final String? playTooltip;
  final String? pauseTooltip;
  final String? nextTooltip;
  final String? sleepTimerTooltip;

  @override
  Widget build(BuildContext context) {
    // Transport order stays LTR (prev | play | next) per platform convention,
    // even when the app locale is Arabic.
    return Directionality(
      textDirection: .ltr,
      child: Row(
        mainAxisSize: .min,
        spacing: componentTokens.controlsGap,
        children: [
          if (!compact) ...[
            _TransportIconButton(
              size: componentTokens.controlButtonSize,
              tooltip: previousTooltip ?? 'Previous track',
              icon: FluentIcons.previous_20_filled,
              iconSize: designTokens.iconSizeMedium,
              enabled: canGoPrevious,
              color: canGoPrevious
                  ? colorScheme.onSurfaceVariant
                  : disabledControlColor,
              onPressed: canGoPrevious ? onPrevious : null,
            ),
          ],
          _PlayPauseButton(
            size: componentTokens.playPauseButtonSize,
            iconSize: componentTokens.playPauseIconSize,
            isPlaying: isPlaying,
            playTooltip: playTooltip,
            pauseTooltip: pauseTooltip,
            onPressed: onPlayPause,
          ),
          if (!compact) ...[
            _TransportIconButton(
              size: componentTokens.controlButtonSize,
              tooltip: nextTooltip ?? 'Next track',
              icon: FluentIcons.next_20_filled,
              iconSize: designTokens.iconSizeMedium,
              enabled: canGoNext,
              color: canGoNext
                  ? colorScheme.onSurfaceVariant
                  : disabledControlColor,
              onPressed: canGoNext ? onNext : null,
            ),
            if (showSleepTimer)
              _TransportIconButton(
                size: componentTokens.controlButtonSize,
                tooltip: sleepTimerTooltip ?? 'Sleep timer',
                icon: isSleepTimerActive
                    ? FluentIcons.timer_20_filled
                    : FluentIcons.timer_20_regular,
                iconSize: designTokens.iconSizeMedium,
                enabled: true,
                color: isSleepTimerActive
                    ? colorScheme.primary
                    : disabledControlColor,
                onPressed: onSleepTimerTap,
              ),
          ],
        ],
      ),
    );
  }
}

class _TransportIconButton extends StatelessWidget {
  const _TransportIconButton({
    required this.size,
    required this.tooltip,
    required this.icon,
    required this.iconSize,
    required this.enabled,
    required this.color,
    required this.onPressed,
  });

  final double size;
  final String tooltip;
  final IconData icon;
  final double iconSize;
  final bool enabled;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: Icon(icon, size: iconSize, color: color),
        onPressed: onPressed,
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.size,
    required this.iconSize,
    required this.isPlaying,
    required this.playTooltip,
    required this.pauseTooltip,
    required this.onPressed,
  });

  final double size;
  final double iconSize;
  final bool isPlaying;
  final String? playTooltip;
  final String? pauseTooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: .circle,
        color: colorScheme.primary,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: isPlaying
            ? (pauseTooltip ?? 'Pause')
            : (playTooltip ?? 'Play'),
        icon: Icon(
          isPlaying ? FluentIcons.pause_16_filled : FluentIcons.play_16_filled,
          color: colorScheme.onPrimary,
          size: iconSize,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
