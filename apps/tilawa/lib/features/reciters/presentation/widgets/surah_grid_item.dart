import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/downloads/presentation/widgets/download_button.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
    final tokens = theme.tokens;
    final borderRadius = BorderRadius.circular(tokens.radiusLarge);

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () {
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
        },
        child: Container(
          decoration: BoxDecoration(
            color: isCurrentItem
                ? theme.primaryColor.withValues(alpha: tokens.opacitySubtle)
                : theme.cardColor,
            borderRadius: borderRadius,
            border: Border.all(
              color: isCurrentItem
                  ? theme.primaryColor.withValues(alpha: tokens.opacityEmphasis)
                  : theme.dividerColor.withValues(alpha: tokens.opacitySubtle),
              width: isCurrentItem
                  ? tokens.borderWidthThin * 3
                  : tokens.borderWidthThin * 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isCurrentItem
                    ? theme.primaryColor.withValues(alpha: tokens.opacitySubtle)
                    : Colors.black.withValues(alpha: tokens.opacitySubtle / 2),
                blurRadius: tokens.blurGlass,
                offset: tokens.shadowOffsetMedium,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: tokens.opacitySubtle / 4),
                blurRadius: tokens.spaceExtraSmall,
                offset: tokens.shadowOffsetSmall,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isTight =
                  constraints.maxHeight < tokens.cardTightHeightThreshold;
              final EdgeInsetsGeometry padding = EdgeInsets.all(
                isTight ? tokens.spaceSmall : tokens.spaceMedium,
              );
              final EdgeInsets resolvedPadding = padding.resolve(
                Directionality.of(context),
              );
              final double contentWidth =
                  constraints.maxWidth - resolvedPadding.horizontal;
              final double gap = isTight
                  ? tokens.spaceExtraSmall
                  : tokens.spaceSmall;
              final double downloadButtonSize =
                  tokens.iconSizeLarge + tokens.spaceSmall;

              return Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisAlignment: .spaceBetween,
                  mainAxisSize: .min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spaceSmall,
                            vertical: tokens.spaceExtraSmall,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: tokens.opacityMedium),
                            borderRadius: BorderRadius.circular(
                              tokens.radiusMedium,
                            ),
                          ),
                          child: Text(
                            surah.formattedId.isNotEmpty
                                ? surah.formattedId
                                : '${index + 1}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCurrentItem)
                          Icon(
                            isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: theme.primaryColor,
                            size: tokens.iconSizeMedium,
                          ),
                      ],
                    ),
                    SizedBox(height: gap),
                    Flexible(
                      child: Align(
                        alignment: .centerStart,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: .centerStart,
                          child: SizedBox(
                            width: contentWidth > 0 ? contentWidth : 0,
                            child: Column(
                              crossAxisAlignment: .start,
                              mainAxisSize: .min,
                              spacing: tokens.spaceExtraSmall,
                              children: [
                                Text(
                                  surah.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentItem
                                        ? theme.primaryColor
                                        : theme.textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  surah.nameAr,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: theme.hintColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: gap),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: SizedBox(
                        width: downloadButtonSize,
                        height: downloadButtonSize,
                        child: FittedBox(
                          child: DownloadButton(
                            url: surah.id,
                            surahTitle: surah.name,
                            reciterName: reciterName,
                            reciterId: reciterId,
                            initialIsDownloaded: surah.isDownloaded,
                            initialIsDownloading: surah.isDownloading,
                            initialProgress: surah.downloadProgress,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
