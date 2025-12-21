// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'surah_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SurahEntity {

@JsonKey(fromJson: MediaItemJson.fromJson, toJson: MediaItemJson.toJson) MediaItem get mediaItem; bool get isDownloaded; bool get isDownloading; double get downloadProgress;// 0.0 to 1.0
 String? get downloadId;
/// Create a copy of SurahEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurahEntityCopyWith<SurahEntity> get copyWith => _$SurahEntityCopyWithImpl<SurahEntity>(this as SurahEntity, _$identity);

  /// Serializes this SurahEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurahEntity&&(identical(other.mediaItem, mediaItem) || other.mediaItem == mediaItem)&&(identical(other.isDownloaded, isDownloaded) || other.isDownloaded == isDownloaded)&&(identical(other.isDownloading, isDownloading) || other.isDownloading == isDownloading)&&(identical(other.downloadProgress, downloadProgress) || other.downloadProgress == downloadProgress)&&(identical(other.downloadId, downloadId) || other.downloadId == downloadId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mediaItem,isDownloaded,isDownloading,downloadProgress,downloadId);

@override
String toString() {
  return 'SurahEntity(mediaItem: $mediaItem, isDownloaded: $isDownloaded, isDownloading: $isDownloading, downloadProgress: $downloadProgress, downloadId: $downloadId)';
}


}

/// @nodoc
abstract mixin class $SurahEntityCopyWith<$Res>  {
  factory $SurahEntityCopyWith(SurahEntity value, $Res Function(SurahEntity) _then) = _$SurahEntityCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: MediaItemJson.fromJson, toJson: MediaItemJson.toJson) MediaItem mediaItem, bool isDownloaded, bool isDownloading, double downloadProgress, String? downloadId
});




}
/// @nodoc
class _$SurahEntityCopyWithImpl<$Res>
    implements $SurahEntityCopyWith<$Res> {
  _$SurahEntityCopyWithImpl(this._self, this._then);

  final SurahEntity _self;
  final $Res Function(SurahEntity) _then;

/// Create a copy of SurahEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mediaItem = null,Object? isDownloaded = null,Object? isDownloading = null,Object? downloadProgress = null,Object? downloadId = freezed,}) {
  return _then(_self.copyWith(
mediaItem: null == mediaItem ? _self.mediaItem : mediaItem // ignore: cast_nullable_to_non_nullable
as MediaItem,isDownloaded: null == isDownloaded ? _self.isDownloaded : isDownloaded // ignore: cast_nullable_to_non_nullable
as bool,isDownloading: null == isDownloading ? _self.isDownloading : isDownloading // ignore: cast_nullable_to_non_nullable
as bool,downloadProgress: null == downloadProgress ? _self.downloadProgress : downloadProgress // ignore: cast_nullable_to_non_nullable
as double,downloadId: freezed == downloadId ? _self.downloadId : downloadId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SurahEntity].
extension SurahEntityPatterns on SurahEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SurahEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SurahEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SurahEntity value)  $default,){
final _that = this;
switch (_that) {
case _SurahEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SurahEntity value)?  $default,){
final _that = this;
switch (_that) {
case _SurahEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: MediaItemJson.fromJson, toJson: MediaItemJson.toJson)  MediaItem mediaItem,  bool isDownloaded,  bool isDownloading,  double downloadProgress,  String? downloadId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SurahEntity() when $default != null:
return $default(_that.mediaItem,_that.isDownloaded,_that.isDownloading,_that.downloadProgress,_that.downloadId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: MediaItemJson.fromJson, toJson: MediaItemJson.toJson)  MediaItem mediaItem,  bool isDownloaded,  bool isDownloading,  double downloadProgress,  String? downloadId)  $default,) {final _that = this;
switch (_that) {
case _SurahEntity():
return $default(_that.mediaItem,_that.isDownloaded,_that.isDownloading,_that.downloadProgress,_that.downloadId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: MediaItemJson.fromJson, toJson: MediaItemJson.toJson)  MediaItem mediaItem,  bool isDownloaded,  bool isDownloading,  double downloadProgress,  String? downloadId)?  $default,) {final _that = this;
switch (_that) {
case _SurahEntity() when $default != null:
return $default(_that.mediaItem,_that.isDownloaded,_that.isDownloading,_that.downloadProgress,_that.downloadId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SurahEntity extends SurahEntity {
  const _SurahEntity({@JsonKey(fromJson: MediaItemJson.fromJson, toJson: MediaItemJson.toJson) required this.mediaItem, this.isDownloaded = false, this.isDownloading = false, this.downloadProgress = 0.0, this.downloadId}): super._();
  factory _SurahEntity.fromJson(Map<String, dynamic> json) => _$SurahEntityFromJson(json);

@override@JsonKey(fromJson: MediaItemJson.fromJson, toJson: MediaItemJson.toJson) final  MediaItem mediaItem;
@override@JsonKey() final  bool isDownloaded;
@override@JsonKey() final  bool isDownloading;
@override@JsonKey() final  double downloadProgress;
// 0.0 to 1.0
@override final  String? downloadId;

/// Create a copy of SurahEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SurahEntityCopyWith<_SurahEntity> get copyWith => __$SurahEntityCopyWithImpl<_SurahEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SurahEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SurahEntity&&(identical(other.mediaItem, mediaItem) || other.mediaItem == mediaItem)&&(identical(other.isDownloaded, isDownloaded) || other.isDownloaded == isDownloaded)&&(identical(other.isDownloading, isDownloading) || other.isDownloading == isDownloading)&&(identical(other.downloadProgress, downloadProgress) || other.downloadProgress == downloadProgress)&&(identical(other.downloadId, downloadId) || other.downloadId == downloadId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mediaItem,isDownloaded,isDownloading,downloadProgress,downloadId);

@override
String toString() {
  return 'SurahEntity(mediaItem: $mediaItem, isDownloaded: $isDownloaded, isDownloading: $isDownloading, downloadProgress: $downloadProgress, downloadId: $downloadId)';
}


}

/// @nodoc
abstract mixin class _$SurahEntityCopyWith<$Res> implements $SurahEntityCopyWith<$Res> {
  factory _$SurahEntityCopyWith(_SurahEntity value, $Res Function(_SurahEntity) _then) = __$SurahEntityCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: MediaItemJson.fromJson, toJson: MediaItemJson.toJson) MediaItem mediaItem, bool isDownloaded, bool isDownloading, double downloadProgress, String? downloadId
});




}
/// @nodoc
class __$SurahEntityCopyWithImpl<$Res>
    implements _$SurahEntityCopyWith<$Res> {
  __$SurahEntityCopyWithImpl(this._self, this._then);

  final _SurahEntity _self;
  final $Res Function(_SurahEntity) _then;

/// Create a copy of SurahEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mediaItem = null,Object? isDownloaded = null,Object? isDownloading = null,Object? downloadProgress = null,Object? downloadId = freezed,}) {
  return _then(_SurahEntity(
mediaItem: null == mediaItem ? _self.mediaItem : mediaItem // ignore: cast_nullable_to_non_nullable
as MediaItem,isDownloaded: null == isDownloaded ? _self.isDownloaded : isDownloaded // ignore: cast_nullable_to_non_nullable
as bool,isDownloading: null == isDownloading ? _self.isDownloading : isDownloading // ignore: cast_nullable_to_non_nullable
as bool,downloadProgress: null == downloadProgress ? _self.downloadProgress : downloadProgress // ignore: cast_nullable_to_non_nullable
as double,downloadId: freezed == downloadId ? _self.downloadId : downloadId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
