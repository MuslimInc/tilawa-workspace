import 'package:flutter/material.dart';

import '../../features/audio_player/domain/entities/audio_modes.dart';
import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'quran_player_queue_utils.dart';

/// Repeat/shuffle visuals and toggles for the expanded player transport row.
abstract final class QuranPlayerTransportControls {
  static IconData repeatIcon(AudioRepeatMode mode) => switch (mode) {
    AudioRepeatMode.one => Icons.repeat_one,
    AudioRepeatMode.all => Icons.repeat_on,
    AudioRepeatMode.none => Icons.repeat_outlined,
  };

  static bool repeatActive(AudioRepeatMode mode) =>
      mode != AudioRepeatMode.none;

  /// Same glyph for on/off; [shuffleActive] drives color. Avoids
  /// `Icons.shuffle_on`, which can render as a missing-glyph box on some
  /// devices when the Material icon font subset is incomplete.
  static IconData shuffleIcon(AudioShuffleMode mode) => Icons.shuffle;

  static bool shuffleActive(AudioShuffleMode mode) =>
      mode == AudioShuffleMode.all;

  static AudioRepeatMode nextRepeatMode(AudioRepeatMode mode) => switch (mode) {
    AudioRepeatMode.none => AudioRepeatMode.all,
    AudioRepeatMode.all => AudioRepeatMode.one,
    AudioRepeatMode.one => AudioRepeatMode.none,
  };

  static AudioShuffleMode nextShuffleMode(AudioShuffleMode mode) =>
      shuffleActive(mode) ? AudioShuffleMode.none : AudioShuffleMode.all;

  /// Whether the play queue order or active index changed.
  static bool playerTreeQueueChanged(
    AudioPlayerState previous,
    AudioPlayerState current,
  ) => QuranPlayerQueueUtils.playerTreeQueueChanged(previous, current);

  /// Whether the expanded player tree should rebuild for [current].
  static bool playerTreeBuildWhen(
    AudioPlayerState previous,
    AudioPlayerState current,
  ) =>
      previous.currentAudio != current.currentAudio ||
      previous.shouldShowBottomPlayer != current.shouldShowBottomPlayer ||
      previous.isPlaying != current.isPlaying ||
      previous.canGoPrevious != current.canGoPrevious ||
      previous.canGoNext != current.canGoNext ||
      previous.isSleepTimerActive != current.isSleepTimerActive ||
      previous.volume != current.volume ||
      previous.speed != current.speed ||
      previous.repeatMode != current.repeatMode ||
      previous.shuffleMode != current.shuffleMode ||
      previous.dismissedAudioId != current.dismissedAudioId ||
      playerTreeQueueChanged(previous, current);
  // [positionData] and non-queue [playbackState] fields are excluded so
  // expand/collapse animations are not interrupted by per-tick progress.
}
