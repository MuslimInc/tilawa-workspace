// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'position_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PositionData {

 Duration get position; Duration get bufferedPosition; Duration get duration;
/// Create a copy of PositionData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionDataCopyWith<PositionData> get copyWith => _$PositionDataCopyWithImpl<PositionData>(this as PositionData, _$identity);

  /// Serializes this PositionData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionData&&(identical(other.position, position) || other.position == position)&&(identical(other.bufferedPosition, bufferedPosition) || other.bufferedPosition == bufferedPosition)&&(identical(other.duration, duration) || other.duration == duration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,bufferedPosition,duration);

@override
String toString() {
  return 'PositionData(position: $position, bufferedPosition: $bufferedPosition, duration: $duration)';
}


}

/// @nodoc
abstract mixin class $PositionDataCopyWith<$Res>  {
  factory $PositionDataCopyWith(PositionData value, $Res Function(PositionData) _then) = _$PositionDataCopyWithImpl;
@useResult
$Res call({
 Duration position, Duration bufferedPosition, Duration duration
});




}
/// @nodoc
class _$PositionDataCopyWithImpl<$Res>
    implements $PositionDataCopyWith<$Res> {
  _$PositionDataCopyWithImpl(this._self, this._then);

  final PositionData _self;
  final $Res Function(PositionData) _then;

/// Create a copy of PositionData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? bufferedPosition = null,Object? duration = null,}) {
  return _then(_self.copyWith(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,bufferedPosition: null == bufferedPosition ? _self.bufferedPosition : bufferedPosition // ignore: cast_nullable_to_non_nullable
as Duration,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [PositionData].
extension PositionDataPatterns on PositionData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PositionData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PositionData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PositionData value)  $default,){
final _that = this;
switch (_that) {
case _PositionData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PositionData value)?  $default,){
final _that = this;
switch (_that) {
case _PositionData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration position,  Duration bufferedPosition,  Duration duration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PositionData() when $default != null:
return $default(_that.position,_that.bufferedPosition,_that.duration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration position,  Duration bufferedPosition,  Duration duration)  $default,) {final _that = this;
switch (_that) {
case _PositionData():
return $default(_that.position,_that.bufferedPosition,_that.duration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration position,  Duration bufferedPosition,  Duration duration)?  $default,) {final _that = this;
switch (_that) {
case _PositionData() when $default != null:
return $default(_that.position,_that.bufferedPosition,_that.duration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PositionData implements PositionData {
  const _PositionData({required this.position, required this.bufferedPosition, required this.duration});
  factory _PositionData.fromJson(Map<String, dynamic> json) => _$PositionDataFromJson(json);

@override final  Duration position;
@override final  Duration bufferedPosition;
@override final  Duration duration;

/// Create a copy of PositionData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionDataCopyWith<_PositionData> get copyWith => __$PositionDataCopyWithImpl<_PositionData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PositionDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PositionData&&(identical(other.position, position) || other.position == position)&&(identical(other.bufferedPosition, bufferedPosition) || other.bufferedPosition == bufferedPosition)&&(identical(other.duration, duration) || other.duration == duration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,bufferedPosition,duration);

@override
String toString() {
  return 'PositionData(position: $position, bufferedPosition: $bufferedPosition, duration: $duration)';
}


}

/// @nodoc
abstract mixin class _$PositionDataCopyWith<$Res> implements $PositionDataCopyWith<$Res> {
  factory _$PositionDataCopyWith(_PositionData value, $Res Function(_PositionData) _then) = __$PositionDataCopyWithImpl;
@override @useResult
$Res call({
 Duration position, Duration bufferedPosition, Duration duration
});




}
/// @nodoc
class __$PositionDataCopyWithImpl<$Res>
    implements _$PositionDataCopyWith<$Res> {
  __$PositionDataCopyWithImpl(this._self, this._then);

  final _PositionData _self;
  final $Res Function(_PositionData) _then;

/// Create a copy of PositionData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? bufferedPosition = null,Object? duration = null,}) {
  return _then(_PositionData(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,bufferedPosition: null == bufferedPosition ? _self.bufferedPosition : bufferedPosition // ignore: cast_nullable_to_non_nullable
as Duration,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

// dart format on
