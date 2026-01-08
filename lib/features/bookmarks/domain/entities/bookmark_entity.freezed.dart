// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmark_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookmarkEntity {
  /// Unique identifier for the bookmark
  String get id;

  /// Surah number (1-114)
  int get surahId;

  /// Surah name in Arabic
  String get surahName;

  /// Surah name in English
  String get surahNameEn;

  /// Reciter ID
  String get reciterId;

  /// Reciter name
  String get reciterName;

  /// Moshaf ID
  int get moshafId;

  /// Moshaf name
  String get moshafName;

  /// Position in the audio (milliseconds)
  int get positionMs;

  /// Total duration of the audio (milliseconds)
  int get durationMs;

  /// Audio URL for playback
  String get audioUrl;

  /// Optional label/note for the bookmark
  String? get label;

  /// Artwork URL
  String? get artworkUrl;

  /// Creation timestamp
  DateTime get createdAt;

  /// Last updated timestamp
  DateTime get updatedAt;

  /// Create a copy of BookmarkEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarkEntityCopyWith<BookmarkEntity> get copyWith =>
      _$BookmarkEntityCopyWithImpl<BookmarkEntity>(
        this as BookmarkEntity,
        _$identity,
      );

  /// Serializes this BookmarkEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarkEntity &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.surahId, surahId) || other.surahId == surahId) &&
            (identical(other.surahName, surahName) ||
                other.surahName == surahName) &&
            (identical(other.surahNameEn, surahNameEn) ||
                other.surahNameEn == surahNameEn) &&
            (identical(other.reciterId, reciterId) ||
                other.reciterId == reciterId) &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName) &&
            (identical(other.moshafId, moshafId) ||
                other.moshafId == moshafId) &&
            (identical(other.moshafName, moshafName) ||
                other.moshafName == moshafName) &&
            (identical(other.positionMs, positionMs) ||
                other.positionMs == positionMs) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.artworkUrl, artworkUrl) ||
                other.artworkUrl == artworkUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    surahId,
    surahName,
    surahNameEn,
    reciterId,
    reciterName,
    moshafId,
    moshafName,
    positionMs,
    durationMs,
    audioUrl,
    label,
    artworkUrl,
    createdAt,
    updatedAt,
  );

  @override
  String toString() {
    return 'BookmarkEntity(id: $id, surahId: $surahId, surahName: $surahName, surahNameEn: $surahNameEn, reciterId: $reciterId, reciterName: $reciterName, moshafId: $moshafId, moshafName: $moshafName, positionMs: $positionMs, durationMs: $durationMs, audioUrl: $audioUrl, label: $label, artworkUrl: $artworkUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $BookmarkEntityCopyWith<$Res> {
  factory $BookmarkEntityCopyWith(
    BookmarkEntity value,
    $Res Function(BookmarkEntity) _then,
  ) = _$BookmarkEntityCopyWithImpl;
  @useResult
  $Res call({
    String id,
    int surahId,
    String surahName,
    String surahNameEn,
    String reciterId,
    String reciterName,
    int moshafId,
    String moshafName,
    int positionMs,
    int durationMs,
    String audioUrl,
    String? label,
    String? artworkUrl,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$BookmarkEntityCopyWithImpl<$Res>
    implements $BookmarkEntityCopyWith<$Res> {
  _$BookmarkEntityCopyWithImpl(this._self, this._then);

  final BookmarkEntity _self;
  final $Res Function(BookmarkEntity) _then;

  /// Create a copy of BookmarkEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? surahId = null,
    Object? surahName = null,
    Object? surahNameEn = null,
    Object? reciterId = null,
    Object? reciterName = null,
    Object? moshafId = null,
    Object? moshafName = null,
    Object? positionMs = null,
    Object? durationMs = null,
    Object? audioUrl = null,
    Object? label = freezed,
    Object? artworkUrl = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        surahId: null == surahId
            ? _self.surahId
            : surahId // ignore: cast_nullable_to_non_nullable
                  as int,
        surahName: null == surahName
            ? _self.surahName
            : surahName // ignore: cast_nullable_to_non_nullable
                  as String,
        surahNameEn: null == surahNameEn
            ? _self.surahNameEn
            : surahNameEn // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterId: null == reciterId
            ? _self.reciterId
            : reciterId // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterName: null == reciterName
            ? _self.reciterName
            : reciterName // ignore: cast_nullable_to_non_nullable
                  as String,
        moshafId: null == moshafId
            ? _self.moshafId
            : moshafId // ignore: cast_nullable_to_non_nullable
                  as int,
        moshafName: null == moshafName
            ? _self.moshafName
            : moshafName // ignore: cast_nullable_to_non_nullable
                  as String,
        positionMs: null == positionMs
            ? _self.positionMs
            : positionMs // ignore: cast_nullable_to_non_nullable
                  as int,
        durationMs: null == durationMs
            ? _self.durationMs
            : durationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        audioUrl: null == audioUrl
            ? _self.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        label: freezed == label
            ? _self.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        artworkUrl: freezed == artworkUrl
            ? _self.artworkUrl
            : artworkUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [BookmarkEntity].
extension BookmarkEntityPatterns on BookmarkEntity {
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
    TResult Function(_BookmarkEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BookmarkEntity() when $default != null:
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
    TResult Function(_BookmarkEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookmarkEntity():
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
    TResult? Function(_BookmarkEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookmarkEntity() when $default != null:
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
      int surahId,
      String surahName,
      String surahNameEn,
      String reciterId,
      String reciterName,
      int moshafId,
      String moshafName,
      int positionMs,
      int durationMs,
      String audioUrl,
      String? label,
      String? artworkUrl,
      DateTime createdAt,
      DateTime updatedAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BookmarkEntity() when $default != null:
        return $default(
          _that.id,
          _that.surahId,
          _that.surahName,
          _that.surahNameEn,
          _that.reciterId,
          _that.reciterName,
          _that.moshafId,
          _that.moshafName,
          _that.positionMs,
          _that.durationMs,
          _that.audioUrl,
          _that.label,
          _that.artworkUrl,
          _that.createdAt,
          _that.updatedAt,
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
      int surahId,
      String surahName,
      String surahNameEn,
      String reciterId,
      String reciterName,
      int moshafId,
      String moshafName,
      int positionMs,
      int durationMs,
      String audioUrl,
      String? label,
      String? artworkUrl,
      DateTime createdAt,
      DateTime updatedAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookmarkEntity():
        return $default(
          _that.id,
          _that.surahId,
          _that.surahName,
          _that.surahNameEn,
          _that.reciterId,
          _that.reciterName,
          _that.moshafId,
          _that.moshafName,
          _that.positionMs,
          _that.durationMs,
          _that.audioUrl,
          _that.label,
          _that.artworkUrl,
          _that.createdAt,
          _that.updatedAt,
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
      int surahId,
      String surahName,
      String surahNameEn,
      String reciterId,
      String reciterName,
      int moshafId,
      String moshafName,
      int positionMs,
      int durationMs,
      String audioUrl,
      String? label,
      String? artworkUrl,
      DateTime createdAt,
      DateTime updatedAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookmarkEntity() when $default != null:
        return $default(
          _that.id,
          _that.surahId,
          _that.surahName,
          _that.surahNameEn,
          _that.reciterId,
          _that.reciterName,
          _that.moshafId,
          _that.moshafName,
          _that.positionMs,
          _that.durationMs,
          _that.audioUrl,
          _that.label,
          _that.artworkUrl,
          _that.createdAt,
          _that.updatedAt,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BookmarkEntity extends BookmarkEntity {
  const _BookmarkEntity({
    required this.id,
    required this.surahId,
    required this.surahName,
    required this.surahNameEn,
    required this.reciterId,
    required this.reciterName,
    required this.moshafId,
    required this.moshafName,
    required this.positionMs,
    required this.durationMs,
    required this.audioUrl,
    this.label,
    this.artworkUrl,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  factory _BookmarkEntity.fromJson(Map<String, dynamic> json) =>
      _$BookmarkEntityFromJson(json);

  /// Unique identifier for the bookmark
  @override
  final String id;

  /// Surah number (1-114)
  @override
  final int surahId;

  /// Surah name in Arabic
  @override
  final String surahName;

  /// Surah name in English
  @override
  final String surahNameEn;

  /// Reciter ID
  @override
  final String reciterId;

  /// Reciter name
  @override
  final String reciterName;

  /// Moshaf ID
  @override
  final int moshafId;

  /// Moshaf name
  @override
  final String moshafName;

  /// Position in the audio (milliseconds)
  @override
  final int positionMs;

  /// Total duration of the audio (milliseconds)
  @override
  final int durationMs;

  /// Audio URL for playback
  @override
  final String audioUrl;

  /// Optional label/note for the bookmark
  @override
  final String? label;

  /// Artwork URL
  @override
  final String? artworkUrl;

  /// Creation timestamp
  @override
  final DateTime createdAt;

  /// Last updated timestamp
  @override
  final DateTime updatedAt;

  /// Create a copy of BookmarkEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookmarkEntityCopyWith<_BookmarkEntity> get copyWith =>
      __$BookmarkEntityCopyWithImpl<_BookmarkEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookmarkEntityToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookmarkEntity &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.surahId, surahId) || other.surahId == surahId) &&
            (identical(other.surahName, surahName) ||
                other.surahName == surahName) &&
            (identical(other.surahNameEn, surahNameEn) ||
                other.surahNameEn == surahNameEn) &&
            (identical(other.reciterId, reciterId) ||
                other.reciterId == reciterId) &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName) &&
            (identical(other.moshafId, moshafId) ||
                other.moshafId == moshafId) &&
            (identical(other.moshafName, moshafName) ||
                other.moshafName == moshafName) &&
            (identical(other.positionMs, positionMs) ||
                other.positionMs == positionMs) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.artworkUrl, artworkUrl) ||
                other.artworkUrl == artworkUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    surahId,
    surahName,
    surahNameEn,
    reciterId,
    reciterName,
    moshafId,
    moshafName,
    positionMs,
    durationMs,
    audioUrl,
    label,
    artworkUrl,
    createdAt,
    updatedAt,
  );

  @override
  String toString() {
    return 'BookmarkEntity(id: $id, surahId: $surahId, surahName: $surahName, surahNameEn: $surahNameEn, reciterId: $reciterId, reciterName: $reciterName, moshafId: $moshafId, moshafName: $moshafName, positionMs: $positionMs, durationMs: $durationMs, audioUrl: $audioUrl, label: $label, artworkUrl: $artworkUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$BookmarkEntityCopyWith<$Res>
    implements $BookmarkEntityCopyWith<$Res> {
  factory _$BookmarkEntityCopyWith(
    _BookmarkEntity value,
    $Res Function(_BookmarkEntity) _then,
  ) = __$BookmarkEntityCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    int surahId,
    String surahName,
    String surahNameEn,
    String reciterId,
    String reciterName,
    int moshafId,
    String moshafName,
    int positionMs,
    int durationMs,
    String audioUrl,
    String? label,
    String? artworkUrl,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$BookmarkEntityCopyWithImpl<$Res>
    implements _$BookmarkEntityCopyWith<$Res> {
  __$BookmarkEntityCopyWithImpl(this._self, this._then);

  final _BookmarkEntity _self;
  final $Res Function(_BookmarkEntity) _then;

  /// Create a copy of BookmarkEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? surahId = null,
    Object? surahName = null,
    Object? surahNameEn = null,
    Object? reciterId = null,
    Object? reciterName = null,
    Object? moshafId = null,
    Object? moshafName = null,
    Object? positionMs = null,
    Object? durationMs = null,
    Object? audioUrl = null,
    Object? label = freezed,
    Object? artworkUrl = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _BookmarkEntity(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        surahId: null == surahId
            ? _self.surahId
            : surahId // ignore: cast_nullable_to_non_nullable
                  as int,
        surahName: null == surahName
            ? _self.surahName
            : surahName // ignore: cast_nullable_to_non_nullable
                  as String,
        surahNameEn: null == surahNameEn
            ? _self.surahNameEn
            : surahNameEn // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterId: null == reciterId
            ? _self.reciterId
            : reciterId // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterName: null == reciterName
            ? _self.reciterName
            : reciterName // ignore: cast_nullable_to_non_nullable
                  as String,
        moshafId: null == moshafId
            ? _self.moshafId
            : moshafId // ignore: cast_nullable_to_non_nullable
                  as int,
        moshafName: null == moshafName
            ? _self.moshafName
            : moshafName // ignore: cast_nullable_to_non_nullable
                  as String,
        positionMs: null == positionMs
            ? _self.positionMs
            : positionMs // ignore: cast_nullable_to_non_nullable
                  as int,
        durationMs: null == durationMs
            ? _self.durationMs
            : durationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        audioUrl: null == audioUrl
            ? _self.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        label: freezed == label
            ? _self.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        artworkUrl: freezed == artworkUrl
            ? _self.artworkUrl
            : artworkUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}
