// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'downloads_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DownloadsStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadsStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DownloadsStatus()';
}


}

/// @nodoc
class $DownloadsStatusCopyWith<$Res>  {
$DownloadsStatusCopyWith(DownloadsStatus _, $Res Function(DownloadsStatus) __);
}


/// Adds pattern-matching-related methods to [DownloadsStatus].
extension DownloadsStatusPatterns on DownloadsStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DownloadStarted value)?  downloadStarted,TResult Function( PremiumRequired value)?  premiumRequired,TResult Function( PlaybackInitiated value)?  playbackInitiated,TResult Function( SurahDownloadStatus value)?  surahDownloadStatus,TResult Function( FileValidationResult value)?  fileValidationResult,TResult Function( ValidDownloadsLoaded value)?  validDownloadsLoaded,TResult Function( Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DownloadStarted() when downloadStarted != null:
return downloadStarted(_that);case PremiumRequired() when premiumRequired != null:
return premiumRequired(_that);case PlaybackInitiated() when playbackInitiated != null:
return playbackInitiated(_that);case SurahDownloadStatus() when surahDownloadStatus != null:
return surahDownloadStatus(_that);case FileValidationResult() when fileValidationResult != null:
return fileValidationResult(_that);case ValidDownloadsLoaded() when validDownloadsLoaded != null:
return validDownloadsLoaded(_that);case Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DownloadStarted value)  downloadStarted,required TResult Function( PremiumRequired value)  premiumRequired,required TResult Function( PlaybackInitiated value)  playbackInitiated,required TResult Function( SurahDownloadStatus value)  surahDownloadStatus,required TResult Function( FileValidationResult value)  fileValidationResult,required TResult Function( ValidDownloadsLoaded value)  validDownloadsLoaded,required TResult Function( Error value)  error,}){
final _that = this;
switch (_that) {
case DownloadStarted():
return downloadStarted(_that);case PremiumRequired():
return premiumRequired(_that);case PlaybackInitiated():
return playbackInitiated(_that);case SurahDownloadStatus():
return surahDownloadStatus(_that);case FileValidationResult():
return fileValidationResult(_that);case ValidDownloadsLoaded():
return validDownloadsLoaded(_that);case Error():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DownloadStarted value)?  downloadStarted,TResult? Function( PremiumRequired value)?  premiumRequired,TResult? Function( PlaybackInitiated value)?  playbackInitiated,TResult? Function( SurahDownloadStatus value)?  surahDownloadStatus,TResult? Function( FileValidationResult value)?  fileValidationResult,TResult? Function( ValidDownloadsLoaded value)?  validDownloadsLoaded,TResult? Function( Error value)?  error,}){
final _that = this;
switch (_that) {
case DownloadStarted() when downloadStarted != null:
return downloadStarted(_that);case PremiumRequired() when premiumRequired != null:
return premiumRequired(_that);case PlaybackInitiated() when playbackInitiated != null:
return playbackInitiated(_that);case SurahDownloadStatus() when surahDownloadStatus != null:
return surahDownloadStatus(_that);case FileValidationResult() when fileValidationResult != null:
return fileValidationResult(_that);case ValidDownloadsLoaded() when validDownloadsLoaded != null:
return validDownloadsLoaded(_that);case Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String surahId,  String surahTitle,  String reciterName)?  downloadStarted,TResult Function( String message)?  premiumRequired,TResult Function( String message)?  playbackInitiated,TResult Function( String surahId,  String reciterName,  bool isDownloaded)?  surahDownloadStatus,TResult Function( String downloadId,  bool isValid)?  fileValidationResult,TResult Function( String reciterName,  List<DownloadItem> validDownloads)?  validDownloadsLoaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DownloadStarted() when downloadStarted != null:
return downloadStarted(_that.surahId,_that.surahTitle,_that.reciterName);case PremiumRequired() when premiumRequired != null:
return premiumRequired(_that.message);case PlaybackInitiated() when playbackInitiated != null:
return playbackInitiated(_that.message);case SurahDownloadStatus() when surahDownloadStatus != null:
return surahDownloadStatus(_that.surahId,_that.reciterName,_that.isDownloaded);case FileValidationResult() when fileValidationResult != null:
return fileValidationResult(_that.downloadId,_that.isValid);case ValidDownloadsLoaded() when validDownloadsLoaded != null:
return validDownloadsLoaded(_that.reciterName,_that.validDownloads);case Error() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String surahId,  String surahTitle,  String reciterName)  downloadStarted,required TResult Function( String message)  premiumRequired,required TResult Function( String message)  playbackInitiated,required TResult Function( String surahId,  String reciterName,  bool isDownloaded)  surahDownloadStatus,required TResult Function( String downloadId,  bool isValid)  fileValidationResult,required TResult Function( String reciterName,  List<DownloadItem> validDownloads)  validDownloadsLoaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case DownloadStarted():
return downloadStarted(_that.surahId,_that.surahTitle,_that.reciterName);case PremiumRequired():
return premiumRequired(_that.message);case PlaybackInitiated():
return playbackInitiated(_that.message);case SurahDownloadStatus():
return surahDownloadStatus(_that.surahId,_that.reciterName,_that.isDownloaded);case FileValidationResult():
return fileValidationResult(_that.downloadId,_that.isValid);case ValidDownloadsLoaded():
return validDownloadsLoaded(_that.reciterName,_that.validDownloads);case Error():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String surahId,  String surahTitle,  String reciterName)?  downloadStarted,TResult? Function( String message)?  premiumRequired,TResult? Function( String message)?  playbackInitiated,TResult? Function( String surahId,  String reciterName,  bool isDownloaded)?  surahDownloadStatus,TResult? Function( String downloadId,  bool isValid)?  fileValidationResult,TResult? Function( String reciterName,  List<DownloadItem> validDownloads)?  validDownloadsLoaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case DownloadStarted() when downloadStarted != null:
return downloadStarted(_that.surahId,_that.surahTitle,_that.reciterName);case PremiumRequired() when premiumRequired != null:
return premiumRequired(_that.message);case PlaybackInitiated() when playbackInitiated != null:
return playbackInitiated(_that.message);case SurahDownloadStatus() when surahDownloadStatus != null:
return surahDownloadStatus(_that.surahId,_that.reciterName,_that.isDownloaded);case FileValidationResult() when fileValidationResult != null:
return fileValidationResult(_that.downloadId,_that.isValid);case ValidDownloadsLoaded() when validDownloadsLoaded != null:
return validDownloadsLoaded(_that.reciterName,_that.validDownloads);case Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class DownloadStarted implements DownloadsStatus {
  const DownloadStarted({required this.surahId, required this.surahTitle, required this.reciterName});
  

 final  String surahId;
 final  String surahTitle;
 final  String reciterName;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadStartedCopyWith<DownloadStarted> get copyWith => _$DownloadStartedCopyWithImpl<DownloadStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadStarted&&(identical(other.surahId, surahId) || other.surahId == surahId)&&(identical(other.surahTitle, surahTitle) || other.surahTitle == surahTitle)&&(identical(other.reciterName, reciterName) || other.reciterName == reciterName));
}


@override
int get hashCode => Object.hash(runtimeType,surahId,surahTitle,reciterName);

@override
String toString() {
  return 'DownloadsStatus.downloadStarted(surahId: $surahId, surahTitle: $surahTitle, reciterName: $reciterName)';
}


}

/// @nodoc
abstract mixin class $DownloadStartedCopyWith<$Res> implements $DownloadsStatusCopyWith<$Res> {
  factory $DownloadStartedCopyWith(DownloadStarted value, $Res Function(DownloadStarted) _then) = _$DownloadStartedCopyWithImpl;
@useResult
$Res call({
 String surahId, String surahTitle, String reciterName
});




}
/// @nodoc
class _$DownloadStartedCopyWithImpl<$Res>
    implements $DownloadStartedCopyWith<$Res> {
  _$DownloadStartedCopyWithImpl(this._self, this._then);

  final DownloadStarted _self;
  final $Res Function(DownloadStarted) _then;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? surahId = null,Object? surahTitle = null,Object? reciterName = null,}) {
  return _then(DownloadStarted(
surahId: null == surahId ? _self.surahId : surahId // ignore: cast_nullable_to_non_nullable
as String,surahTitle: null == surahTitle ? _self.surahTitle : surahTitle // ignore: cast_nullable_to_non_nullable
as String,reciterName: null == reciterName ? _self.reciterName : reciterName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PremiumRequired implements DownloadsStatus {
  const PremiumRequired({required this.message});
  

 final  String message;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PremiumRequiredCopyWith<PremiumRequired> get copyWith => _$PremiumRequiredCopyWithImpl<PremiumRequired>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumRequired&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'DownloadsStatus.premiumRequired(message: $message)';
}


}

/// @nodoc
abstract mixin class $PremiumRequiredCopyWith<$Res> implements $DownloadsStatusCopyWith<$Res> {
  factory $PremiumRequiredCopyWith(PremiumRequired value, $Res Function(PremiumRequired) _then) = _$PremiumRequiredCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PremiumRequiredCopyWithImpl<$Res>
    implements $PremiumRequiredCopyWith<$Res> {
  _$PremiumRequiredCopyWithImpl(this._self, this._then);

  final PremiumRequired _self;
  final $Res Function(PremiumRequired) _then;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PremiumRequired(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PlaybackInitiated implements DownloadsStatus {
  const PlaybackInitiated({required this.message});
  

 final  String message;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackInitiatedCopyWith<PlaybackInitiated> get copyWith => _$PlaybackInitiatedCopyWithImpl<PlaybackInitiated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackInitiated&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'DownloadsStatus.playbackInitiated(message: $message)';
}


}

/// @nodoc
abstract mixin class $PlaybackInitiatedCopyWith<$Res> implements $DownloadsStatusCopyWith<$Res> {
  factory $PlaybackInitiatedCopyWith(PlaybackInitiated value, $Res Function(PlaybackInitiated) _then) = _$PlaybackInitiatedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PlaybackInitiatedCopyWithImpl<$Res>
    implements $PlaybackInitiatedCopyWith<$Res> {
  _$PlaybackInitiatedCopyWithImpl(this._self, this._then);

  final PlaybackInitiated _self;
  final $Res Function(PlaybackInitiated) _then;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PlaybackInitiated(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SurahDownloadStatus implements DownloadsStatus {
  const SurahDownloadStatus({required this.surahId, required this.reciterName, required this.isDownloaded});
  

 final  String surahId;
 final  String reciterName;
 final  bool isDownloaded;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurahDownloadStatusCopyWith<SurahDownloadStatus> get copyWith => _$SurahDownloadStatusCopyWithImpl<SurahDownloadStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurahDownloadStatus&&(identical(other.surahId, surahId) || other.surahId == surahId)&&(identical(other.reciterName, reciterName) || other.reciterName == reciterName)&&(identical(other.isDownloaded, isDownloaded) || other.isDownloaded == isDownloaded));
}


@override
int get hashCode => Object.hash(runtimeType,surahId,reciterName,isDownloaded);

@override
String toString() {
  return 'DownloadsStatus.surahDownloadStatus(surahId: $surahId, reciterName: $reciterName, isDownloaded: $isDownloaded)';
}


}

/// @nodoc
abstract mixin class $SurahDownloadStatusCopyWith<$Res> implements $DownloadsStatusCopyWith<$Res> {
  factory $SurahDownloadStatusCopyWith(SurahDownloadStatus value, $Res Function(SurahDownloadStatus) _then) = _$SurahDownloadStatusCopyWithImpl;
@useResult
$Res call({
 String surahId, String reciterName, bool isDownloaded
});




}
/// @nodoc
class _$SurahDownloadStatusCopyWithImpl<$Res>
    implements $SurahDownloadStatusCopyWith<$Res> {
  _$SurahDownloadStatusCopyWithImpl(this._self, this._then);

  final SurahDownloadStatus _self;
  final $Res Function(SurahDownloadStatus) _then;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? surahId = null,Object? reciterName = null,Object? isDownloaded = null,}) {
  return _then(SurahDownloadStatus(
surahId: null == surahId ? _self.surahId : surahId // ignore: cast_nullable_to_non_nullable
as String,reciterName: null == reciterName ? _self.reciterName : reciterName // ignore: cast_nullable_to_non_nullable
as String,isDownloaded: null == isDownloaded ? _self.isDownloaded : isDownloaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class FileValidationResult implements DownloadsStatus {
  const FileValidationResult({required this.downloadId, required this.isValid});
  

 final  String downloadId;
 final  bool isValid;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileValidationResultCopyWith<FileValidationResult> get copyWith => _$FileValidationResultCopyWithImpl<FileValidationResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileValidationResult&&(identical(other.downloadId, downloadId) || other.downloadId == downloadId)&&(identical(other.isValid, isValid) || other.isValid == isValid));
}


@override
int get hashCode => Object.hash(runtimeType,downloadId,isValid);

@override
String toString() {
  return 'DownloadsStatus.fileValidationResult(downloadId: $downloadId, isValid: $isValid)';
}


}

/// @nodoc
abstract mixin class $FileValidationResultCopyWith<$Res> implements $DownloadsStatusCopyWith<$Res> {
  factory $FileValidationResultCopyWith(FileValidationResult value, $Res Function(FileValidationResult) _then) = _$FileValidationResultCopyWithImpl;
@useResult
$Res call({
 String downloadId, bool isValid
});




}
/// @nodoc
class _$FileValidationResultCopyWithImpl<$Res>
    implements $FileValidationResultCopyWith<$Res> {
  _$FileValidationResultCopyWithImpl(this._self, this._then);

  final FileValidationResult _self;
  final $Res Function(FileValidationResult) _then;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? downloadId = null,Object? isValid = null,}) {
  return _then(FileValidationResult(
downloadId: null == downloadId ? _self.downloadId : downloadId // ignore: cast_nullable_to_non_nullable
as String,isValid: null == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class ValidDownloadsLoaded implements DownloadsStatus {
  const ValidDownloadsLoaded({required this.reciterName, required final  List<DownloadItem> validDownloads}): _validDownloads = validDownloads;
  

 final  String reciterName;
 final  List<DownloadItem> _validDownloads;
 List<DownloadItem> get validDownloads {
  if (_validDownloads is EqualUnmodifiableListView) return _validDownloads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_validDownloads);
}


/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidDownloadsLoadedCopyWith<ValidDownloadsLoaded> get copyWith => _$ValidDownloadsLoadedCopyWithImpl<ValidDownloadsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidDownloadsLoaded&&(identical(other.reciterName, reciterName) || other.reciterName == reciterName)&&const DeepCollectionEquality().equals(other._validDownloads, _validDownloads));
}


@override
int get hashCode => Object.hash(runtimeType,reciterName,const DeepCollectionEquality().hash(_validDownloads));

@override
String toString() {
  return 'DownloadsStatus.validDownloadsLoaded(reciterName: $reciterName, validDownloads: $validDownloads)';
}


}

/// @nodoc
abstract mixin class $ValidDownloadsLoadedCopyWith<$Res> implements $DownloadsStatusCopyWith<$Res> {
  factory $ValidDownloadsLoadedCopyWith(ValidDownloadsLoaded value, $Res Function(ValidDownloadsLoaded) _then) = _$ValidDownloadsLoadedCopyWithImpl;
@useResult
$Res call({
 String reciterName, List<DownloadItem> validDownloads
});




}
/// @nodoc
class _$ValidDownloadsLoadedCopyWithImpl<$Res>
    implements $ValidDownloadsLoadedCopyWith<$Res> {
  _$ValidDownloadsLoadedCopyWithImpl(this._self, this._then);

  final ValidDownloadsLoaded _self;
  final $Res Function(ValidDownloadsLoaded) _then;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reciterName = null,Object? validDownloads = null,}) {
  return _then(ValidDownloadsLoaded(
reciterName: null == reciterName ? _self.reciterName : reciterName // ignore: cast_nullable_to_non_nullable
as String,validDownloads: null == validDownloads ? _self._validDownloads : validDownloads // ignore: cast_nullable_to_non_nullable
as List<DownloadItem>,
  ));
}


}

/// @nodoc


class Error implements DownloadsStatus {
  const Error({required this.message});
  

 final  String message;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorCopyWith<Error> get copyWith => _$ErrorCopyWithImpl<Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'DownloadsStatus.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ErrorCopyWith<$Res> implements $DownloadsStatusCopyWith<$Res> {
  factory $ErrorCopyWith(Error value, $Res Function(Error) _then) = _$ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ErrorCopyWithImpl<$Res>
    implements $ErrorCopyWith<$Res> {
  _$ErrorCopyWithImpl(this._self, this._then);

  final Error _self;
  final $Res Function(Error) _then;

/// Create a copy of DownloadsStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
