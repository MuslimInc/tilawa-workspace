import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/quran_player_semantics_ids.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'quran_player_expand_physics.dart';
import 'quran_player_morph_layout.dart';

/// Exposes [PlayerExpandTransitionMetrics] to the expanded player subtree.
class PlayerExpandMetricsScope extends InheritedWidget {
  const PlayerExpandMetricsScope({
    required this.metrics,
    required super.child,
    super.key,
  });

  final PlayerExpandTransitionMetrics metrics;

  static PlayerExpandTransitionMetrics? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PlayerExpandMetricsScope>()
        ?.metrics;
  }

  @override
  bool updateShouldNotify(PlayerExpandMetricsScope oldWidget) {
    return oldWidget.metrics.handoffT != metrics.handoffT ||
        oldWidget.metrics.stageChromeOpacity != metrics.stageChromeOpacity ||
        oldWidget.metrics.queueChromeT != metrics.queueChromeT;
  }
}

/// Shared artwork + title that morph between mini and expanded during transition.
///
/// Rendered above both chrome layers so the player feels like one element.
class QuranPlayerMorphLayer extends StatelessWidget {
  const QuranPlayerMorphLayer({
    super.key,
    required this.audio,
    required this.handoffT,
    required this.layout,
    required this.onImageBackdrop,
  });

  final AudioEntity audio;
  final double handoffT;
  final QuranPlayerMorphLayout layout;
  final bool onImageBackdrop;

  @override
  Widget build(BuildContext context) {
    if (handoffT < 0.02) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final barTokens = theme.componentTokens.mediaPlayerBar;
    final Color titleColor = onImageBackdrop
        ? colorScheme.onSurface
        : colorScheme.onSurface;
    final Color subtitleColor = onImageBackdrop
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(
            alpha: barTokens.subtitleOpacity,
          );

    return IgnorePointer(
      child: Opacity(
        opacity: handoffT.clamp(0.0, 1.0),
        child: RepaintBoundary(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: layout.artRect,
                child: _MorphArtwork(
                  artUri: audio.artUri,
                  borderRadius: layout.artBorderRadius,
                ),
              ),
              Positioned.fromRect(
                rect: layout.titleRect,
                child: Transform.scale(
                  scale: layout.titleScale,
                  alignment: layout.titleScaleAlignment,
                  child: _MorphMetadata(
                    title: audio.title,
                    artist: audio.artist,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    textAlign: layout.titleAlign,
                    maxLines: layout.titleMaxLines,
                    spacing: tokens.spaceExtraSmall,
                    showSubtitle: layout.showMorphSubtitle,
                    barTokens: barTokens,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MorphArtwork extends StatelessWidget {
  const _MorphArtwork({
    required this.artUri,
    required this.borderRadius,
  });

  final String? artUri;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: QuranPlayerSemanticsIds.expandedArtwork,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: artUri != null
            ? CachedNetworkImage(
                imageUrl: artUri!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (context, url, error) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.componentTokens.mediaPlayerBar.artworkPlaceholderColor,
      child: Center(
        child: Icon(
          FluentIcons.music_note_2_24_filled,
          color: theme.colorScheme.onSurfaceVariant,
          size: theme.tokens.iconSizeLarge,
        ),
      ),
    );
  }
}

class _MorphMetadata extends StatelessWidget {
  const _MorphMetadata({
    required this.title,
    required this.artist,
    required this.titleColor,
    required this.subtitleColor,
    required this.textAlign,
    required this.maxLines,
    required this.spacing,
    required this.showSubtitle,
    required this.barTokens,
  });

  final String title;
  final String? artist;
  final Color titleColor;
  final Color subtitleColor;
  final TextAlign textAlign;
  final int maxLines;
  final double spacing;
  final bool showSubtitle;
  final TilawaMediaPlayerBarTokens barTokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TextStyle titleStyle =
        (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontWeight: barTokens.titleFontWeight,
          color: titleColor,
        );
    final TextStyle subtitleStyle =
        (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
          color: subtitleColor,
        );
    final String subtitleText = artist ?? context.l10n.unknownReciter;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final double maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : double.infinity;

        if (!showSubtitle) {
          return _MorphMetadataStacked(
            title: title,
            subtitle: null,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            textAlign: textAlign,
            titleMaxLines: maxLines,
            spacing: spacing,
          );
        }

        final int stackedTitleLines = _morphStackedTitleMaxLines(
          context: context,
          title: title,
          subtitle: subtitleText,
          titleStyle: titleStyle,
          subtitleStyle: subtitleStyle,
          requestedTitleMaxLines: maxLines,
          spacing: spacing,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );

        if (stackedTitleLines > 0) {
          return _MorphMetadataStacked(
            title: title,
            subtitle: subtitleText,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            textAlign: textAlign,
            titleMaxLines: stackedTitleLines,
            spacing: spacing,
          );
        }

        if (_morphCompactMetadataFits(
          context: context,
          title: title,
          subtitle: subtitleText,
          titleStyle: titleStyle,
          subtitleStyle: subtitleStyle,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        )) {
          return _MorphCompactMetadataLine(
            title: title,
            subtitle: subtitleText,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            textAlign: textAlign,
          );
        }

        return _MorphMetadataStacked(
          title: title,
          subtitle: null,
          titleStyle: titleStyle,
          subtitleStyle: subtitleStyle,
          textAlign: textAlign,
          titleMaxLines: 1,
          spacing: spacing,
        );
      },
    );
  }
}

int _morphStackedTitleMaxLines({
  required BuildContext context,
  required String title,
  required String subtitle,
  required TextStyle titleStyle,
  required TextStyle subtitleStyle,
  required int requestedTitleMaxLines,
  required double spacing,
  required double maxWidth,
  required double maxHeight,
}) {
  for (final int lines in <int>[requestedTitleMaxLines, 1]) {
    if (_morphStackedMetadataFits(
      context: context,
      title: title,
      subtitle: subtitle,
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
      titleMaxLines: lines,
      spacing: spacing,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    )) {
      return lines;
    }
  }
  return 0;
}

bool _morphStackedMetadataFits({
  required BuildContext context,
  required String title,
  required String subtitle,
  required TextStyle titleStyle,
  required TextStyle subtitleStyle,
  required int titleMaxLines,
  required double spacing,
  required double maxWidth,
  required double maxHeight,
}) {
  if (!maxHeight.isFinite) {
    return true;
  }
  final double titleHeight = tilawaMeasureTextHeight(
    context: context,
    style: titleStyle,
    text: title,
    maxLines: titleMaxLines,
    maxWidth: maxWidth,
  );
  final double subtitleHeight = tilawaMeasureTextHeight(
    context: context,
    style: subtitleStyle,
    text: subtitle,
    maxLines: 1,
    maxWidth: maxWidth,
  );
  final double contentHeight = titleHeight + spacing + subtitleHeight;
  return tilawaLayoutHeight(context, contentHeight) <= maxHeight;
}

bool _morphCompactMetadataFits({
  required BuildContext context,
  required String title,
  required String subtitle,
  required TextStyle titleStyle,
  required TextStyle subtitleStyle,
  required double maxWidth,
  required double maxHeight,
}) {
  if (!maxHeight.isFinite) {
    return true;
  }
  final double titleHeight = tilawaMeasureTextHeight(
    context: context,
    style: titleStyle,
    text: title,
    maxLines: 1,
    maxWidth: maxWidth,
  );
  final double subtitleHeight = tilawaMeasureTextHeight(
    context: context,
    style: subtitleStyle,
    text: subtitle,
    maxLines: 1,
    maxWidth: maxWidth,
  );
  final double separatorHeight = tilawaMeasureTextHeight(
    context: context,
    style: subtitleStyle,
    text: ' · ',
    maxLines: 1,
    maxWidth: maxWidth,
  );
  final double contentHeight = titleHeight > subtitleHeight
      ? titleHeight
      : subtitleHeight;
  final double rowHeight = contentHeight > separatorHeight
      ? contentHeight
      : separatorHeight;
  return tilawaLayoutHeight(context, rowHeight) <= maxHeight;
}

class _MorphMetadataStacked extends StatelessWidget {
  const _MorphMetadataStacked({
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.textAlign,
    required this.titleMaxLines,
    required this.spacing,
  });

  final String title;
  final String? subtitle;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final TextAlign textAlign;
  final int titleMaxLines;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final CrossAxisAlignment crossAlign = textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAlign,
      mainAxisSize: MainAxisSize.min,
      spacing: spacing,
      children: [
        Semantics(
          identifier: QuranPlayerSemanticsIds.expandedTrackTitle,
          child: Text(
            title,
            style: titleStyle,
            textAlign: textAlign,
            maxLines: titleMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (subtitle != null)
          Semantics(
            identifier: QuranPlayerSemanticsIds.expandedTrackArtist,
            child: Text(
              subtitle!,
              style: subtitleStyle,
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _MorphCompactMetadataLine extends StatelessWidget {
  const _MorphCompactMetadataLine({
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.textAlign,
  });

  final String title;
  final String subtitle;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final Widget line = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Semantics(
            identifier: QuranPlayerSemanticsIds.expandedTrackTitle,
            child: Text(
              title,
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Text(
          ' · ',
          style: subtitleStyle,
          maxLines: 1,
        ),
        Flexible(
          child: Semantics(
            identifier: QuranPlayerSemanticsIds.expandedTrackArtist,
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

    return switch (textAlign) {
      TextAlign.center => Center(child: line),
      TextAlign.end => Align(alignment: Alignment.centerRight, child: line),
      _ => line,
    };
  }
}
