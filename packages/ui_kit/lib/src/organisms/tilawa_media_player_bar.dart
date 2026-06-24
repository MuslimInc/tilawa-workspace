import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/src/foundation/component_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_icons.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_interactive_surface.dart';

/// Minimum horizontal space reserved for surah + reciter before the bar
/// collapses secondary transport controls (prev / sleep timer). Next track
/// stays visible in compact layout (FR-004).
const double kTilawaMediaPlayerBarMinMetadataWidth = 96.0;

/// Artwork size on compact layouts (slightly smaller to free metadata space).
const double kTilawaMediaPlayerBarCompactArtworkSize = 40.0;

/// Artwork size for the shell dock mini player (compact pill).
const double kTilawaMediaPlayerBarShellArtworkSize = 32.0;

/// Progress strip and matching bottom inset in the shell dock mini player.
const double kTilawaMediaPlayerBarShellEdgeBandHeight = 4.0;

/// Splits [maxHeight] around [rowHeight] into top/bottom bands (max [maxBand]).
///
/// [bottomBand] absorbs any sub-pixel slack so the three slices sum to
/// [maxHeight] exactly.
({double topBand, double bottomBand}) resolveTilawaMediaPlayerCollapsedBands({
  required double maxHeight,
  required double rowHeight,
  double maxBand = kTilawaMediaPlayerBarShellEdgeBandHeight,
}) {
  final double slack = math.max(0, maxHeight - rowHeight);
  final double topBand = math.min(maxBand, (slack / 2).floorToDouble());
  final double bottomBand = math.max(0, maxHeight - rowHeight - topBand);
  return (topBand: topBand, bottomBand: bottomBand);
}

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
    this.onSubtitleTap,
    this.onClose,
    this.playPauseSemanticIdentifier,
    this.closeSemanticIdentifier,
    this.openPlayerSemanticLabel,
    this.titleSubtitle,
    this.identityChromeOpacity = 1,
    this.previousTooltip,
    this.playTooltip,
    this.pauseTooltip,
    this.nextTooltip,
    this.sleepTimerTooltip,
    this.pillBorderRadius,
    this.shellPillLayout = false,
    this.shellDockLayout = false,
    this.contentPaddingOverride,
    this.backgroundColorOverride,
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
  final VoidCallback? onSubtitleTap;
  final VoidCallback? onClose;

  /// Optional [Semantics.identifier] for Maestro / accessibility on play-pause.
  final String? playPauseSemanticIdentifier;

  /// Optional [Semantics.identifier] for Maestro / accessibility on dismiss.
  final String? closeSemanticIdentifier;

  final String? openPlayerSemanticLabel;

  /// Optional title/subtitle widget (e.g. Hero metadata). When null, [title] and
  /// [subtitle] strings are rendered.
  final Widget? titleSubtitle;

  /// Fades artwork + title during expand/collapse handoff (controls unchanged).
  final double identityChromeOpacity;

  final String? previousTooltip;
  final String? playTooltip;
  final String? pauseTooltip;
  final String? nextTooltip;
  final String? sleepTimerTooltip;

  /// When set, overrides [TilawaMediaPlayerBarTokens.borderRadius] for a
  /// capsule-shaped shell mini player.
  final double? pillBorderRadius;

  /// Compact shell dock: smaller artwork padding, no sleep timer.
  final bool shellPillLayout;

  /// Full-width shell dock above bottom nav (YouTube Music style).
  ///
  /// Square edges, top divider only, two-line metadata when height allows.
  final bool shellDockLayout;

  /// Optional override for [TilawaMediaPlayerBarTokens.contentPadding].
  final EdgeInsetsGeometry? contentPaddingOverride;

  /// Optional override for [TilawaMediaPlayerBarTokens.shellBackgroundColor].
  final Color? backgroundColorOverride;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildBar(context, constraints),
    );
  }

  Widget _buildBar(BuildContext context, BoxConstraints constraints) {
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
    final bool isShellChrome = shellDockLayout || shellPillLayout;
    final borderRadius = shellDockLayout
        ? BorderRadius.zero
        : BorderRadius.circular(
            pillBorderRadius ?? componentTokens.borderRadius,
          );
    final TextDirection direction = Directionality.of(context);
    final EdgeInsets basePadding =
        (contentPaddingOverride ?? componentTokens.contentPadding).resolve(
          direction,
        );
    double verticalPaddingTop = basePadding.top;
    double verticalPaddingBottom = basePadding.bottom;
    if (!isShellChrome &&
        constraints.hasBoundedHeight &&
        constraints.maxHeight.isFinite) {
      final double rowBudget =
          constraints.maxHeight -
          designTokens.progressHeight -
          (verticalPaddingTop * 2);
      if (rowBudget < componentTokens.playPauseButtonSize) {
        verticalPaddingTop = math.max(
          4,
          (constraints.maxHeight -
                  designTokens.progressHeight -
                  componentTokens.playPauseButtonSize) /
              2,
        );
        verticalPaddingBottom = verticalPaddingTop;
      }
    }
    final EdgeInsetsGeometry contentPadding = EdgeInsets.fromLTRB(
      basePadding.left,
      verticalPaddingTop,
      basePadding.right,
      verticalPaddingBottom,
    );
    final String resolvedOpenPlayerLabel =
        openPlayerSemanticLabel ??
        (subtitle == null || subtitle!.isEmpty ? title : '$title, $subtitle');

    final double resolvedLayoutWidth = resolveTilawaMediaPlayerBarLayoutWidth(
      context,
      layoutWidth: layoutWidth,
    );
    final bool tightHeight =
        constraints.hasBoundedHeight &&
        constraints.maxHeight.isFinite &&
        constraints.maxHeight <
            designTokens.progressHeight +
                20 +
                componentTokens.playPauseButtonSize;
    final bool showSleepTimer =
        isSleepTimerEnabled && !isShellChrome && !tightHeight;
    final bool useCompactControls =
        isShellChrome ||
        tilawaMediaPlayerBarNeedsCompactControls(
          maxWidth: resolvedLayoutWidth,
          tokens: componentTokens,
          showSleepTimer: showSleepTimer,
        );
    final double artworkSize = shellPillLayout
        ? kTilawaMediaPlayerBarShellArtworkSize
        : shellDockLayout || useCompactControls
        ? kTilawaMediaPlayerBarCompactArtworkSize
        : componentTokens.artworkSize;
    final bool useSingleLineMetadata =
        shellPillLayout || (tightHeight && !shellDockLayout);

    final double artworkInfoGap = isShellChrome
        ? designTokens.spaceExtraSmall
        : componentTokens.artworkInfoGap;
    final double infoControlsGap = isShellChrome
        ? designTokens.spaceExtraSmall
        : componentTokens.infoControlsGap;

    final VoidCallback? identityTap = onTap;
    final bool usePillOutline =
        pillBorderRadius != null && pillBorderRadius! > 0;
    final double pillBorderInset = usePillOutline
        ? designTokens.borderWidthThin * 2
        : 0;

    final Widget contentRow = Row(
      spacing: infoControlsGap,
      children: [
        Expanded(
          child: _OpenPlayerTapTarget(
            onTap: identityTap,
            semanticLabel: identityTap != null ? resolvedOpenPlayerLabel : null,
            child: Opacity(
              opacity: identityChromeOpacity.clamp(0.0, 1.0),
              child: Row(
                children: [
                  _ArtworkTile(
                    size: artworkSize,
                    radius: componentTokens.artworkRadius,
                    placeholderColor: componentTokens.artworkPlaceholderColor,
                    artwork: artwork,
                    defaultIconSize: componentTokens.defaultIconSize,
                  ),
                  SizedBox(width: artworkInfoGap),
                  Expanded(
                    child:
                        titleSubtitle ??
                        (useSingleLineMetadata &&
                                subtitle != null &&
                                subtitle!.isNotEmpty
                            ? _CompactMetadataLine(
                                title: title,
                                subtitle: subtitle!,
                                titleStyle: titleStyle,
                                subtitleStyle: subtitleStyle,
                                onSubtitleTap: onSubtitleTap,
                              )
                            : Column(
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
                                    _SubtitleTapTarget(
                                      onTap: onSubtitleTap,
                                      label: subtitle!,
                                      child: Text(
                                        subtitle!,
                                        style: subtitleStyle,
                                        maxLines: 1,
                                        overflow: .ellipsis,
                                        textAlign: TextAlign.start,
                                      ),
                                    ),
                                ],
                              )),
                  ),
                ],
              ),
            ),
          ),
        ),
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
          shellDockLayout: shellDockLayout,
          onPlayPause: onPlayPause,
          onPrevious: onPrevious,
          onNext: onNext,
          onSleepTimerTap: onSleepTimerTap,
          playPauseSemanticIdentifier: playPauseSemanticIdentifier,
          previousTooltip: previousTooltip,
          playTooltip: playTooltip,
          pauseTooltip: pauseTooltip,
          nextTooltip: nextTooltip,
          sleepTimerTooltip: sleepTimerTooltip,
        ),
      ],
    );

    final bool useCollapsedBandLayout =
        isShellChrome ||
        (constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            tightHeight);
    final double? availableInnerHeight =
        useCollapsedBandLayout &&
            constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite
        ? math.max(0, constraints.maxHeight - pillBorderInset)
        : null;
    final ({double topBand, double bottomBand}) collapsedBands =
        availableInnerHeight != null
        ? resolveTilawaMediaPlayerCollapsedBands(
            maxHeight: availableInnerHeight,
            rowHeight: componentTokens.playPauseButtonSize,
          )
        : (
            topBand: designTokens.progressHeight,
            bottomBand: isShellChrome
                ? kTilawaMediaPlayerBarShellEdgeBandHeight
                : 0.0,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColorOverride ?? componentTokens.shellBackgroundColor,
        borderRadius: borderRadius,
        boxShadow: shellDockLayout || componentTokens.shadowOpacity == 0
            ? null
            : [
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: componentTokens.shadowOpacity * 0.55,
                  ),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: componentTokens.shadowOpacity,
                  ),
                  blurRadius: designTokens.blurShadow,
                  offset: designTokens.shadowOffsetMedium,
                ),
              ],
        border: usePillOutline
            ? Border.all(
                color: componentTokens.shellOutlineColor,
                width: designTokens.borderWidthThin,
              )
            : Border(
                top: BorderSide(
                  color: componentTokens.shellOutlineColor,
                  width: designTokens.borderWidthThin,
                ),
              ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: collapsedBands.topBand,
              child: collapsedBands.topBand <= 0
                  ? const SizedBox.shrink()
                  : ClipRect(
                      clipBehavior: Clip.hardEdge,
                      child: _ProgressTapTarget(
                        onTap: null,
                        semanticLabel: null,
                        child:
                            progressBarOverride ??
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  componentTokens.progressTrackBackgroundColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                              minHeight: collapsedBands.topBand,
                            ),
                      ),
                    ),
            ),
            if (useCollapsedBandLayout) ...[
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: basePadding.resolve(direction).left,
                  end: basePadding.resolve(direction).right,
                ),
                child: SizedBox(
                  height: componentTokens.playPauseButtonSize,
                  child: contentRow,
                ),
              ),
              const Expanded(child: SizedBox.shrink()),
            ] else
              Padding(
                padding: contentPadding.resolve(direction),
                child: SizedBox(
                  height: useSingleLineMetadata
                      ? componentTokens.playPauseButtonSize
                      : null,
                  child: contentRow,
                ),
              ),
          ],
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

/// Returns true when the bar should hide the sleep timer (keeping play/pause)
/// so metadata keeps at least [kTilawaMediaPlayerBarMinMetadataWidth]
/// logical pixels.
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
  final int controlCount = showSleepTimer ? 2 : 1;
  return controlCount * tokens.controlButtonSize +
      (controlCount - 1) * tokens.controlsGap;
}

/// Single-line surah · reciter row for the compact shell mini player.
class _CompactMetadataLine extends StatelessWidget {
  const _CompactMetadataLine({
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subtitleStyle,
    this.onSubtitleTap,
  });

  final String title;
  final String subtitle;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final VoidCallback? onSubtitleTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          ' · ',
          style: subtitleStyle,
          maxLines: 1,
        ),
        Flexible(
          child: _SubtitleTapTarget(
            onTap: onSubtitleTap,
            label: subtitle,
            child: Text(
              subtitle,
              style: subtitleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

/// Reciter / secondary line — optional separate action (e.g. open Reciters tab).
class _SubtitleTapTarget extends StatelessWidget {
  const _SubtitleTapTarget({
    required this.onTap,
    required this.label,
    required this.child,
  });

  final VoidCallback? onTap;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return child;
    }

    return Semantics(
      button: true,
      label: label,
      child: TilawaInteractiveSurface(
        // Outer Semantics owns the button role + label.
        button: false,
        onTap: onTap,
        // Transparent tap region over text/metadata: keep the content static
        // (no press-scale) but gain the keyboard focus ring + state layer.
        enablePressAnimation: false,
        child: child,
      ),
    );
  }
}

/// Progress strip that can expand the full player when identity uses another
/// action (e.g. shell mini metadata opens Reciters).
class _ProgressTapTarget extends StatelessWidget {
  const _ProgressTapTarget({
    required this.onTap,
    required this.semanticLabel,
    required this.child,
  });

  final VoidCallback? onTap;
  final String? semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return child;
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: TilawaInteractiveSurface(
        // Outer Semantics owns the button role + label.
        button: false,
        onTap: onTap,
        // Transparent tap region over text/metadata: keep the content static
        // (no press-scale) but gain the keyboard focus ring + state layer.
        enablePressAnimation: false,
        child: child,
      ),
    );
  }
}

/// Artwork + metadata strip that opens the full player when tapped.
///
/// Transport controls sit outside this target so play/pause taps never
/// also fire [TilawaMediaPlayerBar.onTap] (FR-003).
class _OpenPlayerTapTarget extends StatelessWidget {
  const _OpenPlayerTapTarget({
    required this.onTap,
    required this.semanticLabel,
    required this.child,
  });

  final VoidCallback? onTap;
  final String? semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return child;
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: TilawaInteractiveSurface(
        // Outer Semantics owns the button role + label.
        button: false,
        onTap: onTap,
        // Transparent tap region over text/metadata: keep the content static
        // (no press-scale) but gain the keyboard focus ring + state layer.
        enablePressAnimation: false,
        child: child,
      ),
    );
  }
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
                  TilawaIcons.musicNote,
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
    required this.shellDockLayout,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onSleepTimerTap,
    this.playPauseSemanticIdentifier,
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
  final bool shellDockLayout;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSleepTimerTap;
  final String? playPauseSemanticIdentifier;
  final String? previousTooltip;
  final String? playTooltip;
  final String? pauseTooltip;
  final String? nextTooltip;
  final String? sleepTimerTooltip;

  @override
  Widget build(BuildContext context) {
    final Widget playPause = shellDockLayout
        ? _TransportIconButton(
            size: componentTokens.controlButtonSize,
            tooltip: isPlaying
                ? (pauseTooltip ?? 'Pause')
                : (playTooltip ?? 'Play'),
            icon: isPlaying ? TilawaIcons.pauseSmall : TilawaIcons.playSmall,
            iconSize: designTokens.iconSizeLarge,
            enabled: true,
            color: colorScheme.onSurface,
            onPressed: onPlayPause,
          )
        : _PlayPauseButton(
            size: componentTokens.playPauseButtonSize,
            iconSize: componentTokens.playPauseIconSize,
            isPlaying: isPlaying,
            semanticIdentifier: playPauseSemanticIdentifier,
            playTooltip: playTooltip,
            pauseTooltip: pauseTooltip,
            onPressed: onPlayPause,
          );

    final Widget playPauseControl =
        shellDockLayout && playPauseSemanticIdentifier != null
        ? Semantics(
            identifier: playPauseSemanticIdentifier,
            button: true,
            child: playPause,
          )
        : playPause;

    return Directionality(
      textDirection: .ltr,
      child: Row(
        mainAxisSize: .min,
        spacing: componentTokens.controlsGap,
        children: [
          playPauseControl,
          if (!compact && showSleepTimer)
            _TransportIconButton(
              size: componentTokens.controlButtonSize,
              tooltip: sleepTimerTooltip ?? 'Sleep timer',
              icon: isSleepTimerActive
                  ? TilawaIcons.timerSmallFilled
                  : TilawaIcons.timerSmall,
              iconSize: designTokens.iconSizeMedium,
              enabled: true,
              color: isSleepTimerActive
                  ? colorScheme.primary
                  : disabledControlColor,
              onPressed: onSleepTimerTap,
            ),
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
    this.semanticIdentifier,
    required this.playTooltip,
    required this.pauseTooltip,
    required this.onPressed,
  });

  final double size;
  final double iconSize;
  final bool isPlaying;
  final String? semanticIdentifier;
  final String? playTooltip;
  final String? pauseTooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Widget button = Container(
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
          isPlaying ? TilawaIcons.pauseSmall : TilawaIcons.playSmall,
          color: colorScheme.onPrimary,
          size: iconSize,
        ),
        onPressed: onPressed,
      ),
    );
    if (semanticIdentifier == null) {
      return button;
    }
    return Semantics(
      identifier: semanticIdentifier,
      button: true,
      child: button,
    );
  }
}
