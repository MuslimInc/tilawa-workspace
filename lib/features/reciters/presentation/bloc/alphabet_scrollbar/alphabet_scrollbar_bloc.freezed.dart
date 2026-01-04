// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alphabet_scrollbar_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AlphabetScrollbarState {
  String? get selectedLetter;
  bool get isDragging;

  /// Create a copy of AlphabetScrollbarState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AlphabetScrollbarStateCopyWith<AlphabetScrollbarState> get copyWith =>
      _$AlphabetScrollbarStateCopyWithImpl<AlphabetScrollbarState>(
        this as AlphabetScrollbarState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AlphabetScrollbarState &&
            (identical(other.selectedLetter, selectedLetter) ||
                other.selectedLetter == selectedLetter) &&
            (identical(other.isDragging, isDragging) ||
                other.isDragging == isDragging));
  }

  @override
  int get hashCode => Object.hash(runtimeType, selectedLetter, isDragging);

  @override
  String toString() {
    return 'AlphabetScrollbarState(selectedLetter: $selectedLetter, isDragging: $isDragging)';
  }
}

/// @nodoc
abstract mixin class $AlphabetScrollbarStateCopyWith<$Res> {
  factory $AlphabetScrollbarStateCopyWith(
    AlphabetScrollbarState value,
    $Res Function(AlphabetScrollbarState) _then,
  ) = _$AlphabetScrollbarStateCopyWithImpl;
  @useResult
  $Res call({String? selectedLetter, bool isDragging});
}

/// @nodoc
class _$AlphabetScrollbarStateCopyWithImpl<$Res>
    implements $AlphabetScrollbarStateCopyWith<$Res> {
  _$AlphabetScrollbarStateCopyWithImpl(this._self, this._then);

  final AlphabetScrollbarState _self;
  final $Res Function(AlphabetScrollbarState) _then;

  /// Create a copy of AlphabetScrollbarState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? selectedLetter = freezed, Object? isDragging = null}) {
    return _then(
      _self.copyWith(
        selectedLetter: freezed == selectedLetter
            ? _self.selectedLetter
            : selectedLetter // ignore: cast_nullable_to_non_nullable
                  as String?,
        isDragging: null == isDragging
            ? _self.isDragging
            : isDragging // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AlphabetScrollbarState].
extension AlphabetScrollbarStatePatterns on AlphabetScrollbarState {
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
    TResult Function(_AlphabetScrollbarState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AlphabetScrollbarState() when $default != null:
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
    TResult Function(_AlphabetScrollbarState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AlphabetScrollbarState():
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
    TResult? Function(_AlphabetScrollbarState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AlphabetScrollbarState() when $default != null:
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
    TResult Function(String? selectedLetter, bool isDragging)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AlphabetScrollbarState() when $default != null:
        return $default(_that.selectedLetter, _that.isDragging);
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
    TResult Function(String? selectedLetter, bool isDragging) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AlphabetScrollbarState():
        return $default(_that.selectedLetter, _that.isDragging);
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
    TResult? Function(String? selectedLetter, bool isDragging)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AlphabetScrollbarState() when $default != null:
        return $default(_that.selectedLetter, _that.isDragging);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AlphabetScrollbarState implements AlphabetScrollbarState {
  const _AlphabetScrollbarState({this.selectedLetter, this.isDragging = false});

  @override
  final String? selectedLetter;
  @override
  @JsonKey()
  final bool isDragging;

  /// Create a copy of AlphabetScrollbarState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AlphabetScrollbarStateCopyWith<_AlphabetScrollbarState> get copyWith =>
      __$AlphabetScrollbarStateCopyWithImpl<_AlphabetScrollbarState>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AlphabetScrollbarState &&
            (identical(other.selectedLetter, selectedLetter) ||
                other.selectedLetter == selectedLetter) &&
            (identical(other.isDragging, isDragging) ||
                other.isDragging == isDragging));
  }

  @override
  int get hashCode => Object.hash(runtimeType, selectedLetter, isDragging);

  @override
  String toString() {
    return 'AlphabetScrollbarState(selectedLetter: $selectedLetter, isDragging: $isDragging)';
  }
}

/// @nodoc
abstract mixin class _$AlphabetScrollbarStateCopyWith<$Res>
    implements $AlphabetScrollbarStateCopyWith<$Res> {
  factory _$AlphabetScrollbarStateCopyWith(
    _AlphabetScrollbarState value,
    $Res Function(_AlphabetScrollbarState) _then,
  ) = __$AlphabetScrollbarStateCopyWithImpl;
  @override
  @useResult
  $Res call({String? selectedLetter, bool isDragging});
}

/// @nodoc
class __$AlphabetScrollbarStateCopyWithImpl<$Res>
    implements _$AlphabetScrollbarStateCopyWith<$Res> {
  __$AlphabetScrollbarStateCopyWithImpl(this._self, this._then);

  final _AlphabetScrollbarState _self;
  final $Res Function(_AlphabetScrollbarState) _then;

  /// Create a copy of AlphabetScrollbarState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? selectedLetter = freezed, Object? isDragging = null}) {
    return _then(
      _AlphabetScrollbarState(
        selectedLetter: freezed == selectedLetter
            ? _self.selectedLetter
            : selectedLetter // ignore: cast_nullable_to_non_nullable
                  as String?,
        isDragging: null == isDragging
            ? _self.isDragging
            : isDragging // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}
