import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/downloads/presentation/widgets/download_button.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa/router/router.dart';
import 'package:tilawa_core/entities/audio.dart';

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
        borderRadius: BorderRadius.circular(16.r),
        // Subtle left accent for currently playing
        border: isCurrentItem
            ? Border(
                left: BorderSide(color: theme.primaryColor, width: 3.w),
              )
            : null,
      ),
      child: Material(
        color: isCurrentItem
            ? theme.primaryColor.withValues(alpha: 0.06)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                // Number badge with consistent background
                Container(
                  width: 38.w,
                  height: 38.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrentItem
                        ? theme.primaryColor
                        : theme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
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
                          size: 18.sp,
                        )
                      : Text(
                          surah.formattedId.isNotEmpty
                              ? surah.formattedId
                              : '${index + 1}',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                          ),
                        ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surah.name,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isCurrentItem
                              ? theme.primaryColor
                              : theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        surah.reciterName,
                        style: TextStyle(
                          fontSize: 12.sp,
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
                    ),
                    SizedBox(width: 10.w),
                    // Play/Pause button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40.w,
                      height: 40.w,
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
                        size: 22.sp,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              surah.name,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
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
            SizedBox(height: 16.h),
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
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 80.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
