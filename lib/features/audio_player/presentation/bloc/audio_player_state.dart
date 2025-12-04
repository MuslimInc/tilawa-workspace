part of 'audio_player_bloc.dart';

enum AudioPlayerStatus { initial, success }

@freezed
abstract class AudioPlayerState with _$AudioPlayerState {
  const factory AudioPlayerState({
    MediaItem? mediaItem,
    PlaybackState? playbackState,
    PositionData? positionData,
    QueueState? queueState,
    @Default(1.0) double volume,
    @Default(1.0) double speed,
    required AudioPlayerStatus status,
  }) = _AudioPlayerState;

  const AudioPlayerState._();

  bool get isPlaying => playbackState?.playing ?? false;
  bool get canGoNext => queueState?.hasNext ?? false;
  bool get canGoPrevious => queueState?.hasPrevious ?? false;
  bool get hasMediaItem => mediaItem != null;
}
