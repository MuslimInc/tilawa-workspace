part of 'audio_player_bloc.dart';

enum AudioPlayerStatus { initial, loading, success }

enum SleepTimerType { preset, endOfTrack, custom }

@freezed
abstract class AudioPlayerState with _$AudioPlayerState {
  @JsonSerializable(explicitToJson: true)
  const factory AudioPlayerState({
    required AudioPlayerStatus status,
    AudioEntity? currentAudio,
    PlaybackStateEntity? playbackState,
    PositionData? positionData,
    @Default(1.0) double volume,
    @Default(1.0) double speed,
    @Default(AudioRepeatMode.none) AudioRepeatMode repeatMode,
    @Default(AudioShuffleMode.none) AudioShuffleMode shuffleMode,
    DateTime? sleepTimerTargetTime,
    Duration? lastSleepTimerDuration,
    SleepTimerType? lastSleepTimerType,
    String? dismissedAudioId,
    @JsonKey(includeFromJson: false, includeToJson: false) Failure? failure,
  }) = _AudioPlayerState;

  factory AudioPlayerState.fromJson(Map<String, dynamic> json) =>
      _$AudioPlayerStateFromJson(json);

  const AudioPlayerState._();

  QueueState get queueState => QueueState(
    queue: playbackState?.queue ?? [],
    queueIndex: playbackState?.currentIndex,
    shuffleIndices: null,
    repeatMode: repeatMode,
  );

  bool get isPlaying => playbackState?.isPlaying ?? false;
  bool get canGoNext => queueState.hasNext;
  bool get canGoPrevious => queueState.hasPrevious;
  bool get hasMediaItem => currentAudio != null;
  AudioEntity? get mediaItem => currentAudio;
  bool get hasAudio => currentAudio != null;
  bool get isSleepTimerActive => sleepTimerTargetTime != null;

  bool get shouldShowBottomPlayer =>
      currentAudio != null &&
      status == AudioPlayerStatus.success &&
      dismissedAudioId != currentAudio?.id;
}
