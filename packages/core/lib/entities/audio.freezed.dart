// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AudioEntity {
  String get id;
  String get title;
  String get url;
  Duration get duration;
  String? get artist;
  String? get album;
  String? get artUri;

  /// Create a copy of AudioEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AudioEntityCopyWith<AudioEntity> get copyWith =>
      _$AudioEntityCopyWithImpl<AudioEntity>(this as AudioEntity, _$identity);

  /// Serializes this AudioEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AudioEntity &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.album, album) || other.album == album) &&
            (identical(other.artUri, artUri) || other.artUri == artUri));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, url, duration, artist, album, artUri);

  @override
  String toString() {
    return 'AudioEntity(id: $id, title: $title, url: $url, duration: $duration, artist: $artist, album: $album, artUri: $artUri)';
  }
}

/// @nodoc
abstract mixin class $AudioEntityCopyWith<$Res> {
  factory $AudioEntityCopyWith(
    AudioEntity value,
    $Res Function(AudioEntity) _then,
  ) = _$AudioEntityCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String title,
    String url,
    Duration duration,
    String? artist,
    String? album,
    String? artUri,
  });
}

/// @nodoc
class _$AudioEntityCopyWithImpl<$Res> implements $AudioEntityCopyWith<$Res> {
  _$AudioEntityCopyWithImpl(this._self, this._then);

  final AudioEntity _self;
  final $Res Function(AudioEntity) _then;

  /// Create a copy of AudioEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? url = null,
    Object? duration = null,
    Object? artist = freezed,
    Object? album = freezed,
    Object? artUri = freezed,
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
        duration: null == duration
            ? _self.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as Duration,
        artist: freezed == artist
            ? _self.artist
            : artist // ignore: cast_nullable_to_non_nullable
                  as String?,
        album: freezed == album
            ? _self.album
            : album // ignore: cast_nullable_to_non_nullable
                  as String?,
        artUri: freezed == artUri
            ? _self.artUri
            : artUri // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AudioEntity].
extension AudioEntityPatterns on AudioEntity {
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
    TResult Function(_AudioEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AudioEntity() when $default != null:
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
    TResult Function(_AudioEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioEntity():
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
    TResult? Function(_AudioEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioEntity() when $default != null:
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
      Duration duration,
      String? artist,
      String? album,
      String? artUri,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AudioEntity() when $default != null:
        return $default(
          _that.id,
          _that.title,
          _that.url,
          _that.duration,
          _that.artist,
          _that.album,
          _that.artUri,
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
      Duration duration,
      String? artist,
      String? album,
      String? artUri,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioEntity():
        return $default(
          _that.id,
          _that.title,
          _that.url,
          _that.duration,
          _that.artist,
          _that.album,
          _that.artUri,
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
      Duration duration,
      String? artist,
      String? album,
      String? artUri,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioEntity() when $default != null:
        return $default(
          _that.id,
          _that.title,
          _that.url,
          _that.duration,
          _that.artist,
          _that.album,
          _that.artUri,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _AudioEntity implements AudioEntity {
  const _AudioEntity({
    required this.id,
    required this.title,
    required this.url,
    required this.duration,
    this.artist,
    this.album,
    this.artUri,
  });
  factory _AudioEntity.fromJson(Map<String, dynamic> json) =>
      _$AudioEntityFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String url;
  @override
  final Duration duration;
  @override
  final String? artist;
  @override
  final String? album;
  @override
  final String? artUri;

  /// Create a copy of AudioEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AudioEntityCopyWith<_AudioEntity> get copyWith =>
      __$AudioEntityCopyWithImpl<_AudioEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AudioEntityToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AudioEntity &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.album, album) || other.album == album) &&
            (identical(other.artUri, artUri) || other.artUri == artUri));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, url, duration, artist, album, artUri);

  @override
  String toString() {
    return 'AudioEntity(id: $id, title: $title, url: $url, duration: $duration, artist: $artist, album: $album, artUri: $artUri)';
  }
}

/// @nodoc
abstract mixin class _$AudioEntityCopyWith<$Res>
    implements $AudioEntityCopyWith<$Res> {
  factory _$AudioEntityCopyWith(
    _AudioEntity value,
    $Res Function(_AudioEntity) _then,
  ) = __$AudioEntityCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String url,
    Duration duration,
    String? artist,
    String? album,
    String? artUri,
  });
}

/// @nodoc
class __$AudioEntityCopyWithImpl<$Res> implements _$AudioEntityCopyWith<$Res> {
  __$AudioEntityCopyWithImpl(this._self, this._then);

  final _AudioEntity _self;
  final $Res Function(_AudioEntity) _then;

  /// Create a copy of AudioEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? url = null,
    Object? duration = null,
    Object? artist = freezed,
    Object? album = freezed,
    Object? artUri = freezed,
  }) {
    return _then(
      _AudioEntity(
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
        duration: null == duration
            ? _self.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as Duration,
        artist: freezed == artist
            ? _self.artist
            : artist // ignore: cast_nullable_to_non_nullable
                  as String?,
        album: freezed == album
            ? _self.album
            : album // ignore: cast_nullable_to_non_nullable
                  as String?,
        artUri: freezed == artUri
            ? _self.artUri
            : artUri // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$PlaybackStateEntity {
  bool get isPlaying;
  AudioProcessingStateStatus get processingState;
  Duration get position;
  Duration get bufferedPosition;
  Duration get duration;
  int get currentIndex;
  List<AudioEntity> get queue;

  /// Create a copy of PlaybackStateEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlaybackStateEntityCopyWith<PlaybackStateEntity> get copyWith =>
      _$PlaybackStateEntityCopyWithImpl<PlaybackStateEntity>(
        this as PlaybackStateEntity,
        _$identity,
      );

  /// Serializes this PlaybackStateEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlaybackStateEntity &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.processingState, processingState) ||
                other.processingState == processingState) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.bufferedPosition, bufferedPosition) ||
                other.bufferedPosition == bufferedPosition) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            const DeepCollectionEquality().equals(other.queue, queue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isPlaying,
    processingState,
    position,
    bufferedPosition,
    duration,
    currentIndex,
    const DeepCollectionEquality().hash(queue),
  );

  @override
  String toString() {
    return 'PlaybackStateEntity(isPlaying: $isPlaying, processingState: $processingState, position: $position, bufferedPosition: $bufferedPosition, duration: $duration, currentIndex: $currentIndex, queue: $queue)';
  }
}

/// @nodoc
abstract mixin class $PlaybackStateEntityCopyWith<$Res> {
  factory $PlaybackStateEntityCopyWith(
    PlaybackStateEntity value,
    $Res Function(PlaybackStateEntity) _then,
  ) = _$PlaybackStateEntityCopyWithImpl;
  @useResult
  $Res call({
    bool isPlaying,
    AudioProcessingStateStatus processingState,
    Duration position,
    Duration bufferedPosition,
    Duration duration,
    int currentIndex,
    List<AudioEntity> queue,
  });
}

/// @nodoc
class _$PlaybackStateEntityCopyWithImpl<$Res>
    implements $PlaybackStateEntityCopyWith<$Res> {
  _$PlaybackStateEntityCopyWithImpl(this._self, this._then);

  final PlaybackStateEntity _self;
  final $Res Function(PlaybackStateEntity) _then;

  /// Create a copy of PlaybackStateEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPlaying = null,
    Object? processingState = null,
    Object? position = null,
    Object? bufferedPosition = null,
    Object? duration = null,
    Object? currentIndex = null,
    Object? queue = null,
  }) {
    return _then(
      _self.copyWith(
        isPlaying: null == isPlaying
            ? _self.isPlaying
            : isPlaying // ignore: cast_nullable_to_non_nullable
                  as bool,
        processingState: null == processingState
            ? _self.processingState
            : processingState // ignore: cast_nullable_to_non_nullable
                  as AudioProcessingStateStatus,
        position: null == position
            ? _self.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Duration,
        bufferedPosition: null == bufferedPosition
            ? _self.bufferedPosition
            : bufferedPosition // ignore: cast_nullable_to_non_nullable
                  as Duration,
        duration: null == duration
            ? _self.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as Duration,
        currentIndex: null == currentIndex
            ? _self.currentIndex
            : currentIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        queue: null == queue
            ? _self.queue
            : queue // ignore: cast_nullable_to_non_nullable
                  as List<AudioEntity>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PlaybackStateEntity].
extension PlaybackStateEntityPatterns on PlaybackStateEntity {
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
    TResult Function(_PlaybackStateEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlaybackStateEntity() when $default != null:
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
    TResult Function(_PlaybackStateEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlaybackStateEntity():
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
    TResult? Function(_PlaybackStateEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlaybackStateEntity() when $default != null:
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
      bool isPlaying,
      AudioProcessingStateStatus processingState,
      Duration position,
      Duration bufferedPosition,
      Duration duration,
      int currentIndex,
      List<AudioEntity> queue,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlaybackStateEntity() when $default != null:
        return $default(
          _that.isPlaying,
          _that.processingState,
          _that.position,
          _that.bufferedPosition,
          _that.duration,
          _that.currentIndex,
          _that.queue,
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
      bool isPlaying,
      AudioProcessingStateStatus processingState,
      Duration position,
      Duration bufferedPosition,
      Duration duration,
      int currentIndex,
      List<AudioEntity> queue,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlaybackStateEntity():
        return $default(
          _that.isPlaying,
          _that.processingState,
          _that.position,
          _that.bufferedPosition,
          _that.duration,
          _that.currentIndex,
          _that.queue,
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
      bool isPlaying,
      AudioProcessingStateStatus processingState,
      Duration position,
      Duration bufferedPosition,
      Duration duration,
      int currentIndex,
      List<AudioEntity> queue,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlaybackStateEntity() when $default != null:
        return $default(
          _that.isPlaying,
          _that.processingState,
          _that.position,
          _that.bufferedPosition,
          _that.duration,
          _that.currentIndex,
          _that.queue,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _PlaybackStateEntity implements PlaybackStateEntity {
  const _PlaybackStateEntity({
    required this.isPlaying,
    required this.processingState,
    required this.position,
    required this.bufferedPosition,
    required this.duration,
    required this.currentIndex,
    required final List<AudioEntity> queue,
  }) : _queue = queue;
  factory _PlaybackStateEntity.fromJson(Map<String, dynamic> json) =>
      _$PlaybackStateEntityFromJson(json);

  @override
  final bool isPlaying;
  @override
  final AudioProcessingStateStatus processingState;
  @override
  final Duration position;
  @override
  final Duration bufferedPosition;
  @override
  final Duration duration;
  @override
  final int currentIndex;
  final List<AudioEntity> _queue;
  @override
  List<AudioEntity> get queue {
    if (_queue is EqualUnmodifiableListView) return _queue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_queue);
  }

  /// Create a copy of PlaybackStateEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlaybackStateEntityCopyWith<_PlaybackStateEntity> get copyWith =>
      __$PlaybackStateEntityCopyWithImpl<_PlaybackStateEntity>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$PlaybackStateEntityToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlaybackStateEntity &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.processingState, processingState) ||
                other.processingState == processingState) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.bufferedPosition, bufferedPosition) ||
                other.bufferedPosition == bufferedPosition) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            const DeepCollectionEquality().equals(other._queue, _queue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isPlaying,
    processingState,
    position,
    bufferedPosition,
    duration,
    currentIndex,
    const DeepCollectionEquality().hash(_queue),
  );

  @override
  String toString() {
    return 'PlaybackStateEntity(isPlaying: $isPlaying, processingState: $processingState, position: $position, bufferedPosition: $bufferedPosition, duration: $duration, currentIndex: $currentIndex, queue: $queue)';
  }
}

/// @nodoc
abstract mixin class _$PlaybackStateEntityCopyWith<$Res>
    implements $PlaybackStateEntityCopyWith<$Res> {
  factory _$PlaybackStateEntityCopyWith(
    _PlaybackStateEntity value,
    $Res Function(_PlaybackStateEntity) _then,
  ) = __$PlaybackStateEntityCopyWithImpl;
  @override
  @useResult
  $Res call({
    bool isPlaying,
    AudioProcessingStateStatus processingState,
    Duration position,
    Duration bufferedPosition,
    Duration duration,
    int currentIndex,
    List<AudioEntity> queue,
  });
}

/// @nodoc
class __$PlaybackStateEntityCopyWithImpl<$Res>
    implements _$PlaybackStateEntityCopyWith<$Res> {
  __$PlaybackStateEntityCopyWithImpl(this._self, this._then);

  final _PlaybackStateEntity _self;
  final $Res Function(_PlaybackStateEntity) _then;

  /// Create a copy of PlaybackStateEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isPlaying = null,
    Object? processingState = null,
    Object? position = null,
    Object? bufferedPosition = null,
    Object? duration = null,
    Object? currentIndex = null,
    Object? queue = null,
  }) {
    return _then(
      _PlaybackStateEntity(
        isPlaying: null == isPlaying
            ? _self.isPlaying
            : isPlaying // ignore: cast_nullable_to_non_nullable
                  as bool,
        processingState: null == processingState
            ? _self.processingState
            : processingState // ignore: cast_nullable_to_non_nullable
                  as AudioProcessingStateStatus,
        position: null == position
            ? _self.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Duration,
        bufferedPosition: null == bufferedPosition
            ? _self.bufferedPosition
            : bufferedPosition // ignore: cast_nullable_to_non_nullable
                  as Duration,
        duration: null == duration
            ? _self.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as Duration,
        currentIndex: null == currentIndex
            ? _self.currentIndex
            : currentIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        queue: null == queue
            ? _self._queue
            : queue // ignore: cast_nullable_to_non_nullable
                  as List<AudioEntity>,
      ),
    );
  }
}
