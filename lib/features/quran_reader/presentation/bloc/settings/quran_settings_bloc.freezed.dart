// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quran_settings_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuranSettingsEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is QuranSettingsEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QuranSettingsEvent()';
  }
}

/// @nodoc
class $QuranSettingsEventCopyWith<$Res> {
  $QuranSettingsEventCopyWith(
    QuranSettingsEvent _,
    $Res Function(QuranSettingsEvent) __,
  );
}

/// Adds pattern-matching-related methods to [QuranSettingsEvent].
extension QuranSettingsEventPatterns on QuranSettingsEvent {
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
    TResult Function(_LoadSettings value)? loadSettings,
    TResult Function(_UpdateSettings value)? updateSettings,
    TResult Function(_UpdateFontSize value)? updateFontSize,
    TResult Function(_ToggleTranslation value)? toggleTranslation,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LoadSettings() when loadSettings != null:
        return loadSettings(_that);
      case _UpdateSettings() when updateSettings != null:
        return updateSettings(_that);
      case _UpdateFontSize() when updateFontSize != null:
        return updateFontSize(_that);
      case _ToggleTranslation() when toggleTranslation != null:
        return toggleTranslation(_that);
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
    required TResult Function(_LoadSettings value) loadSettings,
    required TResult Function(_UpdateSettings value) updateSettings,
    required TResult Function(_UpdateFontSize value) updateFontSize,
    required TResult Function(_ToggleTranslation value) toggleTranslation,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadSettings():
        return loadSettings(_that);
      case _UpdateSettings():
        return updateSettings(_that);
      case _UpdateFontSize():
        return updateFontSize(_that);
      case _ToggleTranslation():
        return toggleTranslation(_that);
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
    TResult? Function(_LoadSettings value)? loadSettings,
    TResult? Function(_UpdateSettings value)? updateSettings,
    TResult? Function(_UpdateFontSize value)? updateFontSize,
    TResult? Function(_ToggleTranslation value)? toggleTranslation,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadSettings() when loadSettings != null:
        return loadSettings(_that);
      case _UpdateSettings() when updateSettings != null:
        return updateSettings(_that);
      case _UpdateFontSize() when updateFontSize != null:
        return updateFontSize(_that);
      case _ToggleTranslation() when toggleTranslation != null:
        return toggleTranslation(_that);
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
    TResult Function()? loadSettings,
    TResult Function(ReaderSettingsEntity settings)? updateSettings,
    TResult Function(double fontSize)? updateFontSize,
    TResult Function()? toggleTranslation,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LoadSettings() when loadSettings != null:
        return loadSettings();
      case _UpdateSettings() when updateSettings != null:
        return updateSettings(_that.settings);
      case _UpdateFontSize() when updateFontSize != null:
        return updateFontSize(_that.fontSize);
      case _ToggleTranslation() when toggleTranslation != null:
        return toggleTranslation();
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
    required TResult Function() loadSettings,
    required TResult Function(ReaderSettingsEntity settings) updateSettings,
    required TResult Function(double fontSize) updateFontSize,
    required TResult Function() toggleTranslation,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadSettings():
        return loadSettings();
      case _UpdateSettings():
        return updateSettings(_that.settings);
      case _UpdateFontSize():
        return updateFontSize(_that.fontSize);
      case _ToggleTranslation():
        return toggleTranslation();
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
    TResult? Function()? loadSettings,
    TResult? Function(ReaderSettingsEntity settings)? updateSettings,
    TResult? Function(double fontSize)? updateFontSize,
    TResult? Function()? toggleTranslation,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadSettings() when loadSettings != null:
        return loadSettings();
      case _UpdateSettings() when updateSettings != null:
        return updateSettings(_that.settings);
      case _UpdateFontSize() when updateFontSize != null:
        return updateFontSize(_that.fontSize);
      case _ToggleTranslation() when toggleTranslation != null:
        return toggleTranslation();
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LoadSettings implements QuranSettingsEvent {
  const _LoadSettings();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _LoadSettings);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QuranSettingsEvent.loadSettings()';
  }
}

/// @nodoc

class _UpdateSettings implements QuranSettingsEvent {
  const _UpdateSettings(this.settings);

  final ReaderSettingsEntity settings;

  /// Create a copy of QuranSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UpdateSettingsCopyWith<_UpdateSettings> get copyWith =>
      __$UpdateSettingsCopyWithImpl<_UpdateSettings>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UpdateSettings &&
            (identical(other.settings, settings) ||
                other.settings == settings));
  }

  @override
  int get hashCode => Object.hash(runtimeType, settings);

  @override
  String toString() {
    return 'QuranSettingsEvent.updateSettings(settings: $settings)';
  }
}

/// @nodoc
abstract mixin class _$UpdateSettingsCopyWith<$Res>
    implements $QuranSettingsEventCopyWith<$Res> {
  factory _$UpdateSettingsCopyWith(
    _UpdateSettings value,
    $Res Function(_UpdateSettings) _then,
  ) = __$UpdateSettingsCopyWithImpl;
  @useResult
  $Res call({ReaderSettingsEntity settings});

  $ReaderSettingsEntityCopyWith<$Res> get settings;
}

/// @nodoc
class __$UpdateSettingsCopyWithImpl<$Res>
    implements _$UpdateSettingsCopyWith<$Res> {
  __$UpdateSettingsCopyWithImpl(this._self, this._then);

  final _UpdateSettings _self;
  final $Res Function(_UpdateSettings) _then;

  /// Create a copy of QuranSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? settings = null}) {
    return _then(
      _UpdateSettings(
        null == settings
            ? _self.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as ReaderSettingsEntity,
      ),
    );
  }

  /// Create a copy of QuranSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReaderSettingsEntityCopyWith<$Res> get settings {
    return $ReaderSettingsEntityCopyWith<$Res>(_self.settings, (value) {
      return _then(_self.copyWith(settings: value));
    });
  }
}

/// @nodoc

class _UpdateFontSize implements QuranSettingsEvent {
  const _UpdateFontSize(this.fontSize);

  final double fontSize;

  /// Create a copy of QuranSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UpdateFontSizeCopyWith<_UpdateFontSize> get copyWith =>
      __$UpdateFontSizeCopyWithImpl<_UpdateFontSize>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UpdateFontSize &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fontSize);

  @override
  String toString() {
    return 'QuranSettingsEvent.updateFontSize(fontSize: $fontSize)';
  }
}

/// @nodoc
abstract mixin class _$UpdateFontSizeCopyWith<$Res>
    implements $QuranSettingsEventCopyWith<$Res> {
  factory _$UpdateFontSizeCopyWith(
    _UpdateFontSize value,
    $Res Function(_UpdateFontSize) _then,
  ) = __$UpdateFontSizeCopyWithImpl;
  @useResult
  $Res call({double fontSize});
}

/// @nodoc
class __$UpdateFontSizeCopyWithImpl<$Res>
    implements _$UpdateFontSizeCopyWith<$Res> {
  __$UpdateFontSizeCopyWithImpl(this._self, this._then);

  final _UpdateFontSize _self;
  final $Res Function(_UpdateFontSize) _then;

  /// Create a copy of QuranSettingsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? fontSize = null}) {
    return _then(
      _UpdateFontSize(
        null == fontSize
            ? _self.fontSize
            : fontSize // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _ToggleTranslation implements QuranSettingsEvent {
  const _ToggleTranslation();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _ToggleTranslation);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QuranSettingsEvent.toggleTranslation()';
  }
}

/// @nodoc
mixin _$QuranSettingsState {
  ReaderSettingsEntity get settings;
  bool get isLoading;
  String? get errorMessage;

  /// Create a copy of QuranSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QuranSettingsStateCopyWith<QuranSettingsState> get copyWith =>
      _$QuranSettingsStateCopyWithImpl<QuranSettingsState>(
        this as QuranSettingsState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QuranSettingsState &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, settings, isLoading, errorMessage);

  @override
  String toString() {
    return 'QuranSettingsState(settings: $settings, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class $QuranSettingsStateCopyWith<$Res> {
  factory $QuranSettingsStateCopyWith(
    QuranSettingsState value,
    $Res Function(QuranSettingsState) _then,
  ) = _$QuranSettingsStateCopyWithImpl;
  @useResult
  $Res call({
    ReaderSettingsEntity settings,
    bool isLoading,
    String? errorMessage,
  });

  $ReaderSettingsEntityCopyWith<$Res> get settings;
}

/// @nodoc
class _$QuranSettingsStateCopyWithImpl<$Res>
    implements $QuranSettingsStateCopyWith<$Res> {
  _$QuranSettingsStateCopyWithImpl(this._self, this._then);

  final QuranSettingsState _self;
  final $Res Function(QuranSettingsState) _then;

  /// Create a copy of QuranSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? settings = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _self.copyWith(
        settings: null == settings
            ? _self.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as ReaderSettingsEntity,
        isLoading: null == isLoading
            ? _self.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorMessage: freezed == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of QuranSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReaderSettingsEntityCopyWith<$Res> get settings {
    return $ReaderSettingsEntityCopyWith<$Res>(_self.settings, (value) {
      return _then(_self.copyWith(settings: value));
    });
  }
}

/// Adds pattern-matching-related methods to [QuranSettingsState].
extension QuranSettingsStatePatterns on QuranSettingsState {
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
    TResult Function(_QuranSettingsState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QuranSettingsState() when $default != null:
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
    TResult Function(_QuranSettingsState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranSettingsState():
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
    TResult? Function(_QuranSettingsState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranSettingsState() when $default != null:
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
      ReaderSettingsEntity settings,
      bool isLoading,
      String? errorMessage,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QuranSettingsState() when $default != null:
        return $default(_that.settings, _that.isLoading, _that.errorMessage);
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
      ReaderSettingsEntity settings,
      bool isLoading,
      String? errorMessage,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranSettingsState():
        return $default(_that.settings, _that.isLoading, _that.errorMessage);
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
      ReaderSettingsEntity settings,
      bool isLoading,
      String? errorMessage,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranSettingsState() when $default != null:
        return $default(_that.settings, _that.isLoading, _that.errorMessage);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _QuranSettingsState implements QuranSettingsState {
  const _QuranSettingsState({
    this.settings = const ReaderSettingsEntity(),
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  @JsonKey()
  final ReaderSettingsEntity settings;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? errorMessage;

  /// Create a copy of QuranSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$QuranSettingsStateCopyWith<_QuranSettingsState> get copyWith =>
      __$QuranSettingsStateCopyWithImpl<_QuranSettingsState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _QuranSettingsState &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, settings, isLoading, errorMessage);

  @override
  String toString() {
    return 'QuranSettingsState(settings: $settings, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class _$QuranSettingsStateCopyWith<$Res>
    implements $QuranSettingsStateCopyWith<$Res> {
  factory _$QuranSettingsStateCopyWith(
    _QuranSettingsState value,
    $Res Function(_QuranSettingsState) _then,
  ) = __$QuranSettingsStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    ReaderSettingsEntity settings,
    bool isLoading,
    String? errorMessage,
  });

  @override
  $ReaderSettingsEntityCopyWith<$Res> get settings;
}

/// @nodoc
class __$QuranSettingsStateCopyWithImpl<$Res>
    implements _$QuranSettingsStateCopyWith<$Res> {
  __$QuranSettingsStateCopyWithImpl(this._self, this._then);

  final _QuranSettingsState _self;
  final $Res Function(_QuranSettingsState) _then;

  /// Create a copy of QuranSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? settings = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _QuranSettingsState(
        settings: null == settings
            ? _self.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as ReaderSettingsEntity,
        isLoading: null == isLoading
            ? _self.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorMessage: freezed == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of QuranSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReaderSettingsEntityCopyWith<$Res> get settings {
    return $ReaderSettingsEntityCopyWith<$Res>(_self.settings, (value) {
      return _then(_self.copyWith(settings: value));
    });
  }
}
