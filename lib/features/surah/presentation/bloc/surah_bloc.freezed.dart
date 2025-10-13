// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'surah_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SurahEvent {

 String get reciterName;
/// Create a copy of SurahEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurahEventCopyWith<SurahEvent> get copyWith => _$SurahEventCopyWithImpl<SurahEvent>(this as SurahEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurahEvent&&(identical(other.reciterName, reciterName) || other.reciterName == reciterName));
}


@override
int get hashCode => Object.hash(runtimeType,reciterName);

@override
String toString() {
  return 'SurahEvent(reciterName: $reciterName)';
}


}

/// @nodoc
abstract mixin class $SurahEventCopyWith<$Res>  {
  factory $SurahEventCopyWith(SurahEvent value, $Res Function(SurahEvent) _then) = _$SurahEventCopyWithImpl;
@useResult
$Res call({
 String reciterName
});




}
/// @nodoc
class _$SurahEventCopyWithImpl<$Res>
    implements $SurahEventCopyWith<$Res> {
  _$SurahEventCopyWithImpl(this._self, this._then);

  final SurahEvent _self;
  final $Res Function(SurahEvent) _then;

/// Create a copy of SurahEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reciterName = null,}) {
  return _then(_self.copyWith(
reciterName: null == reciterName ? _self.reciterName : reciterName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SurahEvent].
extension SurahEventPatterns on SurahEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoadSurahsForReciter value)?  loadSurahsForReciter,TResult Function( UpdateSurahDownloadStatus value)?  updateSurahDownloadStatus,TResult Function( UpdateSurahDownloadProgress value)?  updateSurahDownloadProgress,TResult Function( CheckSurahDownloadStatus value)?  checkSurahDownloadStatus,TResult Function( RefreshSurahStatus value)?  refreshSurahStatus,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoadSurahsForReciter() when loadSurahsForReciter != null:
return loadSurahsForReciter(_that);case UpdateSurahDownloadStatus() when updateSurahDownloadStatus != null:
return updateSurahDownloadStatus(_that);case UpdateSurahDownloadProgress() when updateSurahDownloadProgress != null:
return updateSurahDownloadProgress(_that);case CheckSurahDownloadStatus() when checkSurahDownloadStatus != null:
return checkSurahDownloadStatus(_that);case RefreshSurahStatus() when refreshSurahStatus != null:
return refreshSurahStatus(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoadSurahsForReciter value)  loadSurahsForReciter,required TResult Function( UpdateSurahDownloadStatus value)  updateSurahDownloadStatus,required TResult Function( UpdateSurahDownloadProgress value)  updateSurahDownloadProgress,required TResult Function( CheckSurahDownloadStatus value)  checkSurahDownloadStatus,required TResult Function( RefreshSurahStatus value)  refreshSurahStatus,}){
final _that = this;
switch (_that) {
case LoadSurahsForReciter():
return loadSurahsForReciter(_that);case UpdateSurahDownloadStatus():
return updateSurahDownloadStatus(_that);case UpdateSurahDownloadProgress():
return updateSurahDownloadProgress(_that);case CheckSurahDownloadStatus():
return checkSurahDownloadStatus(_that);case RefreshSurahStatus():
return refreshSurahStatus(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoadSurahsForReciter value)?  loadSurahsForReciter,TResult? Function( UpdateSurahDownloadStatus value)?  updateSurahDownloadStatus,TResult? Function( UpdateSurahDownloadProgress value)?  updateSurahDownloadProgress,TResult? Function( CheckSurahDownloadStatus value)?  checkSurahDownloadStatus,TResult? Function( RefreshSurahStatus value)?  refreshSurahStatus,}){
final _that = this;
switch (_that) {
case LoadSurahsForReciter() when loadSurahsForReciter != null:
return loadSurahsForReciter(_that);case UpdateSurahDownloadStatus() when updateSurahDownloadStatus != null:
return updateSurahDownloadStatus(_that);case UpdateSurahDownloadProgress() when updateSurahDownloadProgress != null:
return updateSurahDownloadProgress(_that);case CheckSurahDownloadStatus() when checkSurahDownloadStatus != null:
return checkSurahDownloadStatus(_that);case RefreshSurahStatus() when refreshSurahStatus != null:
return refreshSurahStatus(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String reciterName)?  loadSurahsForReciter,TResult Function( String surahId,  String reciterName,  bool isDownloaded)?  updateSurahDownloadStatus,TResult Function( String surahId,  String reciterName,  bool isDownloading,  double progress,  String? downloadId)?  updateSurahDownloadProgress,TResult Function( String surahId,  String reciterName)?  checkSurahDownloadStatus,TResult Function( String surahId,  String reciterName)?  refreshSurahStatus,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoadSurahsForReciter() when loadSurahsForReciter != null:
return loadSurahsForReciter(_that.reciterName);case UpdateSurahDownloadStatus() when updateSurahDownloadStatus != null:
return updateSurahDownloadStatus(_that.surahId,_that.reciterName,_that.isDownloaded);case UpdateSurahDownloadProgress() when updateSurahDownloadProgress != null:
return updateSurahDownloadProgress(_that.surahId,_that.reciterName,_that.isDownloading,_that.progress,_that.downloadId);case CheckSurahDownloadStatus() when checkSurahDownloadStatus != null:
return checkSurahDownloadStatus(_that.surahId,_that.reciterName);case RefreshSurahStatus() when refreshSurahStatus != null:
return refreshSurahStatus(_that.surahId,_that.reciterName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String reciterName)  loadSurahsForReciter,required TResult Function( String surahId,  String reciterName,  bool isDownloaded)  updateSurahDownloadStatus,required TResult Function( String surahId,  String reciterName,  bool isDownloading,  double progress,  String? downloadId)  updateSurahDownloadProgress,required TResult Function( String surahId,  String reciterName)  checkSurahDownloadStatus,required TResult Function( String surahId,  String reciterName)  refreshSurahStatus,}) {final _that = this;
switch (_that) {
case LoadSurahsForReciter():
return loadSurahsForReciter(_that.reciterName);case UpdateSurahDownloadStatus():
return updateSurahDownloadStatus(_that.surahId,_that.reciterName,_that.isDownloaded);case UpdateSurahDownloadProgress():
return updateSurahDownloadProgress(_that.surahId,_that.reciterName,_that.isDownloading,_that.progress,_that.downloadId);case CheckSurahDownloadStatus():
return checkSurahDownloadStatus(_that.surahId,_that.reciterName);case RefreshSurahStatus():
return refreshSurahStatus(_that.surahId,_that.reciterName);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String reciterName)?  loadSurahsForReciter,TResult? Function( String surahId,  String reciterName,  bool isDownloaded)?  updateSurahDownloadStatus,TResult? Function( String surahId,  String reciterName,  bool isDownloading,  double progress,  String? downloadId)?  updateSurahDownloadProgress,TResult? Function( String surahId,  String reciterName)?  checkSurahDownloadStatus,TResult? Function( String surahId,  String reciterName)?  refreshSurahStatus,}) {final _that = this;
switch (_that) {
case LoadSurahsForReciter() when loadSurahsForReciter != null:
return loadSurahsForReciter(_that.reciterName);case UpdateSurahDownloadStatus() when updateSurahDownloadStatus != null:
return updateSurahDownloadStatus(_that.surahId,_that.reciterName,_that.isDownloaded);case UpdateSurahDownloadProgress() when updateSurahDownloadProgress != null:
return updateSurahDownloadProgress(_that.surahId,_that.reciterName,_that.isDownloading,_that.progress,_that.downloadId);case CheckSurahDownloadStatus() when checkSurahDownloadStatus != null:
return checkSurahDownloadStatus(_that.surahId,_that.reciterName);case RefreshSurahStatus() when refreshSurahStatus != null:
return refreshSurahStatus(_that.surahId,_that.reciterName);case _:
  return null;

}
}

}

/// @nodoc


class LoadSurahsForReciter implements SurahEvent {
  const LoadSurahsForReciter(this.reciterName);
  

@override final  String reciterName;

/// Create a copy of SurahEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadSurahsForReciterCopyWith<LoadSurahsForReciter> get copyWith => _$LoadSurahsForReciterCopyWithImpl<LoadSurahsForReciter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadSurahsForReciter&&(identical(other.reciterName, reciterName) || other.reciterName == reciterName));
}


@override
int get hashCode => Object.hash(runtimeType,reciterName);

@override
String toString() {
  return 'SurahEvent.loadSurahsForReciter(reciterName: $reciterName)';
}


}

/// @nodoc
abstract mixin class $LoadSurahsForReciterCopyWith<$Res> implements $SurahEventCopyWith<$Res> {
  factory $LoadSurahsForReciterCopyWith(LoadSurahsForReciter value, $Res Function(LoadSurahsForReciter) _then) = _$LoadSurahsForReciterCopyWithImpl;
@override @useResult
$Res call({
 String reciterName
});




}
/// @nodoc
class _$LoadSurahsForReciterCopyWithImpl<$Res>
    implements $LoadSurahsForReciterCopyWith<$Res> {
  _$LoadSurahsForReciterCopyWithImpl(this._self, this._then);

  final LoadSurahsForReciter _self;
  final $Res Function(LoadSurahsForReciter) _then;

/// Create a copy of SurahEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reciterName = null,}) {
  return _then(LoadSurahsForReciter(
null == reciterName ? _self.reciterName : reciterName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UpdateSurahDownloadStatus implements SurahEvent {
  const UpdateSurahDownloadStatus({required this.surahId, required this.reciterName, required this.isDownloaded});
  

 final  String surahId;
@override final  String reciterName;
 final  bool isDownloaded;

/// Create a copy of SurahEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateSurahDownloadStatusCopyWith<UpdateSurahDownloadStatus> get copyWith => _$UpdateSurahDownloadStatusCopyWithImpl<UpdateSurahDownloadStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateSurahDownloadStatus&&(identical(other.surahId, surahId) || other.surahId == surahId)&&(identical(other.reciterName, reciterName) || other.reciterName == reciterName)&&(identical(other.isDownloaded, isDownloaded) || other.isDownloaded == isDownloaded));
}


@override
int get hashCode => Object.hash(runtimeType,surahId,reciterName,isDownloaded);

@override
String toString() {
  return 'SurahEvent.updateSurahDownloadStatus(surahId: $surahId, reciterName: $reciterName, isDownloaded: $isDownloaded)';
}


}

/// @nodoc
abstract mixin class $UpdateSurahDownloadStatusCopyWith<$Res> implements $SurahEventCopyWith<$Res> {
  factory $UpdateSurahDownloadStatusCopyWith(UpdateSurahDownloadStatus value, $Res Function(UpdateSurahDownloadStatus) _then) = _$UpdateSurahDownloadStatusCopyWithImpl;
@override @useResult
$Res call({
 String surahId, String reciterName, bool isDownloaded
});




}
/// @nodoc
class _$UpdateSurahDownloadStatusCopyWithImpl<$Res>
    implements $UpdateSurahDownloadStatusCopyWith<$Res> {
  _$UpdateSurahDownloadStatusCopyWithImpl(this._self, this._then);

  final UpdateSurahDownloadStatus _self;
  final $Res Function(UpdateSurahDownloadStatus) _then;

/// Create a copy of SurahEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? surahId = null,Object? reciterName = null,Object? isDownloaded = null,}) {
  return _then(UpdateSurahDownloadStatus(
surahId: null == surahId ? _self.surahId : surahId // ignore: cast_nullable_to_non_nullable
as String,reciterName: null == reciterName ? _self.reciterName : reciterName // ignore: cast_nullable_to_non_nullable
as String,isDownloaded: null == isDownloaded ? _self.isDownloaded : isDownloaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class UpdateSurahDownloadProgress implements SurahEvent {
  const UpdateSurahDownloadProgress({required this.surahId, required this.reciterName, required this.isDownloading, required this.progress, this.downloadId});
  

 final  String surahId;
@override final  String reciterName;
 final  bool isDownloading;
 final  double progress;
 final  String? downloadId;

/// Create a copy of SurahEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateSurahDownloadProgressCopyWith<UpdateSurahDownloadProgress> get copyWith => _$UpdateSurahDownloadProgressCopyWithImpl<UpdateSurahDownloadProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateSurahDownloadProgress&&(identical(other.surahId, surahId) || other.surahId == surahId)&&(identical(other.reciterName, reciterName) || other.reciterName == reciterName)&&(identical(other.isDownloading, isDownloading) || other.isDownloading == isDownloading)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.downloadId, downloadId) || other.downloadId == downloadId));
}


@override
int get hashCode => Object.hash(runtimeType,surahId,reciterName,isDownloading,progress,downloadId);

@override
String toString() {
  return 'SurahEvent.updateSurahDownloadProgress(surahId: $surahId, reciterName: $reciterName, isDownloading: $isDownloading, progress: $progress, downloadId: $downloadId)';
}


}

/// @nodoc
abstract mixin class $UpdateSurahDownloadProgressCopyWith<$Res> implements $SurahEventCopyWith<$Res> {
  factory $UpdateSurahDownloadProgressCopyWith(UpdateSurahDownloadProgress value, $Res Function(UpdateSurahDownloadProgress) _then) = _$UpdateSurahDownloadProgressCopyWithImpl;
@override @useResult
$Res call({
 String surahId, String reciterName, bool isDownloading, double progress, String? downloadId
});




}
/// @nodoc
class _$UpdateSurahDownloadProgressCopyWithImpl<$Res>
    implements $UpdateSurahDownloadProgressCopyWith<$Res> {
  _$UpdateSurahDownloadProgressCopyWithImpl(this._self, this._then);

  final UpdateSurahDownloadProgress _self;
  final $Res Function(UpdateSurahDownloadProgress) _then;

/// Create a copy of SurahEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? surahId = null,Object? reciterName = null,Object? isDownloading = null,Object? progress = null,Object? downloadId = freezed,}) {
  return _then(UpdateSurahDownloadProgress(
surahId: null == surahId ? _self.surahId : surahId // ignore: cast_nullable_to_non_nullable
as String,reciterName: null == reciterName ? _self.reciterName : reciterName // ignore: cast_nullable_to_non_nullable
as String,isDownloading: null == isDownloading ? _self.isDownloading : isDownloading // ignore: cast_nullable_to_non_nullable
as bool,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,downloadId: freezed == downloadId ? _self.downloadId : downloadId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class CheckSurahDownloadStatus implements SurahEvent {
  const CheckSurahDownloadStatus({required this.surahId, required this.reciterName});
  

 final  String surahId;
@override final  String reciterName;

/// Create a copy of SurahEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckSurahDownloadStatusCopyWith<CheckSurahDownloadStatus> get copyWith => _$CheckSurahDownloadStatusCopyWithImpl<CheckSurahDownloadStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckSurahDownloadStatus&&(identical(other.surahId, surahId) || other.surahId == surahId)&&(identical(other.reciterName, reciterName) || other.reciterName == reciterName));
}


@override
int get hashCode => Object.hash(runtimeType,surahId,reciterName);

@override
String toString() {
  return 'SurahEvent.checkSurahDownloadStatus(surahId: $surahId, reciterName: $reciterName)';
}


}

/// @nodoc
abstract mixin class $CheckSurahDownloadStatusCopyWith<$Res> implements $SurahEventCopyWith<$Res> {
  factory $CheckSurahDownloadStatusCopyWith(CheckSurahDownloadStatus value, $Res Function(CheckSurahDownloadStatus) _then) = _$CheckSurahDownloadStatusCopyWithImpl;
@override @useResult
$Res call({
 String surahId, String reciterName
});




}
/// @nodoc
class _$CheckSurahDownloadStatusCopyWithImpl<$Res>
    implements $CheckSurahDownloadStatusCopyWith<$Res> {
  _$CheckSurahDownloadStatusCopyWithImpl(this._self, this._then);

  final CheckSurahDownloadStatus _self;
  final $Res Function(CheckSurahDownloadStatus) _then;

/// Create a copy of SurahEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? surahId = null,Object? reciterName = null,}) {
  return _then(CheckSurahDownloadStatus(
surahId: null == surahId ? _self.surahId : surahId // ignore: cast_nullable_to_non_nullable
as String,reciterName: null == reciterName ? _self.reciterName : reciterName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RefreshSurahStatus implements SurahEvent {
  const RefreshSurahStatus({required this.surahId, required this.reciterName});
  

 final  String surahId;
@override final  String reciterName;

/// Create a copy of SurahEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RefreshSurahStatusCopyWith<RefreshSurahStatus> get copyWith => _$RefreshSurahStatusCopyWithImpl<RefreshSurahStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefreshSurahStatus&&(identical(other.surahId, surahId) || other.surahId == surahId)&&(identical(other.reciterName, reciterName) || other.reciterName == reciterName));
}


@override
int get hashCode => Object.hash(runtimeType,surahId,reciterName);

@override
String toString() {
  return 'SurahEvent.refreshSurahStatus(surahId: $surahId, reciterName: $reciterName)';
}


}

/// @nodoc
abstract mixin class $RefreshSurahStatusCopyWith<$Res> implements $SurahEventCopyWith<$Res> {
  factory $RefreshSurahStatusCopyWith(RefreshSurahStatus value, $Res Function(RefreshSurahStatus) _then) = _$RefreshSurahStatusCopyWithImpl;
@override @useResult
$Res call({
 String surahId, String reciterName
});




}
/// @nodoc
class _$RefreshSurahStatusCopyWithImpl<$Res>
    implements $RefreshSurahStatusCopyWith<$Res> {
  _$RefreshSurahStatusCopyWithImpl(this._self, this._then);

  final RefreshSurahStatus _self;
  final $Res Function(RefreshSurahStatus) _then;

/// Create a copy of SurahEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? surahId = null,Object? reciterName = null,}) {
  return _then(RefreshSurahStatus(
surahId: null == surahId ? _self.surahId : surahId // ignore: cast_nullable_to_non_nullable
as String,reciterName: null == reciterName ? _self.reciterName : reciterName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SurahState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurahState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SurahState()';
}


}

/// @nodoc
class $SurahStateCopyWith<$Res>  {
$SurahStateCopyWith(SurahState _, $Res Function(SurahState) __);
}


/// Adds pattern-matching-related methods to [SurahState].
extension SurahStatePatterns on SurahState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SurahInitial value)?  initial,TResult Function( SurahLoading value)?  loading,TResult Function( SurahLoaded value)?  loaded,TResult Function( SurahError value)?  error,TResult Function( SurahUpdated value)?  surahUpdated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SurahInitial() when initial != null:
return initial(_that);case SurahLoading() when loading != null:
return loading(_that);case SurahLoaded() when loaded != null:
return loaded(_that);case SurahError() when error != null:
return error(_that);case SurahUpdated() when surahUpdated != null:
return surahUpdated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SurahInitial value)  initial,required TResult Function( SurahLoading value)  loading,required TResult Function( SurahLoaded value)  loaded,required TResult Function( SurahError value)  error,required TResult Function( SurahUpdated value)  surahUpdated,}){
final _that = this;
switch (_that) {
case SurahInitial():
return initial(_that);case SurahLoading():
return loading(_that);case SurahLoaded():
return loaded(_that);case SurahError():
return error(_that);case SurahUpdated():
return surahUpdated(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SurahInitial value)?  initial,TResult? Function( SurahLoading value)?  loading,TResult? Function( SurahLoaded value)?  loaded,TResult? Function( SurahError value)?  error,TResult? Function( SurahUpdated value)?  surahUpdated,}){
final _that = this;
switch (_that) {
case SurahInitial() when initial != null:
return initial(_that);case SurahLoading() when loading != null:
return loading(_that);case SurahLoaded() when loaded != null:
return loaded(_that);case SurahError() when error != null:
return error(_that);case SurahUpdated() when surahUpdated != null:
return surahUpdated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Surah> surahs,  String reciterName)?  loaded,TResult Function( String message)?  error,TResult Function( Surah surah)?  surahUpdated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SurahInitial() when initial != null:
return initial();case SurahLoading() when loading != null:
return loading();case SurahLoaded() when loaded != null:
return loaded(_that.surahs,_that.reciterName);case SurahError() when error != null:
return error(_that.message);case SurahUpdated() when surahUpdated != null:
return surahUpdated(_that.surah);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Surah> surahs,  String reciterName)  loaded,required TResult Function( String message)  error,required TResult Function( Surah surah)  surahUpdated,}) {final _that = this;
switch (_that) {
case SurahInitial():
return initial();case SurahLoading():
return loading();case SurahLoaded():
return loaded(_that.surahs,_that.reciterName);case SurahError():
return error(_that.message);case SurahUpdated():
return surahUpdated(_that.surah);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Surah> surahs,  String reciterName)?  loaded,TResult? Function( String message)?  error,TResult? Function( Surah surah)?  surahUpdated,}) {final _that = this;
switch (_that) {
case SurahInitial() when initial != null:
return initial();case SurahLoading() when loading != null:
return loading();case SurahLoaded() when loaded != null:
return loaded(_that.surahs,_that.reciterName);case SurahError() when error != null:
return error(_that.message);case SurahUpdated() when surahUpdated != null:
return surahUpdated(_that.surah);case _:
  return null;

}
}

}

/// @nodoc


class SurahInitial implements SurahState {
  const SurahInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurahInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SurahState.initial()';
}


}




/// @nodoc


class SurahLoading implements SurahState {
  const SurahLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurahLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SurahState.loading()';
}


}




/// @nodoc


class SurahLoaded implements SurahState {
  const SurahLoaded({required final  List<Surah> surahs, required this.reciterName}): _surahs = surahs;
  

 final  List<Surah> _surahs;
 List<Surah> get surahs {
  if (_surahs is EqualUnmodifiableListView) return _surahs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_surahs);
}

 final  String reciterName;

/// Create a copy of SurahState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurahLoadedCopyWith<SurahLoaded> get copyWith => _$SurahLoadedCopyWithImpl<SurahLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurahLoaded&&const DeepCollectionEquality().equals(other._surahs, _surahs)&&(identical(other.reciterName, reciterName) || other.reciterName == reciterName));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_surahs),reciterName);

@override
String toString() {
  return 'SurahState.loaded(surahs: $surahs, reciterName: $reciterName)';
}


}

/// @nodoc
abstract mixin class $SurahLoadedCopyWith<$Res> implements $SurahStateCopyWith<$Res> {
  factory $SurahLoadedCopyWith(SurahLoaded value, $Res Function(SurahLoaded) _then) = _$SurahLoadedCopyWithImpl;
@useResult
$Res call({
 List<Surah> surahs, String reciterName
});




}
/// @nodoc
class _$SurahLoadedCopyWithImpl<$Res>
    implements $SurahLoadedCopyWith<$Res> {
  _$SurahLoadedCopyWithImpl(this._self, this._then);

  final SurahLoaded _self;
  final $Res Function(SurahLoaded) _then;

/// Create a copy of SurahState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? surahs = null,Object? reciterName = null,}) {
  return _then(SurahLoaded(
surahs: null == surahs ? _self._surahs : surahs // ignore: cast_nullable_to_non_nullable
as List<Surah>,reciterName: null == reciterName ? _self.reciterName : reciterName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SurahError implements SurahState {
  const SurahError(this.message);
  

 final  String message;

/// Create a copy of SurahState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurahErrorCopyWith<SurahError> get copyWith => _$SurahErrorCopyWithImpl<SurahError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurahError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SurahState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $SurahErrorCopyWith<$Res> implements $SurahStateCopyWith<$Res> {
  factory $SurahErrorCopyWith(SurahError value, $Res Function(SurahError) _then) = _$SurahErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SurahErrorCopyWithImpl<$Res>
    implements $SurahErrorCopyWith<$Res> {
  _$SurahErrorCopyWithImpl(this._self, this._then);

  final SurahError _self;
  final $Res Function(SurahError) _then;

/// Create a copy of SurahState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SurahError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SurahUpdated implements SurahState {
  const SurahUpdated({required this.surah});
  

 final  Surah surah;

/// Create a copy of SurahState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurahUpdatedCopyWith<SurahUpdated> get copyWith => _$SurahUpdatedCopyWithImpl<SurahUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurahUpdated&&(identical(other.surah, surah) || other.surah == surah));
}


@override
int get hashCode => Object.hash(runtimeType,surah);

@override
String toString() {
  return 'SurahState.surahUpdated(surah: $surah)';
}


}

/// @nodoc
abstract mixin class $SurahUpdatedCopyWith<$Res> implements $SurahStateCopyWith<$Res> {
  factory $SurahUpdatedCopyWith(SurahUpdated value, $Res Function(SurahUpdated) _then) = _$SurahUpdatedCopyWithImpl;
@useResult
$Res call({
 Surah surah
});




}
/// @nodoc
class _$SurahUpdatedCopyWithImpl<$Res>
    implements $SurahUpdatedCopyWith<$Res> {
  _$SurahUpdatedCopyWithImpl(this._self, this._then);

  final SurahUpdated _self;
  final $Res Function(SurahUpdated) _then;

/// Create a copy of SurahState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? surah = null,}) {
  return _then(SurahUpdated(
surah: null == surah ? _self.surah : surah // ignore: cast_nullable_to_non_nullable
as Surah,
  ));
}


}

// dart format on
