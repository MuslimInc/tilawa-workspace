import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/downloads/presentation/widgets/download_button.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../reciter_semantics_ids.dart';
import 'reciter_catalog_chrome.dart';

class SurahGridItem extends StatelessWidget {
  const SurahGridItem({
    super.key,
    required this.surah,
    required this.index,
    required this.reciterName,
    required this.reciterId,
    required this.onTap,
  });

  final SurahEntity surah;
  final int index;
  final String reciterName;
  final int reciterId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    // Combine selectors to reduce overhead and subscription count
    final (bool isPlaying, bool isCurrentItem) = context
        .select<AudioPlayerBloc, (bool, bool)>((bloc) {
          final AudioEntity? currentAudio = bloc.state.currentAudio;
          final PlaybackStateEntity? playbackState = bloc.state.playbackState;
          final bool shouldShowPlayer = bloc.state.shouldShowBottomPlayer;

          final bool isCurrent =
              shouldShowPlayer &&
              (currentAudio?.id == surah.id ||
                  currentAudio?.url == surah.audio.url);

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

    // Shared palette — same as SurahListTile and ReciterCard avatar.
    final List<Color> bgPalette = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      colorScheme.surfaceContainerHighest,
    ];
    final List<Color> fgPalette = [
      colorScheme.onPrimaryContainer,
      colorScheme.onSecondaryContainer,
      colorScheme.onTertiaryContainer,
      colorScheme.onSurfaceVariant,
    ];
    final Color idleBg =
        bgPalette[index % bgPalette.length].withValues(alpha: tokens.opacityEmphasis);
    final Color idleFg = fgPalette[index % fgPalette.length];
    final Color activeFill = ReciterCatalogChrome.activeFill(colorScheme);
    final Color activeOnFill = ReciterCatalogChrome.activeOnFill(colorScheme);
    // Badge fills the full card width so the number reads as a strong hero element.
    // Height is square with the badge width to keep the visual centred.
    final double badgeSize = tokens.iconSizeLarge + tokens.spaceExtraLarge;

    return Semantics(
      identifier: ReciterSemanticsIds.surahRow(
        surah.formattedId.isNotEmpty ? surah.formattedId : '${index + 1}',
      ),
      button: true,
      child: TilawaCard(
        surface: TilawaCardSurface.flat,
        backgroundColor: isCurrentItem
            ? colorScheme.primaryContainer.withValues(alpha: tokens.opacitySubtle * 2)
            : colorScheme.surface,
        borderColor: isCurrentItem
            ? activeFill
            : colorScheme.outlineVariant,
        borderWidth: isCurrentItem
            ? tokens.borderWidthThin * 4
            : tokens.borderWidthThin,
        borderRadius: tokens.radiusLarge,
        padding: EdgeInsets.all(tokens.spaceMedium),
        onTap: handleTap,
        // Vertical layout: badge (top) → name+subtitle (middle) → download (bottom-end).
        // Matches the list tile's token language while fitting the narrow grid column.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: coloured number badge (left) + play/pause state (right when active).
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
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: activeOnFill,
                          size: tokens.iconSizeMedium,
                        )
                      : Text(
                          surah.formattedId.isNotEmpty
                              ? surah.formattedId
                              : '${index + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: idleFg,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                ),
                DownloadButton(
                  url: surah.id,
                  surahTitle: surah.name,
                  reciterName: reciterName,
                  reciterId: reciterId,
                  catalogChrome: true,
                  initialIsDownloaded: surah.isDownloaded,
                  initialIsDownloading: surah.isDownloading,
                  initialProgress: surah.downloadProgress,
                  identifier: ReciterSemanticsIds.surahDownloadButton(
                    surah.formattedId.isNotEmpty
                        ? surah.formattedId
                        : '${index + 1}',
                  ),
                ),
              ],
            ),
            // Bottom: name + reciter — same type styles as list tile.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: tokens.spaceExtraSmall,
              children: [
                Text(
                  surah.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  surah.reciterName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
