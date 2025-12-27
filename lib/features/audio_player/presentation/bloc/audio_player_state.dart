part of 'audio_player_bloc.dart';

enum AudioPlayerStatus { initial, loading, success }

@freezed
abstract class AudioPlayerState with _$AudioPlayerState {
  const factory AudioPlayerState({
    AudioEntity? currentAudio,
    PlaybackStateEntity? playbackState,
    PositionData? positionData,
    @Default(1.0) double volume,
    @Default(1.0) double speed,
    @Default(AudioRepeatMode.none) AudioRepeatMode repeatMode,
    @Default(AudioShuffleMode.none) AudioShuffleMode shuffleMode,
    DateTime? sleepTimerTargetTime,
    required AudioPlayerStatus status,
  }) = _AudioPlayerState;

  const AudioPlayerState._();

  QueueState get queueState => QueueState(
    queue: playbackState?.queue ?? [],
    queueIndex: playbackState?.currentIndex,
    shuffleIndices: null, // Not yet implemented in PlaybackStateEntity
    repeatMode: repeatMode,
  );

  bool get isPlaying => playbackState?.isPlaying ?? false;
  bool get canGoNext => queueState.hasNext;
  bool get canGoPrevious => queueState.hasPrevious;
  bool get hasMediaItem => currentAudio != null;
  AudioEntity? get mediaItem => currentAudio;
  bool get hasAudio => currentAudio != null;
  bool get isSleepTimerActive => sleepTimerTargetTime != null;
}
