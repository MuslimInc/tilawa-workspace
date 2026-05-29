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
                  alignment: layout.titleAlign == TextAlign.center
                      ? Alignment.topCenter
                      : Alignment.topLeft,
                  child: _MorphMetadata(
                    title: audio.title,
                    artist: audio.artist,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    textAlign: layout.titleAlign,
                    maxLines: layout.titleMaxLines,
                    spacing: tokens.spaceExtraSmall,
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
  });

  final String title;
  final String? artist;
  final Color titleColor;
  final Color subtitleColor;
  final TextAlign textAlign;
  final int maxLines;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barTokens = theme.componentTokens.mediaPlayerBar;
    final TextStyle titleStyle =
        (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontWeight: barTokens.titleFontWeight,
          color: titleColor,
        );
    final TextStyle subtitleStyle =
        (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
          color: subtitleColor,
        );

    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: spacing,
      children: [
        Semantics(
          identifier: QuranPlayerSemanticsIds.expandedTrackTitle,
          child: Text(
            title,
            style: titleStyle,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Semantics(
          identifier: QuranPlayerSemanticsIds.expandedTrackArtist,
          child: Text(
            artist ?? context.l10n.unknownReciter,
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
