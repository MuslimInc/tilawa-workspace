// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_button_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DownloadButtonEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadButtonEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonEvent()';
}


}

/// @nodoc
class $DownloadButtonEventCopyWith<$Res>  {
$DownloadButtonEventCopyWith(DownloadButtonEvent _, $Res Function(DownloadButtonEvent) __);
}


/// Adds pattern-matching-related methods to [DownloadButtonEvent].
extension DownloadButtonEventPatterns on DownloadButtonEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initialize value)?  initialize,TResult Function( _StartDownload value)?  startDownload,TResult Function( _Retry value)?  retry,TResult Function( _Cancel value)?  cancel,TResult Function( _ProgressUpdated value)?  progressUpdated,TResult Function( _Completed value)?  completed,TResult Function( _Failed value)?  failed,TResult Function( _Cancelled value)?  cancelled,TResult Function( _Paused value)?  paused,TResult Function( _PendingDetected value)?  pendingDetected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initialize() when initialize != null:
return initialize(_that);case _StartDownload() when startDownload != null:
return startDownload(_that);case _Retry() when retry != null:
return retry(_that);case _Cancel() when cancel != null:
return cancel(_that);case _ProgressUpdated() when progressUpdated != null:
return progressUpdated(_that);case _Completed() when completed != null:
return completed(_that);case _Failed() when failed != null:
return failed(_that);case _Cancelled() when cancelled != null:
return cancelled(_that);case _Paused() when paused != null:
return paused(_that);case _PendingDetected() when pendingDetected != null:
return pendingDetected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initialize value)  initialize,required TResult Function( _StartDownload value)  startDownload,required TResult Function( _Retry value)  retry,required TResult Function( _Cancel value)  cancel,required TResult Function( _ProgressUpdated value)  progressUpdated,required TResult Function( _Completed value)  completed,required TResult Function( _Failed value)  failed,required TResult Function( _Cancelled value)  cancelled,required TResult Function( _Paused value)  paused,required TResult Function( _PendingDetected value)  pendingDetected,}){
final _that = this;
switch (_that) {
case _Initialize():
return initialize(_that);case _StartDownload():
return startDownload(_that);case _Retry():
return retry(_that);case _Cancel():
return cancel(_that);case _ProgressUpdated():
return progressUpdated(_that);case _Completed():
return completed(_that);case _Failed():
return failed(_that);case _Cancelled():
return cancelled(_that);case _Paused():
return paused(_that);case _PendingDetected():
return pendingDetected(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initialize value)?  initialize,TResult? Function( _StartDownload value)?  startDownload,TResult? Function( _Retry value)?  retry,TResult? Function( _Cancel value)?  cancel,TResult? Function( _ProgressUpdated value)?  progressUpdated,TResult? Function( _Completed value)?  completed,TResult? Function( _Failed value)?  failed,TResult? Function( _Cancelled value)?  cancelled,TResult? Function( _Paused value)?  paused,TResult? Function( _PendingDetected value)?  pendingDetected,}){
final _that = this;
switch (_that) {
case _Initialize() when initialize != null:
return initialize(_that);case _StartDownload() when startDownload != null:
return startDownload(_that);case _Retry() when retry != null:
return retry(_that);case _Cancel() when cancel != null:
return cancel(_that);case _ProgressUpdated() when progressUpdated != null:
return progressUpdated(_that);case _Completed() when completed != null:
return completed(_that);case _Failed() when failed != null:
return failed(_that);case _Cancelled() when cancelled != null:
return cancelled(_that);case _Paused() when paused != null:
return paused(_that);case _PendingDetected() when pendingDetected != null:
return pendingDetected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initialize,TResult Function( String surahTitle)?  startDownload,TResult Function( String surahTitle)?  retry,TResult Function()?  cancel,TResult Function( double progress,  int downloadedBytes,  int totalBytes)?  progressUpdated,TResult Function()?  completed,TResult Function( String? errorMessage)?  failed,TResult Function()?  cancelled,TResult Function()?  paused,TResult Function()?  pendingDetected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initialize() when initialize != null:
return initialize();case _StartDownload() when startDownload != null:
return startDownload(_that.surahTitle);case _Retry() when retry != null:
return retry(_that.surahTitle);case _Cancel() when cancel != null:
return cancel();case _ProgressUpdated() when progressUpdated != null:
return progressUpdated(_that.progress,_that.downloadedBytes,_that.totalBytes);case _Completed() when completed != null:
return completed();case _Failed() when failed != null:
return failed(_that.errorMessage);case _Cancelled() when cancelled != null:
return cancelled();case _Paused() when paused != null:
return paused();case _PendingDetected() when pendingDetected != null:
return pendingDetected();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initialize,required TResult Function( String surahTitle)  startDownload,required TResult Function( String surahTitle)  retry,required TResult Function()  cancel,required TResult Function( double progress,  int downloadedBytes,  int totalBytes)  progressUpdated,required TResult Function()  completed,required TResult Function( String? errorMessage)  failed,required TResult Function()  cancelled,required TResult Function()  paused,required TResult Function()  pendingDetected,}) {final _that = this;
switch (_that) {
case _Initialize():
return initialize();case _StartDownload():
return startDownload(_that.surahTitle);case _Retry():
return retry(_that.surahTitle);case _Cancel():
return cancel();case _ProgressUpdated():
return progressUpdated(_that.progress,_that.downloadedBytes,_that.totalBytes);case _Completed():
return completed();case _Failed():
return failed(_that.errorMessage);case _Cancelled():
return cancelled();case _Paused():
return paused();case _PendingDetected():
return pendingDetected();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initialize,TResult? Function( String surahTitle)?  startDownload,TResult? Function( String surahTitle)?  retry,TResult? Function()?  cancel,TResult? Function( double progress,  int downloadedBytes,  int totalBytes)?  progressUpdated,TResult? Function()?  completed,TResult? Function( String? errorMessage)?  failed,TResult? Function()?  cancelled,TResult? Function()?  paused,TResult? Function()?  pendingDetected,}) {final _that = this;
switch (_that) {
case _Initialize() when initialize != null:
return initialize();case _StartDownload() when startDownload != null:
return startDownload(_that.surahTitle);case _Retry() when retry != null:
return retry(_that.surahTitle);case _Cancel() when cancel != null:
return cancel();case _ProgressUpdated() when progressUpdated != null:
return progressUpdated(_that.progress,_that.downloadedBytes,_that.totalBytes);case _Completed() when completed != null:
return completed();case _Failed() when failed != null:
return failed(_that.errorMessage);case _Cancelled() when cancelled != null:
return cancelled();case _Paused() when paused != null:
return paused();case _PendingDetected() when pendingDetected != null:
return pendingDetected();case _:
  return null;

}
}

}

/// @nodoc


class _Initialize implements DownloadButtonEvent {
  const _Initialize();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initialize);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonEvent.initialize()';
}


}




/// @nodoc


class _StartDownload implements DownloadButtonEvent {
  const _StartDownload({required this.surahTitle});
  

 final  String surahTitle;

/// Create a copy of DownloadButtonEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StartDownloadCopyWith<_StartDownload> get copyWith => __$StartDownloadCopyWithImpl<_StartDownload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StartDownload&&(identical(other.surahTitle, surahTitle) || other.surahTitle == surahTitle));
}


@override
int get hashCode => Object.hash(runtimeType,surahTitle);

@override
String toString() {
  return 'DownloadButtonEvent.startDownload(surahTitle: $surahTitle)';
}


}

/// @nodoc
abstract mixin class _$StartDownloadCopyWith<$Res> implements $DownloadButtonEventCopyWith<$Res> {
  factory _$StartDownloadCopyWith(_StartDownload value, $Res Function(_StartDownload) _then) = __$StartDownloadCopyWithImpl;
@useResult
$Res call({
 String surahTitle
});




}
/// @nodoc
class __$StartDownloadCopyWithImpl<$Res>
    implements _$StartDownloadCopyWith<$Res> {
  __$StartDownloadCopyWithImpl(this._self, this._then);

  final _StartDownload _self;
  final $Res Function(_StartDownload) _then;

/// Create a copy of DownloadButtonEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? surahTitle = null,}) {
  return _then(_StartDownload(
surahTitle: null == surahTitle ? _self.surahTitle : surahTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Retry implements DownloadButtonEvent {
  const _Retry({required this.surahTitle});
  

 final  String surahTitle;

/// Create a copy of DownloadButtonEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RetryCopyWith<_Retry> get copyWith => __$RetryCopyWithImpl<_Retry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Retry&&(identical(other.surahTitle, surahTitle) || other.surahTitle == surahTitle));
}


@override
int get hashCode => Object.hash(runtimeType,surahTitle);

@override
String toString() {
  return 'DownloadButtonEvent.retry(surahTitle: $surahTitle)';
}


}

/// @nodoc
abstract mixin class _$RetryCopyWith<$Res> implements $DownloadButtonEventCopyWith<$Res> {
  factory _$RetryCopyWith(_Retry value, $Res Function(_Retry) _then) = __$RetryCopyWithImpl;
@useResult
$Res call({
 String surahTitle
});




}
/// @nodoc
class __$RetryCopyWithImpl<$Res>
    implements _$RetryCopyWith<$Res> {
  __$RetryCopyWithImpl(this._self, this._then);

  final _Retry _self;
  final $Res Function(_Retry) _then;

/// Create a copy of DownloadButtonEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? surahTitle = null,}) {
  return _then(_Retry(
surahTitle: null == surahTitle ? _self.surahTitle : surahTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Cancel implements DownloadButtonEvent {
  const _Cancel();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Cancel);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonEvent.cancel()';
}


}




/// @nodoc


class _ProgressUpdated implements DownloadButtonEvent {
  const _ProgressUpdated({required this.progress, required this.downloadedBytes, required this.totalBytes});
  

 final  double progress;
 final  int downloadedBytes;
 final  int totalBytes;

/// Create a copy of DownloadButtonEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressUpdatedCopyWith<_ProgressUpdated> get copyWith => __$ProgressUpdatedCopyWithImpl<_ProgressUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressUpdated&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.downloadedBytes, downloadedBytes) || other.downloadedBytes == downloadedBytes)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes));
}


@override
int get hashCode => Object.hash(runtimeType,progress,downloadedBytes,totalBytes);

@override
String toString() {
  return 'DownloadButtonEvent.progressUpdated(progress: $progress, downloadedBytes: $downloadedBytes, totalBytes: $totalBytes)';
}


}

/// @nodoc
abstract mixin class _$ProgressUpdatedCopyWith<$Res> implements $DownloadButtonEventCopyWith<$Res> {
  factory _$ProgressUpdatedCopyWith(_ProgressUpdated value, $Res Function(_ProgressUpdated) _then) = __$ProgressUpdatedCopyWithImpl;
@useResult
$Res call({
 double progress, int downloadedBytes, int totalBytes
});




}
/// @nodoc
class __$ProgressUpdatedCopyWithImpl<$Res>
    implements _$ProgressUpdatedCopyWith<$Res> {
  __$ProgressUpdatedCopyWithImpl(this._self, this._then);

  final _ProgressUpdated _self;
  final $Res Function(_ProgressUpdated) _then;

/// Create a copy of DownloadButtonEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? progress = null,Object? downloadedBytes = null,Object? totalBytes = null,}) {
  return _then(_ProgressUpdated(
progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,downloadedBytes: null == downloadedBytes ? _self.downloadedBytes : downloadedBytes // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _Completed implements DownloadButtonEvent {
  const _Completed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Completed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonEvent.completed()';
}


}




/// @nodoc


class _Failed implements DownloadButtonEvent {
  const _Failed({this.errorMessage});
  

 final  String? errorMessage;

/// Create a copy of DownloadButtonEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FailedCopyWith<_Failed> get copyWith => __$FailedCopyWithImpl<_Failed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Failed&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'DownloadButtonEvent.failed(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$FailedCopyWith<$Res> implements $DownloadButtonEventCopyWith<$Res> {
  factory _$FailedCopyWith(_Failed value, $Res Function(_Failed) _then) = __$FailedCopyWithImpl;
@useResult
$Res call({
 String? errorMessage
});




}
/// @nodoc
class __$FailedCopyWithImpl<$Res>
    implements _$FailedCopyWith<$Res> {
  __$FailedCopyWithImpl(this._self, this._then);

  final _Failed _self;
  final $Res Function(_Failed) _then;

/// Create a copy of DownloadButtonEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = freezed,}) {
  return _then(_Failed(
errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _Cancelled implements DownloadButtonEvent {
  const _Cancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Cancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonEvent.cancelled()';
}


}




/// @nodoc


class _Paused implements DownloadButtonEvent {
  const _Paused();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Paused);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonEvent.paused()';
}


}




/// @nodoc


class _PendingDetected implements DownloadButtonEvent {
  const _PendingDetected();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingDetected);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonEvent.pendingDetected()';
}


}




/// @nodoc
mixin _$DownloadButtonState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadButtonState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonState()';
}


}

/// @nodoc
class $DownloadButtonStateCopyWith<$Res>  {
$DownloadButtonStateCopyWith(DownloadButtonState _, $Res Function(DownloadButtonState) __);
}


/// Adds pattern-matching-related methods to [DownloadButtonState].
extension DownloadButtonStatePatterns on DownloadButtonState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _ReadyToDownload value)?  readyToDownload,TResult Function( _PendingState value)?  pending,TResult Function( _Downloading value)?  downloading,TResult Function( _CompletedState value)?  completed,TResult Function( _FailedState value)?  failed,TResult Function( _CancelledState value)?  cancelled,TResult Function( _NetworkError value)?  networkError,TResult Function( _PausedState value)?  paused,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _ReadyToDownload() when readyToDownload != null:
return readyToDownload(_that);case _PendingState() when pending != null:
return pending(_that);case _Downloading() when downloading != null:
return downloading(_that);case _CompletedState() when completed != null:
return completed(_that);case _FailedState() when failed != null:
return failed(_that);case _CancelledState() when cancelled != null:
return cancelled(_that);case _NetworkError() when networkError != null:
return networkError(_that);case _PausedState() when paused != null:
return paused(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _ReadyToDownload value)  readyToDownload,required TResult Function( _PendingState value)  pending,required TResult Function( _Downloading value)  downloading,required TResult Function( _CompletedState value)  completed,required TResult Function( _FailedState value)  failed,required TResult Function( _CancelledState value)  cancelled,required TResult Function( _NetworkError value)  networkError,required TResult Function( _PausedState value)  paused,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _ReadyToDownload():
return readyToDownload(_that);case _PendingState():
return pending(_that);case _Downloading():
return downloading(_that);case _CompletedState():
return completed(_that);case _FailedState():
return failed(_that);case _CancelledState():
return cancelled(_that);case _NetworkError():
return networkError(_that);case _PausedState():
return paused(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _ReadyToDownload value)?  readyToDownload,TResult? Function( _PendingState value)?  pending,TResult? Function( _Downloading value)?  downloading,TResult? Function( _CompletedState value)?  completed,TResult? Function( _FailedState value)?  failed,TResult? Function( _CancelledState value)?  cancelled,TResult? Function( _NetworkError value)?  networkError,TResult? Function( _PausedState value)?  paused,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _ReadyToDownload() when readyToDownload != null:
return readyToDownload(_that);case _PendingState() when pending != null:
return pending(_that);case _Downloading() when downloading != null:
return downloading(_that);case _CompletedState() when completed != null:
return completed(_that);case _FailedState() when failed != null:
return failed(_that);case _CancelledState() when cancelled != null:
return cancelled(_that);case _NetworkError() when networkError != null:
return networkError(_that);case _PausedState() when paused != null:
return paused(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  readyToDownload,TResult Function()?  pending,TResult Function( double progress,  int downloadedBytes,  int totalBytes)?  downloading,TResult Function()?  completed,TResult Function( String? errorMessage)?  failed,TResult Function()?  cancelled,TResult Function( String? errorMessage)?  networkError,TResult Function()?  paused,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _ReadyToDownload() when readyToDownload != null:
return readyToDownload();case _PendingState() when pending != null:
return pending();case _Downloading() when downloading != null:
return downloading(_that.progress,_that.downloadedBytes,_that.totalBytes);case _CompletedState() when completed != null:
return completed();case _FailedState() when failed != null:
return failed(_that.errorMessage);case _CancelledState() when cancelled != null:
return cancelled();case _NetworkError() when networkError != null:
return networkError(_that.errorMessage);case _PausedState() when paused != null:
return paused();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  readyToDownload,required TResult Function()  pending,required TResult Function( double progress,  int downloadedBytes,  int totalBytes)  downloading,required TResult Function()  completed,required TResult Function( String? errorMessage)  failed,required TResult Function()  cancelled,required TResult Function( String? errorMessage)  networkError,required TResult Function()  paused,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _ReadyToDownload():
return readyToDownload();case _PendingState():
return pending();case _Downloading():
return downloading(_that.progress,_that.downloadedBytes,_that.totalBytes);case _CompletedState():
return completed();case _FailedState():
return failed(_that.errorMessage);case _CancelledState():
return cancelled();case _NetworkError():
return networkError(_that.errorMessage);case _PausedState():
return paused();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  readyToDownload,TResult? Function()?  pending,TResult? Function( double progress,  int downloadedBytes,  int totalBytes)?  downloading,TResult? Function()?  completed,TResult? Function( String? errorMessage)?  failed,TResult? Function()?  cancelled,TResult? Function( String? errorMessage)?  networkError,TResult? Function()?  paused,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _ReadyToDownload() when readyToDownload != null:
return readyToDownload();case _PendingState() when pending != null:
return pending();case _Downloading() when downloading != null:
return downloading(_that.progress,_that.downloadedBytes,_that.totalBytes);case _CompletedState() when completed != null:
return completed();case _FailedState() when failed != null:
return failed(_that.errorMessage);case _CancelledState() when cancelled != null:
return cancelled();case _NetworkError() when networkError != null:
return networkError(_that.errorMessage);case _PausedState() when paused != null:
return paused();case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements DownloadButtonState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonState.initial()';
}


}




/// @nodoc


class _ReadyToDownload implements DownloadButtonState {
  const _ReadyToDownload();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadyToDownload);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonState.readyToDownload()';
}


}




/// @nodoc


class _PendingState implements DownloadButtonState {
  const _PendingState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonState.pending()';
}


}




/// @nodoc


class _Downloading implements DownloadButtonState {
  const _Downloading({required this.progress, this.downloadedBytes = 0, this.totalBytes = 0});
  

 final  double progress;
@JsonKey() final  int downloadedBytes;
@JsonKey() final  int totalBytes;

/// Create a copy of DownloadButtonState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadingCopyWith<_Downloading> get copyWith => __$DownloadingCopyWithImpl<_Downloading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Downloading&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.downloadedBytes, downloadedBytes) || other.downloadedBytes == downloadedBytes)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes));
}


@override
int get hashCode => Object.hash(runtimeType,progress,downloadedBytes,totalBytes);

@override
String toString() {
  return 'DownloadButtonState.downloading(progress: $progress, downloadedBytes: $downloadedBytes, totalBytes: $totalBytes)';
}


}

/// @nodoc
abstract mixin class _$DownloadingCopyWith<$Res> implements $DownloadButtonStateCopyWith<$Res> {
  factory _$DownloadingCopyWith(_Downloading value, $Res Function(_Downloading) _then) = __$DownloadingCopyWithImpl;
@useResult
$Res call({
 double progress, int downloadedBytes, int totalBytes
});




}
/// @nodoc
class __$DownloadingCopyWithImpl<$Res>
    implements _$DownloadingCopyWith<$Res> {
  __$DownloadingCopyWithImpl(this._self, this._then);

  final _Downloading _self;
  final $Res Function(_Downloading) _then;

/// Create a copy of DownloadButtonState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? progress = null,Object? downloadedBytes = null,Object? totalBytes = null,}) {
  return _then(_Downloading(
progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,downloadedBytes: null == downloadedBytes ? _self.downloadedBytes : downloadedBytes // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _CompletedState implements DownloadButtonState {
  const _CompletedState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompletedState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonState.completed()';
}


}




/// @nodoc


class _FailedState implements DownloadButtonState {
  const _FailedState({this.errorMessage});
  

 final  String? errorMessage;

/// Create a copy of DownloadButtonState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FailedStateCopyWith<_FailedState> get copyWith => __$FailedStateCopyWithImpl<_FailedState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FailedState&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'DownloadButtonState.failed(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$FailedStateCopyWith<$Res> implements $DownloadButtonStateCopyWith<$Res> {
  factory _$FailedStateCopyWith(_FailedState value, $Res Function(_FailedState) _then) = __$FailedStateCopyWithImpl;
@useResult
$Res call({
 String? errorMessage
});




}
/// @nodoc
class __$FailedStateCopyWithImpl<$Res>
    implements _$FailedStateCopyWith<$Res> {
  __$FailedStateCopyWithImpl(this._self, this._then);

  final _FailedState _self;
  final $Res Function(_FailedState) _then;

/// Create a copy of DownloadButtonState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = freezed,}) {
  return _then(_FailedState(
errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _CancelledState implements DownloadButtonState {
  const _CancelledState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CancelledState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonState.cancelled()';
}


}




/// @nodoc


class _NetworkError implements DownloadButtonState {
  const _NetworkError({this.errorMessage});
  

 final  String? errorMessage;

/// Create a copy of DownloadButtonState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkErrorCopyWith<_NetworkError> get copyWith => __$NetworkErrorCopyWithImpl<_NetworkError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkError&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'DownloadButtonState.networkError(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$NetworkErrorCopyWith<$Res> implements $DownloadButtonStateCopyWith<$Res> {
  factory _$NetworkErrorCopyWith(_NetworkError value, $Res Function(_NetworkError) _then) = __$NetworkErrorCopyWithImpl;
@useResult
$Res call({
 String? errorMessage
});




}
/// @nodoc
class __$NetworkErrorCopyWithImpl<$Res>
    implements _$NetworkErrorCopyWith<$Res> {
  __$NetworkErrorCopyWithImpl(this._self, this._then);

  final _NetworkError _self;
  final $Res Function(_NetworkError) _then;

/// Create a copy of DownloadButtonState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = freezed,}) {
  return _then(_NetworkError(
errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _PausedState implements DownloadButtonState {
  const _PausedState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PausedState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadButtonState.paused()';
}


}




// dart format on
