// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'downloads_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadsEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is DownloadsEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'DownloadsEvent()';
  }
}

/// @nodoc
class $DownloadsEventCopyWith<$Res> {
  $DownloadsEventCopyWith(DownloadsEvent _, $Res Function(DownloadsEvent) __);
}

/// Adds pattern-matching-related methods to [DownloadsEvent].
extension DownloadsEventPatterns on DownloadsEvent {
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
    TResult Function(LoadDownloads value)? loadDownloads,
    TResult Function(DownloadSurahEvent value)? downloadSurah,
    TResult Function(DeleteDownloadEvent value)? deleteDownload,
    TResult Function(DeleteReciterDownloads value)? deleteReciterDownloads,
    TResult Function(ClearAllDownloads value)? clearAllDownloads,
    TResult Function(CheckSurahDownloadedEvent value)? checkSurahDownloaded,
    TResult Function(ValidateDownloadedFileEvent value)? validateDownloadedFile,
    TResult Function(GetValidCompletedDownloadsEvent value)?
    getValidCompletedDownloads,
    TResult Function(PlayDownloadedSurahEvent value)? playDownloadedSurah,
    TResult Function(PlayAllDownloadsEvent value)? playAllDownloads,
    TResult Function(CheckPremiumAccessEvent value)? checkPremiumAccess,
    TResult Function(RetryDownloadEvent value)? retryDownload,
    TResult Function(RefreshDownloadsProgress value)? refreshDownloadsProgress,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case LoadDownloads() when loadDownloads != null:
        return loadDownloads(_that);
      case DownloadSurahEvent() when downloadSurah != null:
        return downloadSurah(_that);
      case DeleteDownloadEvent() when deleteDownload != null:
        return deleteDownload(_that);
      case DeleteReciterDownloads() when deleteReciterDownloads != null:
        return deleteReciterDownloads(_that);
      case ClearAllDownloads() when clearAllDownloads != null:
        return clearAllDownloads(_that);
      case CheckSurahDownloadedEvent() when checkSurahDownloaded != null:
        return checkSurahDownloaded(_that);
      case ValidateDownloadedFileEvent() when validateDownloadedFile != null:
        return validateDownloadedFile(_that);
      case GetValidCompletedDownloadsEvent()
          when getValidCompletedDownloads != null:
        return getValidCompletedDownloads(_that);
      case PlayDownloadedSurahEvent() when playDownloadedSurah != null:
        return playDownloadedSurah(_that);
      case PlayAllDownloadsEvent() when playAllDownloads != null:
        return playAllDownloads(_that);
      case CheckPremiumAccessEvent() when checkPremiumAccess != null:
        return checkPremiumAccess(_that);
      case RetryDownloadEvent() when retryDownload != null:
        return retryDownload(_that);
      case RefreshDownloadsProgress() when refreshDownloadsProgress != null:
        return refreshDownloadsProgress(_that);
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
    required TResult Function(LoadDownloads value) loadDownloads,
    required TResult Function(DownloadSurahEvent value) downloadSurah,
    required TResult Function(DeleteDownloadEvent value) deleteDownload,
    required TResult Function(DeleteReciterDownloads value)
    deleteReciterDownloads,
    required TResult Function(ClearAllDownloads value) clearAllDownloads,
    required TResult Function(CheckSurahDownloadedEvent value)
    checkSurahDownloaded,
    required TResult Function(ValidateDownloadedFileEvent value)
    validateDownloadedFile,
    required TResult Function(GetValidCompletedDownloadsEvent value)
    getValidCompletedDownloads,
    required TResult Function(PlayDownloadedSurahEvent value)
    playDownloadedSurah,
    required TResult Function(PlayAllDownloadsEvent value) playAllDownloads,
    required TResult Function(CheckPremiumAccessEvent value) checkPremiumAccess,
    required TResult Function(RetryDownloadEvent value) retryDownload,
    required TResult Function(RefreshDownloadsProgress value)
    refreshDownloadsProgress,
  }) {
    final _that = this;
    switch (_that) {
      case LoadDownloads():
        return loadDownloads(_that);
      case DownloadSurahEvent():
        return downloadSurah(_that);
      case DeleteDownloadEvent():
        return deleteDownload(_that);
      case DeleteReciterDownloads():
        return deleteReciterDownloads(_that);
      case ClearAllDownloads():
        return clearAllDownloads(_that);
      case CheckSurahDownloadedEvent():
        return checkSurahDownloaded(_that);
      case ValidateDownloadedFileEvent():
        return validateDownloadedFile(_that);
      case GetValidCompletedDownloadsEvent():
        return getValidCompletedDownloads(_that);
      case PlayDownloadedSurahEvent():
        return playDownloadedSurah(_that);
      case PlayAllDownloadsEvent():
        return playAllDownloads(_that);
      case CheckPremiumAccessEvent():
        return checkPremiumAccess(_that);
      case RetryDownloadEvent():
        return retryDownload(_that);
      case RefreshDownloadsProgress():
        return refreshDownloadsProgress(_that);
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
    TResult? Function(LoadDownloads value)? loadDownloads,
    TResult? Function(DownloadSurahEvent value)? downloadSurah,
    TResult? Function(DeleteDownloadEvent value)? deleteDownload,
    TResult? Function(DeleteReciterDownloads value)? deleteReciterDownloads,
    TResult? Function(ClearAllDownloads value)? clearAllDownloads,
    TResult? Function(CheckSurahDownloadedEvent value)? checkSurahDownloaded,
    TResult? Function(ValidateDownloadedFileEvent value)?
    validateDownloadedFile,
    TResult? Function(GetValidCompletedDownloadsEvent value)?
    getValidCompletedDownloads,
    TResult? Function(PlayDownloadedSurahEvent value)? playDownloadedSurah,
    TResult? Function(PlayAllDownloadsEvent value)? playAllDownloads,
    TResult? Function(CheckPremiumAccessEvent value)? checkPremiumAccess,
    TResult? Function(RetryDownloadEvent value)? retryDownload,
    TResult? Function(RefreshDownloadsProgress value)? refreshDownloadsProgress,
  }) {
    final _that = this;
    switch (_that) {
      case LoadDownloads() when loadDownloads != null:
        return loadDownloads(_that);
      case DownloadSurahEvent() when downloadSurah != null:
        return downloadSurah(_that);
      case DeleteDownloadEvent() when deleteDownload != null:
        return deleteDownload(_that);
      case DeleteReciterDownloads() when deleteReciterDownloads != null:
        return deleteReciterDownloads(_that);
      case ClearAllDownloads() when clearAllDownloads != null:
        return clearAllDownloads(_that);
      case CheckSurahDownloadedEvent() when checkSurahDownloaded != null:
        return checkSurahDownloaded(_that);
      case ValidateDownloadedFileEvent() when validateDownloadedFile != null:
        return validateDownloadedFile(_that);
      case GetValidCompletedDownloadsEvent()
          when getValidCompletedDownloads != null:
        return getValidCompletedDownloads(_that);
      case PlayDownloadedSurahEvent() when playDownloadedSurah != null:
        return playDownloadedSurah(_that);
      case PlayAllDownloadsEvent() when playAllDownloads != null:
        return playAllDownloads(_that);
      case CheckPremiumAccessEvent() when checkPremiumAccess != null:
        return checkPremiumAccess(_that);
      case RetryDownloadEvent() when retryDownload != null:
        return retryDownload(_that);
      case RefreshDownloadsProgress() when refreshDownloadsProgress != null:
        return refreshDownloadsProgress(_that);
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
    TResult Function()? loadDownloads,
    TResult Function(
      String surahId,
      String surahTitle,
      String reciterName,
      int reciterId,
    )?
    downloadSurah,
    TResult Function(String downloadId)? deleteDownload,
    TResult Function(String reciterName)? deleteReciterDownloads,
    TResult Function()? clearAllDownloads,
    TResult Function(String surahId, String reciterName)? checkSurahDownloaded,
    TResult Function(String downloadId)? validateDownloadedFile,
    TResult Function(String reciterName)? getValidCompletedDownloads,
    TResult Function(String downloadId)? playDownloadedSurah,
    TResult Function(String reciterName)? playAllDownloads,
    TResult Function()? checkPremiumAccess,
    TResult Function(String downloadId)? retryDownload,
    TResult Function()? refreshDownloadsProgress,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case LoadDownloads() when loadDownloads != null:
        return loadDownloads();
      case DownloadSurahEvent() when downloadSurah != null:
        return downloadSurah(
          _that.surahId,
          _that.surahTitle,
          _that.reciterName,
          _that.reciterId,
        );
      case DeleteDownloadEvent() when deleteDownload != null:
        return deleteDownload(_that.downloadId);
      case DeleteReciterDownloads() when deleteReciterDownloads != null:
        return deleteReciterDownloads(_that.reciterName);
      case ClearAllDownloads() when clearAllDownloads != null:
        return clearAllDownloads();
      case CheckSurahDownloadedEvent() when checkSurahDownloaded != null:
        return checkSurahDownloaded(_that.surahId, _that.reciterName);
      case ValidateDownloadedFileEvent() when validateDownloadedFile != null:
        return validateDownloadedFile(_that.downloadId);
      case GetValidCompletedDownloadsEvent()
          when getValidCompletedDownloads != null:
        return getValidCompletedDownloads(_that.reciterName);
      case PlayDownloadedSurahEvent() when playDownloadedSurah != null:
        return playDownloadedSurah(_that.downloadId);
      case PlayAllDownloadsEvent() when playAllDownloads != null:
        return playAllDownloads(_that.reciterName);
      case CheckPremiumAccessEvent() when checkPremiumAccess != null:
        return checkPremiumAccess();
      case RetryDownloadEvent() when retryDownload != null:
        return retryDownload(_that.downloadId);
      case RefreshDownloadsProgress() when refreshDownloadsProgress != null:
        return refreshDownloadsProgress();
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
    required TResult Function() loadDownloads,
    required TResult Function(
      String surahId,
      String surahTitle,
      String reciterName,
      int reciterId,
    )
    downloadSurah,
    required TResult Function(String downloadId) deleteDownload,
    required TResult Function(String reciterName) deleteReciterDownloads,
    required TResult Function() clearAllDownloads,
    required TResult Function(String surahId, String reciterName)
    checkSurahDownloaded,
    required TResult Function(String downloadId) validateDownloadedFile,
    required TResult Function(String reciterName) getValidCompletedDownloads,
    required TResult Function(String downloadId) playDownloadedSurah,
    required TResult Function(String reciterName) playAllDownloads,
    required TResult Function() checkPremiumAccess,
    required TResult Function(String downloadId) retryDownload,
    required TResult Function() refreshDownloadsProgress,
  }) {
    final _that = this;
    switch (_that) {
      case LoadDownloads():
        return loadDownloads();
      case DownloadSurahEvent():
        return downloadSurah(
          _that.surahId,
          _that.surahTitle,
          _that.reciterName,
          _that.reciterId,
        );
      case DeleteDownloadEvent():
        return deleteDownload(_that.downloadId);
      case DeleteReciterDownloads():
        return deleteReciterDownloads(_that.reciterName);
      case ClearAllDownloads():
        return clearAllDownloads();
      case CheckSurahDownloadedEvent():
        return checkSurahDownloaded(_that.surahId, _that.reciterName);
      case ValidateDownloadedFileEvent():
        return validateDownloadedFile(_that.downloadId);
      case GetValidCompletedDownloadsEvent():
        return getValidCompletedDownloads(_that.reciterName);
      case PlayDownloadedSurahEvent():
        return playDownloadedSurah(_that.downloadId);
      case PlayAllDownloadsEvent():
        return playAllDownloads(_that.reciterName);
      case CheckPremiumAccessEvent():
        return checkPremiumAccess();
      case RetryDownloadEvent():
        return retryDownload(_that.downloadId);
      case RefreshDownloadsProgress():
        return refreshDownloadsProgress();
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
    TResult? Function()? loadDownloads,
    TResult? Function(
      String surahId,
      String surahTitle,
      String reciterName,
      int reciterId,
    )?
    downloadSurah,
    TResult? Function(String downloadId)? deleteDownload,
    TResult? Function(String reciterName)? deleteReciterDownloads,
    TResult? Function()? clearAllDownloads,
    TResult? Function(String surahId, String reciterName)? checkSurahDownloaded,
    TResult? Function(String downloadId)? validateDownloadedFile,
    TResult? Function(String reciterName)? getValidCompletedDownloads,
    TResult? Function(String downloadId)? playDownloadedSurah,
    TResult? Function(String reciterName)? playAllDownloads,
    TResult? Function()? checkPremiumAccess,
    TResult? Function(String downloadId)? retryDownload,
    TResult? Function()? refreshDownloadsProgress,
  }) {
    final _that = this;
    switch (_that) {
      case LoadDownloads() when loadDownloads != null:
        return loadDownloads();
      case DownloadSurahEvent() when downloadSurah != null:
        return downloadSurah(
          _that.surahId,
          _that.surahTitle,
          _that.reciterName,
          _that.reciterId,
        );
      case DeleteDownloadEvent() when deleteDownload != null:
        return deleteDownload(_that.downloadId);
      case DeleteReciterDownloads() when deleteReciterDownloads != null:
        return deleteReciterDownloads(_that.reciterName);
      case ClearAllDownloads() when clearAllDownloads != null:
        return clearAllDownloads();
      case CheckSurahDownloadedEvent() when checkSurahDownloaded != null:
        return checkSurahDownloaded(_that.surahId, _that.reciterName);
      case ValidateDownloadedFileEvent() when validateDownloadedFile != null:
        return validateDownloadedFile(_that.downloadId);
      case GetValidCompletedDownloadsEvent()
          when getValidCompletedDownloads != null:
        return getValidCompletedDownloads(_that.reciterName);
      case PlayDownloadedSurahEvent() when playDownloadedSurah != null:
        return playDownloadedSurah(_that.downloadId);
      case PlayAllDownloadsEvent() when playAllDownloads != null:
        return playAllDownloads(_that.reciterName);
      case CheckPremiumAccessEvent() when checkPremiumAccess != null:
        return checkPremiumAccess();
      case RetryDownloadEvent() when retryDownload != null:
        return retryDownload(_that.downloadId);
      case RefreshDownloadsProgress() when refreshDownloadsProgress != null:
        return refreshDownloadsProgress();
      case _:
        return null;
    }
  }
}

/// @nodoc

class LoadDownloads implements DownloadsEvent {
  const LoadDownloads();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LoadDownloads);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'DownloadsEvent.loadDownloads()';
  }
}

/// @nodoc

class DownloadSurahEvent implements DownloadsEvent {
  const DownloadSurahEvent({
    required this.surahId,
    required this.surahTitle,
    required this.reciterName,
    required this.reciterId,
  });

  final String surahId;
  final String surahTitle;
  final String reciterName;
  final int reciterId;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DownloadSurahEventCopyWith<DownloadSurahEvent> get copyWith =>
      _$DownloadSurahEventCopyWithImpl<DownloadSurahEvent>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DownloadSurahEvent &&
            (identical(other.surahId, surahId) || other.surahId == surahId) &&
            (identical(other.surahTitle, surahTitle) ||
                other.surahTitle == surahTitle) &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName) &&
            (identical(other.reciterId, reciterId) ||
                other.reciterId == reciterId));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, surahId, surahTitle, reciterName, reciterId);

  @override
  String toString() {
    return 'DownloadsEvent.downloadSurah(surahId: $surahId, surahTitle: $surahTitle, reciterName: $reciterName, reciterId: $reciterId)';
  }
}

/// @nodoc
abstract mixin class $DownloadSurahEventCopyWith<$Res>
    implements $DownloadsEventCopyWith<$Res> {
  factory $DownloadSurahEventCopyWith(
    DownloadSurahEvent value,
    $Res Function(DownloadSurahEvent) _then,
  ) = _$DownloadSurahEventCopyWithImpl;
  @useResult
  $Res call({
    String surahId,
    String surahTitle,
    String reciterName,
    int reciterId,
  });
}

/// @nodoc
class _$DownloadSurahEventCopyWithImpl<$Res>
    implements $DownloadSurahEventCopyWith<$Res> {
  _$DownloadSurahEventCopyWithImpl(this._self, this._then);

  final DownloadSurahEvent _self;
  final $Res Function(DownloadSurahEvent) _then;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? surahId = null,
    Object? surahTitle = null,
    Object? reciterName = null,
    Object? reciterId = null,
  }) {
    return _then(
      DownloadSurahEvent(
        surahId: null == surahId
            ? _self.surahId
            : surahId // ignore: cast_nullable_to_non_nullable
                  as String,
        surahTitle: null == surahTitle
            ? _self.surahTitle
            : surahTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterName: null == reciterName
            ? _self.reciterName
            : reciterName // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterId: null == reciterId
            ? _self.reciterId
            : reciterId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class DeleteDownloadEvent implements DownloadsEvent {
  const DeleteDownloadEvent({required this.downloadId});

  final String downloadId;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DeleteDownloadEventCopyWith<DeleteDownloadEvent> get copyWith =>
      _$DeleteDownloadEventCopyWithImpl<DeleteDownloadEvent>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DeleteDownloadEvent &&
            (identical(other.downloadId, downloadId) ||
                other.downloadId == downloadId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, downloadId);

  @override
  String toString() {
    return 'DownloadsEvent.deleteDownload(downloadId: $downloadId)';
  }
}

/// @nodoc
abstract mixin class $DeleteDownloadEventCopyWith<$Res>
    implements $DownloadsEventCopyWith<$Res> {
  factory $DeleteDownloadEventCopyWith(
    DeleteDownloadEvent value,
    $Res Function(DeleteDownloadEvent) _then,
  ) = _$DeleteDownloadEventCopyWithImpl;
  @useResult
  $Res call({String downloadId});
}

/// @nodoc
class _$DeleteDownloadEventCopyWithImpl<$Res>
    implements $DeleteDownloadEventCopyWith<$Res> {
  _$DeleteDownloadEventCopyWithImpl(this._self, this._then);

  final DeleteDownloadEvent _self;
  final $Res Function(DeleteDownloadEvent) _then;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? downloadId = null}) {
    return _then(
      DeleteDownloadEvent(
        downloadId: null == downloadId
            ? _self.downloadId
            : downloadId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class DeleteReciterDownloads implements DownloadsEvent {
  const DeleteReciterDownloads({required this.reciterName});

  final String reciterName;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DeleteReciterDownloadsCopyWith<DeleteReciterDownloads> get copyWith =>
      _$DeleteReciterDownloadsCopyWithImpl<DeleteReciterDownloads>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DeleteReciterDownloads &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reciterName);

  @override
  String toString() {
    return 'DownloadsEvent.deleteReciterDownloads(reciterName: $reciterName)';
  }
}

/// @nodoc
abstract mixin class $DeleteReciterDownloadsCopyWith<$Res>
    implements $DownloadsEventCopyWith<$Res> {
  factory $DeleteReciterDownloadsCopyWith(
    DeleteReciterDownloads value,
    $Res Function(DeleteReciterDownloads) _then,
  ) = _$DeleteReciterDownloadsCopyWithImpl;
  @useResult
  $Res call({String reciterName});
}

/// @nodoc
class _$DeleteReciterDownloadsCopyWithImpl<$Res>
    implements $DeleteReciterDownloadsCopyWith<$Res> {
  _$DeleteReciterDownloadsCopyWithImpl(this._self, this._then);

  final DeleteReciterDownloads _self;
  final $Res Function(DeleteReciterDownloads) _then;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? reciterName = null}) {
    return _then(
      DeleteReciterDownloads(
        reciterName: null == reciterName
            ? _self.reciterName
            : reciterName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class ClearAllDownloads implements DownloadsEvent {
  const ClearAllDownloads();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ClearAllDownloads);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'DownloadsEvent.clearAllDownloads()';
  }
}

/// @nodoc

class CheckSurahDownloadedEvent implements DownloadsEvent {
  const CheckSurahDownloadedEvent({
    required this.surahId,
    required this.reciterName,
  });

  final String surahId;
  final String reciterName;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CheckSurahDownloadedEventCopyWith<CheckSurahDownloadedEvent> get copyWith =>
      _$CheckSurahDownloadedEventCopyWithImpl<CheckSurahDownloadedEvent>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CheckSurahDownloadedEvent &&
            (identical(other.surahId, surahId) || other.surahId == surahId) &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, surahId, reciterName);

  @override
  String toString() {
    return 'DownloadsEvent.checkSurahDownloaded(surahId: $surahId, reciterName: $reciterName)';
  }
}

/// @nodoc
abstract mixin class $CheckSurahDownloadedEventCopyWith<$Res>
    implements $DownloadsEventCopyWith<$Res> {
  factory $CheckSurahDownloadedEventCopyWith(
    CheckSurahDownloadedEvent value,
    $Res Function(CheckSurahDownloadedEvent) _then,
  ) = _$CheckSurahDownloadedEventCopyWithImpl;
  @useResult
  $Res call({String surahId, String reciterName});
}

/// @nodoc
class _$CheckSurahDownloadedEventCopyWithImpl<$Res>
    implements $CheckSurahDownloadedEventCopyWith<$Res> {
  _$CheckSurahDownloadedEventCopyWithImpl(this._self, this._then);

  final CheckSurahDownloadedEvent _self;
  final $Res Function(CheckSurahDownloadedEvent) _then;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? surahId = null, Object? reciterName = null}) {
    return _then(
      CheckSurahDownloadedEvent(
        surahId: null == surahId
            ? _self.surahId
            : surahId // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterName: null == reciterName
            ? _self.reciterName
            : reciterName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class ValidateDownloadedFileEvent implements DownloadsEvent {
  const ValidateDownloadedFileEvent({required this.downloadId});

  final String downloadId;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ValidateDownloadedFileEventCopyWith<ValidateDownloadedFileEvent>
  get copyWith =>
      _$ValidateDownloadedFileEventCopyWithImpl<ValidateDownloadedFileEvent>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ValidateDownloadedFileEvent &&
            (identical(other.downloadId, downloadId) ||
                other.downloadId == downloadId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, downloadId);

  @override
  String toString() {
    return 'DownloadsEvent.validateDownloadedFile(downloadId: $downloadId)';
  }
}

/// @nodoc
abstract mixin class $ValidateDownloadedFileEventCopyWith<$Res>
    implements $DownloadsEventCopyWith<$Res> {
  factory $ValidateDownloadedFileEventCopyWith(
    ValidateDownloadedFileEvent value,
    $Res Function(ValidateDownloadedFileEvent) _then,
  ) = _$ValidateDownloadedFileEventCopyWithImpl;
  @useResult
  $Res call({String downloadId});
}

/// @nodoc
class _$ValidateDownloadedFileEventCopyWithImpl<$Res>
    implements $ValidateDownloadedFileEventCopyWith<$Res> {
  _$ValidateDownloadedFileEventCopyWithImpl(this._self, this._then);

  final ValidateDownloadedFileEvent _self;
  final $Res Function(ValidateDownloadedFileEvent) _then;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? downloadId = null}) {
    return _then(
      ValidateDownloadedFileEvent(
        downloadId: null == downloadId
            ? _self.downloadId
            : downloadId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class GetValidCompletedDownloadsEvent implements DownloadsEvent {
  const GetValidCompletedDownloadsEvent({required this.reciterName});

  final String reciterName;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GetValidCompletedDownloadsEventCopyWith<GetValidCompletedDownloadsEvent>
  get copyWith =>
      _$GetValidCompletedDownloadsEventCopyWithImpl<
        GetValidCompletedDownloadsEvent
      >(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GetValidCompletedDownloadsEvent &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reciterName);

  @override
  String toString() {
    return 'DownloadsEvent.getValidCompletedDownloads(reciterName: $reciterName)';
  }
}

/// @nodoc
abstract mixin class $GetValidCompletedDownloadsEventCopyWith<$Res>
    implements $DownloadsEventCopyWith<$Res> {
  factory $GetValidCompletedDownloadsEventCopyWith(
    GetValidCompletedDownloadsEvent value,
    $Res Function(GetValidCompletedDownloadsEvent) _then,
  ) = _$GetValidCompletedDownloadsEventCopyWithImpl;
  @useResult
  $Res call({String reciterName});
}

/// @nodoc
class _$GetValidCompletedDownloadsEventCopyWithImpl<$Res>
    implements $GetValidCompletedDownloadsEventCopyWith<$Res> {
  _$GetValidCompletedDownloadsEventCopyWithImpl(this._self, this._then);

  final GetValidCompletedDownloadsEvent _self;
  final $Res Function(GetValidCompletedDownloadsEvent) _then;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? reciterName = null}) {
    return _then(
      GetValidCompletedDownloadsEvent(
        reciterName: null == reciterName
            ? _self.reciterName
            : reciterName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class PlayDownloadedSurahEvent implements DownloadsEvent {
  const PlayDownloadedSurahEvent({required this.downloadId});

  final String downloadId;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlayDownloadedSurahEventCopyWith<PlayDownloadedSurahEvent> get copyWith =>
      _$PlayDownloadedSurahEventCopyWithImpl<PlayDownloadedSurahEvent>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlayDownloadedSurahEvent &&
            (identical(other.downloadId, downloadId) ||
                other.downloadId == downloadId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, downloadId);

  @override
  String toString() {
    return 'DownloadsEvent.playDownloadedSurah(downloadId: $downloadId)';
  }
}

/// @nodoc
abstract mixin class $PlayDownloadedSurahEventCopyWith<$Res>
    implements $DownloadsEventCopyWith<$Res> {
  factory $PlayDownloadedSurahEventCopyWith(
    PlayDownloadedSurahEvent value,
    $Res Function(PlayDownloadedSurahEvent) _then,
  ) = _$PlayDownloadedSurahEventCopyWithImpl;
  @useResult
  $Res call({String downloadId});
}

/// @nodoc
class _$PlayDownloadedSurahEventCopyWithImpl<$Res>
    implements $PlayDownloadedSurahEventCopyWith<$Res> {
  _$PlayDownloadedSurahEventCopyWithImpl(this._self, this._then);

  final PlayDownloadedSurahEvent _self;
  final $Res Function(PlayDownloadedSurahEvent) _then;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? downloadId = null}) {
    return _then(
      PlayDownloadedSurahEvent(
        downloadId: null == downloadId
            ? _self.downloadId
            : downloadId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class PlayAllDownloadsEvent implements DownloadsEvent {
  const PlayAllDownloadsEvent({required this.reciterName});

  final String reciterName;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlayAllDownloadsEventCopyWith<PlayAllDownloadsEvent> get copyWith =>
      _$PlayAllDownloadsEventCopyWithImpl<PlayAllDownloadsEvent>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlayAllDownloadsEvent &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reciterName);

  @override
  String toString() {
    return 'DownloadsEvent.playAllDownloads(reciterName: $reciterName)';
  }
}

/// @nodoc
abstract mixin class $PlayAllDownloadsEventCopyWith<$Res>
    implements $DownloadsEventCopyWith<$Res> {
  factory $PlayAllDownloadsEventCopyWith(
    PlayAllDownloadsEvent value,
    $Res Function(PlayAllDownloadsEvent) _then,
  ) = _$PlayAllDownloadsEventCopyWithImpl;
  @useResult
  $Res call({String reciterName});
}

/// @nodoc
class _$PlayAllDownloadsEventCopyWithImpl<$Res>
    implements $PlayAllDownloadsEventCopyWith<$Res> {
  _$PlayAllDownloadsEventCopyWithImpl(this._self, this._then);

  final PlayAllDownloadsEvent _self;
  final $Res Function(PlayAllDownloadsEvent) _then;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? reciterName = null}) {
    return _then(
      PlayAllDownloadsEvent(
        reciterName: null == reciterName
            ? _self.reciterName
            : reciterName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class CheckPremiumAccessEvent implements DownloadsEvent {
  const CheckPremiumAccessEvent();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is CheckPremiumAccessEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'DownloadsEvent.checkPremiumAccess()';
  }
}

/// @nodoc

class RetryDownloadEvent implements DownloadsEvent {
  const RetryDownloadEvent({required this.downloadId});

  final String downloadId;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RetryDownloadEventCopyWith<RetryDownloadEvent> get copyWith =>
      _$RetryDownloadEventCopyWithImpl<RetryDownloadEvent>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RetryDownloadEvent &&
            (identical(other.downloadId, downloadId) ||
                other.downloadId == downloadId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, downloadId);

  @override
  String toString() {
    return 'DownloadsEvent.retryDownload(downloadId: $downloadId)';
  }
}

/// @nodoc
abstract mixin class $RetryDownloadEventCopyWith<$Res>
    implements $DownloadsEventCopyWith<$Res> {
  factory $RetryDownloadEventCopyWith(
    RetryDownloadEvent value,
    $Res Function(RetryDownloadEvent) _then,
  ) = _$RetryDownloadEventCopyWithImpl;
  @useResult
  $Res call({String downloadId});
}

/// @nodoc
class _$RetryDownloadEventCopyWithImpl<$Res>
    implements $RetryDownloadEventCopyWith<$Res> {
  _$RetryDownloadEventCopyWithImpl(this._self, this._then);

  final RetryDownloadEvent _self;
  final $Res Function(RetryDownloadEvent) _then;

  /// Create a copy of DownloadsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? downloadId = null}) {
    return _then(
      RetryDownloadEvent(
        downloadId: null == downloadId
            ? _self.downloadId
            : downloadId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class RefreshDownloadsProgress implements DownloadsEvent {
  const RefreshDownloadsProgress();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RefreshDownloadsProgress);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'DownloadsEvent.refreshDownloadsProgress()';
  }
}

/// @nodoc
mixin _$DownloadsState {
  DownloadsStateStatus get status;
  Map<String, Map<String, List<DownloadItem>>> get downloads;
  int get totalDownloadsSize;
  String? get errorMessage;

  /// Create a copy of DownloadsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DownloadsStateCopyWith<DownloadsState> get copyWith =>
      _$DownloadsStateCopyWithImpl<DownloadsState>(
        this as DownloadsState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DownloadsState &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other.downloads, downloads) &&
            (identical(other.totalDownloadsSize, totalDownloadsSize) ||
                other.totalDownloadsSize == totalDownloadsSize) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    const DeepCollectionEquality().hash(downloads),
    totalDownloadsSize,
    errorMessage,
  );

  @override
  String toString() {
    return 'DownloadsState(status: $status, downloads: $downloads, totalDownloadsSize: $totalDownloadsSize, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class $DownloadsStateCopyWith<$Res> {
  factory $DownloadsStateCopyWith(
    DownloadsState value,
    $Res Function(DownloadsState) _then,
  ) = _$DownloadsStateCopyWithImpl;
  @useResult
  $Res call({
    DownloadsStateStatus status,
    Map<String, Map<String, List<DownloadItem>>> downloads,
    int totalDownloadsSize,
    String? errorMessage,
  });
}

/// @nodoc
class _$DownloadsStateCopyWithImpl<$Res>
    implements $DownloadsStateCopyWith<$Res> {
  _$DownloadsStateCopyWithImpl(this._self, this._then);

  final DownloadsState _self;
  final $Res Function(DownloadsState) _then;

  /// Create a copy of DownloadsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? downloads = null,
    Object? totalDownloadsSize = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _self.copyWith(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as DownloadsStateStatus,
        downloads: null == downloads
            ? _self.downloads
            : downloads // ignore: cast_nullable_to_non_nullable
                  as Map<String, Map<String, List<DownloadItem>>>,
        totalDownloadsSize: null == totalDownloadsSize
            ? _self.totalDownloadsSize
            : totalDownloadsSize // ignore: cast_nullable_to_non_nullable
                  as int,
        errorMessage: freezed == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [DownloadsState].
extension DownloadsStatePatterns on DownloadsState {
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
    TResult Function(_DownloadsState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DownloadsState() when $default != null:
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
    TResult Function(_DownloadsState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadsState():
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
    TResult? Function(_DownloadsState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadsState() when $default != null:
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
      DownloadsStateStatus status,
      Map<String, Map<String, List<DownloadItem>>> downloads,
      int totalDownloadsSize,
      String? errorMessage,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DownloadsState() when $default != null:
        return $default(
          _that.status,
          _that.downloads,
          _that.totalDownloadsSize,
          _that.errorMessage,
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
      DownloadsStateStatus status,
      Map<String, Map<String, List<DownloadItem>>> downloads,
      int totalDownloadsSize,
      String? errorMessage,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadsState():
        return $default(
          _that.status,
          _that.downloads,
          _that.totalDownloadsSize,
          _that.errorMessage,
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
      DownloadsStateStatus status,
      Map<String, Map<String, List<DownloadItem>>> downloads,
      int totalDownloadsSize,
      String? errorMessage,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadsState() when $default != null:
        return $default(
          _that.status,
          _that.downloads,
          _that.totalDownloadsSize,
          _that.errorMessage,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DownloadsState extends DownloadsState {
  const _DownloadsState({
    this.status = DownloadsStateStatus.initial,
    final Map<String, Map<String, List<DownloadItem>>> downloads = const {},
    this.totalDownloadsSize = 0,
    this.errorMessage,
  }) : _downloads = downloads,
       super._();

  @override
  @JsonKey()
  final DownloadsStateStatus status;
  final Map<String, Map<String, List<DownloadItem>>> _downloads;
  @override
  @JsonKey()
  Map<String, Map<String, List<DownloadItem>>> get downloads {
    if (_downloads is EqualUnmodifiableMapView) return _downloads;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_downloads);
  }

  @override
  @JsonKey()
  final int totalDownloadsSize;
  @override
  final String? errorMessage;

  /// Create a copy of DownloadsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DownloadsStateCopyWith<_DownloadsState> get copyWith =>
      __$DownloadsStateCopyWithImpl<_DownloadsState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DownloadsState &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(
              other._downloads,
              _downloads,
            ) &&
            (identical(other.totalDownloadsSize, totalDownloadsSize) ||
                other.totalDownloadsSize == totalDownloadsSize) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    const DeepCollectionEquality().hash(_downloads),
    totalDownloadsSize,
    errorMessage,
  );

  @override
  String toString() {
    return 'DownloadsState(status: $status, downloads: $downloads, totalDownloadsSize: $totalDownloadsSize, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class _$DownloadsStateCopyWith<$Res>
    implements $DownloadsStateCopyWith<$Res> {
  factory _$DownloadsStateCopyWith(
    _DownloadsState value,
    $Res Function(_DownloadsState) _then,
  ) = __$DownloadsStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    DownloadsStateStatus status,
    Map<String, Map<String, List<DownloadItem>>> downloads,
    int totalDownloadsSize,
    String? errorMessage,
  });
}

/// @nodoc
class __$DownloadsStateCopyWithImpl<$Res>
    implements _$DownloadsStateCopyWith<$Res> {
  __$DownloadsStateCopyWithImpl(this._self, this._then);

  final _DownloadsState _self;
  final $Res Function(_DownloadsState) _then;

  /// Create a copy of DownloadsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? status = null,
    Object? downloads = null,
    Object? totalDownloadsSize = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _DownloadsState(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as DownloadsStateStatus,
        downloads: null == downloads
            ? _self._downloads
            : downloads // ignore: cast_nullable_to_non_nullable
                  as Map<String, Map<String, List<DownloadItem>>>,
        totalDownloadsSize: null == totalDownloadsSize
            ? _self.totalDownloadsSize
            : totalDownloadsSize // ignore: cast_nullable_to_non_nullable
                  as int,
        errorMessage: freezed == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
