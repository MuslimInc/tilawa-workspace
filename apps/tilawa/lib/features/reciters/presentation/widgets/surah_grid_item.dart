import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/downloads/presentation/widgets/download_button.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa_core/entities/audio.dart';

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
        borderRadius: BorderRadius.circular(16),
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
                ? theme.primaryColor.withValues(alpha: 0.08)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentItem
                  ? theme.primaryColor.withValues(alpha: 0.5)
                  : theme.dividerColor.withValues(alpha: 0.15),
              width: isCurrentItem ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isCurrentItem
                    ? theme.primaryColor.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      surah.formattedId.isNotEmpty
                          ? surah.formattedId
                          : '${index + 1}',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isCurrentItem)
                    Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                ],
              ),
              SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      surah.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCurrentItem
                            ? theme.primaryColor
                            : theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      surah.nameAr,
                      // Arabic font handling usually needed here
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: theme.hintColor,
                        fontFamily:
                            'Amiri', // Assuming Amiri is available or default
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
