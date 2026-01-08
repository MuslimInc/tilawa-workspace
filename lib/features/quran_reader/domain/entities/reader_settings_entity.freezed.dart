// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reader_settings_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReaderSettingsEntity {
  double get fontSize;
  double get lineHeight;
  QuranFontType get fontType;
  ReadingMode get readingMode;
  bool get showTranslation;
  String get translationLanguage;
  bool get showTransliteration;
  bool get showAyahNumbers;
  bool get nightMode;
  double get translationFontSize;
  int? get lastReadSurah;
  int? get lastReadAyah;
  int? get lastReadPage;

  /// Create a copy of ReaderSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReaderSettingsEntityCopyWith<ReaderSettingsEntity> get copyWith =>
      _$ReaderSettingsEntityCopyWithImpl<ReaderSettingsEntity>(
        this as ReaderSettingsEntity,
        _$identity,
      );

  /// Serializes this ReaderSettingsEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReaderSettingsEntity &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize) &&
            (identical(other.lineHeight, lineHeight) ||
                other.lineHeight == lineHeight) &&
            (identical(other.fontType, fontType) ||
                other.fontType == fontType) &&
            (identical(other.readingMode, readingMode) ||
                other.readingMode == readingMode) &&
            (identical(other.showTranslation, showTranslation) ||
                other.showTranslation == showTranslation) &&
            (identical(other.translationLanguage, translationLanguage) ||
                other.translationLanguage == translationLanguage) &&
            (identical(other.showTransliteration, showTransliteration) ||
                other.showTransliteration == showTransliteration) &&
            (identical(other.showAyahNumbers, showAyahNumbers) ||
                other.showAyahNumbers == showAyahNumbers) &&
            (identical(other.nightMode, nightMode) ||
                other.nightMode == nightMode) &&
            (identical(other.translationFontSize, translationFontSize) ||
                other.translationFontSize == translationFontSize) &&
            (identical(other.lastReadSurah, lastReadSurah) ||
                other.lastReadSurah == lastReadSurah) &&
            (identical(other.lastReadAyah, lastReadAyah) ||
                other.lastReadAyah == lastReadAyah) &&
            (identical(other.lastReadPage, lastReadPage) ||
                other.lastReadPage == lastReadPage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    fontSize,
    lineHeight,
    fontType,
    readingMode,
    showTranslation,
    translationLanguage,
    showTransliteration,
    showAyahNumbers,
    nightMode,
    translationFontSize,
    lastReadSurah,
    lastReadAyah,
    lastReadPage,
  );

  @override
  String toString() {
    return 'ReaderSettingsEntity(fontSize: $fontSize, lineHeight: $lineHeight, fontType: $fontType, readingMode: $readingMode, showTranslation: $showTranslation, translationLanguage: $translationLanguage, showTransliteration: $showTransliteration, showAyahNumbers: $showAyahNumbers, nightMode: $nightMode, translationFontSize: $translationFontSize, lastReadSurah: $lastReadSurah, lastReadAyah: $lastReadAyah, lastReadPage: $lastReadPage)';
  }
}

/// @nodoc
abstract mixin class $ReaderSettingsEntityCopyWith<$Res> {
  factory $ReaderSettingsEntityCopyWith(
    ReaderSettingsEntity value,
    $Res Function(ReaderSettingsEntity) _then,
  ) = _$ReaderSettingsEntityCopyWithImpl;
  @useResult
  $Res call({
    double fontSize,
    double lineHeight,
    QuranFontType fontType,
    ReadingMode readingMode,
    bool showTranslation,
    String translationLanguage,
    bool showTransliteration,
    bool showAyahNumbers,
    bool nightMode,
    double translationFontSize,
    int? lastReadSurah,
    int? lastReadAyah,
    int? lastReadPage,
  });
}

/// @nodoc
class _$ReaderSettingsEntityCopyWithImpl<$Res>
    implements $ReaderSettingsEntityCopyWith<$Res> {
  _$ReaderSettingsEntityCopyWithImpl(this._self, this._then);

  final ReaderSettingsEntity _self;
  final $Res Function(ReaderSettingsEntity) _then;

  /// Create a copy of ReaderSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fontSize = null,
    Object? lineHeight = null,
    Object? fontType = null,
    Object? readingMode = null,
    Object? showTranslation = null,
    Object? translationLanguage = null,
    Object? showTransliteration = null,
    Object? showAyahNumbers = null,
    Object? nightMode = null,
    Object? translationFontSize = null,
    Object? lastReadSurah = freezed,
    Object? lastReadAyah = freezed,
    Object? lastReadPage = freezed,
  }) {
    return _then(
      _self.copyWith(
        fontSize: null == fontSize
            ? _self.fontSize
            : fontSize // ignore: cast_nullable_to_non_nullable
                  as double,
        lineHeight: null == lineHeight
            ? _self.lineHeight
            : lineHeight // ignore: cast_nullable_to_non_nullable
                  as double,
        fontType: null == fontType
            ? _self.fontType
            : fontType // ignore: cast_nullable_to_non_nullable
                  as QuranFontType,
        readingMode: null == readingMode
            ? _self.readingMode
            : readingMode // ignore: cast_nullable_to_non_nullable
                  as ReadingMode,
        showTranslation: null == showTranslation
            ? _self.showTranslation
            : showTranslation // ignore: cast_nullable_to_non_nullable
                  as bool,
        translationLanguage: null == translationLanguage
            ? _self.translationLanguage
            : translationLanguage // ignore: cast_nullable_to_non_nullable
                  as String,
        showTransliteration: null == showTransliteration
            ? _self.showTransliteration
            : showTransliteration // ignore: cast_nullable_to_non_nullable
                  as bool,
        showAyahNumbers: null == showAyahNumbers
            ? _self.showAyahNumbers
            : showAyahNumbers // ignore: cast_nullable_to_non_nullable
                  as bool,
        nightMode: null == nightMode
            ? _self.nightMode
            : nightMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        translationFontSize: null == translationFontSize
            ? _self.translationFontSize
            : translationFontSize // ignore: cast_nullable_to_non_nullable
                  as double,
        lastReadSurah: freezed == lastReadSurah
            ? _self.lastReadSurah
            : lastReadSurah // ignore: cast_nullable_to_non_nullable
                  as int?,
        lastReadAyah: freezed == lastReadAyah
            ? _self.lastReadAyah
            : lastReadAyah // ignore: cast_nullable_to_non_nullable
                  as int?,
        lastReadPage: freezed == lastReadPage
            ? _self.lastReadPage
            : lastReadPage // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ReaderSettingsEntity].
extension ReaderSettingsEntityPatterns on ReaderSettingsEntity {
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
    TResult Function(_ReaderSettingsEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ReaderSettingsEntity() when $default != null:
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
    TResult Function(_ReaderSettingsEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReaderSettingsEntity():
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
    TResult? Function(_ReaderSettingsEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReaderSettingsEntity() when $default != null:
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
      double fontSize,
      double lineHeight,
      QuranFontType fontType,
      ReadingMode readingMode,
      bool showTranslation,
      String translationLanguage,
      bool showTransliteration,
      bool showAyahNumbers,
      bool nightMode,
      double translationFontSize,
      int? lastReadSurah,
      int? lastReadAyah,
      int? lastReadPage,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ReaderSettingsEntity() when $default != null:
        return $default(
          _that.fontSize,
          _that.lineHeight,
          _that.fontType,
          _that.readingMode,
          _that.showTranslation,
          _that.translationLanguage,
          _that.showTransliteration,
          _that.showAyahNumbers,
          _that.nightMode,
          _that.translationFontSize,
          _that.lastReadSurah,
          _that.lastReadAyah,
          _that.lastReadPage,
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
      double fontSize,
      double lineHeight,
      QuranFontType fontType,
      ReadingMode readingMode,
      bool showTranslation,
      String translationLanguage,
      bool showTransliteration,
      bool showAyahNumbers,
      bool nightMode,
      double translationFontSize,
      int? lastReadSurah,
      int? lastReadAyah,
      int? lastReadPage,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReaderSettingsEntity():
        return $default(
          _that.fontSize,
          _that.lineHeight,
          _that.fontType,
          _that.readingMode,
          _that.showTranslation,
          _that.translationLanguage,
          _that.showTransliteration,
          _that.showAyahNumbers,
          _that.nightMode,
          _that.translationFontSize,
          _that.lastReadSurah,
          _that.lastReadAyah,
          _that.lastReadPage,
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
      double fontSize,
      double lineHeight,
      QuranFontType fontType,
      ReadingMode readingMode,
      bool showTranslation,
      String translationLanguage,
      bool showTransliteration,
      bool showAyahNumbers,
      bool nightMode,
      double translationFontSize,
      int? lastReadSurah,
      int? lastReadAyah,
      int? lastReadPage,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReaderSettingsEntity() when $default != null:
        return $default(
          _that.fontSize,
          _that.lineHeight,
          _that.fontType,
          _that.readingMode,
          _that.showTranslation,
          _that.translationLanguage,
          _that.showTransliteration,
          _that.showAyahNumbers,
          _that.nightMode,
          _that.translationFontSize,
          _that.lastReadSurah,
          _that.lastReadAyah,
          _that.lastReadPage,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ReaderSettingsEntity extends ReaderSettingsEntity {
  const _ReaderSettingsEntity({
    this.fontSize = 24.0,
    this.lineHeight = 1.8,
    this.fontType = QuranFontType.uthmani,
    this.readingMode = ReadingMode.surah,
    this.showTranslation = true,
    this.translationLanguage = 'en',
    this.showTransliteration = false,
    this.showAyahNumbers = true,
    this.nightMode = false,
    this.translationFontSize = 1.0,
    this.lastReadSurah = null,
    this.lastReadAyah = null,
    this.lastReadPage = null,
  }) : super._();
  factory _ReaderSettingsEntity.fromJson(Map<String, dynamic> json) =>
      _$ReaderSettingsEntityFromJson(json);

  @override
  @JsonKey()
  final double fontSize;
  @override
  @JsonKey()
  final double lineHeight;
  @override
  @JsonKey()
  final QuranFontType fontType;
  @override
  @JsonKey()
  final ReadingMode readingMode;
  @override
  @JsonKey()
  final bool showTranslation;
  @override
  @JsonKey()
  final String translationLanguage;
  @override
  @JsonKey()
  final bool showTransliteration;
  @override
  @JsonKey()
  final bool showAyahNumbers;
  @override
  @JsonKey()
  final bool nightMode;
  @override
  @JsonKey()
  final double translationFontSize;
  @override
  @JsonKey()
  final int? lastReadSurah;
  @override
  @JsonKey()
  final int? lastReadAyah;
  @override
  @JsonKey()
  final int? lastReadPage;

  /// Create a copy of ReaderSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ReaderSettingsEntityCopyWith<_ReaderSettingsEntity> get copyWith =>
      __$ReaderSettingsEntityCopyWithImpl<_ReaderSettingsEntity>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$ReaderSettingsEntityToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ReaderSettingsEntity &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize) &&
            (identical(other.lineHeight, lineHeight) ||
                other.lineHeight == lineHeight) &&
            (identical(other.fontType, fontType) ||
                other.fontType == fontType) &&
            (identical(other.readingMode, readingMode) ||
                other.readingMode == readingMode) &&
            (identical(other.showTranslation, showTranslation) ||
                other.showTranslation == showTranslation) &&
            (identical(other.translationLanguage, translationLanguage) ||
                other.translationLanguage == translationLanguage) &&
            (identical(other.showTransliteration, showTransliteration) ||
                other.showTransliteration == showTransliteration) &&
            (identical(other.showAyahNumbers, showAyahNumbers) ||
                other.showAyahNumbers == showAyahNumbers) &&
            (identical(other.nightMode, nightMode) ||
                other.nightMode == nightMode) &&
            (identical(other.translationFontSize, translationFontSize) ||
                other.translationFontSize == translationFontSize) &&
            (identical(other.lastReadSurah, lastReadSurah) ||
                other.lastReadSurah == lastReadSurah) &&
            (identical(other.lastReadAyah, lastReadAyah) ||
                other.lastReadAyah == lastReadAyah) &&
            (identical(other.lastReadPage, lastReadPage) ||
                other.lastReadPage == lastReadPage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    fontSize,
    lineHeight,
    fontType,
    readingMode,
    showTranslation,
    translationLanguage,
    showTransliteration,
    showAyahNumbers,
    nightMode,
    translationFontSize,
    lastReadSurah,
    lastReadAyah,
    lastReadPage,
  );

  @override
  String toString() {
    return 'ReaderSettingsEntity(fontSize: $fontSize, lineHeight: $lineHeight, fontType: $fontType, readingMode: $readingMode, showTranslation: $showTranslation, translationLanguage: $translationLanguage, showTransliteration: $showTransliteration, showAyahNumbers: $showAyahNumbers, nightMode: $nightMode, translationFontSize: $translationFontSize, lastReadSurah: $lastReadSurah, lastReadAyah: $lastReadAyah, lastReadPage: $lastReadPage)';
  }
}

/// @nodoc
abstract mixin class _$ReaderSettingsEntityCopyWith<$Res>
    implements $ReaderSettingsEntityCopyWith<$Res> {
  factory _$ReaderSettingsEntityCopyWith(
    _ReaderSettingsEntity value,
    $Res Function(_ReaderSettingsEntity) _then,
  ) = __$ReaderSettingsEntityCopyWithImpl;
  @override
  @useResult
  $Res call({
    double fontSize,
    double lineHeight,
    QuranFontType fontType,
    ReadingMode readingMode,
    bool showTranslation,
    String translationLanguage,
    bool showTransliteration,
    bool showAyahNumbers,
    bool nightMode,
    double translationFontSize,
    int? lastReadSurah,
    int? lastReadAyah,
    int? lastReadPage,
  });
}

/// @nodoc
class __$ReaderSettingsEntityCopyWithImpl<$Res>
    implements _$ReaderSettingsEntityCopyWith<$Res> {
  __$ReaderSettingsEntityCopyWithImpl(this._self, this._then);

  final _ReaderSettingsEntity _self;
  final $Res Function(_ReaderSettingsEntity) _then;

  /// Create a copy of ReaderSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fontSize = null,
    Object? lineHeight = null,
    Object? fontType = null,
    Object? readingMode = null,
    Object? showTranslation = null,
    Object? translationLanguage = null,
    Object? showTransliteration = null,
    Object? showAyahNumbers = null,
    Object? nightMode = null,
    Object? translationFontSize = null,
    Object? lastReadSurah = freezed,
    Object? lastReadAyah = freezed,
    Object? lastReadPage = freezed,
  }) {
    return _then(
      _ReaderSettingsEntity(
        fontSize: null == fontSize
            ? _self.fontSize
            : fontSize // ignore: cast_nullable_to_non_nullable
                  as double,
        lineHeight: null == lineHeight
            ? _self.lineHeight
            : lineHeight // ignore: cast_nullable_to_non_nullable
                  as double,
        fontType: null == fontType
            ? _self.fontType
            : fontType // ignore: cast_nullable_to_non_nullable
                  as QuranFontType,
        readingMode: null == readingMode
            ? _self.readingMode
            : readingMode // ignore: cast_nullable_to_non_nullable
                  as ReadingMode,
        showTranslation: null == showTranslation
            ? _self.showTranslation
            : showTranslation // ignore: cast_nullable_to_non_nullable
                  as bool,
        translationLanguage: null == translationLanguage
            ? _self.translationLanguage
            : translationLanguage // ignore: cast_nullable_to_non_nullable
                  as String,
        showTransliteration: null == showTransliteration
            ? _self.showTransliteration
            : showTransliteration // ignore: cast_nullable_to_non_nullable
                  as bool,
        showAyahNumbers: null == showAyahNumbers
            ? _self.showAyahNumbers
            : showAyahNumbers // ignore: cast_nullable_to_non_nullable
                  as bool,
        nightMode: null == nightMode
            ? _self.nightMode
            : nightMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        translationFontSize: null == translationFontSize
            ? _self.translationFontSize
            : translationFontSize // ignore: cast_nullable_to_non_nullable
                  as double,
        lastReadSurah: freezed == lastReadSurah
            ? _self.lastReadSurah
            : lastReadSurah // ignore: cast_nullable_to_non_nullable
                  as int?,
        lastReadAyah: freezed == lastReadAyah
            ? _self.lastReadAyah
            : lastReadAyah // ignore: cast_nullable_to_non_nullable
                  as int?,
        lastReadPage: freezed == lastReadPage
            ? _self.lastReadPage
            : lastReadPage // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}
