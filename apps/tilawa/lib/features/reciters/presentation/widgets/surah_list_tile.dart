import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/downloads/presentation/widgets/download_button.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa/router/router.dart';
import 'package:tilawa_core/entities/audio.dart';

import '../reciter_semantics_ids.dart';

class SurahListTile extends StatelessWidget {
  const SurahListTile({
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Subtle left accent for currently playing
        border: isCurrentItem
            ? Border(left: BorderSide(color: theme.primaryColor, width: 3))
            : null,
      ),
      child: Material(
        color: isCurrentItem
            ? theme.primaryColor.withValues(alpha: 0.06)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: () => _showSurahOptionsSheet(context, surah),
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Number badge with consistent background
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrentItem
                        ? theme.primaryColor
                        : theme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isCurrentItem
                        ? [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isCurrentItem
                      ? Icon(
                          Icons.graphic_eq_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : Text(
                          surah.formattedId.isNotEmpty
                              ? surah.formattedId
                              : '${index + 1}',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surah.name,
                        style: TextStyle(
                          fontSize: 15,
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
                        surah.reciterName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DownloadButton(
                      url: surah.id,
                      surahTitle: surah.name,
                      reciterName: reciterName,
                      reciterId: reciterId,
                      initialIsDownloaded: surah.isDownloaded,
                      initialIsDownloading: surah.isDownloading,
                      initialProgress: surah.downloadProgress,
                      identifier: ReciterSemanticsIds.surahDownloadButton(
                        surah.formattedId.isNotEmpty
                            ? surah.formattedId
                            : '${index + 1}',
                      ),
                    ),
                    SizedBox(width: 10),
                    // Play/Pause button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrentItem
                            ? theme.primaryColor
                            : theme.primaryColor.withValues(alpha: 0.08),
                        boxShadow: isCurrentItem
                            ? [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isCurrentItem && isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: isCurrentItem
                            ? Colors.white
                            : theme.primaryColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSurahOptionsSheet(BuildContext context, SurahEntity surah) {
    final ThemeData theme = Theme.of(context);
    // Extract surah number from formatted ID or use index
    final int surahNumber = int.tryParse(surah.formattedId) ?? (index + 1);

    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              surah.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Divider(height: 1, color: theme.dividerColor),
            ListTile(
              leading: Icon(Icons.menu_book_rounded, color: theme.primaryColor),
              title: Text(context.l10n.quranReader),
              subtitle: Text(context.l10n.continueReading),
              onTap: () {
                Navigator.pop(sheetContext);
                QuranReaderRoute(surahNumber: surahNumber).push(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.bookmark_outline_rounded,
                color: theme.primaryColor,
              ),
              title: Text(context.l10n.addBookmark),
              onTap: () {
                Navigator.pop(sheetContext);
                const BookmarksRoute().push(context);
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class SkeletonSurahListTile extends StatelessWidget {
  const SkeletonSurahListTile({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
