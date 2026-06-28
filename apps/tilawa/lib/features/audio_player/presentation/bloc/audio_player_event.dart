part of 'audio_player_bloc.dart';

@freezed
sealed class AudioPlayerEvent with _$AudioPlayerEvent {
  const factory AudioPlayerEvent.resetAudioPlayer() = ResetAudioPlayer;
  const factory AudioPlayerEvent.syncActivePlayback() = SyncActivePlayback;
  const factory AudioPlayerEvent.syncActivePlaybackTrailing() =
      SyncActivePlaybackTrailing;
  const factory AudioPlayerEvent.requestPlaybackReconciliation() =
      RequestPlaybackReconciliation;
  const factory AudioPlayerEvent.updateAudio(AudioEntity? audio) = UpdateAudio;
  const factory AudioPlayerEvent.updatePlaybackStateEntity(
    PlaybackStateEntity playbackState,
  ) = UpdatePlaybackStateEntity;
  const factory AudioPlayerEvent.updatePositionData(PositionData positionData) =
      UpdatePositionData;
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
  const factory AudioPlayerEvent.playFromQueue(
    List<AudioEntity> queue,
    int index, {
    Duration? initialPosition,
  }) = PlayFromQueue;
  const factory AudioPlayerEvent.updateQueue(List<AudioEntity> queue) =
      UpdateQueue;
  const factory AudioPlayerEvent.addQueueItem(AudioEntity audio) = AddQueueItem;
  const factory AudioPlayerEvent.removeQueueItem(AudioEntity audio) =
      RemoveQueueItem;
  const factory AudioPlayerEvent.moveQueueItem(int currentIndex, int newIndex) =
      MoveQueueItem;
  const factory AudioPlayerEvent.setRepeatMode(AudioRepeatMode repeatMode) =
      SetRepeatMode;
  const factory AudioPlayerEvent.setShuffleMode(AudioShuffleMode shuffleMode) =
      SetShuffleMode;
  const factory AudioPlayerEvent.setSleepTimer(
    Duration duration, {
    @Default(SleepTimerType.preset) SleepTimerType type,
  }) = SetSleepTimer;
  const factory AudioPlayerEvent.cancelSleepTimer({
    @Default(true) bool clearPreference,
  }) = CancelSleepTimer;
  const factory AudioPlayerEvent.audioTimerExpired() = AudioTimerExpired;
}
