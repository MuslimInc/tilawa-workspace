import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/position_data.dart';
import 'package:muzakri/shared/widgets/control_buttons.dart';
import 'package:muzakri/shared/widgets/seek_bar.dart';

class ExpandedPlayerScreen extends StatelessWidget {
  const ExpandedPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FluentIcons.arrow_down_24_regular),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.currentPlaying),
        centerTitle: true,
      ),
      body: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
        builder: (context, state) {
          if (state.status != AudioPlayerStatus.success ||
              state.mediaItem == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No audio playing'),
                  const SizedBox(height: 16),
                  Text('Status: ${state.status}'),
                  Text('MediaItem: ${state.mediaItem?.title ?? "null"}'),
                ],
              ),
            );
          }

          final mediaItem = state.mediaItem!;

          return Column(
            children: [
              // Album art with Hero animation
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Hero(
                      tag: 'audio_player',
                      flightShuttleBuilder:
                          (
                            flightContext,
                            animation,
                            flightDirection,
                            fromHeroContext,
                            toHeroContext,
                          ) {
                            return Material(
                              color: Colors.transparent,
                              child: AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 + (animation.value * 0.1),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2 * animation.value,
                                            ),
                                            blurRadius: 20 * animation.value,
                                            offset: Offset(
                                              0,
                                              10 * animation.value,
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: fromHeroContext.widget,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: mediaItem.artUri != null
                                ? Image.network(
                                    mediaItem.artUri.toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.1),
                                        child: Icon(
                                          FluentIcons.music_note_1_20_regular,
                                          color: Theme.of(context).primaryColor,
                                          size: 100,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                    child: Icon(
                                      FluentIcons.music_note_1_20_regular,
                                      color: Theme.of(context).primaryColor,
                                      size: 100,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    // Song info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            mediaItem.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mediaItem.artist ?? mediaItem.album ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Progress bar with time display - matches BottomPlayer pattern
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                        builder: (context, state) {
                          if (state.status != AudioPlayerStatus.success) {
                            return const SizedBox.shrink();
                          }

                          final positionData =
                              state.positionData ??
                              PositionData(
                                position: Duration.zero,
                                bufferedPosition: Duration.zero,
                                duration: Duration.zero,
                              );

                          return Column(
                            children: [
                              // Time display - matches bottom player pattern
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(positionData.position),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withValues(alpha: 0.7),
                                          ),
                                    ),
                                    Text(
                                      _formatDuration(positionData.duration),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // SeekBar
                              SeekBar(
                                duration: positionData.duration,
                                position: positionData.position,
                                bufferedPosition: positionData.bufferedPosition,
                                onChangeEnd: (newPosition) {
                                  context.read<AudioPlayerBloc>().add(
                                    AudioPlayerEvent.seekTo(newPosition),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Controls
                    ControlButtons(),
                  ],
                ),
              ),

              // const SizedBox(height: 16),

              // Queue
              // Expanded(
              //   flex: 2,
              //   child: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
              //     builder: (context, state) {
              //       if (state.status != AudioPlayerStatus.success) {
              //         return const SizedBox.shrink();
              //       }

              //       final queueState = state.queueState ?? QueueState.empty;
              //       final queue = queueState.queue;

              //       if (queue.isEmpty) {
              //         return const Center(
              //           child: Text(
              //             'No items in queue',
              //             style: TextStyle(color: Colors.white70),
              //           ),
              //         );
              //       }

              //       return ListView.separated(
              //         itemCount: queue.length,
              //         shrinkWrap: true,
              //         separatorBuilder: (context, index) =>
              //             const SizedBox(height: 10),
              //         padding: const EdgeInsets.symmetric(horizontal: 16),
              //         itemBuilder: (context, index) {
              //           final item = queue[index];
              //           final isCurrentItem = index == queueState.queueIndex;

              //           return Container(
              //             margin: const EdgeInsets.symmetric(
              //               horizontal: 16,
              //               vertical: 4,
              //             ),
              //             decoration: BoxDecoration(
              //               color: Colors.black,
              //               borderRadius: BorderRadius.circular(8),
              //             ),
              //             child: ListTile(
              //               leading: CircleAvatar(
              //                 backgroundColor: isCurrentItem
              //                     ? Theme.of(context).primaryColor
              //                     : Colors.white.withValues(alpha: 0.2),
              //                 child: Text(
              //                   '${index + 1}',
              //                   style: TextStyle(
              //                     color: isCurrentItem
              //                         ? Colors.white
              //                         : Colors.white70,
              //                     fontWeight: FontWeight.bold,
              //                   ),
              //                 ),
              //               ),
              //               title: Text(
              //                 item.title,
              //                 style: TextStyle(
              //                   color: isCurrentItem
              //                       ? Colors.white
              //                       : Colors.white70,
              //                   fontWeight: isCurrentItem
              //                       ? FontWeight.w600
              //                       : FontWeight.normal,
              //                 ),
              //                 maxLines: 1,
              //                 overflow: TextOverflow.ellipsis,
              //               ),
              //               subtitle: Text(
              //                 item.artist ?? '',
              //                 style: const TextStyle(color: Colors.white60),
              //                 maxLines: 1,
              //                 overflow: TextOverflow.ellipsis,
              //               ),
              //               onTap: () => context.read<AudioPlayerBloc>().add(
              //                 AudioPlayerEvent.skipToQueueItem(index),
              //               ),
              //             ),
              //           );
              //         },
              //       );
              //     },
              //   ),
              // ),

              // const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }
}
