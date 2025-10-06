import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/helpers/reciter_helper.dart';
import 'package:muzakri/position_data.dart';
import 'package:muzakri/screens/reciter_details_screen.dart';

class BottomPlayer extends StatefulWidget {
  final VoidCallback? onTap;

  const BottomPlayer({super.key, this.onTap});

  @override
  State<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends State<BottomPlayer> {
  @override
  void initState() {
    super.initState();

    // Initialize the AudioPlayerBloc
    context.read<AudioPlayerBloc>().add(
      const AudioPlayerEvent.loadAudioPlayerData(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        final mediaItem = state.mediaItem;
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }
        if (state.status != AudioPlayerStatus.success) {
          return const SizedBox.shrink();
        }

        final positionData = state.positionData;

        final isPlaying = state.isPlaying;
        final position =
            positionData ??
            PositionData(
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              duration: Duration.zero,
            );

        // Check if next/previous buttons should be enabled
        final canGoNext = state.canGoNext;
        final canGoPrevious = state.canGoPrevious;

        return Hero(
          tag: 'audio_player',
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: widget.onTap,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8.h,
                    children: [
                      // View Reciter button
                      if (ReciterHelper.hasReciterInfo(mediaItem))
                        ViewReciterButton(mediaItem: mediaItem),

                      // Progress bar - Real time
                      Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: position.duration.inMilliseconds > 0
                                ? position.position.inMilliseconds /
                                      position.duration.inMilliseconds
                                : 0.0,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),

                      // Main controls
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 1,
                        ),
                        child: Row(
                          children: [
                            // Album art or icon
                            Container(
                              width: 48.w,
                              height: 48.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1),
                              ),
                              child: mediaItem.artUri != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        mediaItem.artUri.toString(),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Icon(
                                                Icons.music_note,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                size: 22,
                                              );
                                            },
                                      ),
                                    )
                                  : Icon(
                                      Icons.music_note,
                                      color: Theme.of(context).primaryColor,
                                      size: 22,
                                    ),
                            ),

                            const SizedBox(width: 8),

                            // Song info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    mediaItem.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // const SizedBox(height: 1),
                                  // Text(
                                  //   mediaItem.artist ??
                                  //       mediaItem.album ??
                                  //       'Unknown',
                                  //   style: Theme.of(context).textTheme.bodySmall
                                  //       ?.copyWith(color: Colors.black),
                                  //   maxLines: 1,
                                  //   overflow: TextOverflow.ellipsis,
                                  // ),
                                ],
                              ),
                            ),

                            // Previous button
                            IconButton(
                              icon: const Icon(
                                FluentIcons.arrow_left_24_regular,
                                size: 18,
                              ),
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              onPressed: canGoPrevious
                                  ? () => context.read<AudioPlayerBloc>().add(
                                      const AudioPlayerEvent.skipToPrevious(),
                                    )
                                  : null,
                            ),

                            // Play/Pause button
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? FluentIcons.pause_24_regular
                                      : FluentIcons.play_24_regular,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                  minWidth: 34,
                                  minHeight: 34,
                                ),
                                onPressed: () {
                                  if (isPlaying) {
                                    context.read<AudioPlayerBloc>().add(
                                      const AudioPlayerEvent.pauseAudio(),
                                    );
                                  } else {
                                    context.read<AudioPlayerBloc>().add(
                                      const AudioPlayerEvent.playAudio(),
                                    );
                                  }
                                },
                              ),
                            ),

                            // Next button
                            IconButton(
                              icon: const Icon(
                                FluentIcons.arrow_right_24_regular,
                                size: 18,
                              ),
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              onPressed: canGoNext
                                  ? () => context.read<AudioPlayerBloc>().add(
                                      const AudioPlayerEvent.skipToNext(),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ViewReciterButton extends StatelessWidget {
  const ViewReciterButton({super.key, required this.mediaItem});
  final MediaItem mediaItem;

  @override
  Widget build(BuildContext context) {
    Future<void> navigateToReciterDetails(
      BuildContext context,
      MediaItem mediaItem,
    ) async {
      try {
        final reciter = await ReciterHelper.getReciterFromMediaItem(mediaItem);
        if (reciter != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReciterDetailsScreen(reciter: reciter),
            ),
          );
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reciter information not available'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading reciter: ${e.toString()}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(start: 12),
      child: TextButton.icon(
        icon: const Icon(FluentIcons.person_24_regular, size: 18),
        label: Text('${mediaItem.artist}'),
        onPressed: () => navigateToReciterDetails(context, mediaItem),
      ),
    );
  }
}
