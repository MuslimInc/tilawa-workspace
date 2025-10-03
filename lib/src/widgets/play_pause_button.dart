import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PlayPauseButton extends StatefulWidget {
  const PlayPauseButton({required this.playerState, required this.audioPlayer});
  final PlayerState? playerState;
  final AudioPlayer audioPlayer;

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> {
  Icon playIcon = const Icon(Icons.play_arrow, color: Colors.white, size: 40);

  Icon pauseIcon = const Icon(Icons.pause, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    final processingState = widget.playerState!.processingState;
    // print('auidoState: $processingState endState');
    // print('audioFile: ${widget.audioPlayer.hasPrevious} endState');
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      return IconButton(icon: playIcon, iconSize: 64.0, onPressed: () {});
    } else if (widget.audioPlayer.playing != true) {
      return IconButton(
        icon: playIcon,
        iconSize: 64.0,
        onPressed: widget.audioPlayer.play,
      );
    } else if (processingState != ProcessingState.completed) {
      return IconButton(
        icon: pauseIcon,
        iconSize: 64.0,
        onPressed: widget.audioPlayer.pause,
      );
    } else if (processingState == ProcessingState.completed) {
      return TextButton(
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: const Color(0xFF323777),
          padding: const EdgeInsets.all(20),
        ),
        child: playIcon,
        onPressed: () => widget.audioPlayer.seek(
          Duration.zero,
          index: widget.audioPlayer.effectiveIndices.first,
        ),
      );
    } else {
      return IconButton(
        icon: playIcon,
        iconSize: 64.0,
        onPressed: () => widget.audioPlayer.seek(
          Duration.zero,
          index: widget.audioPlayer.effectiveIndices.first,
        ),
      );
    }
  }
}

// class PlayerButtons extends StatelessWidget {
//   const PlayerButtons({required this.audioPlayer});

//   final AudioPlayer audioPlayer;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // StreamBuilder<bool>(
//         //   stream: audioPlayer.shuffleModeEnabledStream,
//         //   builder: (context, snapshot) {
//         //     return _shuffleButton(context, snapshot.data ?? false);
//         //   },
//         // ),
//         // StreamBuilder<SequenceState?>(
//         //   stream: audioPlayer.sequenceStateStream,
//         //   builder: (_, __) {
//         //     return _previousButton();
//         //   },
//         // ),

//         StreamBuilder<PlayerState>(
//           stream: audioPlayer.playerStateStream,
//           builder: (_, snapshot) {
//             final playerState = snapshot.data;
//             return _playPauseButton(playerState!);
//           },
//         ),

//         // StreamBuilder<SequenceState?>(
//         //   stream: audioPlayer.sequenceStateStream,
//         //   builder: (_, __) {
//         //     return _nextButton();
//         //   },
//         // ),
//         // StreamBuilder<LoopMode>(
//         //   stream: audioPlayer.loopModeStream,
//         //   builder: (context, snapshot) {
//         //     return _repeatButton(context, snapshot.data ?? LoopMode.off);
//         //   },
//         // ),
//       ],
//     );
//   }

//   Widget _playPauseButton(PlayerState playerState) {
//     final processingState = playerState.processingState;
//     if (processingState == ProcessingState.loading ||
//         processingState == ProcessingState.buffering) {
//       return Container(
//         margin: EdgeInsets.all(8.0),
//         width: 64.0,
//         height: 64.0,
//         child: CircularProgressIndicator(),
//       );
//     } else if (audioPlayer.playing != true) {
//       return IconButton(
//         icon: Icon(Icons.play_arrow),
//         iconSize: 64.0,
//         onPressed: audioPlayer.play,
//       );
//     } else if (processingState != ProcessingState.completed) {
//       return IconButton(
//         icon: Icon(Icons.pause),
//         iconSize: 64.0,
//         onPressed: audioPlayer.pause,
//       );
//     } else {
//       return IconButton(
//         icon: Icon(Icons.replay),
//         iconSize: 64.0,
//         onPressed: () => audioPlayer.seek(Duration.zero,
//             index: audioPlayer.effectiveIndices!.first),
//       );
//     }
//   }

//   Widget _shuffleButton(BuildContext context, bool isEnabled) {
//     return IconButton(
//       icon: isEnabled
//           ? Icon(Icons.shuffle, color: Theme.of(context).accentColor)
//           : Icon(Icons.shuffle),
//       onPressed: () async {
//         final enable = !isEnabled;
//         if (enable) {
//           await audioPlayer.shuffle();
//         }
//         await audioPlayer.setShuffleModeEnabled(enable);
//       },
//     );
//   }

//   Widget _previousButton() {
//     return IconButton(
//       icon: Icon(Icons.skip_previous),
//       onPressed: audioPlayer.hasPrevious ? audioPlayer.seekToPrevious : null,
//     );
//   }

//   Widget _nextButton() {
//     return IconButton(
//       icon: Icon(Icons.skip_next),
//       onPressed: audioPlayer.hasNext ? audioPlayer.seekToNext : null,
//     );
//   }

//   Widget _repeatButton(BuildContext context, LoopMode loopMode) {
//     final icons = [
//       Icon(Icons.repeat),
//       Icon(Icons.repeat, color: Theme.of(context).accentColor),
//       Icon(Icons.repeat_one, color: Theme.of(context).accentColor),
//     ];
//     const cycleModes = [
//       LoopMode.off,
//       LoopMode.all,
//       LoopMode.one,
//     ];
//     final index = cycleModes.indexOf(loopMode);
//     return IconButton(
//       icon: icons[index],
//       onPressed: () {
//         audioPlayer.setLoopMode(
//             cycleModes[(cycleModes.indexOf(loopMode) + 1) % cycleModes.length]);
//       },
//     );
//   }
// }
