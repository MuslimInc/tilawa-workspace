// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadItem {
  String get id;
  String get title;
  String get url;
  String get filePath;
  String get reciterName;
  int? get reciterId;
  DownloadStatus get status;

  /// Progress value from 0.0 to 1.0
  double get progress;

  /// File size in bytes
  int get fileSize;

  /// Downloaded size in bytes
  int get downloadedSize;
  DateTime get createdAt;
  DateTime? get completedAt;

  /// Create a copy of DownloadItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DownloadItemCopyWith<DownloadItem> get copyWith =>
      _$DownloadItemCopyWithImpl<DownloadItem>(
        this as DownloadItem,
        _$identity,
      );

  /// Serializes this DownloadItem to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DownloadItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName) &&
            (identical(other.reciterId, reciterId) ||
                other.reciterId == reciterId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.downloadedSize, downloadedSize) ||
                other.downloadedSize == downloadedSize) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    url,
    filePath,
    reciterName,
    reciterId,
    status,
    progress,
    fileSize,
    downloadedSize,
    createdAt,
    completedAt,
  );

  @override
  String toString() {
    return 'DownloadItem(id: $id, title: $title, url: $url, filePath: $filePath, reciterName: $reciterName, reciterId: $reciterId, status: $status, progress: $progress, fileSize: $fileSize, downloadedSize: $downloadedSize, createdAt: $createdAt, completedAt: $completedAt)';
  }
}

/// @nodoc
abstract mixin class $DownloadItemCopyWith<$Res> {
  factory $DownloadItemCopyWith(
    DownloadItem value,
    $Res Function(DownloadItem) _then,
  ) = _$DownloadItemCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String title,
    String url,
    String filePath,
    String reciterName,
    int? reciterId,
    DownloadStatus status,
    double progress,
    int fileSize,
    int downloadedSize,
    DateTime createdAt,
    DateTime? completedAt,
  });
}

/// @nodoc
class _$DownloadItemCopyWithImpl<$Res> implements $DownloadItemCopyWith<$Res> {
  _$DownloadItemCopyWithImpl(this._self, this._then);

  final DownloadItem _self;
  final $Res Function(DownloadItem) _then;

  /// Create a copy of DownloadItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? url = null,
    Object? filePath = null,
    Object? reciterName = null,
    Object? reciterId = freezed,
    Object? status = null,
    Object? progress = null,
    Object? fileSize = null,
    Object? downloadedSize = null,
    Object? createdAt = null,
    Object? completedAt = freezed,
  }) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _self.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        filePath: null == filePath
            ? _self.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterName: null == reciterName
            ? _self.reciterName
            : reciterName // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterId: freezed == reciterId
            ? _self.reciterId
            : reciterId // ignore: cast_nullable_to_non_nullable
                  as int?,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as DownloadStatus,
        progress: null == progress
            ? _self.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
        fileSize: null == fileSize
            ? _self.fileSize
            : fileSize // ignore: cast_nullable_to_non_nullable
                  as int,
        downloadedSize: null == downloadedSize
            ? _self.downloadedSize
            : downloadedSize // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        completedAt: freezed == completedAt
            ? _self.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [DownloadItem].
extension DownloadItemPatterns on DownloadItem {
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
    TResult Function(_DownloadItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DownloadItem() when $default != null:
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
    TResult Function(_DownloadItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadItem():
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
    TResult? Function(_DownloadItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadItem() when $default != null:
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
      String id,
      String title,
      String url,
      String filePath,
      String reciterName,
      int? reciterId,
      DownloadStatus status,
      double progress,
      int fileSize,
      int downloadedSize,
      DateTime createdAt,
      DateTime? completedAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DownloadItem() when $default != null:
        return $default(
          _that.id,
          _that.title,
          _that.url,
          _that.filePath,
          _that.reciterName,
          _that.reciterId,
          _that.status,
          _that.progress,
          _that.fileSize,
          _that.downloadedSize,
          _that.createdAt,
          _that.completedAt,
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
      String id,
      String title,
      String url,
      String filePath,
      String reciterName,
      int? reciterId,
      DownloadStatus status,
      double progress,
      int fileSize,
      int downloadedSize,
      DateTime createdAt,
      DateTime? completedAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadItem():
        return $default(
          _that.id,
          _that.title,
          _that.url,
          _that.filePath,
          _that.reciterName,
          _that.reciterId,
          _that.status,
          _that.progress,
          _that.fileSize,
          _that.downloadedSize,
          _that.createdAt,
          _that.completedAt,
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
      String id,
      String title,
      String url,
      String filePath,
      String reciterName,
      int? reciterId,
      DownloadStatus status,
      double progress,
      int fileSize,
      int downloadedSize,
      DateTime createdAt,
      DateTime? completedAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadItem() when $default != null:
        return $default(
          _that.id,
          _that.title,
          _that.url,
          _that.filePath,
          _that.reciterName,
          _that.reciterId,
          _that.status,
          _that.progress,
          _that.fileSize,
          _that.downloadedSize,
          _that.createdAt,
          _that.completedAt,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _DownloadItem implements DownloadItem {
  const _DownloadItem({
    required this.id,
    required this.title,
    required this.url,
    required this.filePath,
    required this.reciterName,
    this.reciterId,
    required this.status,
    required this.progress,
    required this.fileSize,
    required this.downloadedSize,
    required this.createdAt,
    this.completedAt,
  });
  factory _DownloadItem.fromJson(Map<String, dynamic> json) =>
      _$DownloadItemFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String url;
  @override
  final String filePath;
  @override
  final String reciterName;
  @override
  final int? reciterId;
  @override
  final DownloadStatus status;

  /// Progress value from 0.0 to 1.0
  @override
  final double progress;

  /// File size in bytes
  @override
  final int fileSize;

  /// Downloaded size in bytes
  @override
  final int downloadedSize;
  @override
  final DateTime createdAt;
  @override
  final DateTime? completedAt;

  /// Create a copy of DownloadItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DownloadItemCopyWith<_DownloadItem> get copyWith =>
      __$DownloadItemCopyWithImpl<_DownloadItem>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DownloadItemToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DownloadItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName) &&
            (identical(other.reciterId, reciterId) ||
                other.reciterId == reciterId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.downloadedSize, downloadedSize) ||
                other.downloadedSize == downloadedSize) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    url,
    filePath,
    reciterName,
    reciterId,
    status,
    progress,
    fileSize,
    downloadedSize,
    createdAt,
    completedAt,
  );

  @override
  String toString() {
    return 'DownloadItem(id: $id, title: $title, url: $url, filePath: $filePath, reciterName: $reciterName, reciterId: $reciterId, status: $status, progress: $progress, fileSize: $fileSize, downloadedSize: $downloadedSize, createdAt: $createdAt, completedAt: $completedAt)';
  }
}

/// @nodoc
abstract mixin class _$DownloadItemCopyWith<$Res>
    implements $DownloadItemCopyWith<$Res> {
  factory _$DownloadItemCopyWith(
    _DownloadItem value,
    $Res Function(_DownloadItem) _then,
  ) = __$DownloadItemCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String url,
    String filePath,
    String reciterName,
    int? reciterId,
    DownloadStatus status,
    double progress,
    int fileSize,
    int downloadedSize,
    DateTime createdAt,
    DateTime? completedAt,
  });
}

/// @nodoc
class __$DownloadItemCopyWithImpl<$Res>
    implements _$DownloadItemCopyWith<$Res> {
  __$DownloadItemCopyWithImpl(this._self, this._then);

  final _DownloadItem _self;
  final $Res Function(_DownloadItem) _then;

  /// Create a copy of DownloadItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? url = null,
    Object? filePath = null,
    Object? reciterName = null,
    Object? reciterId = freezed,
    Object? status = null,
    Object? progress = null,
    Object? fileSize = null,
    Object? downloadedSize = null,
    Object? createdAt = null,
    Object? completedAt = freezed,
  }) {
    return _then(
      _DownloadItem(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _self.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        filePath: null == filePath
            ? _self.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterName: null == reciterName
            ? _self.reciterName
            : reciterName // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterId: freezed == reciterId
            ? _self.reciterId
            : reciterId // ignore: cast_nullable_to_non_nullable
                  as int?,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as DownloadStatus,
        progress: null == progress
            ? _self.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
        fileSize: null == fileSize
            ? _self.fileSize
            : fileSize // ignore: cast_nullable_to_non_nullable
                  as int,
        downloadedSize: null == downloadedSize
            ? _self.downloadedSize
            : downloadedSize // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        completedAt: freezed == completedAt
            ? _self.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}
