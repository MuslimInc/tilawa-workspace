// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'word_by_word_audio_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WordByWordAudioEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is WordByWordAudioEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'WordByWordAudioEvent()';
  }
}

/// @nodoc
class $WordByWordAudioEventCopyWith<$Res> {
  $WordByWordAudioEventCopyWith(
    WordByWordAudioEvent _,
    $Res Function(WordByWordAudioEvent) __,
  );
}

/// Adds pattern-matching-related methods to [WordByWordAudioEvent].
extension WordByWordAudioEventPatterns on WordByWordAudioEvent {
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
    TResult Function(_PlayWord value)? playWord,
    TResult Function(_StopAudio value)? stopAudio,
    TResult Function(_PlayerStateChanged value)? playerStateChanged,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlayWord() when playWord != null:
        return playWord(_that);
      case _StopAudio() when stopAudio != null:
        return stopAudio(_that);
      case _PlayerStateChanged() when playerStateChanged != null:
        return playerStateChanged(_that);
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
    required TResult Function(_PlayWord value) playWord,
    required TResult Function(_StopAudio value) stopAudio,
    required TResult Function(_PlayerStateChanged value) playerStateChanged,
  }) {
    final _that = this;
    switch (_that) {
      case _PlayWord():
        return playWord(_that);
      case _StopAudio():
        return stopAudio(_that);
      case _PlayerStateChanged():
        return playerStateChanged(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PlayWord value)? playWord,
    TResult? Function(_StopAudio value)? stopAudio,
    TResult? Function(_PlayerStateChanged value)? playerStateChanged,
  }) {
    final _that = this;
    switch (_that) {
      case _PlayWord() when playWord != null:
        return playWord(_that);
      case _StopAudio() when stopAudio != null:
        return stopAudio(_that);
      case _PlayerStateChanged() when playerStateChanged != null:
        return playerStateChanged(_that);
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
    TResult Function(String url, int wordId)? playWord,
    TResult Function()? stopAudio,
    TResult Function(PlayerState playerState)? playerStateChanged,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlayWord() when playWord != null:
        return playWord(_that.url, _that.wordId);
      case _StopAudio() when stopAudio != null:
        return stopAudio();
      case _PlayerStateChanged() when playerStateChanged != null:
        return playerStateChanged(_that.playerState);
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
    required TResult Function(String url, int wordId) playWord,
    required TResult Function() stopAudio,
    required TResult Function(PlayerState playerState) playerStateChanged,
  }) {
    final _that = this;
    switch (_that) {
      case _PlayWord():
        return playWord(_that.url, _that.wordId);
      case _StopAudio():
        return stopAudio();
      case _PlayerStateChanged():
        return playerStateChanged(_that.playerState);
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String url, int wordId)? playWord,
    TResult? Function()? stopAudio,
    TResult? Function(PlayerState playerState)? playerStateChanged,
  }) {
    final _that = this;
    switch (_that) {
      case _PlayWord() when playWord != null:
        return playWord(_that.url, _that.wordId);
      case _StopAudio() when stopAudio != null:
        return stopAudio();
      case _PlayerStateChanged() when playerStateChanged != null:
        return playerStateChanged(_that.playerState);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PlayWord implements WordByWordAudioEvent {
  const _PlayWord(this.url, this.wordId);

  final String url;
  final int wordId;

  /// Create a copy of WordByWordAudioEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlayWordCopyWith<_PlayWord> get copyWith =>
      __$PlayWordCopyWithImpl<_PlayWord>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlayWord &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.wordId, wordId) || other.wordId == wordId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, url, wordId);

  @override
  String toString() {
    return 'WordByWordAudioEvent.playWord(url: $url, wordId: $wordId)';
  }
}

/// @nodoc
abstract mixin class _$PlayWordCopyWith<$Res>
    implements $WordByWordAudioEventCopyWith<$Res> {
  factory _$PlayWordCopyWith(_PlayWord value, $Res Function(_PlayWord) _then) =
      __$PlayWordCopyWithImpl;
  @useResult
  $Res call({String url, int wordId});
}

/// @nodoc
class __$PlayWordCopyWithImpl<$Res> implements _$PlayWordCopyWith<$Res> {
  __$PlayWordCopyWithImpl(this._self, this._then);

  final _PlayWord _self;
  final $Res Function(_PlayWord) _then;

  /// Create a copy of WordByWordAudioEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? url = null, Object? wordId = null}) {
    return _then(
      _PlayWord(
        null == url
            ? _self.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        null == wordId
            ? _self.wordId
            : wordId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _StopAudio implements WordByWordAudioEvent {
  const _StopAudio();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _StopAudio);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'WordByWordAudioEvent.stopAudio()';
  }
}

/// @nodoc

class _PlayerStateChanged implements WordByWordAudioEvent {
  const _PlayerStateChanged(this.playerState);

  final PlayerState playerState;

  /// Create a copy of WordByWordAudioEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlayerStateChangedCopyWith<_PlayerStateChanged> get copyWith =>
      __$PlayerStateChangedCopyWithImpl<_PlayerStateChanged>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlayerStateChanged &&
            (identical(other.playerState, playerState) ||
                other.playerState == playerState));
  }

  @override
  int get hashCode => Object.hash(runtimeType, playerState);

  @override
  String toString() {
    return 'WordByWordAudioEvent.playerStateChanged(playerState: $playerState)';
  }
}

/// @nodoc
abstract mixin class _$PlayerStateChangedCopyWith<$Res>
    implements $WordByWordAudioEventCopyWith<$Res> {
  factory _$PlayerStateChangedCopyWith(
    _PlayerStateChanged value,
    $Res Function(_PlayerStateChanged) _then,
  ) = __$PlayerStateChangedCopyWithImpl;
  @useResult
  $Res call({PlayerState playerState});
}

/// @nodoc
class __$PlayerStateChangedCopyWithImpl<$Res>
    implements _$PlayerStateChangedCopyWith<$Res> {
  __$PlayerStateChangedCopyWithImpl(this._self, this._then);

  final _PlayerStateChanged _self;
  final $Res Function(_PlayerStateChanged) _then;

  /// Create a copy of WordByWordAudioEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? playerState = null}) {
    return _then(
      _PlayerStateChanged(
        null == playerState
            ? _self.playerState
            : playerState // ignore: cast_nullable_to_non_nullable
                  as PlayerState,
      ),
    );
  }
}

/// @nodoc
mixin _$WordByWordAudioState {
  int? get playingWordId;
  bool get isPlaying;

  /// Create a copy of WordByWordAudioState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WordByWordAudioStateCopyWith<WordByWordAudioState> get copyWith =>
      _$WordByWordAudioStateCopyWithImpl<WordByWordAudioState>(
        this as WordByWordAudioState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WordByWordAudioState &&
            (identical(other.playingWordId, playingWordId) ||
                other.playingWordId == playingWordId) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying));
  }

  @override
  int get hashCode => Object.hash(runtimeType, playingWordId, isPlaying);

  @override
  String toString() {
    return 'WordByWordAudioState(playingWordId: $playingWordId, isPlaying: $isPlaying)';
  }
}

/// @nodoc
abstract mixin class $WordByWordAudioStateCopyWith<$Res> {
  factory $WordByWordAudioStateCopyWith(
    WordByWordAudioState value,
    $Res Function(WordByWordAudioState) _then,
  ) = _$WordByWordAudioStateCopyWithImpl;
  @useResult
  $Res call({int? playingWordId, bool isPlaying});
}

/// @nodoc
class _$WordByWordAudioStateCopyWithImpl<$Res>
    implements $WordByWordAudioStateCopyWith<$Res> {
  _$WordByWordAudioStateCopyWithImpl(this._self, this._then);

  final WordByWordAudioState _self;
  final $Res Function(WordByWordAudioState) _then;

  /// Create a copy of WordByWordAudioState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? playingWordId = freezed, Object? isPlaying = null}) {
    return _then(
      _self.copyWith(
        playingWordId: freezed == playingWordId
            ? _self.playingWordId
            : playingWordId // ignore: cast_nullable_to_non_nullable
                  as int?,
        isPlaying: null == isPlaying
            ? _self.isPlaying
            : isPlaying // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [WordByWordAudioState].
extension WordByWordAudioStatePatterns on WordByWordAudioState {
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
    TResult Function(_WordByWordAudioState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WordByWordAudioState() when $default != null:
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
    TResult Function(_WordByWordAudioState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordByWordAudioState():
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
    TResult? Function(_WordByWordAudioState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordByWordAudioState() when $default != null:
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
    TResult Function(int? playingWordId, bool isPlaying)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WordByWordAudioState() when $default != null:
        return $default(_that.playingWordId, _that.isPlaying);
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
    TResult Function(int? playingWordId, bool isPlaying) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordByWordAudioState():
        return $default(_that.playingWordId, _that.isPlaying);
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
    TResult? Function(int? playingWordId, bool isPlaying)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordByWordAudioState() when $default != null:
        return $default(_that.playingWordId, _that.isPlaying);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _WordByWordAudioState implements WordByWordAudioState {
  const _WordByWordAudioState({this.playingWordId, this.isPlaying = false});

  @override
  final int? playingWordId;
  @override
  @JsonKey()
  final bool isPlaying;

  /// Create a copy of WordByWordAudioState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WordByWordAudioStateCopyWith<_WordByWordAudioState> get copyWith =>
      __$WordByWordAudioStateCopyWithImpl<_WordByWordAudioState>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WordByWordAudioState &&
            (identical(other.playingWordId, playingWordId) ||
                other.playingWordId == playingWordId) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying));
  }

  @override
  int get hashCode => Object.hash(runtimeType, playingWordId, isPlaying);

  @override
  String toString() {
    return 'WordByWordAudioState(playingWordId: $playingWordId, isPlaying: $isPlaying)';
  }
}

/// @nodoc
abstract mixin class _$WordByWordAudioStateCopyWith<$Res>
    implements $WordByWordAudioStateCopyWith<$Res> {
  factory _$WordByWordAudioStateCopyWith(
    _WordByWordAudioState value,
    $Res Function(_WordByWordAudioState) _then,
  ) = __$WordByWordAudioStateCopyWithImpl;
  @override
  @useResult
  $Res call({int? playingWordId, bool isPlaying});
}

/// @nodoc
class __$WordByWordAudioStateCopyWithImpl<$Res>
    implements _$WordByWordAudioStateCopyWith<$Res> {
  __$WordByWordAudioStateCopyWithImpl(this._self, this._then);

  final _WordByWordAudioState _self;
  final $Res Function(_WordByWordAudioState) _then;

  /// Create a copy of WordByWordAudioState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? playingWordId = freezed, Object? isPlaying = null}) {
    return _then(
      _WordByWordAudioState(
        playingWordId: freezed == playingWordId
            ? _self.playingWordId
            : playingWordId // ignore: cast_nullable_to_non_nullable
                  as int?,
        isPlaying: null == isPlaying
            ? _self.isPlaying
            : isPlaying // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}
