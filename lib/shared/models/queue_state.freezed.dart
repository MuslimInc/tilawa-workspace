// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QueueState {

 List<MediaItem> get queue; int? get queueIndex; List<int>? get shuffleIndices; AudioServiceRepeatMode get repeatMode;
/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueStateCopyWith<QueueState> get copyWith => _$QueueStateCopyWithImpl<QueueState>(this as QueueState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueState&&const DeepCollectionEquality().equals(other.queue, queue)&&(identical(other.queueIndex, queueIndex) || other.queueIndex == queueIndex)&&const DeepCollectionEquality().equals(other.shuffleIndices, shuffleIndices)&&(identical(other.repeatMode, repeatMode) || other.repeatMode == repeatMode));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(queue),queueIndex,const DeepCollectionEquality().hash(shuffleIndices),repeatMode);

@override
String toString() {
  return 'QueueState(queue: $queue, queueIndex: $queueIndex, shuffleIndices: $shuffleIndices, repeatMode: $repeatMode)';
}


}

/// @nodoc
abstract mixin class $QueueStateCopyWith<$Res>  {
  factory $QueueStateCopyWith(QueueState value, $Res Function(QueueState) _then) = _$QueueStateCopyWithImpl;
@useResult
$Res call({
 List<MediaItem> queue, int? queueIndex, List<int>? shuffleIndices, AudioServiceRepeatMode repeatMode
});




}
/// @nodoc
class _$QueueStateCopyWithImpl<$Res>
    implements $QueueStateCopyWith<$Res> {
  _$QueueStateCopyWithImpl(this._self, this._then);

  final QueueState _self;
  final $Res Function(QueueState) _then;

/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? queue = null,Object? queueIndex = freezed,Object? shuffleIndices = freezed,Object? repeatMode = null,}) {
  return _then(_self.copyWith(
queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,queueIndex: freezed == queueIndex ? _self.queueIndex : queueIndex // ignore: cast_nullable_to_non_nullable
as int?,shuffleIndices: freezed == shuffleIndices ? _self.shuffleIndices : shuffleIndices // ignore: cast_nullable_to_non_nullable
as List<int>?,repeatMode: null == repeatMode ? _self.repeatMode : repeatMode // ignore: cast_nullable_to_non_nullable
as AudioServiceRepeatMode,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueState].
extension QueueStatePatterns on QueueState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueState value)  $default,){
final _that = this;
switch (_that) {
case _QueueState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueState value)?  $default,){
final _that = this;
switch (_that) {
case _QueueState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MediaItem> queue,  int? queueIndex,  List<int>? shuffleIndices,  AudioServiceRepeatMode repeatMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueState() when $default != null:
return $default(_that.queue,_that.queueIndex,_that.shuffleIndices,_that.repeatMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MediaItem> queue,  int? queueIndex,  List<int>? shuffleIndices,  AudioServiceRepeatMode repeatMode)  $default,) {final _that = this;
switch (_that) {
case _QueueState():
return $default(_that.queue,_that.queueIndex,_that.shuffleIndices,_that.repeatMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MediaItem> queue,  int? queueIndex,  List<int>? shuffleIndices,  AudioServiceRepeatMode repeatMode)?  $default,) {final _that = this;
switch (_that) {
case _QueueState() when $default != null:
return $default(_that.queue,_that.queueIndex,_that.shuffleIndices,_that.repeatMode);case _:
  return null;

}
}

}

/// @nodoc


class _QueueState extends QueueState {
  const _QueueState({required final  List<MediaItem> queue, required this.queueIndex, required final  List<int>? shuffleIndices, required this.repeatMode}): _queue = queue,_shuffleIndices = shuffleIndices,super._();
  

 final  List<MediaItem> _queue;
@override List<MediaItem> get queue {
  if (_queue is EqualUnmodifiableListView) return _queue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queue);
}

@override final  int? queueIndex;
 final  List<int>? _shuffleIndices;
@override List<int>? get shuffleIndices {
  final value = _shuffleIndices;
  if (value == null) return null;
  if (_shuffleIndices is EqualUnmodifiableListView) return _shuffleIndices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  AudioServiceRepeatMode repeatMode;

/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueStateCopyWith<_QueueState> get copyWith => __$QueueStateCopyWithImpl<_QueueState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueState&&const DeepCollectionEquality().equals(other._queue, _queue)&&(identical(other.queueIndex, queueIndex) || other.queueIndex == queueIndex)&&const DeepCollectionEquality().equals(other._shuffleIndices, _shuffleIndices)&&(identical(other.repeatMode, repeatMode) || other.repeatMode == repeatMode));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_queue),queueIndex,const DeepCollectionEquality().hash(_shuffleIndices),repeatMode);

@override
String toString() {
  return 'QueueState(queue: $queue, queueIndex: $queueIndex, shuffleIndices: $shuffleIndices, repeatMode: $repeatMode)';
}


}

/// @nodoc
abstract mixin class _$QueueStateCopyWith<$Res> implements $QueueStateCopyWith<$Res> {
  factory _$QueueStateCopyWith(_QueueState value, $Res Function(_QueueState) _then) = __$QueueStateCopyWithImpl;
@override @useResult
$Res call({
 List<MediaItem> queue, int? queueIndex, List<int>? shuffleIndices, AudioServiceRepeatMode repeatMode
});




}
/// @nodoc
class __$QueueStateCopyWithImpl<$Res>
    implements _$QueueStateCopyWith<$Res> {
  __$QueueStateCopyWithImpl(this._self, this._then);

  final _QueueState _self;
  final $Res Function(_QueueState) _then;

/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? queue = null,Object? queueIndex = freezed,Object? shuffleIndices = freezed,Object? repeatMode = null,}) {
  return _then(_QueueState(
queue: null == queue ? _self._queue : queue // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,queueIndex: freezed == queueIndex ? _self.queueIndex : queueIndex // ignore: cast_nullable_to_non_nullable
as int?,shuffleIndices: freezed == shuffleIndices ? _self._shuffleIndices : shuffleIndices // ignore: cast_nullable_to_non_nullable
as List<int>?,repeatMode: null == repeatMode ? _self.repeatMode : repeatMode // ignore: cast_nullable_to_non_nullable
as AudioServiceRepeatMode,
  ));
}


}

// dart format on
