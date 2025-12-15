// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_player_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AudioPlayerEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioPlayerEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AudioPlayerEvent()';
}


}

/// @nodoc
class $AudioPlayerEventCopyWith<$Res>  {
$AudioPlayerEventCopyWith(AudioPlayerEvent _, $Res Function(AudioPlayerEvent) __);
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoadAudioPlayerData value)?  loadAudioPlayerData,TResult Function( UpdateMediaItem value)?  updateMediaItem,TResult Function( UpdatePlaybackState value)?  updatePlaybackState,TResult Function( UpdatePositionData value)?  updatePositionData,TResult Function( UpdateQueueState value)?  updateQueueState,TResult Function( UpdateVolume value)?  updateVolume,TResult Function( UpdateSpeed value)?  updateSpeed,TResult Function( PlayAudio value)?  playAudio,TResult Function( PauseAudio value)?  pauseAudio,TResult Function( StopAudio value)?  stopAudio,TResult Function( SkipToNext value)?  skipToNext,TResult Function( SkipToPrevious value)?  skipToPrevious,TResult Function( SeekTo value)?  seekTo,TResult Function( SetVolume value)?  setVolume,TResult Function( SetSpeed value)?  setSpeed,TResult Function( SkipToQueueItem value)?  skipToQueueItem,TResult Function( PlayFromQueue value)?  playFromQueue,TResult Function( UpdateQueue value)?  updateQueue,TResult Function( AddQueueItem value)?  addQueueItem,TResult Function( RemoveQueueItem value)?  removeQueueItem,TResult Function( MoveQueueItem value)?  moveQueueItem,TResult Function( SetRepeatMode value)?  setRepeatMode,TResult Function( SetShuffleMode value)?  setShuffleMode,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoadAudioPlayerData() when loadAudioPlayerData != null:
return loadAudioPlayerData(_that);case UpdateMediaItem() when updateMediaItem != null:
return updateMediaItem(_that);case UpdatePlaybackState() when updatePlaybackState != null:
return updatePlaybackState(_that);case UpdatePositionData() when updatePositionData != null:
return updatePositionData(_that);case UpdateQueueState() when updateQueueState != null:
return updateQueueState(_that);case UpdateVolume() when updateVolume != null:
return updateVolume(_that);case UpdateSpeed() when updateSpeed != null:
return updateSpeed(_that);case PlayAudio() when playAudio != null:
return playAudio(_that);case PauseAudio() when pauseAudio != null:
return pauseAudio(_that);case StopAudio() when stopAudio != null:
return stopAudio(_that);case SkipToNext() when skipToNext != null:
return skipToNext(_that);case SkipToPrevious() when skipToPrevious != null:
return skipToPrevious(_that);case SeekTo() when seekTo != null:
return seekTo(_that);case SetVolume() when setVolume != null:
return setVolume(_that);case SetSpeed() when setSpeed != null:
return setSpeed(_that);case SkipToQueueItem() when skipToQueueItem != null:
return skipToQueueItem(_that);case PlayFromQueue() when playFromQueue != null:
return playFromQueue(_that);case UpdateQueue() when updateQueue != null:
return updateQueue(_that);case AddQueueItem() when addQueueItem != null:
return addQueueItem(_that);case RemoveQueueItem() when removeQueueItem != null:
return removeQueueItem(_that);case MoveQueueItem() when moveQueueItem != null:
return moveQueueItem(_that);case SetRepeatMode() when setRepeatMode != null:
return setRepeatMode(_that);case SetShuffleMode() when setShuffleMode != null:
return setShuffleMode(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoadAudioPlayerData value)  loadAudioPlayerData,required TResult Function( UpdateMediaItem value)  updateMediaItem,required TResult Function( UpdatePlaybackState value)  updatePlaybackState,required TResult Function( UpdatePositionData value)  updatePositionData,required TResult Function( UpdateQueueState value)  updateQueueState,required TResult Function( UpdateVolume value)  updateVolume,required TResult Function( UpdateSpeed value)  updateSpeed,required TResult Function( PlayAudio value)  playAudio,required TResult Function( PauseAudio value)  pauseAudio,required TResult Function( StopAudio value)  stopAudio,required TResult Function( SkipToNext value)  skipToNext,required TResult Function( SkipToPrevious value)  skipToPrevious,required TResult Function( SeekTo value)  seekTo,required TResult Function( SetVolume value)  setVolume,required TResult Function( SetSpeed value)  setSpeed,required TResult Function( SkipToQueueItem value)  skipToQueueItem,required TResult Function( PlayFromQueue value)  playFromQueue,required TResult Function( UpdateQueue value)  updateQueue,required TResult Function( AddQueueItem value)  addQueueItem,required TResult Function( RemoveQueueItem value)  removeQueueItem,required TResult Function( MoveQueueItem value)  moveQueueItem,required TResult Function( SetRepeatMode value)  setRepeatMode,required TResult Function( SetShuffleMode value)  setShuffleMode,}){
final _that = this;
switch (_that) {
case LoadAudioPlayerData():
return loadAudioPlayerData(_that);case UpdateMediaItem():
return updateMediaItem(_that);case UpdatePlaybackState():
return updatePlaybackState(_that);case UpdatePositionData():
return updatePositionData(_that);case UpdateQueueState():
return updateQueueState(_that);case UpdateVolume():
return updateVolume(_that);case UpdateSpeed():
return updateSpeed(_that);case PlayAudio():
return playAudio(_that);case PauseAudio():
return pauseAudio(_that);case StopAudio():
return stopAudio(_that);case SkipToNext():
return skipToNext(_that);case SkipToPrevious():
return skipToPrevious(_that);case SeekTo():
return seekTo(_that);case SetVolume():
return setVolume(_that);case SetSpeed():
return setSpeed(_that);case SkipToQueueItem():
return skipToQueueItem(_that);case PlayFromQueue():
return playFromQueue(_that);case UpdateQueue():
return updateQueue(_that);case AddQueueItem():
return addQueueItem(_that);case RemoveQueueItem():
return removeQueueItem(_that);case MoveQueueItem():
return moveQueueItem(_that);case SetRepeatMode():
return setRepeatMode(_that);case SetShuffleMode():
return setShuffleMode(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoadAudioPlayerData value)?  loadAudioPlayerData,TResult? Function( UpdateMediaItem value)?  updateMediaItem,TResult? Function( UpdatePlaybackState value)?  updatePlaybackState,TResult? Function( UpdatePositionData value)?  updatePositionData,TResult? Function( UpdateQueueState value)?  updateQueueState,TResult? Function( UpdateVolume value)?  updateVolume,TResult? Function( UpdateSpeed value)?  updateSpeed,TResult? Function( PlayAudio value)?  playAudio,TResult? Function( PauseAudio value)?  pauseAudio,TResult? Function( StopAudio value)?  stopAudio,TResult? Function( SkipToNext value)?  skipToNext,TResult? Function( SkipToPrevious value)?  skipToPrevious,TResult? Function( SeekTo value)?  seekTo,TResult? Function( SetVolume value)?  setVolume,TResult? Function( SetSpeed value)?  setSpeed,TResult? Function( SkipToQueueItem value)?  skipToQueueItem,TResult? Function( PlayFromQueue value)?  playFromQueue,TResult? Function( UpdateQueue value)?  updateQueue,TResult? Function( AddQueueItem value)?  addQueueItem,TResult? Function( RemoveQueueItem value)?  removeQueueItem,TResult? Function( MoveQueueItem value)?  moveQueueItem,TResult? Function( SetRepeatMode value)?  setRepeatMode,TResult? Function( SetShuffleMode value)?  setShuffleMode,}){
final _that = this;
switch (_that) {
case LoadAudioPlayerData() when loadAudioPlayerData != null:
return loadAudioPlayerData(_that);case UpdateMediaItem() when updateMediaItem != null:
return updateMediaItem(_that);case UpdatePlaybackState() when updatePlaybackState != null:
return updatePlaybackState(_that);case UpdatePositionData() when updatePositionData != null:
return updatePositionData(_that);case UpdateQueueState() when updateQueueState != null:
return updateQueueState(_that);case UpdateVolume() when updateVolume != null:
return updateVolume(_that);case UpdateSpeed() when updateSpeed != null:
return updateSpeed(_that);case PlayAudio() when playAudio != null:
return playAudio(_that);case PauseAudio() when pauseAudio != null:
return pauseAudio(_that);case StopAudio() when stopAudio != null:
return stopAudio(_that);case SkipToNext() when skipToNext != null:
return skipToNext(_that);case SkipToPrevious() when skipToPrevious != null:
return skipToPrevious(_that);case SeekTo() when seekTo != null:
return seekTo(_that);case SetVolume() when setVolume != null:
return setVolume(_that);case SetSpeed() when setSpeed != null:
return setSpeed(_that);case SkipToQueueItem() when skipToQueueItem != null:
return skipToQueueItem(_that);case PlayFromQueue() when playFromQueue != null:
return playFromQueue(_that);case UpdateQueue() when updateQueue != null:
return updateQueue(_that);case AddQueueItem() when addQueueItem != null:
return addQueueItem(_that);case RemoveQueueItem() when removeQueueItem != null:
return removeQueueItem(_that);case MoveQueueItem() when moveQueueItem != null:
return moveQueueItem(_that);case SetRepeatMode() when setRepeatMode != null:
return setRepeatMode(_that);case SetShuffleMode() when setShuffleMode != null:
return setShuffleMode(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadAudioPlayerData,TResult Function( MediaItem? mediaItem)?  updateMediaItem,TResult Function( PlaybackState playbackState)?  updatePlaybackState,TResult Function( PositionData positionData)?  updatePositionData,TResult Function( QueueState queueState)?  updateQueueState,TResult Function( double volume)?  updateVolume,TResult Function( double speed)?  updateSpeed,TResult Function()?  playAudio,TResult Function()?  pauseAudio,TResult Function()?  stopAudio,TResult Function()?  skipToNext,TResult Function()?  skipToPrevious,TResult Function( Duration position)?  seekTo,TResult Function( double volume)?  setVolume,TResult Function( double speed)?  setSpeed,TResult Function( int index)?  skipToQueueItem,TResult Function( List<MediaItem> queue,  int index)?  playFromQueue,TResult Function( List<MediaItem> queue)?  updateQueue,TResult Function( MediaItem item)?  addQueueItem,TResult Function( MediaItem item)?  removeQueueItem,TResult Function( int currentIndex,  int newIndex)?  moveQueueItem,TResult Function( AudioServiceRepeatMode repeatMode)?  setRepeatMode,TResult Function( AudioServiceShuffleMode shuffleMode)?  setShuffleMode,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoadAudioPlayerData() when loadAudioPlayerData != null:
return loadAudioPlayerData();case UpdateMediaItem() when updateMediaItem != null:
return updateMediaItem(_that.mediaItem);case UpdatePlaybackState() when updatePlaybackState != null:
return updatePlaybackState(_that.playbackState);case UpdatePositionData() when updatePositionData != null:
return updatePositionData(_that.positionData);case UpdateQueueState() when updateQueueState != null:
return updateQueueState(_that.queueState);case UpdateVolume() when updateVolume != null:
return updateVolume(_that.volume);case UpdateSpeed() when updateSpeed != null:
return updateSpeed(_that.speed);case PlayAudio() when playAudio != null:
return playAudio();case PauseAudio() when pauseAudio != null:
return pauseAudio();case StopAudio() when stopAudio != null:
return stopAudio();case SkipToNext() when skipToNext != null:
return skipToNext();case SkipToPrevious() when skipToPrevious != null:
return skipToPrevious();case SeekTo() when seekTo != null:
return seekTo(_that.position);case SetVolume() when setVolume != null:
return setVolume(_that.volume);case SetSpeed() when setSpeed != null:
return setSpeed(_that.speed);case SkipToQueueItem() when skipToQueueItem != null:
return skipToQueueItem(_that.index);case PlayFromQueue() when playFromQueue != null:
return playFromQueue(_that.queue,_that.index);case UpdateQueue() when updateQueue != null:
return updateQueue(_that.queue);case AddQueueItem() when addQueueItem != null:
return addQueueItem(_that.item);case RemoveQueueItem() when removeQueueItem != null:
return removeQueueItem(_that.item);case MoveQueueItem() when moveQueueItem != null:
return moveQueueItem(_that.currentIndex,_that.newIndex);case SetRepeatMode() when setRepeatMode != null:
return setRepeatMode(_that.repeatMode);case SetShuffleMode() when setShuffleMode != null:
return setShuffleMode(_that.shuffleMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadAudioPlayerData,required TResult Function( MediaItem? mediaItem)  updateMediaItem,required TResult Function( PlaybackState playbackState)  updatePlaybackState,required TResult Function( PositionData positionData)  updatePositionData,required TResult Function( QueueState queueState)  updateQueueState,required TResult Function( double volume)  updateVolume,required TResult Function( double speed)  updateSpeed,required TResult Function()  playAudio,required TResult Function()  pauseAudio,required TResult Function()  stopAudio,required TResult Function()  skipToNext,required TResult Function()  skipToPrevious,required TResult Function( Duration position)  seekTo,required TResult Function( double volume)  setVolume,required TResult Function( double speed)  setSpeed,required TResult Function( int index)  skipToQueueItem,required TResult Function( List<MediaItem> queue,  int index)  playFromQueue,required TResult Function( List<MediaItem> queue)  updateQueue,required TResult Function( MediaItem item)  addQueueItem,required TResult Function( MediaItem item)  removeQueueItem,required TResult Function( int currentIndex,  int newIndex)  moveQueueItem,required TResult Function( AudioServiceRepeatMode repeatMode)  setRepeatMode,required TResult Function( AudioServiceShuffleMode shuffleMode)  setShuffleMode,}) {final _that = this;
switch (_that) {
case LoadAudioPlayerData():
return loadAudioPlayerData();case UpdateMediaItem():
return updateMediaItem(_that.mediaItem);case UpdatePlaybackState():
return updatePlaybackState(_that.playbackState);case UpdatePositionData():
return updatePositionData(_that.positionData);case UpdateQueueState():
return updateQueueState(_that.queueState);case UpdateVolume():
return updateVolume(_that.volume);case UpdateSpeed():
return updateSpeed(_that.speed);case PlayAudio():
return playAudio();case PauseAudio():
return pauseAudio();case StopAudio():
return stopAudio();case SkipToNext():
return skipToNext();case SkipToPrevious():
return skipToPrevious();case SeekTo():
return seekTo(_that.position);case SetVolume():
return setVolume(_that.volume);case SetSpeed():
return setSpeed(_that.speed);case SkipToQueueItem():
return skipToQueueItem(_that.index);case PlayFromQueue():
return playFromQueue(_that.queue,_that.index);case UpdateQueue():
return updateQueue(_that.queue);case AddQueueItem():
return addQueueItem(_that.item);case RemoveQueueItem():
return removeQueueItem(_that.item);case MoveQueueItem():
return moveQueueItem(_that.currentIndex,_that.newIndex);case SetRepeatMode():
return setRepeatMode(_that.repeatMode);case SetShuffleMode():
return setShuffleMode(_that.shuffleMode);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadAudioPlayerData,TResult? Function( MediaItem? mediaItem)?  updateMediaItem,TResult? Function( PlaybackState playbackState)?  updatePlaybackState,TResult? Function( PositionData positionData)?  updatePositionData,TResult? Function( QueueState queueState)?  updateQueueState,TResult? Function( double volume)?  updateVolume,TResult? Function( double speed)?  updateSpeed,TResult? Function()?  playAudio,TResult? Function()?  pauseAudio,TResult? Function()?  stopAudio,TResult? Function()?  skipToNext,TResult? Function()?  skipToPrevious,TResult? Function( Duration position)?  seekTo,TResult? Function( double volume)?  setVolume,TResult? Function( double speed)?  setSpeed,TResult? Function( int index)?  skipToQueueItem,TResult? Function( List<MediaItem> queue,  int index)?  playFromQueue,TResult? Function( List<MediaItem> queue)?  updateQueue,TResult? Function( MediaItem item)?  addQueueItem,TResult? Function( MediaItem item)?  removeQueueItem,TResult? Function( int currentIndex,  int newIndex)?  moveQueueItem,TResult? Function( AudioServiceRepeatMode repeatMode)?  setRepeatMode,TResult? Function( AudioServiceShuffleMode shuffleMode)?  setShuffleMode,}) {final _that = this;
switch (_that) {
case LoadAudioPlayerData() when loadAudioPlayerData != null:
return loadAudioPlayerData();case UpdateMediaItem() when updateMediaItem != null:
return updateMediaItem(_that.mediaItem);case UpdatePlaybackState() when updatePlaybackState != null:
return updatePlaybackState(_that.playbackState);case UpdatePositionData() when updatePositionData != null:
return updatePositionData(_that.positionData);case UpdateQueueState() when updateQueueState != null:
return updateQueueState(_that.queueState);case UpdateVolume() when updateVolume != null:
return updateVolume(_that.volume);case UpdateSpeed() when updateSpeed != null:
return updateSpeed(_that.speed);case PlayAudio() when playAudio != null:
return playAudio();case PauseAudio() when pauseAudio != null:
return pauseAudio();case StopAudio() when stopAudio != null:
return stopAudio();case SkipToNext() when skipToNext != null:
return skipToNext();case SkipToPrevious() when skipToPrevious != null:
return skipToPrevious();case SeekTo() when seekTo != null:
return seekTo(_that.position);case SetVolume() when setVolume != null:
return setVolume(_that.volume);case SetSpeed() when setSpeed != null:
return setSpeed(_that.speed);case SkipToQueueItem() when skipToQueueItem != null:
return skipToQueueItem(_that.index);case PlayFromQueue() when playFromQueue != null:
return playFromQueue(_that.queue,_that.index);case UpdateQueue() when updateQueue != null:
return updateQueue(_that.queue);case AddQueueItem() when addQueueItem != null:
return addQueueItem(_that.item);case RemoveQueueItem() when removeQueueItem != null:
return removeQueueItem(_that.item);case MoveQueueItem() when moveQueueItem != null:
return moveQueueItem(_that.currentIndex,_that.newIndex);case SetRepeatMode() when setRepeatMode != null:
return setRepeatMode(_that.repeatMode);case SetShuffleMode() when setShuffleMode != null:
return setShuffleMode(_that.shuffleMode);case _:
  return null;

}
}

}

/// @nodoc


class LoadAudioPlayerData implements AudioPlayerEvent {
  const LoadAudioPlayerData();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadAudioPlayerData);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AudioPlayerEvent.loadAudioPlayerData()';
}


}




/// @nodoc


class UpdateMediaItem implements AudioPlayerEvent {
  const UpdateMediaItem(this.mediaItem);
  

 final  MediaItem? mediaItem;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateMediaItemCopyWith<UpdateMediaItem> get copyWith => _$UpdateMediaItemCopyWithImpl<UpdateMediaItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateMediaItem&&(identical(other.mediaItem, mediaItem) || other.mediaItem == mediaItem));
}


@override
int get hashCode => Object.hash(runtimeType,mediaItem);

@override
String toString() {
  return 'AudioPlayerEvent.updateMediaItem(mediaItem: $mediaItem)';
}


}

/// @nodoc
abstract mixin class $UpdateMediaItemCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdateMediaItemCopyWith(UpdateMediaItem value, $Res Function(UpdateMediaItem) _then) = _$UpdateMediaItemCopyWithImpl;
@useResult
$Res call({
 MediaItem? mediaItem
});




}
/// @nodoc
class _$UpdateMediaItemCopyWithImpl<$Res>
    implements $UpdateMediaItemCopyWith<$Res> {
  _$UpdateMediaItemCopyWithImpl(this._self, this._then);

  final UpdateMediaItem _self;
  final $Res Function(UpdateMediaItem) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mediaItem = freezed,}) {
  return _then(UpdateMediaItem(
freezed == mediaItem ? _self.mediaItem : mediaItem // ignore: cast_nullable_to_non_nullable
as MediaItem?,
  ));
}


}

/// @nodoc


class UpdatePlaybackState implements AudioPlayerEvent {
  const UpdatePlaybackState(this.playbackState);
  

 final  PlaybackState playbackState;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdatePlaybackStateCopyWith<UpdatePlaybackState> get copyWith => _$UpdatePlaybackStateCopyWithImpl<UpdatePlaybackState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdatePlaybackState&&(identical(other.playbackState, playbackState) || other.playbackState == playbackState));
}


@override
int get hashCode => Object.hash(runtimeType,playbackState);

@override
String toString() {
  return 'AudioPlayerEvent.updatePlaybackState(playbackState: $playbackState)';
}


}

/// @nodoc
abstract mixin class $UpdatePlaybackStateCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdatePlaybackStateCopyWith(UpdatePlaybackState value, $Res Function(UpdatePlaybackState) _then) = _$UpdatePlaybackStateCopyWithImpl;
@useResult
$Res call({
 PlaybackState playbackState
});




}
/// @nodoc
class _$UpdatePlaybackStateCopyWithImpl<$Res>
    implements $UpdatePlaybackStateCopyWith<$Res> {
  _$UpdatePlaybackStateCopyWithImpl(this._self, this._then);

  final UpdatePlaybackState _self;
  final $Res Function(UpdatePlaybackState) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playbackState = null,}) {
  return _then(UpdatePlaybackState(
null == playbackState ? _self.playbackState : playbackState // ignore: cast_nullable_to_non_nullable
as PlaybackState,
  ));
}


}

/// @nodoc


class UpdatePositionData implements AudioPlayerEvent {
  const UpdatePositionData(this.positionData);
  

 final  PositionData positionData;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdatePositionDataCopyWith<UpdatePositionData> get copyWith => _$UpdatePositionDataCopyWithImpl<UpdatePositionData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdatePositionData&&(identical(other.positionData, positionData) || other.positionData == positionData));
}


@override
int get hashCode => Object.hash(runtimeType,positionData);

@override
String toString() {
  return 'AudioPlayerEvent.updatePositionData(positionData: $positionData)';
}


}

/// @nodoc
abstract mixin class $UpdatePositionDataCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdatePositionDataCopyWith(UpdatePositionData value, $Res Function(UpdatePositionData) _then) = _$UpdatePositionDataCopyWithImpl;
@useResult
$Res call({
 PositionData positionData
});


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
@pragma('vm:prefer-inline') $Res call({Object? positionData = null,}) {
  return _then(UpdatePositionData(
null == positionData ? _self.positionData : positionData // ignore: cast_nullable_to_non_nullable
as PositionData,
  ));
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


class UpdateQueueState implements AudioPlayerEvent {
  const UpdateQueueState(this.queueState);
  

 final  QueueState queueState;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateQueueStateCopyWith<UpdateQueueState> get copyWith => _$UpdateQueueStateCopyWithImpl<UpdateQueueState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateQueueState&&(identical(other.queueState, queueState) || other.queueState == queueState));
}


@override
int get hashCode => Object.hash(runtimeType,queueState);

@override
String toString() {
  return 'AudioPlayerEvent.updateQueueState(queueState: $queueState)';
}


}

/// @nodoc
abstract mixin class $UpdateQueueStateCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdateQueueStateCopyWith(UpdateQueueState value, $Res Function(UpdateQueueState) _then) = _$UpdateQueueStateCopyWithImpl;
@useResult
$Res call({
 QueueState queueState
});


$QueueStateCopyWith<$Res> get queueState;

}
/// @nodoc
class _$UpdateQueueStateCopyWithImpl<$Res>
    implements $UpdateQueueStateCopyWith<$Res> {
  _$UpdateQueueStateCopyWithImpl(this._self, this._then);

  final UpdateQueueState _self;
  final $Res Function(UpdateQueueState) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? queueState = null,}) {
  return _then(UpdateQueueState(
null == queueState ? _self.queueState : queueState // ignore: cast_nullable_to_non_nullable
as QueueState,
  ));
}

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueueStateCopyWith<$Res> get queueState {
  
  return $QueueStateCopyWith<$Res>(_self.queueState, (value) {
    return _then(_self.copyWith(queueState: value));
  });
}
}

/// @nodoc


class UpdateVolume implements AudioPlayerEvent {
  const UpdateVolume(this.volume);
  

 final  double volume;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateVolumeCopyWith<UpdateVolume> get copyWith => _$UpdateVolumeCopyWithImpl<UpdateVolume>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateVolume&&(identical(other.volume, volume) || other.volume == volume));
}


@override
int get hashCode => Object.hash(runtimeType,volume);

@override
String toString() {
  return 'AudioPlayerEvent.updateVolume(volume: $volume)';
}


}

/// @nodoc
abstract mixin class $UpdateVolumeCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdateVolumeCopyWith(UpdateVolume value, $Res Function(UpdateVolume) _then) = _$UpdateVolumeCopyWithImpl;
@useResult
$Res call({
 double volume
});




}
/// @nodoc
class _$UpdateVolumeCopyWithImpl<$Res>
    implements $UpdateVolumeCopyWith<$Res> {
  _$UpdateVolumeCopyWithImpl(this._self, this._then);

  final UpdateVolume _self;
  final $Res Function(UpdateVolume) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? volume = null,}) {
  return _then(UpdateVolume(
null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class UpdateSpeed implements AudioPlayerEvent {
  const UpdateSpeed(this.speed);
  

 final  double speed;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateSpeedCopyWith<UpdateSpeed> get copyWith => _$UpdateSpeedCopyWithImpl<UpdateSpeed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateSpeed&&(identical(other.speed, speed) || other.speed == speed));
}


@override
int get hashCode => Object.hash(runtimeType,speed);

@override
String toString() {
  return 'AudioPlayerEvent.updateSpeed(speed: $speed)';
}


}

/// @nodoc
abstract mixin class $UpdateSpeedCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdateSpeedCopyWith(UpdateSpeed value, $Res Function(UpdateSpeed) _then) = _$UpdateSpeedCopyWithImpl;
@useResult
$Res call({
 double speed
});




}
/// @nodoc
class _$UpdateSpeedCopyWithImpl<$Res>
    implements $UpdateSpeedCopyWith<$Res> {
  _$UpdateSpeedCopyWithImpl(this._self, this._then);

  final UpdateSpeed _self;
  final $Res Function(UpdateSpeed) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? speed = null,}) {
  return _then(UpdateSpeed(
null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class PlayAudio implements AudioPlayerEvent {
  const PlayAudio();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayAudio);
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PauseAudio);
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StopAudio);
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkipToNext);
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkipToPrevious);
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
  

 final  Duration position;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeekToCopyWith<SeekTo> get copyWith => _$SeekToCopyWithImpl<SeekTo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeekTo&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,position);

@override
String toString() {
  return 'AudioPlayerEvent.seekTo(position: $position)';
}


}

/// @nodoc
abstract mixin class $SeekToCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $SeekToCopyWith(SeekTo value, $Res Function(SeekTo) _then) = _$SeekToCopyWithImpl;
@useResult
$Res call({
 Duration position
});




}
/// @nodoc
class _$SeekToCopyWithImpl<$Res>
    implements $SeekToCopyWith<$Res> {
  _$SeekToCopyWithImpl(this._self, this._then);

  final SeekTo _self;
  final $Res Function(SeekTo) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? position = null,}) {
  return _then(SeekTo(
null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc


class SetVolume implements AudioPlayerEvent {
  const SetVolume(this.volume);
  

 final  double volume;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetVolumeCopyWith<SetVolume> get copyWith => _$SetVolumeCopyWithImpl<SetVolume>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetVolume&&(identical(other.volume, volume) || other.volume == volume));
}


@override
int get hashCode => Object.hash(runtimeType,volume);

@override
String toString() {
  return 'AudioPlayerEvent.setVolume(volume: $volume)';
}


}

/// @nodoc
abstract mixin class $SetVolumeCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $SetVolumeCopyWith(SetVolume value, $Res Function(SetVolume) _then) = _$SetVolumeCopyWithImpl;
@useResult
$Res call({
 double volume
});




}
/// @nodoc
class _$SetVolumeCopyWithImpl<$Res>
    implements $SetVolumeCopyWith<$Res> {
  _$SetVolumeCopyWithImpl(this._self, this._then);

  final SetVolume _self;
  final $Res Function(SetVolume) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? volume = null,}) {
  return _then(SetVolume(
null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class SetSpeed implements AudioPlayerEvent {
  const SetSpeed(this.speed);
  

 final  double speed;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetSpeedCopyWith<SetSpeed> get copyWith => _$SetSpeedCopyWithImpl<SetSpeed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetSpeed&&(identical(other.speed, speed) || other.speed == speed));
}


@override
int get hashCode => Object.hash(runtimeType,speed);

@override
String toString() {
  return 'AudioPlayerEvent.setSpeed(speed: $speed)';
}


}

/// @nodoc
abstract mixin class $SetSpeedCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $SetSpeedCopyWith(SetSpeed value, $Res Function(SetSpeed) _then) = _$SetSpeedCopyWithImpl;
@useResult
$Res call({
 double speed
});




}
/// @nodoc
class _$SetSpeedCopyWithImpl<$Res>
    implements $SetSpeedCopyWith<$Res> {
  _$SetSpeedCopyWithImpl(this._self, this._then);

  final SetSpeed _self;
  final $Res Function(SetSpeed) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? speed = null,}) {
  return _then(SetSpeed(
null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class SkipToQueueItem implements AudioPlayerEvent {
  const SkipToQueueItem(this.index);
  

 final  int index;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkipToQueueItemCopyWith<SkipToQueueItem> get copyWith => _$SkipToQueueItemCopyWithImpl<SkipToQueueItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkipToQueueItem&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode => Object.hash(runtimeType,index);

@override
String toString() {
  return 'AudioPlayerEvent.skipToQueueItem(index: $index)';
}


}

/// @nodoc
abstract mixin class $SkipToQueueItemCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $SkipToQueueItemCopyWith(SkipToQueueItem value, $Res Function(SkipToQueueItem) _then) = _$SkipToQueueItemCopyWithImpl;
@useResult
$Res call({
 int index
});




}
/// @nodoc
class _$SkipToQueueItemCopyWithImpl<$Res>
    implements $SkipToQueueItemCopyWith<$Res> {
  _$SkipToQueueItemCopyWithImpl(this._self, this._then);

  final SkipToQueueItem _self;
  final $Res Function(SkipToQueueItem) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,}) {
  return _then(SkipToQueueItem(
null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class PlayFromQueue implements AudioPlayerEvent {
  const PlayFromQueue(final  List<MediaItem> queue, this.index): _queue = queue;
  

 final  List<MediaItem> _queue;
 List<MediaItem> get queue {
  if (_queue is EqualUnmodifiableListView) return _queue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queue);
}

 final  int index;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayFromQueueCopyWith<PlayFromQueue> get copyWith => _$PlayFromQueueCopyWithImpl<PlayFromQueue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayFromQueue&&const DeepCollectionEquality().equals(other._queue, _queue)&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_queue),index);

@override
String toString() {
  return 'AudioPlayerEvent.playFromQueue(queue: $queue, index: $index)';
}


}

/// @nodoc
abstract mixin class $PlayFromQueueCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $PlayFromQueueCopyWith(PlayFromQueue value, $Res Function(PlayFromQueue) _then) = _$PlayFromQueueCopyWithImpl;
@useResult
$Res call({
 List<MediaItem> queue, int index
});




}
/// @nodoc
class _$PlayFromQueueCopyWithImpl<$Res>
    implements $PlayFromQueueCopyWith<$Res> {
  _$PlayFromQueueCopyWithImpl(this._self, this._then);

  final PlayFromQueue _self;
  final $Res Function(PlayFromQueue) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? queue = null,Object? index = null,}) {
  return _then(PlayFromQueue(
null == queue ? _self._queue : queue // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class UpdateQueue implements AudioPlayerEvent {
  const UpdateQueue(final  List<MediaItem> queue): _queue = queue;
  

 final  List<MediaItem> _queue;
 List<MediaItem> get queue {
  if (_queue is EqualUnmodifiableListView) return _queue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queue);
}


/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateQueueCopyWith<UpdateQueue> get copyWith => _$UpdateQueueCopyWithImpl<UpdateQueue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateQueue&&const DeepCollectionEquality().equals(other._queue, _queue));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_queue));

@override
String toString() {
  return 'AudioPlayerEvent.updateQueue(queue: $queue)';
}


}

/// @nodoc
abstract mixin class $UpdateQueueCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $UpdateQueueCopyWith(UpdateQueue value, $Res Function(UpdateQueue) _then) = _$UpdateQueueCopyWithImpl;
@useResult
$Res call({
 List<MediaItem> queue
});




}
/// @nodoc
class _$UpdateQueueCopyWithImpl<$Res>
    implements $UpdateQueueCopyWith<$Res> {
  _$UpdateQueueCopyWithImpl(this._self, this._then);

  final UpdateQueue _self;
  final $Res Function(UpdateQueue) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? queue = null,}) {
  return _then(UpdateQueue(
null == queue ? _self._queue : queue // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,
  ));
}


}

/// @nodoc


class AddQueueItem implements AudioPlayerEvent {
  const AddQueueItem(this.item);
  

 final  MediaItem item;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddQueueItemCopyWith<AddQueueItem> get copyWith => _$AddQueueItemCopyWithImpl<AddQueueItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddQueueItem&&(identical(other.item, item) || other.item == item));
}


@override
int get hashCode => Object.hash(runtimeType,item);

@override
String toString() {
  return 'AudioPlayerEvent.addQueueItem(item: $item)';
}


}

/// @nodoc
abstract mixin class $AddQueueItemCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $AddQueueItemCopyWith(AddQueueItem value, $Res Function(AddQueueItem) _then) = _$AddQueueItemCopyWithImpl;
@useResult
$Res call({
 MediaItem item
});




}
/// @nodoc
class _$AddQueueItemCopyWithImpl<$Res>
    implements $AddQueueItemCopyWith<$Res> {
  _$AddQueueItemCopyWithImpl(this._self, this._then);

  final AddQueueItem _self;
  final $Res Function(AddQueueItem) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? item = null,}) {
  return _then(AddQueueItem(
null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as MediaItem,
  ));
}


}

/// @nodoc


class RemoveQueueItem implements AudioPlayerEvent {
  const RemoveQueueItem(this.item);
  

 final  MediaItem item;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoveQueueItemCopyWith<RemoveQueueItem> get copyWith => _$RemoveQueueItemCopyWithImpl<RemoveQueueItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoveQueueItem&&(identical(other.item, item) || other.item == item));
}


@override
int get hashCode => Object.hash(runtimeType,item);

@override
String toString() {
  return 'AudioPlayerEvent.removeQueueItem(item: $item)';
}


}

/// @nodoc
abstract mixin class $RemoveQueueItemCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $RemoveQueueItemCopyWith(RemoveQueueItem value, $Res Function(RemoveQueueItem) _then) = _$RemoveQueueItemCopyWithImpl;
@useResult
$Res call({
 MediaItem item
});




}
/// @nodoc
class _$RemoveQueueItemCopyWithImpl<$Res>
    implements $RemoveQueueItemCopyWith<$Res> {
  _$RemoveQueueItemCopyWithImpl(this._self, this._then);

  final RemoveQueueItem _self;
  final $Res Function(RemoveQueueItem) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? item = null,}) {
  return _then(RemoveQueueItem(
null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as MediaItem,
  ));
}


}

/// @nodoc


class MoveQueueItem implements AudioPlayerEvent {
  const MoveQueueItem(this.currentIndex, this.newIndex);
  

 final  int currentIndex;
 final  int newIndex;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoveQueueItemCopyWith<MoveQueueItem> get copyWith => _$MoveQueueItemCopyWithImpl<MoveQueueItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoveQueueItem&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.newIndex, newIndex) || other.newIndex == newIndex));
}


@override
int get hashCode => Object.hash(runtimeType,currentIndex,newIndex);

@override
String toString() {
  return 'AudioPlayerEvent.moveQueueItem(currentIndex: $currentIndex, newIndex: $newIndex)';
}


}

/// @nodoc
abstract mixin class $MoveQueueItemCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $MoveQueueItemCopyWith(MoveQueueItem value, $Res Function(MoveQueueItem) _then) = _$MoveQueueItemCopyWithImpl;
@useResult
$Res call({
 int currentIndex, int newIndex
});




}
/// @nodoc
class _$MoveQueueItemCopyWithImpl<$Res>
    implements $MoveQueueItemCopyWith<$Res> {
  _$MoveQueueItemCopyWithImpl(this._self, this._then);

  final MoveQueueItem _self;
  final $Res Function(MoveQueueItem) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? currentIndex = null,Object? newIndex = null,}) {
  return _then(MoveQueueItem(
null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,null == newIndex ? _self.newIndex : newIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SetRepeatMode implements AudioPlayerEvent {
  const SetRepeatMode(this.repeatMode);
  

 final  AudioServiceRepeatMode repeatMode;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetRepeatModeCopyWith<SetRepeatMode> get copyWith => _$SetRepeatModeCopyWithImpl<SetRepeatMode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetRepeatMode&&(identical(other.repeatMode, repeatMode) || other.repeatMode == repeatMode));
}


@override
int get hashCode => Object.hash(runtimeType,repeatMode);

@override
String toString() {
  return 'AudioPlayerEvent.setRepeatMode(repeatMode: $repeatMode)';
}


}

/// @nodoc
abstract mixin class $SetRepeatModeCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $SetRepeatModeCopyWith(SetRepeatMode value, $Res Function(SetRepeatMode) _then) = _$SetRepeatModeCopyWithImpl;
@useResult
$Res call({
 AudioServiceRepeatMode repeatMode
});




}
/// @nodoc
class _$SetRepeatModeCopyWithImpl<$Res>
    implements $SetRepeatModeCopyWith<$Res> {
  _$SetRepeatModeCopyWithImpl(this._self, this._then);

  final SetRepeatMode _self;
  final $Res Function(SetRepeatMode) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? repeatMode = null,}) {
  return _then(SetRepeatMode(
null == repeatMode ? _self.repeatMode : repeatMode // ignore: cast_nullable_to_non_nullable
as AudioServiceRepeatMode,
  ));
}


}

/// @nodoc


class SetShuffleMode implements AudioPlayerEvent {
  const SetShuffleMode(this.shuffleMode);
  

 final  AudioServiceShuffleMode shuffleMode;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetShuffleModeCopyWith<SetShuffleMode> get copyWith => _$SetShuffleModeCopyWithImpl<SetShuffleMode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetShuffleMode&&(identical(other.shuffleMode, shuffleMode) || other.shuffleMode == shuffleMode));
}


@override
int get hashCode => Object.hash(runtimeType,shuffleMode);

@override
String toString() {
  return 'AudioPlayerEvent.setShuffleMode(shuffleMode: $shuffleMode)';
}


}

/// @nodoc
abstract mixin class $SetShuffleModeCopyWith<$Res> implements $AudioPlayerEventCopyWith<$Res> {
  factory $SetShuffleModeCopyWith(SetShuffleMode value, $Res Function(SetShuffleMode) _then) = _$SetShuffleModeCopyWithImpl;
@useResult
$Res call({
 AudioServiceShuffleMode shuffleMode
});




}
/// @nodoc
class _$SetShuffleModeCopyWithImpl<$Res>
    implements $SetShuffleModeCopyWith<$Res> {
  _$SetShuffleModeCopyWithImpl(this._self, this._then);

  final SetShuffleMode _self;
  final $Res Function(SetShuffleMode) _then;

/// Create a copy of AudioPlayerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shuffleMode = null,}) {
  return _then(SetShuffleMode(
null == shuffleMode ? _self.shuffleMode : shuffleMode // ignore: cast_nullable_to_non_nullable
as AudioServiceShuffleMode,
  ));
}


}

/// @nodoc
mixin _$AudioPlayerState {

 MediaItem? get mediaItem; PlaybackState? get playbackState; PositionData? get positionData; QueueState? get queueState; double get volume; double get speed; AudioPlayerStatus get status;
/// Create a copy of AudioPlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioPlayerStateCopyWith<AudioPlayerState> get copyWith => _$AudioPlayerStateCopyWithImpl<AudioPlayerState>(this as AudioPlayerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioPlayerState&&(identical(other.mediaItem, mediaItem) || other.mediaItem == mediaItem)&&(identical(other.playbackState, playbackState) || other.playbackState == playbackState)&&(identical(other.positionData, positionData) || other.positionData == positionData)&&(identical(other.queueState, queueState) || other.queueState == queueState)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,mediaItem,playbackState,positionData,queueState,volume,speed,status);

@override
String toString() {
  return 'AudioPlayerState(mediaItem: $mediaItem, playbackState: $playbackState, positionData: $positionData, queueState: $queueState, volume: $volume, speed: $speed, status: $status)';
}


}

/// @nodoc
abstract mixin class $AudioPlayerStateCopyWith<$Res>  {
  factory $AudioPlayerStateCopyWith(AudioPlayerState value, $Res Function(AudioPlayerState) _then) = _$AudioPlayerStateCopyWithImpl;
@useResult
$Res call({
 MediaItem? mediaItem, PlaybackState? playbackState, PositionData? positionData, QueueState? queueState, double volume, double speed, AudioPlayerStatus status
});


$PositionDataCopyWith<$Res>? get positionData;$QueueStateCopyWith<$Res>? get queueState;

}
/// @nodoc
class _$AudioPlayerStateCopyWithImpl<$Res>
    implements $AudioPlayerStateCopyWith<$Res> {
  _$AudioPlayerStateCopyWithImpl(this._self, this._then);

  final AudioPlayerState _self;
  final $Res Function(AudioPlayerState) _then;

/// Create a copy of AudioPlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mediaItem = freezed,Object? playbackState = freezed,Object? positionData = freezed,Object? queueState = freezed,Object? volume = null,Object? speed = null,Object? status = null,}) {
  return _then(_self.copyWith(
mediaItem: freezed == mediaItem ? _self.mediaItem : mediaItem // ignore: cast_nullable_to_non_nullable
as MediaItem?,playbackState: freezed == playbackState ? _self.playbackState : playbackState // ignore: cast_nullable_to_non_nullable
as PlaybackState?,positionData: freezed == positionData ? _self.positionData : positionData // ignore: cast_nullable_to_non_nullable
as PositionData?,queueState: freezed == queueState ? _self.queueState : queueState // ignore: cast_nullable_to_non_nullable
as QueueState?,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AudioPlayerStatus,
  ));
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
}/// Create a copy of AudioPlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueueStateCopyWith<$Res>? get queueState {
    if (_self.queueState == null) {
    return null;
  }

  return $QueueStateCopyWith<$Res>(_self.queueState!, (value) {
    return _then(_self.copyWith(queueState: value));
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioPlayerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioPlayerState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioPlayerState value)  $default,){
final _that = this;
switch (_that) {
case _AudioPlayerState():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioPlayerState value)?  $default,){
final _that = this;
switch (_that) {
case _AudioPlayerState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MediaItem? mediaItem,  PlaybackState? playbackState,  PositionData? positionData,  QueueState? queueState,  double volume,  double speed,  AudioPlayerStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioPlayerState() when $default != null:
return $default(_that.mediaItem,_that.playbackState,_that.positionData,_that.queueState,_that.volume,_that.speed,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MediaItem? mediaItem,  PlaybackState? playbackState,  PositionData? positionData,  QueueState? queueState,  double volume,  double speed,  AudioPlayerStatus status)  $default,) {final _that = this;
switch (_that) {
case _AudioPlayerState():
return $default(_that.mediaItem,_that.playbackState,_that.positionData,_that.queueState,_that.volume,_that.speed,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MediaItem? mediaItem,  PlaybackState? playbackState,  PositionData? positionData,  QueueState? queueState,  double volume,  double speed,  AudioPlayerStatus status)?  $default,) {final _that = this;
switch (_that) {
case _AudioPlayerState() when $default != null:
return $default(_that.mediaItem,_that.playbackState,_that.positionData,_that.queueState,_that.volume,_that.speed,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _AudioPlayerState extends AudioPlayerState {
  const _AudioPlayerState({this.mediaItem, this.playbackState, this.positionData, this.queueState, this.volume = 1.0, this.speed = 1.0, required this.status}): super._();
  

@override final  MediaItem? mediaItem;
@override final  PlaybackState? playbackState;
@override final  PositionData? positionData;
@override final  QueueState? queueState;
@override@JsonKey() final  double volume;
@override@JsonKey() final  double speed;
@override final  AudioPlayerStatus status;

/// Create a copy of AudioPlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioPlayerStateCopyWith<_AudioPlayerState> get copyWith => __$AudioPlayerStateCopyWithImpl<_AudioPlayerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioPlayerState&&(identical(other.mediaItem, mediaItem) || other.mediaItem == mediaItem)&&(identical(other.playbackState, playbackState) || other.playbackState == playbackState)&&(identical(other.positionData, positionData) || other.positionData == positionData)&&(identical(other.queueState, queueState) || other.queueState == queueState)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,mediaItem,playbackState,positionData,queueState,volume,speed,status);

@override
String toString() {
  return 'AudioPlayerState(mediaItem: $mediaItem, playbackState: $playbackState, positionData: $positionData, queueState: $queueState, volume: $volume, speed: $speed, status: $status)';
}


}

/// @nodoc
abstract mixin class _$AudioPlayerStateCopyWith<$Res> implements $AudioPlayerStateCopyWith<$Res> {
  factory _$AudioPlayerStateCopyWith(_AudioPlayerState value, $Res Function(_AudioPlayerState) _then) = __$AudioPlayerStateCopyWithImpl;
@override @useResult
$Res call({
 MediaItem? mediaItem, PlaybackState? playbackState, PositionData? positionData, QueueState? queueState, double volume, double speed, AudioPlayerStatus status
});


@override $PositionDataCopyWith<$Res>? get positionData;@override $QueueStateCopyWith<$Res>? get queueState;

}
/// @nodoc
class __$AudioPlayerStateCopyWithImpl<$Res>
    implements _$AudioPlayerStateCopyWith<$Res> {
  __$AudioPlayerStateCopyWithImpl(this._self, this._then);

  final _AudioPlayerState _self;
  final $Res Function(_AudioPlayerState) _then;

/// Create a copy of AudioPlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mediaItem = freezed,Object? playbackState = freezed,Object? positionData = freezed,Object? queueState = freezed,Object? volume = null,Object? speed = null,Object? status = null,}) {
  return _then(_AudioPlayerState(
mediaItem: freezed == mediaItem ? _self.mediaItem : mediaItem // ignore: cast_nullable_to_non_nullable
as MediaItem?,playbackState: freezed == playbackState ? _self.playbackState : playbackState // ignore: cast_nullable_to_non_nullable
as PlaybackState?,positionData: freezed == positionData ? _self.positionData : positionData // ignore: cast_nullable_to_non_nullable
as PositionData?,queueState: freezed == queueState ? _self.queueState : queueState // ignore: cast_nullable_to_non_nullable
as QueueState?,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AudioPlayerStatus,
  ));
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
}/// Create a copy of AudioPlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueueStateCopyWith<$Res>? get queueState {
    if (_self.queueState == null) {
    return null;
  }

  return $QueueStateCopyWith<$Res>(_self.queueState!, (value) {
    return _then(_self.copyWith(queueState: value));
  });
}
}

// dart format on
