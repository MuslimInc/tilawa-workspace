// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HistoryEntity {
  /// Unique identifier for the history entry
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

  /// Last played position in milliseconds
  int get lastPositionMs;

  /// Total duration of the audio in milliseconds
  int get durationMs;

  /// Audio URL for playback
  String get audioUrl;

  /// Artwork URL
  String? get artworkUrl;

  /// Timestamp when last played
  DateTime get playedAt;

  /// Whether the surah was completed
  bool get completed;

  /// Number of times played
  int get playCount;

  /// Create a copy of HistoryEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HistoryEntityCopyWith<HistoryEntity> get copyWith =>
      _$HistoryEntityCopyWithImpl<HistoryEntity>(
        this as HistoryEntity,
        _$identity,
      );

  /// Serializes this HistoryEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HistoryEntity &&
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
            (identical(other.lastPositionMs, lastPositionMs) ||
                other.lastPositionMs == lastPositionMs) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.artworkUrl, artworkUrl) ||
                other.artworkUrl == artworkUrl) &&
            (identical(other.playedAt, playedAt) ||
                other.playedAt == playedAt) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount));
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
    lastPositionMs,
    durationMs,
    audioUrl,
    artworkUrl,
    playedAt,
    completed,
    playCount,
  );

  @override
  String toString() {
    return 'HistoryEntity(id: $id, surahId: $surahId, surahName: $surahName, surahNameEn: $surahNameEn, reciterId: $reciterId, reciterName: $reciterName, moshafId: $moshafId, moshafName: $moshafName, lastPositionMs: $lastPositionMs, durationMs: $durationMs, audioUrl: $audioUrl, artworkUrl: $artworkUrl, playedAt: $playedAt, completed: $completed, playCount: $playCount)';
  }
}

/// @nodoc
abstract mixin class $HistoryEntityCopyWith<$Res> {
  factory $HistoryEntityCopyWith(
    HistoryEntity value,
    $Res Function(HistoryEntity) _then,
  ) = _$HistoryEntityCopyWithImpl;
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
    int lastPositionMs,
    int durationMs,
    String audioUrl,
    String? artworkUrl,
    DateTime playedAt,
    bool completed,
    int playCount,
  });
}

/// @nodoc
class _$HistoryEntityCopyWithImpl<$Res>
    implements $HistoryEntityCopyWith<$Res> {
  _$HistoryEntityCopyWithImpl(this._self, this._then);

  final HistoryEntity _self;
  final $Res Function(HistoryEntity) _then;

  /// Create a copy of HistoryEntity
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
    Object? lastPositionMs = null,
    Object? durationMs = null,
    Object? audioUrl = null,
    Object? artworkUrl = freezed,
    Object? playedAt = null,
    Object? completed = null,
    Object? playCount = null,
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
        lastPositionMs: null == lastPositionMs
            ? _self.lastPositionMs
            : lastPositionMs // ignore: cast_nullable_to_non_nullable
                  as int,
        durationMs: null == durationMs
            ? _self.durationMs
            : durationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        audioUrl: null == audioUrl
            ? _self.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        artworkUrl: freezed == artworkUrl
            ? _self.artworkUrl
            : artworkUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        playedAt: null == playedAt
            ? _self.playedAt
            : playedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        completed: null == completed
            ? _self.completed
            : completed // ignore: cast_nullable_to_non_nullable
                  as bool,
        playCount: null == playCount
            ? _self.playCount
            : playCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [HistoryEntity].
extension HistoryEntityPatterns on HistoryEntity {
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
    TResult Function(_HistoryEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HistoryEntity() when $default != null:
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
    TResult Function(_HistoryEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HistoryEntity():
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
    TResult? Function(_HistoryEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HistoryEntity() when $default != null:
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
      int lastPositionMs,
      int durationMs,
      String audioUrl,
      String? artworkUrl,
      DateTime playedAt,
      bool completed,
      int playCount,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HistoryEntity() when $default != null:
        return $default(
          _that.id,
          _that.surahId,
          _that.surahName,
          _that.surahNameEn,
          _that.reciterId,
          _that.reciterName,
          _that.moshafId,
          _that.moshafName,
          _that.lastPositionMs,
          _that.durationMs,
          _that.audioUrl,
          _that.artworkUrl,
          _that.playedAt,
          _that.completed,
          _that.playCount,
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
      int lastPositionMs,
      int durationMs,
      String audioUrl,
      String? artworkUrl,
      DateTime playedAt,
      bool completed,
      int playCount,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HistoryEntity():
        return $default(
          _that.id,
          _that.surahId,
          _that.surahName,
          _that.surahNameEn,
          _that.reciterId,
          _that.reciterName,
          _that.moshafId,
          _that.moshafName,
          _that.lastPositionMs,
          _that.durationMs,
          _that.audioUrl,
          _that.artworkUrl,
          _that.playedAt,
          _that.completed,
          _that.playCount,
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
      int lastPositionMs,
      int durationMs,
      String audioUrl,
      String? artworkUrl,
      DateTime playedAt,
      bool completed,
      int playCount,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HistoryEntity() when $default != null:
        return $default(
          _that.id,
          _that.surahId,
          _that.surahName,
          _that.surahNameEn,
          _that.reciterId,
          _that.reciterName,
          _that.moshafId,
          _that.moshafName,
          _that.lastPositionMs,
          _that.durationMs,
          _that.audioUrl,
          _that.artworkUrl,
          _that.playedAt,
          _that.completed,
          _that.playCount,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _HistoryEntity extends HistoryEntity {
  const _HistoryEntity({
    required this.id,
    required this.surahId,
    required this.surahName,
    required this.surahNameEn,
    required this.reciterId,
    required this.reciterName,
    required this.moshafId,
    required this.moshafName,
    required this.lastPositionMs,
    required this.durationMs,
    required this.audioUrl,
    this.artworkUrl,
    required this.playedAt,
    this.completed = false,
    this.playCount = 1,
  }) : super._();
  factory _HistoryEntity.fromJson(Map<String, dynamic> json) =>
      _$HistoryEntityFromJson(json);

  /// Unique identifier for the history entry
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

  /// Last played position in milliseconds
  @override
  final int lastPositionMs;

  /// Total duration of the audio in milliseconds
  @override
  final int durationMs;

  /// Audio URL for playback
  @override
  final String audioUrl;

  /// Artwork URL
  @override
  final String? artworkUrl;

  /// Timestamp when last played
  @override
  final DateTime playedAt;

  /// Whether the surah was completed
  @override
  @JsonKey()
  final bool completed;

  /// Number of times played
  @override
  @JsonKey()
  final int playCount;

  /// Create a copy of HistoryEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HistoryEntityCopyWith<_HistoryEntity> get copyWith =>
      __$HistoryEntityCopyWithImpl<_HistoryEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HistoryEntityToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HistoryEntity &&
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
            (identical(other.lastPositionMs, lastPositionMs) ||
                other.lastPositionMs == lastPositionMs) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.artworkUrl, artworkUrl) ||
                other.artworkUrl == artworkUrl) &&
            (identical(other.playedAt, playedAt) ||
                other.playedAt == playedAt) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount));
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
    lastPositionMs,
    durationMs,
    audioUrl,
    artworkUrl,
    playedAt,
    completed,
    playCount,
  );

  @override
  String toString() {
    return 'HistoryEntity(id: $id, surahId: $surahId, surahName: $surahName, surahNameEn: $surahNameEn, reciterId: $reciterId, reciterName: $reciterName, moshafId: $moshafId, moshafName: $moshafName, lastPositionMs: $lastPositionMs, durationMs: $durationMs, audioUrl: $audioUrl, artworkUrl: $artworkUrl, playedAt: $playedAt, completed: $completed, playCount: $playCount)';
  }
}

/// @nodoc
abstract mixin class _$HistoryEntityCopyWith<$Res>
    implements $HistoryEntityCopyWith<$Res> {
  factory _$HistoryEntityCopyWith(
    _HistoryEntity value,
    $Res Function(_HistoryEntity) _then,
  ) = __$HistoryEntityCopyWithImpl;
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
    int lastPositionMs,
    int durationMs,
    String audioUrl,
    String? artworkUrl,
    DateTime playedAt,
    bool completed,
    int playCount,
  });
}

/// @nodoc
class __$HistoryEntityCopyWithImpl<$Res>
    implements _$HistoryEntityCopyWith<$Res> {
  __$HistoryEntityCopyWithImpl(this._self, this._then);

  final _HistoryEntity _self;
  final $Res Function(_HistoryEntity) _then;

  /// Create a copy of HistoryEntity
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
    Object? lastPositionMs = null,
    Object? durationMs = null,
    Object? audioUrl = null,
    Object? artworkUrl = freezed,
    Object? playedAt = null,
    Object? completed = null,
    Object? playCount = null,
  }) {
    return _then(
      _HistoryEntity(
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
        lastPositionMs: null == lastPositionMs
            ? _self.lastPositionMs
            : lastPositionMs // ignore: cast_nullable_to_non_nullable
                  as int,
        durationMs: null == durationMs
            ? _self.durationMs
            : durationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        audioUrl: null == audioUrl
            ? _self.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        artworkUrl: freezed == artworkUrl
            ? _self.artworkUrl
            : artworkUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        playedAt: null == playedAt
            ? _self.playedAt
            : playedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        completed: null == completed
            ? _self.completed
            : completed // ignore: cast_nullable_to_non_nullable
                  as bool,
        playCount: null == playCount
            ? _self.playCount
            : playCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}
