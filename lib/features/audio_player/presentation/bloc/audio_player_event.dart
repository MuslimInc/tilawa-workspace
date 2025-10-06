part of 'audio_player_bloc.dart';

@freezed
sealed class AudioPlayerEvent with _$AudioPlayerEvent {
  const factory AudioPlayerEvent.loadAudioPlayerData() = LoadAudioPlayerData;
  const factory AudioPlayerEvent.updateMediaItem(MediaItem? mediaItem) =
      UpdateMediaItem;
  const factory AudioPlayerEvent.updatePlaybackState(
    PlaybackState playbackState,
  ) = UpdatePlaybackState;
  const factory AudioPlayerEvent.updatePositionData(PositionData positionData) =
      UpdatePositionData;
  const factory AudioPlayerEvent.updateQueueState(QueueState queueState) =
      UpdateQueueState;
  const factory AudioPlayerEvent.updateVolume(double volume) = UpdateVolume;
  const factory AudioPlayerEvent.updateSpeed(double speed) = UpdateSpeed;

  // Audio control events
  const factory AudioPlayerEvent.playAudio() = PlayAudio;
  const factory AudioPlayerEvent.pauseAudio() = PauseAudio;
  const factory AudioPlayerEvent.stopAudio() = StopAudio;
  const factory AudioPlayerEvent.skipToNext() = SkipToNext;
  const factory AudioPlayerEvent.skipToPrevious() = SkipToPrevious;
  const factory AudioPlayerEvent.seekTo(Duration position) = SeekTo;
  const factory AudioPlayerEvent.setVolume(double volume) = SetVolume;
  const factory AudioPlayerEvent.setSpeed(double speed) = SetSpeed;
  const factory AudioPlayerEvent.skipToQueueItem(int index) = SkipToQueueItem;
  const factory AudioPlayerEvent.updateQueue(List<MediaItem> queue) =
      UpdateQueue;
  const factory AudioPlayerEvent.addQueueItem(MediaItem item) = AddQueueItem;
  const factory AudioPlayerEvent.removeQueueItem(MediaItem item) =
      RemoveQueueItem;
  const factory AudioPlayerEvent.moveQueueItem(int currentIndex, int newIndex) =
      MoveQueueItem;
  const factory AudioPlayerEvent.setRepeatMode(
    AudioServiceRepeatMode repeatMode,
  ) = SetRepeatMode;
  const factory AudioPlayerEvent.setShuffleMode(
    AudioServiceShuffleMode shuffleMode,
  ) = SetShuffleMode;
}
