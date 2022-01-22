// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';

// // class PageManager {
// //   final progressNotifier = ValueNotifier<ProgressBarState>(
// //     ProgressBarState(
// //       current: Duration.zero,
// //       buffered: Duration.zero,
// //       total: Duration.zero,
// //     ),
// //   );
// //   final buttonNotifier = ValueNotifier<ButtonState>(ButtonState.isPaused);

// //   late AudioPlayer _audioPlayer;
// //   static const url =
// //       "https://server14.mp3quran.net/swlim/Rewayat-Hafs-A-n-Assem/001.mp3";

// //   PageManager() {
// //     _init();
// //   }

// //   void _init() async {
// //     try {
// //       // initialize the song
// //       _audioPlayer = AudioPlayer();
// //       await _audioPlayer.setUrl(url);

// //       // listen for changes in player state
// //       _audioPlayer.playerStateStream.listen((playerState) {
// //         final isPlaying = playerState.playing;
// //         final processingState = playerState.processingState;
// //         if (processingState == ProcessingState.loading ||
// //             processingState == ProcessingState.buffering) {
// //           buttonNotifier.value = ButtonState.isLoading;
// //         } else if (!isPlaying) {
// //           buttonNotifier.value = ButtonState.isPaused;
// //         } else if (processingState != ProcessingState.completed) {
// //           buttonNotifier.value = ButtonState.isPlaying;
// //         } else {
// //           _audioPlayer.seek(Duration.zero);
// //           _audioPlayer.pause();
// //         }
// //       });

// //       // listen for changes in play position
// //       _audioPlayer.positionStream.listen((position) {
// //         final oldState = progressNotifier.value;
// //         progressNotifier.value = ProgressBarState(
// //           current: position,
// //           buffered: oldState.buffered,
// //           total: oldState.total,
// //         );
// //       });

// //       // listen for changes in the buffered position
// //       _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
// //         final oldState = progressNotifier.value;
// //         progressNotifier.value = ProgressBarState(
// //           current: oldState.current,
// //           buffered: bufferedPosition,
// //           total: oldState.total,
// //         );
// //       });

// //       // listen for changes in the total audio duration
// //       _audioPlayer.durationStream.listen((totalDuration) {
// //         final oldState = progressNotifier.value;
// //         progressNotifier.value = ProgressBarState(
// //           current: oldState.current,
// //           buffered: oldState.buffered,
// //           total: totalDuration ?? Duration.zero,
// //         );
// //       });
// //     } catch (e) {
// //       print('I eeerroro: $e');
// //     }
// //   }

// //   void play() async {
// //     _audioPlayer.play();
// //   }

// //   void pause() {
// //     _audioPlayer.pause();
// //   }

// //   void seek(Duration position) {
// //     _audioPlayer.seek(position);
// //   }

// //   void dispose() {
// //     _audioPlayer.dispose();
// //   }
// // }

// class PageManager extends ChangeNotifier {
//   final String? urll;
//   final progressNotifier = ValueNotifier<ProgressBarState>(
//     ProgressBarState(
//       current: Duration.zero,
//       buffered: Duration.zero,
//       total: Duration.zero,
//     ),
//   );
//   final buttonNotifier = ValueNotifier<ButtonState>(ButtonState.isPaused);

//   late AudioPlayer _audioPlayer;
//   // static const url =
//   //     "https://server14.mp3quran.net/swlim/Rewayat-Hafs-A-n-Assem/001.mp3";

//   PageManager({this.urll}) {
//     _init(url: urll ?? '');
//   }

//   void _init({required String url}) async {
//     try {
//       // initialize the song
//       _audioPlayer = AudioPlayer();
//       await _audioPlayer.setUrl(url);

//       // listen for changes in player state
//       _audioPlayer.playerStateStream.listen((playerState) {
//         final isPlaying = playerState.playing;
//         final processingState = playerState.processingState;
//         if (processingState == ProcessingState.loading ||
//             processingState == ProcessingState.buffering) {
//           buttonNotifier.value = ButtonState.isLoading;
//         } else if (!isPlaying) {
//           buttonNotifier.value = ButtonState.isPaused;
//         } else if (processingState != ProcessingState.completed) {
//           buttonNotifier.value = ButtonState.isPlaying;
//         } else {
//           _audioPlayer.seek(Duration.zero);
//           _audioPlayer.pause();
//         }
//       });

//       // listen for changes in play position
//       _audioPlayer.positionStream.listen((position) {
//         final oldState = progressNotifier.value;
//         progressNotifier.value = ProgressBarState(
//           current: position,
//           buffered: oldState.buffered,
//           total: oldState.total,
//         );
//       });

//       // listen for changes in the buffered position
//       _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
//         final oldState = progressNotifier.value;
//         progressNotifier.value = ProgressBarState(
//           current: oldState.current,
//           buffered: bufferedPosition,
//           total: oldState.total,
//         );
//       });

//       // listen for changes in the total audio duration
//       _audioPlayer.durationStream.listen((totalDuration) {
//         final oldState = progressNotifier.value;
//         progressNotifier.value = ProgressBarState(
//           current: oldState.current,
//           buffered: oldState.buffered,
//           total: totalDuration ?? Duration.zero,
//         );
//       });
//     } catch (e) {
//       print('I eeerroro: $e');
//     }
//     notifyListeners();
//   }

//   void play() async {
//     _audioPlayer.play();
//     notifyListeners();
//   }

//   void pause() {
//     _audioPlayer.pause();
//     notifyListeners();
//   }

//   void seek(Duration position) {
//     _audioPlayer.seek(position);
//     notifyListeners();
//   }

//   // void dispose() {
//   //   _audioPlayer.dispose();
//   //   notifyListeners();
//   // }

// }

// // class ProgressBarState {
// //   ProgressBarState({
// //     required this.current,
// //     required this.buffered,
// //     required this.total,
// //   });
// //   final Duration current;
// //   final Duration buffered;
// //   final Duration total;
// // }

// enum ButtonState { isPaused, isPlaying, isLoading }
