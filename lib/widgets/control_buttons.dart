import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/bloc/audio_player/audio_player_bloc.dart';
import 'package:muzakri/helpers/show_slider_dialog.dart';
import 'package:muzakri/queue_state.dart';

class ControlButtons extends StatelessWidget {
  const ControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
          builder: (context, state) {
            final volume = state.status == AudioPlayerStatus.success
                ? state.volume
                : 1.0;
            return IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () {
                showSliderDialog(
                  context: context,
                  title: "Adjust volume",
                  divisions: 10,
                  min: 0.0,
                  max: 1.0,
                  value: volume,
                  onChanged: (newVolume) {
                    context.read<AudioPlayerBloc>().add(
                      AudioPlayerEvent.setVolume(newVolume),
                    );
                  },
                );
              },
            );
          },
        ),
        BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
          builder: (context, state) {
            if (state.status != AudioPlayerStatus.success) {
              return IconButton(
                icon: const Icon(FluentIcons.arrow_left_24_regular),
                onPressed: null,
              );
            }

            final queueState = state.queueState ?? QueueState.empty;
            return IconButton(
              icon: Icon(FluentIcons.arrow_left_24_regular),
              onPressed: () {
                if (queueState.hasPrevious) {
                  context.read<AudioPlayerBloc>().add(SkipToPrevious());
                }
              },
            );
          },
        ),
        BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
          builder: (context, state) {
            if (state.status != AudioPlayerStatus.success) {
              return IconButton(
                icon: const Icon(FluentIcons.play_24_regular),
                iconSize: 64.0,
                onPressed: () {
                  context.read<AudioPlayerBloc>().add(
                    AudioPlayerEvent.playAudio(),
                  );
                },
              );
            }

            final playbackState = state.playbackState;
            final processingState = playbackState?.processingState;
            final playing = playbackState?.playing;
            if (processingState == AudioProcessingState.loading ||
                processingState == AudioProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(FluentIcons.play_24_regular),
                iconSize: 64.0,
                onPressed: () {
                  context.read<AudioPlayerBloc>().add(
                    AudioPlayerEvent.playAudio(),
                  );
                },
              );
            } else {
              return IconButton(
                icon: const Icon(FluentIcons.pause_24_regular),
                iconSize: 64.0,
                onPressed: () {
                  context.read<AudioPlayerBloc>().add(
                    AudioPlayerEvent.pauseAudio(),
                  );
                },
              );
            }
          },
        ),
        BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
          builder: (context, state) {
            if (state.status != AudioPlayerStatus.success) {
              return IconButton(
                icon: const Icon(FluentIcons.arrow_right_24_regular),
                onPressed: null,
              );
            }

            final queueState = state.queueState ?? QueueState.empty;
            return IconButton(
              icon: const Icon(FluentIcons.arrow_right_24_regular),
              onPressed: queueState.hasNext
                  ? () {
                      context.read<AudioPlayerBloc>().add(SkipToNext());
                    }
                  : null,
            );
          },
        ),
        BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
          builder: (context, state) {
            final speed = state.status == AudioPlayerStatus.success
                ? state.speed
                : 1.0;
            return IconButton(
              icon: Text(
                "${speed.toStringAsFixed(1)}x",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                showSliderDialog(
                  context: context,
                  title: "Adjust speed",
                  divisions: 10,
                  min: 0.5,
                  max: 1.5,
                  value: speed,
                  onChanged: (newSpeed) {
                    context.read<AudioPlayerBloc>().add(
                      AudioPlayerEvent.setSpeed(newSpeed),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
