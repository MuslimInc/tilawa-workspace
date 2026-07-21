import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/downloads/presentation/widgets/download_button.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../models/reciter_surah_list_item.dart';
import '../reciter_semantics_ids.dart';
import 'reciter_catalog_chrome.dart';

class SurahListTile extends StatelessWidget {
  const SurahListTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ReciterSurahListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final double tileRadius = tokens.resolveRadius(
      family: TilawaRadiusFamily.chrome,
    );
    final double badgeSize = tokens.iconBadgeSize;
    final Color activeFill = ReciterCatalogChrome.activeFill(colorScheme);
    final Color rowFill = colorScheme.surfaceContainerLowest;

    final (bool isPlaying, bool isCurrentItem) = context
        .select<AudioPlayerBloc, (bool, bool)>((bloc) {
          final AudioEntity? currentAudio = bloc.state.currentAudio;
          final PlaybackStateEntity? playbackState = bloc.state.playbackState;
          final bool shouldShowPlayer = bloc.state.shouldShowBottomPlayer;

          final bool isCurrent =
              shouldShowPlayer &&
              (currentAudio?.id == item.audioId ||
                  currentAudio?.url == item.audioUrl);

          final bool playing = isCurrent && (playbackState?.isPlaying ?? false);

          return (playing, isCurrent);
        });
    final Color rowSurface = isCurrentItem
        ? colorScheme.surfaceContainerHigh
        : rowFill;
    final String trackNumber =
        int.tryParse(item.formattedNumber)?.toString() ?? item.formattedNumber;

    void handleTap() {
      if (isCurrentItem) {
        if (isPlaying) {
          context.read<AudioPlayerBloc>().add(
            const AudioPlayerEvent.pauseAudio(),
          );
        } else {
          context.read<AudioPlayerBloc>().add(
            const AudioPlayerEvent.playAudio(),
          );
        }
      } else {
        onTap();
      }
    }

    return AnimatedContainer(
      duration: tokens.durationFast,
      curve: tokens.curveStandard,
      decoration: BoxDecoration(
        color: rowSurface,
        borderRadius: BorderRadius.circular(tileRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              identifier: ReciterSemanticsIds.surahRow(item.semanticsKey),
              button: true,
              label: item.displayName,
              value: isCurrentItem ? context.l10n.currentPlaying : null,
              hint: isPlaying ? context.l10n.pause : context.l10n.play,
              excludeSemantics: true,
              child: TilawaCard(
                surface: TilawaCardSurface.flat,
                backgroundColor: rowSurface,
                borderColor: rowSurface,
                borderWidth: tokens.borderWidthThin,
                borderRadius: tileRadius,
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceSmall,
                  vertical: tokens.spaceMedium,
                ),
                onTap: handleTap,
                child: Row(
                  spacing: tokens.spaceMedium,
                  children: [
                    SizedBox(
                      width: badgeSize,
                      child: Center(
                        child: isCurrentItem
                            ? Icon(
                                Icons.graphic_eq_rounded,
                                color: activeFill,
                                size: tokens.iconSizeLarge,
                              )
                            : Text(
                                trackNumber,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        spacing: tokens.spaceExtraSmall,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isCurrentItem
                                ? '${context.l10n.currentPlaying} · ${item.reciterName}'
                                : item.reciterName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
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
          _SurahOverflowButton(
            item: item,
            backgroundColor: rowSurface,
          ),
          SizedBox(width: tokens.spaceExtraSmall),
        ],
      ),
    );
  }
}

class _SurahOverflowButton extends StatelessWidget {
  const _SurahOverflowButton({
    required this.item,
    required this.backgroundColor,
  });

  final ReciterSurahListItem item;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return TilawaIconActionButton(
      icon: Icons.more_vert_rounded,
      backgroundColor: backgroundColor,
      tooltip: context.l10n.moreOptions,
      onTap: () {
        unawaited(
          showTilawaModalBottomSheet<void>(
            context: context,
            builder: (sheetContext) => _SurahActionsSheet(item: item),
          ),
        );
      },
    );
  }
}

class _SurahActionsSheet extends StatelessWidget {
  const _SurahActionsSheet({required this.item});

  final ReciterSurahListItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: context.floatingBottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TilawaSheetHandle(),
          Padding(
            padding: EdgeInsets.all(tokens.spaceLarge),
            child: Column(
              spacing: tokens.spaceLarge,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  spacing: tokens.spaceExtraSmall,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.reciterName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: tokens.spaceMedium,
                  children: [
                    Icon(
                      Icons.download_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: tokens.iconSizeMedium,
                    ),
                    Expanded(
                      child: Text(
                        context.l10n.download,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DownloadButton(
                      url: item.audioId,
                      surahTitle: item.displayName,
                      reciterName: item.reciterName,
                      reciterId: item.reciterId,
                      catalogChrome: true,
                      initialIsDownloaded: item.isDownloaded,
                      initialIsDownloading: item.isDownloading,
                      initialProgress: item.downloadProgress,
                      identifier: ReciterSemanticsIds.surahDownloadButton(
                        item.semanticsKey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
