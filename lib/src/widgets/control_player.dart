import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:muzakri/player/play_page.dart';

class ControlButtons extends StatelessWidget {
  final AudioPlayerHandler audioHandler;
  final bool shuffle;
  final bool miniplayer;

  const ControlButtons(
    this.audioHandler, {
    this.shuffle = false,
    this.miniplayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<QueueState>(
          stream: audioHandler.queueState,
          builder: (context, snapshot) {
            final queueState = snapshot.data ?? QueueState.empty;
            return IconButton(
              icon: const Icon(Icons.skip_previous_rounded),
              iconSize: miniplayer ? 24.0 : 45.0,
              tooltip: 'Skip Previous',
              onPressed: queueState.hasPrevious
                  ? audioHandler.skipToPrevious
                  : null,
            );
          },
        ),
        SizedBox(
          height: miniplayer ? 40.0 : 65.0,
          width: miniplayer ? 40.0 : 65.0,
          child: StreamBuilder<PlaybackState>(
            stream: audioHandler.playbackState,
            builder: (context, snapshot) {
              final playbackState = snapshot.data;
              final processingState = playbackState?.processingState;
              final playing = playbackState?.playing ?? false;
              return Stack(
                children: [
                  if (processingState == AudioProcessingState.loading ||
                      processingState == AudioProcessingState.buffering)
                    Center(
                      child: SizedBox(
                        height: miniplayer ? 40.0 : 65.0,
                        width: miniplayer ? 40.0 : 65.0,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  if (miniplayer)
                    Center(
                      child: playing
                          ? IconButton(
                              tooltip: 'Pause',
                              onPressed: audioHandler.pause,
                              icon: const Icon(Icons.pause_rounded),
                            )
                          : IconButton(
                              tooltip: 'Play',
                              onPressed: audioHandler.play,
                              icon: const Icon(Icons.play_arrow_rounded),
                            ),
                    )
                  else
                    Center(
                      child: SizedBox(
                        height: 59,
                        width: 59,
                        child: Center(
                          child: playing
                              ? FloatingActionButton(
                                  elevation: 10,
                                  tooltip: 'Pause',
                                  onPressed: audioHandler.pause,
                                  child: const Icon(
                                    Icons.pause_rounded,
                                    size: 40.0,
                                    color: Colors.white,
                                  ),
                                )
                              : FloatingActionButton(
                                  elevation: 10,
                                  tooltip: 'Play',
                                  onPressed: audioHandler.play,
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 40.0,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        StreamBuilder<QueueState>(
          stream: audioHandler.queueState,
          builder: (context, snapshot) {
            final queueState = snapshot.data ?? QueueState.empty;
            return IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              iconSize: miniplayer ? 24.0 : 45.0,
              tooltip: 'Skip Next',
              onPressed: queueState.hasNext ? audioHandler.skipToNext : null,
            );
          },
        ),
      ],
    );
  }
}
