import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/downloads/presentation/widgets/download_button.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../models/reciter_surah_list_item.dart';
import '../reciter_semantics_ids.dart';
import 'reciter_catalog_chrome.dart';

class SurahGridItem extends StatelessWidget {
  const SurahGridItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ReciterSurahListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

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

    final Color activeFill = ReciterCatalogChrome.activeFill(colorScheme);
    final Color activeOnFill = ReciterCatalogChrome.activeOnFill(colorScheme);
    final Color idleBg = ReciterCatalogChrome.idleFill(colorScheme);
    final Color idleFg = colorScheme.primary;
    final double tileRadius = tokens.resolveRadius(
      family: TilawaRadiusFamily.card,
    );
    final double badgeSize = tokens.iconSizeLarge + tokens.spaceExtraLarge;

    return Semantics(
      identifier: ReciterSemanticsIds.surahRow(item.semanticsKey),
      button: true,
      child: TilawaCard(
        surface: TilawaCardSurface.raised,
        backgroundColor: isCurrentItem
            ? colorScheme.primaryContainer.withValues(
                alpha: tokens.opacitySubtle * 2,
              )
            : colorScheme.surface,
        borderColor: isCurrentItem ? activeFill : colorScheme.outlineVariant,
        borderWidth: isCurrentItem
            ? tokens.borderWidthThin * 4
            : tokens.borderWidthThin,
        borderRadius: tileRadius,
        padding: EdgeInsets.all(tokens.spaceMedium),
        onTap: handleTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: tokens.durationFast,
                  width: badgeSize,
                  height: badgeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrentItem ? activeFill : idleBg,
                    borderRadius: BorderRadius.circular(tokens.radiusLarge),
                    border: Border.all(
                      color: isCurrentItem
                          ? activeFill
                          : idleFg.withValues(alpha: tokens.opacityShadow),
                      width: tokens.borderWidthThin * 2,
                    ),
                  ),
                  child: isCurrentItem
                      ? Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: activeOnFill,
                          size: tokens.iconSizeMedium,
                        )
                      : Text(
                          item.formattedNumber,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: idleFg,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
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
            Text(
              item.displayName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
