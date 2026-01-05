// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_player_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AudioPlayerEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AudioPlayerEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AudioPlayerEvent()';
  }
}

/// @nodoc
class $AudioPlayerEventCopyWith<$Res> {
  $AudioPlayerEventCopyWith(
    AudioPlayerEvent _,
    $Res Function(AudioPlayerEvent) __,
  );
}

/// Adds pattern-matching-related methods to [AudioPlayerEvent].
extension AudioPlayerEventPatterns on AudioPlayerEvent {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ResetAudioPlayer value)? resetAudioPlayer,
    TResult Function(LoadAudioPlayerData value)? loadAudioPlayerData,
    TResult Function(UpdateAudio value)? updateAudio,
    TResult Function(UpdatePlaybackStateEntity value)?
    updatePlaybackStateEntity,
    TResult Function(UpdatePositionData value)? updatePositionData,
    TResult Function(UpdateVolume value)? updateVolume,
    TResult Function(UpdateSpeed value)? updateSpeed,
    TResult Function(PlayAudio value)? playAudio,
    TResult Function(PauseAudio value)? pauseAudio,
    TResult Function(StopAudio value)? stopAudio,
    TResult Function(SkipToNext value)? skipToNext,
    TResult Function(SkipToPrevious value)? skipToPrevious,
    TResult Function(SeekTo value)? seekTo,
    TResult Function(SetVolume value)? setVolume,
    TResult Function(SetSpeed value)? setSpeed,
    TResult Function(SkipToQueueItem value)? skipToQueueItem,
    TResult Function(PlayFromQueue value)? playFromQueue,
    TResult Function(UpdateQueue value)? updateQueue,
    TResult Function(AddQueueItem value)? addQueueItem,
    TResult Function(RemoveQueueItem value)? removeQueueItem,
    TResult Function(MoveQueueItem value)? moveQueueItem,
    TResult Function(SetRepeatMode value)? setRepeatMode,
    TResult Function(SetShuffleMode value)? setShuffleMode,
    TResult Function(SetSleepTimer value)? setSleepTimer,
    TResult Function(CancelSleepTimer value)? cancelSleepTimer,
    TResult Function(AudioTimerExpired value)? audioTimerExpired,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ResetAudioPlayer() when resetAudioPlayer != null:
        return resetAudioPlayer(_that);
      case LoadAudioPlayerData() when loadAudioPlayerData != null:
        return loadAudioPlayerData(_that);
      case UpdateAudio() when updateAudio != null:
        return updateAudio(_that);
      case UpdatePlaybackStateEntity() when updatePlaybackStateEntity != null:
        return updatePlaybackStateEntity(_that);
      case UpdatePositionData() when updatePositionData != null:
        return updatePositionData(_that);
      case UpdateVolume() when updateVolume != null:
        return updateVolume(_that);
      case UpdateSpeed() when updateSpeed != null:
        return updateSpeed(_that);
      case PlayAudio() when playAudio != null:
        return playAudio(_that);
      case PauseAudio() when pauseAudio != null:
        return pauseAudio(_that);
      case StopAudio() when stopAudio != null:
        return stopAudio(_that);
      case SkipToNext() when skipToNext != null:
        return skipToNext(_that);
      case SkipToPrevious() when skipToPrevious != null:
        return skipToPrevious(_that);
      case SeekTo() when seekTo != null:
        return seekTo(_that);
      case SetVolume() when setVolume != null:
        return setVolume(_that);
      case SetSpeed() when setSpeed != null:
        return setSpeed(_that);
      case SkipToQueueItem() when skipToQueueItem != null:
        return skipToQueueItem(_that);
      case PlayFromQueue() when playFromQueue != null:
        return playFromQueue(_that);
      case UpdateQueue() when updateQueue != null:
        return updateQueue(_that);
      case AddQueueItem() when addQueueItem != null:
        return addQueueItem(_that);
      case RemoveQueueItem() when removeQueueItem != null:
        return removeQueueItem(_that);
      case MoveQueueItem() when moveQueueItem != null:
        return moveQueueItem(_that);
      case SetRepeatMode() when setRepeatMode != null:
        return setRepeatMode(_that);
      case SetShuffleMode() when setShuffleMode != null:
        return setShuffleMode(_that);
      case SetSleepTimer() when setSleepTimer != null:
        return setSleepTimer(_that);
      case CancelSleepTimer() when cancelSleepTimer != null:
        return cancelSleepTimer(_that);
      case AudioTimerExpired() when audioTimerExpired != null:
        return audioTimerExpired(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ResetAudioPlayer value) resetAudioPlayer,
    required TResult Function(LoadAudioPlayerData value) loadAudioPlayerData,
    required TResult Function(UpdateAudio value) updateAudio,
    required TResult Function(UpdatePlaybackStateEntity value)
    updatePlaybackStateEntity,
    required TResult Function(UpdatePositionData value) updatePositionData,
    required TResult Function(UpdateVolume value) updateVolume,
    required TResult Function(UpdateSpeed value) updateSpeed,
    required TResult Function(PlayAudio value) playAudio,
    required TResult Function(PauseAudio value) pauseAudio,
    required TResult Function(StopAudio value) stopAudio,
    required TResult Function(SkipToNext value) skipToNext,
    required TResult Function(SkipToPrevious value) skipToPrevious,
    required TResult Function(SeekTo value) seekTo,
    required TResult Function(SetVolume value) setVolume,
    required TResult Function(SetSpeed value) setSpeed,
    required TResult Function(SkipToQueueItem value) skipToQueueItem,
    required TResult Function(PlayFromQueue value) playFromQueue,
    required TResult Function(UpdateQueue value) updateQueue,
    required TResult Function(AddQueueItem value) addQueueItem,
    required TResult Function(RemoveQueueItem value) removeQueueItem,
    required TResult Function(MoveQueueItem value) moveQueueItem,
    required TResult Function(SetRepeatMode value) setRepeatMode,
    required TResult Function(SetShuffleMode value) setShuffleMode,
    required TResult Function(SetSleepTimer value) setSleepTimer,
    required TResult Function(CancelSleepTimer value) cancelSleepTimer,
    required TResult Function(AudioTimerExpired value) audioTimerExpired,
  }) {
    final _that = this;
    switch (_that) {
      case ResetAudioPlayer():
        return resetAudioPlayer(_that);
      case LoadAudioPlayerData():
        return loadAudioPlayerData(_that);
      case UpdateAudio():
        return updateAudio(_that);
      case UpdatePlaybackStateEntity():
        return updatePlaybackStateEntity(_that);
      case UpdatePositionData():
        return updatePositionData(_that);
      case UpdateVolume():
        return updateVolume(_that);
      case UpdateSpeed():
        return updateSpeed(_that);
      case PlayAudio():
        return playAudio(_that);
      case PauseAudio():
        return pauseAudio(_that);
      case StopAudio():
        return stopAudio(_that);
      case SkipToNext():
        return skipToNext(_that);
      case SkipToPrevious():
        return skipToPrevious(_that);
      case SeekTo():
        return seekTo(_that);
      case SetVolume():
        return setVolume(_that);
      case SetSpeed():
        return setSpeed(_that);
      case SkipToQueueItem():
        return skipToQueueItem(_that);
      case PlayFromQueue():
        return playFromQueue(_that);
      case UpdateQueue():
        return updateQueue(_that);
      case AddQueueItem():
        return addQueueItem(_that);
      case RemoveQueueItem():
        return removeQueueItem(_that);
      case MoveQueueItem():
        return moveQueueItem(_that);
      case SetRepeatMode():
        return setRepeatMode(_that);
      case SetShuffleMode():
        return setShuffleMode(_that);
      case SetSleepTimer():
        return setSleepTimer(_that);
      case CancelSleepTimer():
        return cancelSleepTimer(_that);
      case AudioTimerExpired():
        return audioTimerExpired(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ResetAudioPlayer value)? resetAudioPlayer,
    TResult? Function(LoadAudioPlayerData value)? loadAudioPlayerData,
    TResult? Function(UpdateAudio value)? updateAudio,
    TResult? Function(UpdatePlaybackStateEntity value)?
    updatePlaybackStateEntity,
    TResult? Function(UpdatePositionData value)? updatePositionData,
    TResult? Function(UpdateVolume value)? updateVolume,
    TResult? Function(UpdateSpeed value)? updateSpeed,
    TResult? Function(PlayAudio value)? playAudio,
    TResult? Function(PauseAudio value)? pauseAudio,
    TResult? Function(StopAudio value)? stopAudio,
    TResult? Function(SkipToNext value)? skipToNext,
    TResult? Function(SkipToPrevious value)? skipToPrevious,
    TResult? Function(SeekTo value)? seekTo,
    TResult? Function(SetVolume value)? setVolume,
    TResult? Function(SetSpeed value)? setSpeed,
    TResult? Function(SkipToQueueItem value)? skipToQueueItem,
    TResult? Function(PlayFromQueue value)? playFromQueue,
    TResult? Function(UpdateQueue value)? updateQueue,
    TResult? Function(AddQueueItem value)? addQueueItem,
    TResult? Function(RemoveQueueItem value)? removeQueueItem,
    TResult? Function(MoveQueueItem value)? moveQueueItem,
    TResult? Function(SetRepeatMode value)? setRepeatMode,
    TResult? Function(SetShuffleMode value)? setShuffleMode,
    TResult? Function(SetSleepTimer value)? setSleepTimer,
    TResult? Function(CancelSleepTimer value)? cancelSleepTimer,
    TResult? Function(AudioTimerExpired value)? audioTimerExpired,
  }) {
    final _that = this;
    switch (_that) {
      case ResetAudioPlayer() when resetAudioPlayer != null:
        return resetAudioPlayer(_that);
      case LoadAudioPlayerData() when loadAudioPlayerData != null:
        return loadAudioPlayerData(_that);
      case UpdateAudio() when updateAudio != null:
        return updateAudio(_that);
      case UpdatePlaybackStateEntity() when updatePlaybackStateEntity != null:
        return updatePlaybackStateEntity(_that);
      case UpdatePositionData() when updatePositionData != null:
        return updatePositionData(_that);
      case UpdateVolume() when updateVolume != null:
        return updateVolume(_that);
      case UpdateSpeed() when updateSpeed != null:
        return updateSpeed(_that);
      case PlayAudio() when playAudio != null:
        return playAudio(_that);
      case PauseAudio() when pauseAudio != null:
        return pauseAudio(_that);
      case StopAudio() when stopAudio != null:
        return stopAudio(_that);
      case SkipToNext() when skipToNext != null:
        return skipToNext(_that);
      case SkipToPrevious() when skipToPrevious != null:
        return skipToPrevious(_that);
      case SeekTo() when seekTo != null:
        return seekTo(_that);
      case SetVolume() when setVolume != null:
        return setVolume(_that);
      case SetSpeed() when setSpeed != null:
        return setSpeed(_that);
      case SkipToQueueItem() when skipToQueueItem != null:
        return skipToQueueItem(_that);
      case PlayFromQueue() when playFromQueue != null:
        return playFromQueue(_that);
      case UpdateQueue() when updateQueue != null:
        return updateQueue(_that);
      case AddQueueItem() when addQueueItem != null:
        return addQueueItem(_that);
      case RemoveQueueItem() when removeQueueItem != null:
        return removeQueueItem(_that);
      case MoveQueueItem() when moveQueueItem != null:
        return moveQueueItem(_that);
      case SetRepeatMode() when setRepeatMode != null:
        return setRepeatMode(_that);
      case SetShuffleMode() when setShuffleMode != null:
        return setShuffleMode(_that);
      case SetSleepTimer() when setSleepTimer != null:
        return setSleepTimer(_that);
      case CancelSleepTimer() when cancelSleepTimer != null:
        return cancelSleepTimer(_that);
      case AudioTimerExpired() when audioTimerExpired != null:
        return audioTimerExpired(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? resetAudioPlayer,
    TResult Function(bool restorePlayback)? loadAudioPlayerData,
    TResult Function(AudioEntity? audio)? updateAudio,
    TResult Function(PlaybackStateEntity playbackState)?
    updatePlaybackStateEntity,
    TResult Function(PositionData positionData)? updatePositionData,
    TResult Function(double volume)? updateVolume,
    TResult Function(double speed)? updateSpeed,
    TResult Function()? playAudio,
    TResult Function()? pauseAudio,
    TResult Function()? stopAudio,
    TResult Function()? skipToNext,
    TResult Function()? skipToPrevious,
    TResult Function(Duration position)? seekTo,
    TResult Function(double volume)? setVolume,
    TResult Function(double speed)? setSpeed,
    TResult Function(int index)? skipToQueueItem,
    TResult Function(List<AudioEntity> queue, int index)? playFromQueue,
    TResult Function(List<AudioEntity> queue)? updateQueue,
    TResult Function(AudioEntity audio)? addQueueItem,
    TResult Function(AudioEntity audio)? removeQueueItem,
    TResult Function(int currentIndex, int newIndex)? moveQueueItem,
    TResult Function(AudioRepeatMode repeatMode)? setRepeatMode,
    TResult Function(AudioShuffleMode shuffleMode)? setShuffleMode,
    TResult Function(Duration duration)? setSleepTimer,
    TResult Function(bool clearPreference)? cancelSleepTimer,
    TResult Function()? audioTimerExpired,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ResetAudioPlayer() when resetAudioPlayer != null:
        return resetAudioPlayer();
      case LoadAudioPlayerData() when loadAudioPlayerData != null:
        return loadAudioPlayerData(_that.restorePlayback);
      case UpdateAudio() when updateAudio != null:
        return updateAudio(_that.audio);
      case UpdatePlaybackStateEntity() when updatePlaybackStateEntity != null:
        return updatePlaybackStateEntity(_that.playbackState);
      case UpdatePositionData() when updatePositionData != null:
        return updatePositionData(_that.positionData);
      case UpdateVolume() when updateVolume != null:
        return updateVolume(_that.volume);
      case UpdateSpeed() when updateSpeed != null:
        return updateSpeed(_that.speed);
      case PlayAudio() when playAudio != null:
        return playAudio();
      case PauseAudio() when pauseAudio != null:
        return pauseAudio();
      case StopAudio() when stopAudio != null:
        return stopAudio();
      case SkipToNext() when skipToNext != null:
        return skipToNext();
      case SkipToPrevious() when skipToPrevious != null:
        return skipToPrevious();
      case SeekTo() when seekTo != null:
        return seekTo(_that.position);
      case SetVolume() when setVolume != null:
        return setVolume(_that.volume);
      case SetSpeed() when setSpeed != null:
        return setSpeed(_that.speed);
      case SkipToQueueItem() when skipToQueueItem != null:
        return skipToQueueItem(_that.index);
      case PlayFromQueue() when playFromQueue != null:
        return playFromQueue(_that.queue, _that.index);
      case UpdateQueue() when updateQueue != null:
        return updateQueue(_that.queue);
      case AddQueueItem() when addQueueItem != null:
        return addQueueItem(_that.audio);
      case RemoveQueueItem() when removeQueueItem != null:
        return removeQueueItem(_that.audio);
      case MoveQueueItem() when moveQueueItem != null:
        return moveQueueItem(_that.currentIndex, _that.newIndex);
      case SetRepeatMode() when setRepeatMode != null:
        return setRepeatMode(_that.repeatMode);
      case SetShuffleMode() when setShuffleMode != null:
        return setShuffleMode(_that.shuffleMode);
      case SetSleepTimer() when setSleepTimer != null:
        return setSleepTimer(_that.duration);
      case CancelSleepTimer() when cancelSleepTimer != null:
        return cancelSleepTimer(_that.clearPreference);
      case AudioTimerExpired() when audioTimerExpired != null:
        return audioTimerExpired();
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() resetAudioPlayer,
    required TResult Function(bool restorePlayback) loadAudioPlayerData,
    required TResult Function(AudioEntity? audio) updateAudio,
    required TResult Function(PlaybackStateEntity playbackState)
    updatePlaybackStateEntity,
    required TResult Function(PositionData positionData) updatePositionData,
    required TResult Function(double volume) updateVolume,
    required TResult Function(double speed) updateSpeed,
    required TResult Function() playAudio,
    required TResult Function() pauseAudio,
    required TResult Function() stopAudio,
    required TResult Function() skipToNext,
    required TResult Function() skipToPrevious,
    required TResult Function(Duration position) seekTo,
    required TResult Function(double volume) setVolume,
    required TResult Function(double speed) setSpeed,
    required TResult Function(int index) skipToQueueItem,
    required TResult Function(List<AudioEntity> queue, int index) playFromQueue,
    required TResult Function(List<AudioEntity> queue) updateQueue,
    required TResult Function(AudioEntity audio) addQueueItem,
    required TResult Function(AudioEntity audio) removeQueueItem,
    required TResult Function(int currentIndex, int newIndex) moveQueueItem,
    required TResult Function(AudioRepeatMode repeatMode) setRepeatMode,
    required TResult Function(AudioShuffleMode shuffleMode) setShuffleMode,
    required TResult Function(Duration duration) setSleepTimer,
    required TResult Function(bool clearPreference) cancelSleepTimer,
    required TResult Function() audioTimerExpired,
  }) {
    final _that = this;
    switch (_that) {
      case ResetAudioPlayer():
        return resetAudioPlayer();
      case LoadAudioPlayerData():
        return loadAudioPlayerData(_that.restorePlayback);
      case UpdateAudio():
        return updateAudio(_that.audio);
      case UpdatePlaybackStateEntity():
        return updatePlaybackStateEntity(_that.playbackState);
      case UpdatePositionData():
        return updatePositionData(_that.positionData);
      case UpdateVolume():
        return updateVolume(_that.volume);
      case UpdateSpeed():
        return updateSpeed(_that.speed);
      case PlayAudio():
        return playAudio();
      case PauseAudio():
        return pauseAudio();
      case StopAudio():
        return stopAudio();
      case SkipToNext():
        return skipToNext();
      case SkipToPrevious():
        return skipToPrevious();
      case SeekTo():
        return seekTo(_that.position);
      case SetVolume():
        return setVolume(_that.volume);
      case SetSpeed():
        return setSpeed(_that.speed);
      case SkipToQueueItem():
        return skipToQueueItem(_that.index);
      case PlayFromQueue():
        return playFromQueue(_that.queue, _that.index);
      case UpdateQueue():
        return updateQueue(_that.queue);
      case AddQueueItem():
        return addQueueItem(_that.audio);
      case RemoveQueueItem():
        return removeQueueItem(_that.audio);
      case MoveQueueItem():
        return moveQueueItem(_that.currentIndex, _that.newIndex);
      case SetRepeatMode():
        return setRepeatMode(_that.repeatMode);
      case SetShuffleMode():
        return setShuffleMode(_that.shuffleMode);
      case SetSleepTimer():
        return setSleepTimer(_that.duration);
      case CancelSleepTimer():
        return cancelSleepTimer(_that.clearPreference);
      case AudioTimerExpired():
        return audioTimerExpired();
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? resetAudioPlayer,
    TResult? Function(bool restorePlayback)? loadAudioPlayerData,
    TResult? Function(AudioEntity? audio)? updateAudio,
    TResult? Function(PlaybackStateEntity playbackState)?
    updatePlaybackStateEntity,
    TResult? Function(PositionData positionData)? updatePositionData,
    TResult? Function(double volume)? updateVolume,
    TResult? Function(double speed)? updateSpeed,
    TResult? Function()? playAudio,
    TResult? Function()? pauseAudio,
    TResult? Function()? stopAudio,
    TResult? Function()? skipToNext,
    TResult? Function()? skipToPrevious,
    TResult? Function(Duration position)? seekTo,
    TResult? Function(double volume)? setVolume,
    TResult? Function(double speed)? setSpeed,
    TResult? Function(int index)? skipToQueueItem,
    TResult? Function(List<AudioEntity> queue, int index)? playFromQueue,
    TResult? Function(List<AudioEntity> queue)? updateQueue,
    TResult? Function(AudioEntity audio)? addQueueItem,
    TResult? Function(AudioEntity audio)? removeQueueItem,
    TResult? Function(int currentIndex, int newIndex)? moveQueueItem,
    TResult? Function(AudioRepeatMode repeatMode)? setRepeatMode,
    TResult? Function(AudioShuffleMode shuffleMode)? setShuffleMode,
    TResult? Function(Duration duration)? setSleepTimer,
    TResult? Function(bool clearPreference)? cancelSleepTimer,
    TResult? Function()? audioTimerExpired,
  }) {
    final _that = this;
    switch (_that) {
      case ResetAudioPlayer() when resetAudioPlayer != null:
        return resetAudioPlayer();
      case LoadAudioPlayerData() when loadAudioPlayerData != null:
        return loadAudioPlayerData(_that.restorePlayback);
      case UpdateAudio() when updateAudio != null:
        return updateAudio(_that.audio);
      case UpdatePlaybackStateEntity() when updatePlaybackStateEntity != null:
        return updatePlaybackStateEntity(_that.playbackState);
      case UpdatePositionData() when updatePositionData != null:
        return updatePositionData(_that.positionData);
      case UpdateVolume() when updateVolume != null:
        return updateVolume(_that.volume);
      case UpdateSpeed() when updateSpeed != null:
        return updateSpeed(_that.speed);
      case PlayAudio() when playAudio != null:
        return playAudio();
      case PauseAudio() when pauseAudio != null:
        return pauseAudio();
      case StopAudio() when stopAudio != null:
        return stopAudio();
      case SkipToNext() when skipToNext != null:
        return skipToNext();
      case SkipToPrevious() when skipToPrevious != null:
        return skipToPrevious();
      case SeekTo() when seekTo != null:
        return seekTo(_that.position);
      case SetVolume() when setVolume != null:
        return setVolume(_that.volume);
      case SetSpeed() when setSpeed != null:
        return setSpeed(_that.speed);
      case SkipToQueueItem() when skipToQueueItem != null:
        return skipToQueueItem(_that.index);
      case PlayFromQueue() when playFromQueue != null:
        return playFromQueue(_that.queue, _that.index);
      case UpdateQueue() when updateQueue != null:
        return updateQueue(_that.queue);
      case AddQueueItem() when addQueueItem != null:
        return addQueueItem(_that.audio);
      case RemoveQueueItem() when removeQueueItem != null:
        return removeQueueItem(_that.audio);
      case MoveQueueItem() when moveQueueItem != null:
        return moveQueueItem(_that.currentIndex, _that.newIndex);
      case SetRepeatMode() when setRepeatMode != null:
        return setRepeatMode(_that.repeatMode);
      case SetShuffleMode() when setShuffleMode != null:
        return setShuffleMode(_that.shuffleMode);
      case SetSleepTimer() when setSleepTimer != null:
        return setSleepTimer(_that.duration);
      case CancelSleepTimer() when cancelSleepTimer != null:
        return cancelSleepTimer(_that.clearPreference);
      case AudioTimerExpired() when audioTimerExpired != null:
        return audioTimerExpired();
      case _:
        return null;
    }
  }
}

/// @nodoc

class ResetAudioPlayer implements AudioPlayerEvent {
  const ResetAudioPlayer();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ResetAudioPlayer);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AudioPlayerEvent.resetAudioPlayer()';
  }
}

/// @nodoc

class LoadAudioPlayerData implements AudioPlayerEvent {
  const LoadAudioPlayerData({this.restorePlayback = true});

  @JsonKey()
  final bool restorePlayback;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LoadAudioPlayerDataCopyWith<LoadAudioPlayerData> get copyWith =>
      _$LoadAudioPlayerDataCopyWithImpl<LoadAudioPlayerData>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LoadAudioPlayerData &&
            (identical(other.restorePlayback, restorePlayback) ||
                other.restorePlayback == restorePlayback));
  }

  @override
  int get hashCode => Object.hash(runtimeType, restorePlayback);

  @override
  String toString() {
    return 'AudioPlayerEvent.loadAudioPlayerData(restorePlayback: $restorePlayback)';
  }
}

/// @nodoc
abstract mixin class $LoadAudioPlayerDataCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $LoadAudioPlayerDataCopyWith(
    LoadAudioPlayerData value,
    $Res Function(LoadAudioPlayerData) _then,
  ) = _$LoadAudioPlayerDataCopyWithImpl;
  @useResult
  $Res call({bool restorePlayback});
}

/// @nodoc
class _$LoadAudioPlayerDataCopyWithImpl<$Res>
    implements $LoadAudioPlayerDataCopyWith<$Res> {
  _$LoadAudioPlayerDataCopyWithImpl(this._self, this._then);

  final LoadAudioPlayerData _self;
  final $Res Function(LoadAudioPlayerData) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? restorePlayback = null}) {
    return _then(
      LoadAudioPlayerData(
        restorePlayback: null == restorePlayback
            ? _self.restorePlayback
            : restorePlayback // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class UpdateAudio implements AudioPlayerEvent {
  const UpdateAudio(this.audio);

  final AudioEntity? audio;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdateAudioCopyWith<UpdateAudio> get copyWith =>
      _$UpdateAudioCopyWithImpl<UpdateAudio>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdateAudio &&
            (identical(other.audio, audio) || other.audio == audio));
  }

  @override
  int get hashCode => Object.hash(runtimeType, audio);

  @override
  String toString() {
    return 'AudioPlayerEvent.updateAudio(audio: $audio)';
  }
}

/// @nodoc
abstract mixin class $UpdateAudioCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdateAudioCopyWith(
    UpdateAudio value,
    $Res Function(UpdateAudio) _then,
  ) = _$UpdateAudioCopyWithImpl;
  @useResult
  $Res call({AudioEntity? audio});

  $AudioEntityCopyWith<$Res>? get audio;
}

/// @nodoc
class _$UpdateAudioCopyWithImpl<$Res> implements $UpdateAudioCopyWith<$Res> {
  _$UpdateAudioCopyWithImpl(this._self, this._then);

  final UpdateAudio _self;
  final $Res Function(UpdateAudio) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? audio = freezed}) {
    return _then(
      UpdateAudio(
        freezed == audio
            ? _self.audio
            : audio // ignore: cast_nullable_to_non_nullable
                  as AudioEntity?,
      ),
    );
  }

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AudioEntityCopyWith<$Res>? get audio {
    if (_self.audio == null) {
      return null;
    }

    return $AudioEntityCopyWith<$Res>(_self.audio!, (value) {
      return _then(_self.copyWith(audio: value));
    });
  }
}

/// @nodoc

class UpdatePlaybackStateEntity implements AudioPlayerEvent {
  const UpdatePlaybackStateEntity(this.playbackState);

  final PlaybackStateEntity playbackState;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdatePlaybackStateEntityCopyWith<UpdatePlaybackStateEntity> get copyWith =>
      _$UpdatePlaybackStateEntityCopyWithImpl<UpdatePlaybackStateEntity>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdatePlaybackStateEntity &&
            (identical(other.playbackState, playbackState) ||
                other.playbackState == playbackState));
  }

  @override
  int get hashCode => Object.hash(runtimeType, playbackState);

  @override
  String toString() {
    return 'AudioPlayerEvent.updatePlaybackStateEntity(playbackState: $playbackState)';
  }
}

/// @nodoc
abstract mixin class $UpdatePlaybackStateEntityCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdatePlaybackStateEntityCopyWith(
    UpdatePlaybackStateEntity value,
    $Res Function(UpdatePlaybackStateEntity) _then,
  ) = _$UpdatePlaybackStateEntityCopyWithImpl;
  @useResult
  $Res call({PlaybackStateEntity playbackState});

  $PlaybackStateEntityCopyWith<$Res> get playbackState;
}

/// @nodoc
class _$UpdatePlaybackStateEntityCopyWithImpl<$Res>
    implements $UpdatePlaybackStateEntityCopyWith<$Res> {
  _$UpdatePlaybackStateEntityCopyWithImpl(this._self, this._then);

  final UpdatePlaybackStateEntity _self;
  final $Res Function(UpdatePlaybackStateEntity) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? playbackState = null}) {
    return _then(
      UpdatePlaybackStateEntity(
        null == playbackState
            ? _self.playbackState
            : playbackState // ignore: cast_nullable_to_non_nullable
                  as PlaybackStateEntity,
      ),
    );
  }

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaybackStateEntityCopyWith<$Res> get playbackState {
    return $PlaybackStateEntityCopyWith<$Res>(_self.playbackState, (value) {
      return _then(_self.copyWith(playbackState: value));
    });
  }
}

/// @nodoc

class UpdatePositionData implements AudioPlayerEvent {
  const UpdatePositionData(this.positionData);

  final PositionData positionData;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdatePositionDataCopyWith<UpdatePositionData> get copyWith =>
      _$UpdatePositionDataCopyWithImpl<UpdatePositionData>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdatePositionData &&
            (identical(other.positionData, positionData) ||
                other.positionData == positionData));
  }

  @override
  int get hashCode => Object.hash(runtimeType, positionData);

  @override
  String toString() {
    return 'AudioPlayerEvent.updatePositionData(positionData: $positionData)';
  }
}

/// @nodoc
abstract mixin class $UpdatePositionDataCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdatePositionDataCopyWith(
    UpdatePositionData value,
    $Res Function(UpdatePositionData) _then,
  ) = _$UpdatePositionDataCopyWithImpl;
  @useResult
  $Res call({PositionData positionData});

  $PositionDataCopyWith<$Res> get positionData;
}

/// @nodoc
class _$UpdatePositionDataCopyWithImpl<$Res>
    implements $UpdatePositionDataCopyWith<$Res> {
  _$UpdatePositionDataCopyWithImpl(this._self, this._then);

  final UpdatePositionData _self;
  final $Res Function(UpdatePositionData) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? positionData = null}) {
    return _then(
      UpdatePositionData(
        null == positionData
            ? _self.positionData
            : positionData // ignore: cast_nullable_to_non_nullable
                  as PositionData,
      ),
    );
  }

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PositionDataCopyWith<$Res> get positionData {
    return $PositionDataCopyWith<$Res>(_self.positionData, (value) {
      return _then(_self.copyWith(positionData: value));
    });
  }
}

/// @nodoc

class UpdateVolume implements AudioPlayerEvent {
  const UpdateVolume(this.volume);

  final double volume;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdateVolumeCopyWith<UpdateVolume> get copyWith =>
      _$UpdateVolumeCopyWithImpl<UpdateVolume>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdateVolume &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @override
  int get hashCode => Object.hash(runtimeType, volume);

  @override
  String toString() {
    return 'AudioPlayerEvent.updateVolume(volume: $volume)';
  }
}

/// @nodoc
abstract mixin class $UpdateVolumeCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdateVolumeCopyWith(
    UpdateVolume value,
    $Res Function(UpdateVolume) _then,
  ) = _$UpdateVolumeCopyWithImpl;
  @useResult
  $Res call({double volume});
}

/// @nodoc
class _$UpdateVolumeCopyWithImpl<$Res> implements $UpdateVolumeCopyWith<$Res> {
  _$UpdateVolumeCopyWithImpl(this._self, this._then);

  final UpdateVolume _self;
  final $Res Function(UpdateVolume) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? volume = null}) {
    return _then(
      UpdateVolume(
        null == volume
            ? _self.volume
            : volume // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class UpdateSpeed implements AudioPlayerEvent {
  const UpdateSpeed(this.speed);

  final double speed;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdateSpeedCopyWith<UpdateSpeed> get copyWith =>
      _$UpdateSpeedCopyWithImpl<UpdateSpeed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdateSpeed &&
            (identical(other.speed, speed) || other.speed == speed));
  }

  @override
  int get hashCode => Object.hash(runtimeType, speed);

  @override
  String toString() {
    return 'AudioPlayerEvent.updateSpeed(speed: $speed)';
  }
}

/// @nodoc
abstract mixin class $UpdateSpeedCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdateSpeedCopyWith(
    UpdateSpeed value,
    $Res Function(UpdateSpeed) _then,
  ) = _$UpdateSpeedCopyWithImpl;
  @useResult
  $Res call({double speed});
}

/// @nodoc
class _$UpdateSpeedCopyWithImpl<$Res> implements $UpdateSpeedCopyWith<$Res> {
  _$UpdateSpeedCopyWithImpl(this._self, this._then);

  final UpdateSpeed _self;
  final $Res Function(UpdateSpeed) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? speed = null}) {
    return _then(
      UpdateSpeed(
        null == speed
            ? _self.speed
            : speed // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class PlayAudio implements AudioPlayerEvent {
  const PlayAudio();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PlayAudio);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AudioPlayerEvent.playAudio()';
  }
}

/// @nodoc

class PauseAudio implements AudioPlayerEvent {
  const PauseAudio();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PauseAudio);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AudioPlayerEvent.pauseAudio()';
  }
}

/// @nodoc

class StopAudio implements AudioPlayerEvent {
  const StopAudio();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is StopAudio);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AudioPlayerEvent.stopAudio()';
  }
}

/// @nodoc

class SkipToNext implements AudioPlayerEvent {
  const SkipToNext();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SkipToNext);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AudioPlayerEvent.skipToNext()';
  }
}

/// @nodoc

class SkipToPrevious implements AudioPlayerEvent {
  const SkipToPrevious();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SkipToPrevious);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AudioPlayerEvent.skipToPrevious()';
  }
}

/// @nodoc

class SeekTo implements AudioPlayerEvent {
  const SeekTo(this.position);

  final Duration position;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SeekToCopyWith<SeekTo> get copyWith =>
      _$SeekToCopyWithImpl<SeekTo>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SeekTo &&
            (identical(other.position, position) ||
                other.position == position));
  }

  @override
  int get hashCode => Object.hash(runtimeType, position);

  @override
  String toString() {
    return 'AudioPlayerEvent.seekTo(position: $position)';
  }
}

/// @nodoc
abstract mixin class $SeekToCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $SeekToCopyWith(SeekTo value, $Res Function(SeekTo) _then) =
      _$SeekToCopyWithImpl;
  @useResult
  $Res call({Duration position});
}

/// @nodoc
class _$SeekToCopyWithImpl<$Res> implements $SeekToCopyWith<$Res> {
  _$SeekToCopyWithImpl(this._self, this._then);

  final SeekTo _self;
  final $Res Function(SeekTo) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? position = null}) {
    return _then(
      SeekTo(
        null == position
            ? _self.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Duration,
      ),
    );
  }
}

/// @nodoc

class SetVolume implements AudioPlayerEvent {
  const SetVolume(this.volume);

  final double volume;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SetVolumeCopyWith<SetVolume> get copyWith =>
      _$SetVolumeCopyWithImpl<SetVolume>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SetVolume &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @override
  int get hashCode => Object.hash(runtimeType, volume);

  @override
  String toString() {
    return 'AudioPlayerEvent.setVolume(volume: $volume)';
  }
}

/// @nodoc
abstract mixin class $SetVolumeCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $SetVolumeCopyWith(SetVolume value, $Res Function(SetVolume) _then) =
      _$SetVolumeCopyWithImpl;
  @useResult
  $Res call({double volume});
}

/// @nodoc
class _$SetVolumeCopyWithImpl<$Res> implements $SetVolumeCopyWith<$Res> {
  _$SetVolumeCopyWithImpl(this._self, this._then);

  final SetVolume _self;
  final $Res Function(SetVolume) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? volume = null}) {
    return _then(
      SetVolume(
        null == volume
            ? _self.volume
            : volume // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class SetSpeed implements AudioPlayerEvent {
  const SetSpeed(this.speed);

  final double speed;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SetSpeedCopyWith<SetSpeed> get copyWith =>
      _$SetSpeedCopyWithImpl<SetSpeed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SetSpeed &&
            (identical(other.speed, speed) || other.speed == speed));
  }

  @override
  int get hashCode => Object.hash(runtimeType, speed);

  @override
  String toString() {
    return 'AudioPlayerEvent.setSpeed(speed: $speed)';
  }
}

/// @nodoc
abstract mixin class $SetSpeedCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $SetSpeedCopyWith(SetSpeed value, $Res Function(SetSpeed) _then) =
      _$SetSpeedCopyWithImpl;
  @useResult
  $Res call({double speed});
}

/// @nodoc
class _$SetSpeedCopyWithImpl<$Res> implements $SetSpeedCopyWith<$Res> {
  _$SetSpeedCopyWithImpl(this._self, this._then);

  final SetSpeed _self;
  final $Res Function(SetSpeed) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? speed = null}) {
    return _then(
      SetSpeed(
        null == speed
            ? _self.speed
            : speed // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class SkipToQueueItem implements AudioPlayerEvent {
  const SkipToQueueItem(this.index);

  final int index;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SkipToQueueItemCopyWith<SkipToQueueItem> get copyWith =>
      _$SkipToQueueItemCopyWithImpl<SkipToQueueItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SkipToQueueItem &&
            (identical(other.index, index) || other.index == index));
  }

  @override
  int get hashCode => Object.hash(runtimeType, index);

  @override
  String toString() {
    return 'AudioPlayerEvent.skipToQueueItem(index: $index)';
  }
}

/// @nodoc
abstract mixin class $SkipToQueueItemCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $SkipToQueueItemCopyWith(
    SkipToQueueItem value,
    $Res Function(SkipToQueueItem) _then,
  ) = _$SkipToQueueItemCopyWithImpl;
  @useResult
  $Res call({int index});
}

/// @nodoc
class _$SkipToQueueItemCopyWithImpl<$Res>
    implements $SkipToQueueItemCopyWith<$Res> {
  _$SkipToQueueItemCopyWithImpl(this._self, this._then);

  final SkipToQueueItem _self;
  final $Res Function(SkipToQueueItem) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? index = null}) {
    return _then(
      SkipToQueueItem(
        null == index
            ? _self.index
            : index // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class PlayFromQueue implements AudioPlayerEvent {
  const PlayFromQueue(final List<AudioEntity> queue, this.index)
    : _queue = queue;

  final List<AudioEntity> _queue;
  List<AudioEntity> get queue {
    if (_queue is EqualUnmodifiableListView) return _queue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_queue);
  }

  final int index;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlayFromQueueCopyWith<PlayFromQueue> get copyWith =>
      _$PlayFromQueueCopyWithImpl<PlayFromQueue>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlayFromQueue &&
            const DeepCollectionEquality().equals(other._queue, _queue) &&
            (identical(other.index, index) || other.index == index));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_queue),
    index,
  );

  @override
  String toString() {
    return 'AudioPlayerEvent.playFromQueue(queue: $queue, index: $index)';
  }
}

/// @nodoc
abstract mixin class $PlayFromQueueCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $PlayFromQueueCopyWith(
    PlayFromQueue value,
    $Res Function(PlayFromQueue) _then,
  ) = _$PlayFromQueueCopyWithImpl;
  @useResult
  $Res call({List<AudioEntity> queue, int index});
}

/// @nodoc
class _$PlayFromQueueCopyWithImpl<$Res>
    implements $PlayFromQueueCopyWith<$Res> {
  _$PlayFromQueueCopyWithImpl(this._self, this._then);

  final PlayFromQueue _self;
  final $Res Function(PlayFromQueue) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? queue = null, Object? index = null}) {
    return _then(
      PlayFromQueue(
        null == queue
            ? _self._queue
            : queue // ignore: cast_nullable_to_non_nullable
                  as List<AudioEntity>,
        null == index
            ? _self.index
            : index // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class UpdateQueue implements AudioPlayerEvent {
  const UpdateQueue(final List<AudioEntity> queue) : _queue = queue;

  final List<AudioEntity> _queue;
  List<AudioEntity> get queue {
    if (_queue is EqualUnmodifiableListView) return _queue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_queue);
  }

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdateQueueCopyWith<UpdateQueue> get copyWith =>
      _$UpdateQueueCopyWithImpl<UpdateQueue>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdateQueue &&
            const DeepCollectionEquality().equals(other._queue, _queue));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_queue));

  @override
  String toString() {
    return 'AudioPlayerEvent.updateQueue(queue: $queue)';
  }
}

/// @nodoc
abstract mixin class $UpdateQueueCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdateQueueCopyWith(
    UpdateQueue value,
    $Res Function(UpdateQueue) _then,
  ) = _$UpdateQueueCopyWithImpl;
  @useResult
  $Res call({List<AudioEntity> queue});
}

/// @nodoc
class _$UpdateQueueCopyWithImpl<$Res> implements $UpdateQueueCopyWith<$Res> {
  _$UpdateQueueCopyWithImpl(this._self, this._then);

  final UpdateQueue _self;
  final $Res Function(UpdateQueue) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? queue = null}) {
    return _then(
      UpdateQueue(
        null == queue
            ? _self._queue
            : queue // ignore: cast_nullable_to_non_nullable
                  as List<AudioEntity>,
      ),
    );
  }
}

/// @nodoc

class AddQueueItem implements AudioPlayerEvent {
  const AddQueueItem(this.audio);

  final AudioEntity audio;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AddQueueItemCopyWith<AddQueueItem> get copyWith =>
      _$AddQueueItemCopyWithImpl<AddQueueItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AddQueueItem &&
            (identical(other.audio, audio) || other.audio == audio));
  }

  @override
  int get hashCode => Object.hash(runtimeType, audio);

  @override
  String toString() {
    return 'AudioPlayerEvent.addQueueItem(audio: $audio)';
  }
}

/// @nodoc
abstract mixin class $AddQueueItemCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $AddQueueItemCopyWith(
    AddQueueItem value,
    $Res Function(AddQueueItem) _then,
  ) = _$AddQueueItemCopyWithImpl;
  @useResult
  $Res call({AudioEntity audio});

  $AudioEntityCopyWith<$Res> get audio;
}

/// @nodoc
class _$AddQueueItemCopyWithImpl<$Res> implements $AddQueueItemCopyWith<$Res> {
  _$AddQueueItemCopyWithImpl(this._self, this._then);

  final AddQueueItem _self;
  final $Res Function(AddQueueItem) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? audio = null}) {
    return _then(
      AddQueueItem(
        null == audio
            ? _self.audio
            : audio // ignore: cast_nullable_to_non_nullable
                  as AudioEntity,
      ),
    );
  }

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AudioEntityCopyWith<$Res> get audio {
    return $AudioEntityCopyWith<$Res>(_self.audio, (value) {
      return _then(_self.copyWith(audio: value));
    });
  }
}

/// @nodoc

class RemoveQueueItem implements AudioPlayerEvent {
  const RemoveQueueItem(this.audio);

  final AudioEntity audio;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RemoveQueueItemCopyWith<RemoveQueueItem> get copyWith =>
      _$RemoveQueueItemCopyWithImpl<RemoveQueueItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RemoveQueueItem &&
            (identical(other.audio, audio) || other.audio == audio));
  }

  @override
  int get hashCode => Object.hash(runtimeType, audio);

  @override
  String toString() {
    return 'AudioPlayerEvent.removeQueueItem(audio: $audio)';
  }
}

/// @nodoc
abstract mixin class $RemoveQueueItemCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $RemoveQueueItemCopyWith(
    RemoveQueueItem value,
    $Res Function(RemoveQueueItem) _then,
  ) = _$RemoveQueueItemCopyWithImpl;
  @useResult
  $Res call({AudioEntity audio});

  $AudioEntityCopyWith<$Res> get audio;
}

/// @nodoc
class _$RemoveQueueItemCopyWithImpl<$Res>
    implements $RemoveQueueItemCopyWith<$Res> {
  _$RemoveQueueItemCopyWithImpl(this._self, this._then);

  final RemoveQueueItem _self;
  final $Res Function(RemoveQueueItem) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? audio = null}) {
    return _then(
      RemoveQueueItem(
        null == audio
            ? _self.audio
            : audio // ignore: cast_nullable_to_non_nullable
                  as AudioEntity,
      ),
    );
  }

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AudioEntityCopyWith<$Res> get audio {
    return $AudioEntityCopyWith<$Res>(_self.audio, (value) {
      return _then(_self.copyWith(audio: value));
    });
  }
}

/// @nodoc

class MoveQueueItem implements AudioPlayerEvent {
  const MoveQueueItem(this.currentIndex, this.newIndex);

  final int currentIndex;
  final int newIndex;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MoveQueueItemCopyWith<MoveQueueItem> get copyWith =>
      _$MoveQueueItemCopyWithImpl<MoveQueueItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MoveQueueItem &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.newIndex, newIndex) ||
                other.newIndex == newIndex));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentIndex, newIndex);

  @override
  String toString() {
    return 'AudioPlayerEvent.moveQueueItem(currentIndex: $currentIndex, newIndex: $newIndex)';
  }
}

/// @nodoc
abstract mixin class $MoveQueueItemCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $MoveQueueItemCopyWith(
    MoveQueueItem value,
    $Res Function(MoveQueueItem) _then,
  ) = _$MoveQueueItemCopyWithImpl;
  @useResult
  $Res call({int currentIndex, int newIndex});
}

/// @nodoc
class _$MoveQueueItemCopyWithImpl<$Res>
    implements $MoveQueueItemCopyWith<$Res> {
  _$MoveQueueItemCopyWithImpl(this._self, this._then);

  final MoveQueueItem _self;
  final $Res Function(MoveQueueItem) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? currentIndex = null, Object? newIndex = null}) {
    return _then(
      MoveQueueItem(
        null == currentIndex
            ? _self.currentIndex
            : currentIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        null == newIndex
            ? _self.newIndex
            : newIndex // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class SetRepeatMode implements AudioPlayerEvent {
  const SetRepeatMode(this.repeatMode);

  final AudioRepeatMode repeatMode;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SetRepeatModeCopyWith<SetRepeatMode> get copyWith =>
      _$SetRepeatModeCopyWithImpl<SetRepeatMode>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SetRepeatMode &&
            (identical(other.repeatMode, repeatMode) ||
                other.repeatMode == repeatMode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, repeatMode);

  @override
  String toString() {
    return 'AudioPlayerEvent.setRepeatMode(repeatMode: $repeatMode)';
  }
}

/// @nodoc
abstract mixin class $SetRepeatModeCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $SetRepeatModeCopyWith(
    SetRepeatMode value,
    $Res Function(SetRepeatMode) _then,
  ) = _$SetRepeatModeCopyWithImpl;
  @useResult
  $Res call({AudioRepeatMode repeatMode});
}

/// @nodoc
class _$SetRepeatModeCopyWithImpl<$Res>
    implements $SetRepeatModeCopyWith<$Res> {
  _$SetRepeatModeCopyWithImpl(this._self, this._then);

  final SetRepeatMode _self;
  final $Res Function(SetRepeatMode) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? repeatMode = null}) {
    return _then(
      SetRepeatMode(
        null == repeatMode
            ? _self.repeatMode
            : repeatMode // ignore: cast_nullable_to_non_nullable
                  as AudioRepeatMode,
      ),
    );
  }
}

/// @nodoc

class SetShuffleMode implements AudioPlayerEvent {
  const SetShuffleMode(this.shuffleMode);

  final AudioShuffleMode shuffleMode;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SetShuffleModeCopyWith<SetShuffleMode> get copyWith =>
      _$SetShuffleModeCopyWithImpl<SetShuffleMode>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SetShuffleMode &&
            (identical(other.shuffleMode, shuffleMode) ||
                other.shuffleMode == shuffleMode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, shuffleMode);

  @override
  String toString() {
    return 'AudioPlayerEvent.setShuffleMode(shuffleMode: $shuffleMode)';
  }
}

/// @nodoc
abstract mixin class $SetShuffleModeCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $SetShuffleModeCopyWith(
    SetShuffleMode value,
    $Res Function(SetShuffleMode) _then,
  ) = _$SetShuffleModeCopyWithImpl;
  @useResult
  $Res call({AudioShuffleMode shuffleMode});
}

/// @nodoc
class _$SetShuffleModeCopyWithImpl<$Res>
    implements $SetShuffleModeCopyWith<$Res> {
  _$SetShuffleModeCopyWithImpl(this._self, this._then);

  final SetShuffleMode _self;
  final $Res Function(SetShuffleMode) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? shuffleMode = null}) {
    return _then(
      SetShuffleMode(
        null == shuffleMode
            ? _self.shuffleMode
            : shuffleMode // ignore: cast_nullable_to_non_nullable
                  as AudioShuffleMode,
      ),
    );
  }
}

/// @nodoc

class SetSleepTimer implements AudioPlayerEvent {
  const SetSleepTimer(this.duration);

  final Duration duration;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SetSleepTimerCopyWith<SetSleepTimer> get copyWith =>
      _$SetSleepTimerCopyWithImpl<SetSleepTimer>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SetSleepTimer &&
            (identical(other.duration, duration) ||
                other.duration == duration));
  }

  @override
  int get hashCode => Object.hash(runtimeType, duration);

  @override
  String toString() {
    return 'AudioPlayerEvent.setSleepTimer(duration: $duration)';
  }
}

/// @nodoc
abstract mixin class $SetSleepTimerCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $SetSleepTimerCopyWith(
    SetSleepTimer value,
    $Res Function(SetSleepTimer) _then,
  ) = _$SetSleepTimerCopyWithImpl;
  @useResult
  $Res call({Duration duration});
}

/// @nodoc
class _$SetSleepTimerCopyWithImpl<$Res>
    implements $SetSleepTimerCopyWith<$Res> {
  _$SetSleepTimerCopyWithImpl(this._self, this._then);

  final SetSleepTimer _self;
  final $Res Function(SetSleepTimer) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? duration = null}) {
    return _then(
      SetSleepTimer(
        null == duration
            ? _self.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as Duration,
      ),
    );
  }
}

/// @nodoc

class CancelSleepTimer implements AudioPlayerEvent {
  const CancelSleepTimer({this.clearPreference = true});

  @JsonKey()
  final bool clearPreference;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CancelSleepTimerCopyWith<CancelSleepTimer> get copyWith =>
      _$CancelSleepTimerCopyWithImpl<CancelSleepTimer>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CancelSleepTimer &&
            (identical(other.clearPreference, clearPreference) ||
                other.clearPreference == clearPreference));
  }

  @override
  int get hashCode => Object.hash(runtimeType, clearPreference);

  @override
  String toString() {
    return 'AudioPlayerEvent.cancelSleepTimer(clearPreference: $clearPreference)';
  }
}

/// @nodoc
abstract mixin class $CancelSleepTimerCopyWith<$Res>
    implements $AudioPlayerEventCopyWith<$Res> {
  factory $CancelSleepTimerCopyWith(
    CancelSleepTimer value,
    $Res Function(CancelSleepTimer) _then,
  ) = _$CancelSleepTimerCopyWithImpl;
  @useResult
  $Res call({bool clearPreference});
}

/// @nodoc
class _$CancelSleepTimerCopyWithImpl<$Res>
    implements $CancelSleepTimerCopyWith<$Res> {
  _$CancelSleepTimerCopyWithImpl(this._self, this._then);

  final CancelSleepTimer _self;
  final $Res Function(CancelSleepTimer) _then;

  /// Create a copy of AudioPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? clearPreference = null}) {
    return _then(
      CancelSleepTimer(
        clearPreference: null == clearPreference
            ? _self.clearPreference
            : clearPreference // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class AudioTimerExpired implements AudioPlayerEvent {
  const AudioTimerExpired();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AudioTimerExpired);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AudioPlayerEvent.audioTimerExpired()';
  }
}

/// @nodoc
mixin _$AudioPlayerState {
  AudioPlayerStatus get status;
  AudioEntity? get currentAudio;
  PlaybackStateEntity? get playbackState;
  PositionData? get positionData;
  double get volume;
  double get speed;
  AudioRepeatMode get repeatMode;
  AudioShuffleMode get shuffleMode;
  DateTime? get sleepTimerTargetTime;
  Duration? get lastSleepTimerDuration;
  String? get dismissedAudioId;

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AudioPlayerStateCopyWith<AudioPlayerState> get copyWith =>
      _$AudioPlayerStateCopyWithImpl<AudioPlayerState>(
        this as AudioPlayerState,
        _$identity,
      );

  /// Serializes this AudioPlayerState to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AudioPlayerState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentAudio, currentAudio) ||
                other.currentAudio == currentAudio) &&
            (identical(other.playbackState, playbackState) ||
                other.playbackState == playbackState) &&
            (identical(other.positionData, positionData) ||
                other.positionData == positionData) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.speed, speed) || other.speed == speed) &&
            (identical(other.repeatMode, repeatMode) ||
                other.repeatMode == repeatMode) &&
            (identical(other.shuffleMode, shuffleMode) ||
                other.shuffleMode == shuffleMode) &&
            (identical(other.sleepTimerTargetTime, sleepTimerTargetTime) ||
                other.sleepTimerTargetTime == sleepTimerTargetTime) &&
            (identical(other.lastSleepTimerDuration, lastSleepTimerDuration) ||
                other.lastSleepTimerDuration == lastSleepTimerDuration) &&
            (identical(other.dismissedAudioId, dismissedAudioId) ||
                other.dismissedAudioId == dismissedAudioId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    currentAudio,
    playbackState,
    positionData,
    volume,
    speed,
    repeatMode,
    shuffleMode,
    sleepTimerTargetTime,
    lastSleepTimerDuration,
    dismissedAudioId,
  );

  @override
  String toString() {
    return 'AudioPlayerState(status: $status, currentAudio: $currentAudio, playbackState: $playbackState, positionData: $positionData, volume: $volume, speed: $speed, repeatMode: $repeatMode, shuffleMode: $shuffleMode, sleepTimerTargetTime: $sleepTimerTargetTime, lastSleepTimerDuration: $lastSleepTimerDuration, dismissedAudioId: $dismissedAudioId)';
  }
}

/// @nodoc
abstract mixin class $AudioPlayerStateCopyWith<$Res> {
  factory $AudioPlayerStateCopyWith(
    AudioPlayerState value,
    $Res Function(AudioPlayerState) _then,
  ) = _$AudioPlayerStateCopyWithImpl;
  @useResult
  $Res call({
    AudioPlayerStatus status,
    AudioEntity? currentAudio,
    PlaybackStateEntity? playbackState,
    PositionData? positionData,
    double volume,
    double speed,
    AudioRepeatMode repeatMode,
    AudioShuffleMode shuffleMode,
    DateTime? sleepTimerTargetTime,
    Duration? lastSleepTimerDuration,
    String? dismissedAudioId,
  });

  $AudioEntityCopyWith<$Res>? get currentAudio;
  $PlaybackStateEntityCopyWith<$Res>? get playbackState;
  $PositionDataCopyWith<$Res>? get positionData;
}

/// @nodoc
class _$AudioPlayerStateCopyWithImpl<$Res>
    implements $AudioPlayerStateCopyWith<$Res> {
  _$AudioPlayerStateCopyWithImpl(this._self, this._then);

  final AudioPlayerState _self;
  final $Res Function(AudioPlayerState) _then;

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? currentAudio = freezed,
    Object? playbackState = freezed,
    Object? positionData = freezed,
    Object? volume = null,
    Object? speed = null,
    Object? repeatMode = null,
    Object? shuffleMode = null,
    Object? sleepTimerTargetTime = freezed,
    Object? lastSleepTimerDuration = freezed,
    Object? dismissedAudioId = freezed,
  }) {
    return _then(
      _self.copyWith(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as AudioPlayerStatus,
        currentAudio: freezed == currentAudio
            ? _self.currentAudio
            : currentAudio // ignore: cast_nullable_to_non_nullable
                  as AudioEntity?,
        playbackState: freezed == playbackState
            ? _self.playbackState
            : playbackState // ignore: cast_nullable_to_non_nullable
                  as PlaybackStateEntity?,
        positionData: freezed == positionData
            ? _self.positionData
            : positionData // ignore: cast_nullable_to_non_nullable
                  as PositionData?,
        volume: null == volume
            ? _self.volume
            : volume // ignore: cast_nullable_to_non_nullable
                  as double,
        speed: null == speed
            ? _self.speed
            : speed // ignore: cast_nullable_to_non_nullable
                  as double,
        repeatMode: null == repeatMode
            ? _self.repeatMode
            : repeatMode // ignore: cast_nullable_to_non_nullable
                  as AudioRepeatMode,
        shuffleMode: null == shuffleMode
            ? _self.shuffleMode
            : shuffleMode // ignore: cast_nullable_to_non_nullable
                  as AudioShuffleMode,
        sleepTimerTargetTime: freezed == sleepTimerTargetTime
            ? _self.sleepTimerTargetTime
            : sleepTimerTargetTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastSleepTimerDuration: freezed == lastSleepTimerDuration
            ? _self.lastSleepTimerDuration
            : lastSleepTimerDuration // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        dismissedAudioId: freezed == dismissedAudioId
            ? _self.dismissedAudioId
            : dismissedAudioId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AudioEntityCopyWith<$Res>? get currentAudio {
    if (_self.currentAudio == null) {
      return null;
    }

    return $AudioEntityCopyWith<$Res>(_self.currentAudio!, (value) {
      return _then(_self.copyWith(currentAudio: value));
    });
  }

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaybackStateEntityCopyWith<$Res>? get playbackState {
    if (_self.playbackState == null) {
      return null;
    }

    return $PlaybackStateEntityCopyWith<$Res>(_self.playbackState!, (value) {
      return _then(_self.copyWith(playbackState: value));
    });
  }

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PositionDataCopyWith<$Res>? get positionData {
    if (_self.positionData == null) {
      return null;
    }

    return $PositionDataCopyWith<$Res>(_self.positionData!, (value) {
      return _then(_self.copyWith(positionData: value));
    });
  }
}

/// Adds pattern-matching-related methods to [AudioPlayerState].
extension AudioPlayerStatePatterns on AudioPlayerState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AudioPlayerState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AudioPlayerState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AudioPlayerState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioPlayerState():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AudioPlayerState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioPlayerState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      AudioPlayerStatus status,
      AudioEntity? currentAudio,
      PlaybackStateEntity? playbackState,
      PositionData? positionData,
      double volume,
      double speed,
      AudioRepeatMode repeatMode,
      AudioShuffleMode shuffleMode,
      DateTime? sleepTimerTargetTime,
      Duration? lastSleepTimerDuration,
      String? dismissedAudioId,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AudioPlayerState() when $default != null:
        return $default(
          _that.status,
          _that.currentAudio,
          _that.playbackState,
          _that.positionData,
          _that.volume,
          _that.speed,
          _that.repeatMode,
          _that.shuffleMode,
          _that.sleepTimerTargetTime,
          _that.lastSleepTimerDuration,
          _that.dismissedAudioId,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      AudioPlayerStatus status,
      AudioEntity? currentAudio,
      PlaybackStateEntity? playbackState,
      PositionData? positionData,
      double volume,
      double speed,
      AudioRepeatMode repeatMode,
      AudioShuffleMode shuffleMode,
      DateTime? sleepTimerTargetTime,
      Duration? lastSleepTimerDuration,
      String? dismissedAudioId,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioPlayerState():
        return $default(
          _that.status,
          _that.currentAudio,
          _that.playbackState,
          _that.positionData,
          _that.volume,
          _that.speed,
          _that.repeatMode,
          _that.shuffleMode,
          _that.sleepTimerTargetTime,
          _that.lastSleepTimerDuration,
          _that.dismissedAudioId,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      AudioPlayerStatus status,
      AudioEntity? currentAudio,
      PlaybackStateEntity? playbackState,
      PositionData? positionData,
      double volume,
      double speed,
      AudioRepeatMode repeatMode,
      AudioShuffleMode shuffleMode,
      DateTime? sleepTimerTargetTime,
      Duration? lastSleepTimerDuration,
      String? dismissedAudioId,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioPlayerState() when $default != null:
        return $default(
          _that.status,
          _that.currentAudio,
          _that.playbackState,
          _that.positionData,
          _that.volume,
          _that.speed,
          _that.repeatMode,
          _that.shuffleMode,
          _that.sleepTimerTargetTime,
          _that.lastSleepTimerDuration,
          _that.dismissedAudioId,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _AudioPlayerState extends AudioPlayerState {
  const _AudioPlayerState({
    required this.status,
    this.currentAudio,
    this.playbackState,
    this.positionData,
    this.volume = 1.0,
    this.speed = 1.0,
    this.repeatMode = AudioRepeatMode.none,
    this.shuffleMode = AudioShuffleMode.none,
    this.sleepTimerTargetTime,
    this.lastSleepTimerDuration,
    this.dismissedAudioId,
  }) : super._();
  factory _AudioPlayerState.fromJson(Map<String, dynamic> json) =>
      _$AudioPlayerStateFromJson(json);

  @override
  final AudioPlayerStatus status;
  @override
  final AudioEntity? currentAudio;
  @override
  final PlaybackStateEntity? playbackState;
  @override
  final PositionData? positionData;
  @override
  @JsonKey()
  final double volume;
  @override
  @JsonKey()
  final double speed;
  @override
  @JsonKey()
  final AudioRepeatMode repeatMode;
  @override
  @JsonKey()
  final AudioShuffleMode shuffleMode;
  @override
  final DateTime? sleepTimerTargetTime;
  @override
  final Duration? lastSleepTimerDuration;
  @override
  final String? dismissedAudioId;

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AudioPlayerStateCopyWith<_AudioPlayerState> get copyWith =>
      __$AudioPlayerStateCopyWithImpl<_AudioPlayerState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AudioPlayerStateToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AudioPlayerState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentAudio, currentAudio) ||
                other.currentAudio == currentAudio) &&
            (identical(other.playbackState, playbackState) ||
                other.playbackState == playbackState) &&
            (identical(other.positionData, positionData) ||
                other.positionData == positionData) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.speed, speed) || other.speed == speed) &&
            (identical(other.repeatMode, repeatMode) ||
                other.repeatMode == repeatMode) &&
            (identical(other.shuffleMode, shuffleMode) ||
                other.shuffleMode == shuffleMode) &&
            (identical(other.sleepTimerTargetTime, sleepTimerTargetTime) ||
                other.sleepTimerTargetTime == sleepTimerTargetTime) &&
            (identical(other.lastSleepTimerDuration, lastSleepTimerDuration) ||
                other.lastSleepTimerDuration == lastSleepTimerDuration) &&
            (identical(other.dismissedAudioId, dismissedAudioId) ||
                other.dismissedAudioId == dismissedAudioId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    currentAudio,
    playbackState,
    positionData,
    volume,
    speed,
    repeatMode,
    shuffleMode,
    sleepTimerTargetTime,
    lastSleepTimerDuration,
    dismissedAudioId,
  );

  @override
  String toString() {
    return 'AudioPlayerState(status: $status, currentAudio: $currentAudio, playbackState: $playbackState, positionData: $positionData, volume: $volume, speed: $speed, repeatMode: $repeatMode, shuffleMode: $shuffleMode, sleepTimerTargetTime: $sleepTimerTargetTime, lastSleepTimerDuration: $lastSleepTimerDuration, dismissedAudioId: $dismissedAudioId)';
  }
}

/// @nodoc
abstract mixin class _$AudioPlayerStateCopyWith<$Res>
    implements $AudioPlayerStateCopyWith<$Res> {
  factory _$AudioPlayerStateCopyWith(
    _AudioPlayerState value,
    $Res Function(_AudioPlayerState) _then,
  ) = __$AudioPlayerStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    AudioPlayerStatus status,
    AudioEntity? currentAudio,
    PlaybackStateEntity? playbackState,
    PositionData? positionData,
    double volume,
    double speed,
    AudioRepeatMode repeatMode,
    AudioShuffleMode shuffleMode,
    DateTime? sleepTimerTargetTime,
    Duration? lastSleepTimerDuration,
    String? dismissedAudioId,
  });

  @override
  $AudioEntityCopyWith<$Res>? get currentAudio;
  @override
  $PlaybackStateEntityCopyWith<$Res>? get playbackState;
  @override
  $PositionDataCopyWith<$Res>? get positionData;
}

/// @nodoc
class __$AudioPlayerStateCopyWithImpl<$Res>
    implements _$AudioPlayerStateCopyWith<$Res> {
  __$AudioPlayerStateCopyWithImpl(this._self, this._then);

  final _AudioPlayerState _self;
  final $Res Function(_AudioPlayerState) _then;

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? status = null,
    Object? currentAudio = freezed,
    Object? playbackState = freezed,
    Object? positionData = freezed,
    Object? volume = null,
    Object? speed = null,
    Object? repeatMode = null,
    Object? shuffleMode = null,
    Object? sleepTimerTargetTime = freezed,
    Object? lastSleepTimerDuration = freezed,
    Object? dismissedAudioId = freezed,
  }) {
    return _then(
      _AudioPlayerState(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as AudioPlayerStatus,
        currentAudio: freezed == currentAudio
            ? _self.currentAudio
            : currentAudio // ignore: cast_nullable_to_non_nullable
                  as AudioEntity?,
        playbackState: freezed == playbackState
            ? _self.playbackState
            : playbackState // ignore: cast_nullable_to_non_nullable
                  as PlaybackStateEntity?,
        positionData: freezed == positionData
            ? _self.positionData
            : positionData // ignore: cast_nullable_to_non_nullable
                  as PositionData?,
        volume: null == volume
            ? _self.volume
            : volume // ignore: cast_nullable_to_non_nullable
                  as double,
        speed: null == speed
            ? _self.speed
            : speed // ignore: cast_nullable_to_non_nullable
                  as double,
        repeatMode: null == repeatMode
            ? _self.repeatMode
            : repeatMode // ignore: cast_nullable_to_non_nullable
                  as AudioRepeatMode,
        shuffleMode: null == shuffleMode
            ? _self.shuffleMode
            : shuffleMode // ignore: cast_nullable_to_non_nullable
                  as AudioShuffleMode,
        sleepTimerTargetTime: freezed == sleepTimerTargetTime
            ? _self.sleepTimerTargetTime
            : sleepTimerTargetTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastSleepTimerDuration: freezed == lastSleepTimerDuration
            ? _self.lastSleepTimerDuration
            : lastSleepTimerDuration // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        dismissedAudioId: freezed == dismissedAudioId
            ? _self.dismissedAudioId
            : dismissedAudioId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AudioEntityCopyWith<$Res>? get currentAudio {
    if (_self.currentAudio == null) {
      return null;
    }

    return $AudioEntityCopyWith<$Res>(_self.currentAudio!, (value) {
      return _then(_self.copyWith(currentAudio: value));
    });
  }

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaybackStateEntityCopyWith<$Res>? get playbackState {
    if (_self.playbackState == null) {
      return null;
    }

    return $PlaybackStateEntityCopyWith<$Res>(_self.playbackState!, (value) {
      return _then(_self.copyWith(playbackState: value));
    });
  }

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PositionDataCopyWith<$Res>? get positionData {
    if (_self.positionData == null) {
      return null;
    }

    return $PositionDataCopyWith<$Res>(_self.positionData!, (value) {
      return _then(_self.copyWith(positionData: value));
    });
  }
}
