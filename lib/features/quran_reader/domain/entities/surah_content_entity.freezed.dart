// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'surah_content_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SurahContentEntity {
  int get number;
  String get name;
  String get nameEnglish;
  String get nameTranslation;
  String get revelationType;
  int get numberOfAyahs;
  List<AyahEntity> get ayahs;
  int? get startPage;
  int? get endPage;

  /// Create a copy of SurahContentEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SurahContentEntityCopyWith<SurahContentEntity> get copyWith =>
      _$SurahContentEntityCopyWithImpl<SurahContentEntity>(
        this as SurahContentEntity,
        _$identity,
      );

  /// Serializes this SurahContentEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SurahContentEntity &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.nameEnglish, nameEnglish) ||
                other.nameEnglish == nameEnglish) &&
            (identical(other.nameTranslation, nameTranslation) ||
                other.nameTranslation == nameTranslation) &&
            (identical(other.revelationType, revelationType) ||
                other.revelationType == revelationType) &&
            (identical(other.numberOfAyahs, numberOfAyahs) ||
                other.numberOfAyahs == numberOfAyahs) &&
            const DeepCollectionEquality().equals(other.ayahs, ayahs) &&
            (identical(other.startPage, startPage) ||
                other.startPage == startPage) &&
            (identical(other.endPage, endPage) || other.endPage == endPage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    number,
    name,
    nameEnglish,
    nameTranslation,
    revelationType,
    numberOfAyahs,
    const DeepCollectionEquality().hash(ayahs),
    startPage,
    endPage,
  );

  @override
  String toString() {
    return 'SurahContentEntity(number: $number, name: $name, nameEnglish: $nameEnglish, nameTranslation: $nameTranslation, revelationType: $revelationType, numberOfAyahs: $numberOfAyahs, ayahs: $ayahs, startPage: $startPage, endPage: $endPage)';
  }
}

/// @nodoc
abstract mixin class $SurahContentEntityCopyWith<$Res> {
  factory $SurahContentEntityCopyWith(
    SurahContentEntity value,
    $Res Function(SurahContentEntity) _then,
  ) = _$SurahContentEntityCopyWithImpl;
  @useResult
  $Res call({
    int number,
    String name,
    String nameEnglish,
    String nameTranslation,
    String revelationType,
    int numberOfAyahs,
    List<AyahEntity> ayahs,
    int? startPage,
    int? endPage,
  });
}

/// @nodoc
class _$SurahContentEntityCopyWithImpl<$Res>
    implements $SurahContentEntityCopyWith<$Res> {
  _$SurahContentEntityCopyWithImpl(this._self, this._then);

  final SurahContentEntity _self;
  final $Res Function(SurahContentEntity) _then;

  /// Create a copy of SurahContentEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? name = null,
    Object? nameEnglish = null,
    Object? nameTranslation = null,
    Object? revelationType = null,
    Object? numberOfAyahs = null,
    Object? ayahs = null,
    Object? startPage = freezed,
    Object? endPage = freezed,
  }) {
    return _then(
      _self.copyWith(
        number: null == number
            ? _self.number
            : number // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        nameEnglish: null == nameEnglish
            ? _self.nameEnglish
            : nameEnglish // ignore: cast_nullable_to_non_nullable
                  as String,
        nameTranslation: null == nameTranslation
            ? _self.nameTranslation
            : nameTranslation // ignore: cast_nullable_to_non_nullable
                  as String,
        revelationType: null == revelationType
            ? _self.revelationType
            : revelationType // ignore: cast_nullable_to_non_nullable
                  as String,
        numberOfAyahs: null == numberOfAyahs
            ? _self.numberOfAyahs
            : numberOfAyahs // ignore: cast_nullable_to_non_nullable
                  as int,
        ayahs: null == ayahs
            ? _self.ayahs
            : ayahs // ignore: cast_nullable_to_non_nullable
                  as List<AyahEntity>,
        startPage: freezed == startPage
            ? _self.startPage
            : startPage // ignore: cast_nullable_to_non_nullable
                  as int?,
        endPage: freezed == endPage
            ? _self.endPage
            : endPage // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SurahContentEntity].
extension SurahContentEntityPatterns on SurahContentEntity {
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
    TResult Function(_SurahContentEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SurahContentEntity() when $default != null:
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
    TResult Function(_SurahContentEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SurahContentEntity():
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
    TResult? Function(_SurahContentEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SurahContentEntity() when $default != null:
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
      int number,
      String name,
      String nameEnglish,
      String nameTranslation,
      String revelationType,
      int numberOfAyahs,
      List<AyahEntity> ayahs,
      int? startPage,
      int? endPage,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SurahContentEntity() when $default != null:
        return $default(
          _that.number,
          _that.name,
          _that.nameEnglish,
          _that.nameTranslation,
          _that.revelationType,
          _that.numberOfAyahs,
          _that.ayahs,
          _that.startPage,
          _that.endPage,
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
      int number,
      String name,
      String nameEnglish,
      String nameTranslation,
      String revelationType,
      int numberOfAyahs,
      List<AyahEntity> ayahs,
      int? startPage,
      int? endPage,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SurahContentEntity():
        return $default(
          _that.number,
          _that.name,
          _that.nameEnglish,
          _that.nameTranslation,
          _that.revelationType,
          _that.numberOfAyahs,
          _that.ayahs,
          _that.startPage,
          _that.endPage,
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
      int number,
      String name,
      String nameEnglish,
      String nameTranslation,
      String revelationType,
      int numberOfAyahs,
      List<AyahEntity> ayahs,
      int? startPage,
      int? endPage,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SurahContentEntity() when $default != null:
        return $default(
          _that.number,
          _that.name,
          _that.nameEnglish,
          _that.nameTranslation,
          _that.revelationType,
          _that.numberOfAyahs,
          _that.ayahs,
          _that.startPage,
          _that.endPage,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SurahContentEntity extends SurahContentEntity {
  const _SurahContentEntity({
    required this.number,
    required this.name,
    required this.nameEnglish,
    required this.nameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    required final List<AyahEntity> ayahs,
    this.startPage,
    this.endPage,
  }) : _ayahs = ayahs,
       super._();
  factory _SurahContentEntity.fromJson(Map<String, dynamic> json) =>
      _$SurahContentEntityFromJson(json);

  @override
  final int number;
  @override
  final String name;
  @override
  final String nameEnglish;
  @override
  final String nameTranslation;
  @override
  final String revelationType;
  @override
  final int numberOfAyahs;
  final List<AyahEntity> _ayahs;
  @override
  List<AyahEntity> get ayahs {
    if (_ayahs is EqualUnmodifiableListView) return _ayahs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ayahs);
  }

  @override
  final int? startPage;
  @override
  final int? endPage;

  /// Create a copy of SurahContentEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SurahContentEntityCopyWith<_SurahContentEntity> get copyWith =>
      __$SurahContentEntityCopyWithImpl<_SurahContentEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SurahContentEntityToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SurahContentEntity &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.nameEnglish, nameEnglish) ||
                other.nameEnglish == nameEnglish) &&
            (identical(other.nameTranslation, nameTranslation) ||
                other.nameTranslation == nameTranslation) &&
            (identical(other.revelationType, revelationType) ||
                other.revelationType == revelationType) &&
            (identical(other.numberOfAyahs, numberOfAyahs) ||
                other.numberOfAyahs == numberOfAyahs) &&
            const DeepCollectionEquality().equals(other._ayahs, _ayahs) &&
            (identical(other.startPage, startPage) ||
                other.startPage == startPage) &&
            (identical(other.endPage, endPage) || other.endPage == endPage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    number,
    name,
    nameEnglish,
    nameTranslation,
    revelationType,
    numberOfAyahs,
    const DeepCollectionEquality().hash(_ayahs),
    startPage,
    endPage,
  );

  @override
  String toString() {
    return 'SurahContentEntity(number: $number, name: $name, nameEnglish: $nameEnglish, nameTranslation: $nameTranslation, revelationType: $revelationType, numberOfAyahs: $numberOfAyahs, ayahs: $ayahs, startPage: $startPage, endPage: $endPage)';
  }
}

/// @nodoc
abstract mixin class _$SurahContentEntityCopyWith<$Res>
    implements $SurahContentEntityCopyWith<$Res> {
  factory _$SurahContentEntityCopyWith(
    _SurahContentEntity value,
    $Res Function(_SurahContentEntity) _then,
  ) = __$SurahContentEntityCopyWithImpl;
  @override
  @useResult
  $Res call({
    int number,
    String name,
    String nameEnglish,
    String nameTranslation,
    String revelationType,
    int numberOfAyahs,
    List<AyahEntity> ayahs,
    int? startPage,
    int? endPage,
  });
}

/// @nodoc
class __$SurahContentEntityCopyWithImpl<$Res>
    implements _$SurahContentEntityCopyWith<$Res> {
  __$SurahContentEntityCopyWithImpl(this._self, this._then);

  final _SurahContentEntity _self;
  final $Res Function(_SurahContentEntity) _then;

  /// Create a copy of SurahContentEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? number = null,
    Object? name = null,
    Object? nameEnglish = null,
    Object? nameTranslation = null,
    Object? revelationType = null,
    Object? numberOfAyahs = null,
    Object? ayahs = null,
    Object? startPage = freezed,
    Object? endPage = freezed,
  }) {
    return _then(
      _SurahContentEntity(
        number: null == number
            ? _self.number
            : number // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        nameEnglish: null == nameEnglish
            ? _self.nameEnglish
            : nameEnglish // ignore: cast_nullable_to_non_nullable
                  as String,
        nameTranslation: null == nameTranslation
            ? _self.nameTranslation
            : nameTranslation // ignore: cast_nullable_to_non_nullable
                  as String,
        revelationType: null == revelationType
            ? _self.revelationType
            : revelationType // ignore: cast_nullable_to_non_nullable
                  as String,
        numberOfAyahs: null == numberOfAyahs
            ? _self.numberOfAyahs
            : numberOfAyahs // ignore: cast_nullable_to_non_nullable
                  as int,
        ayahs: null == ayahs
            ? _self._ayahs
            : ayahs // ignore: cast_nullable_to_non_nullable
                  as List<AyahEntity>,
        startPage: freezed == startPage
            ? _self.startPage
            : startPage // ignore: cast_nullable_to_non_nullable
                  as int?,
        endPage: freezed == endPage
            ? _self.endPage
            : endPage // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
mixin _$QuranPageEntity {
  int get pageNumber;
  List<PageAyahInfo> get ayahs;
  int get juz;
  int get hizb;

  /// Create a copy of QuranPageEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QuranPageEntityCopyWith<QuranPageEntity> get copyWith =>
      _$QuranPageEntityCopyWithImpl<QuranPageEntity>(
        this as QuranPageEntity,
        _$identity,
      );

  /// Serializes this QuranPageEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QuranPageEntity &&
            (identical(other.pageNumber, pageNumber) ||
                other.pageNumber == pageNumber) &&
            const DeepCollectionEquality().equals(other.ayahs, ayahs) &&
            (identical(other.juz, juz) || other.juz == juz) &&
            (identical(other.hizb, hizb) || other.hizb == hizb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    pageNumber,
    const DeepCollectionEquality().hash(ayahs),
    juz,
    hizb,
  );

  @override
  String toString() {
    return 'QuranPageEntity(pageNumber: $pageNumber, ayahs: $ayahs, juz: $juz, hizb: $hizb)';
  }
}

/// @nodoc
abstract mixin class $QuranPageEntityCopyWith<$Res> {
  factory $QuranPageEntityCopyWith(
    QuranPageEntity value,
    $Res Function(QuranPageEntity) _then,
  ) = _$QuranPageEntityCopyWithImpl;
  @useResult
  $Res call({int pageNumber, List<PageAyahInfo> ayahs, int juz, int hizb});
}

/// @nodoc
class _$QuranPageEntityCopyWithImpl<$Res>
    implements $QuranPageEntityCopyWith<$Res> {
  _$QuranPageEntityCopyWithImpl(this._self, this._then);

  final QuranPageEntity _self;
  final $Res Function(QuranPageEntity) _then;

  /// Create a copy of QuranPageEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pageNumber = null,
    Object? ayahs = null,
    Object? juz = null,
    Object? hizb = null,
  }) {
    return _then(
      _self.copyWith(
        pageNumber: null == pageNumber
            ? _self.pageNumber
            : pageNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        ayahs: null == ayahs
            ? _self.ayahs
            : ayahs // ignore: cast_nullable_to_non_nullable
                  as List<PageAyahInfo>,
        juz: null == juz
            ? _self.juz
            : juz // ignore: cast_nullable_to_non_nullable
                  as int,
        hizb: null == hizb
            ? _self.hizb
            : hizb // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [QuranPageEntity].
extension QuranPageEntityPatterns on QuranPageEntity {
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
    TResult Function(_QuranPageEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QuranPageEntity() when $default != null:
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
    TResult Function(_QuranPageEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranPageEntity():
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
    TResult? Function(_QuranPageEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranPageEntity() when $default != null:
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
      int pageNumber,
      List<PageAyahInfo> ayahs,
      int juz,
      int hizb,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QuranPageEntity() when $default != null:
        return $default(_that.pageNumber, _that.ayahs, _that.juz, _that.hizb);
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
      int pageNumber,
      List<PageAyahInfo> ayahs,
      int juz,
      int hizb,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranPageEntity():
        return $default(_that.pageNumber, _that.ayahs, _that.juz, _that.hizb);
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
      int pageNumber,
      List<PageAyahInfo> ayahs,
      int juz,
      int hizb,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranPageEntity() when $default != null:
        return $default(_that.pageNumber, _that.ayahs, _that.juz, _that.hizb);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _QuranPageEntity extends QuranPageEntity {
  const _QuranPageEntity({
    required this.pageNumber,
    required final List<PageAyahInfo> ayahs,
    required this.juz,
    required this.hizb,
  }) : _ayahs = ayahs,
       super._();
  factory _QuranPageEntity.fromJson(Map<String, dynamic> json) =>
      _$QuranPageEntityFromJson(json);

  @override
  final int pageNumber;
  final List<PageAyahInfo> _ayahs;
  @override
  List<PageAyahInfo> get ayahs {
    if (_ayahs is EqualUnmodifiableListView) return _ayahs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ayahs);
  }

  @override
  final int juz;
  @override
  final int hizb;

  /// Create a copy of QuranPageEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$QuranPageEntityCopyWith<_QuranPageEntity> get copyWith =>
      __$QuranPageEntityCopyWithImpl<_QuranPageEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$QuranPageEntityToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _QuranPageEntity &&
            (identical(other.pageNumber, pageNumber) ||
                other.pageNumber == pageNumber) &&
            const DeepCollectionEquality().equals(other._ayahs, _ayahs) &&
            (identical(other.juz, juz) || other.juz == juz) &&
            (identical(other.hizb, hizb) || other.hizb == hizb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    pageNumber,
    const DeepCollectionEquality().hash(_ayahs),
    juz,
    hizb,
  );

  @override
  String toString() {
    return 'QuranPageEntity(pageNumber: $pageNumber, ayahs: $ayahs, juz: $juz, hizb: $hizb)';
  }
}

/// @nodoc
abstract mixin class _$QuranPageEntityCopyWith<$Res>
    implements $QuranPageEntityCopyWith<$Res> {
  factory _$QuranPageEntityCopyWith(
    _QuranPageEntity value,
    $Res Function(_QuranPageEntity) _then,
  ) = __$QuranPageEntityCopyWithImpl;
  @override
  @useResult
  $Res call({int pageNumber, List<PageAyahInfo> ayahs, int juz, int hizb});
}

/// @nodoc
class __$QuranPageEntityCopyWithImpl<$Res>
    implements _$QuranPageEntityCopyWith<$Res> {
  __$QuranPageEntityCopyWithImpl(this._self, this._then);

  final _QuranPageEntity _self;
  final $Res Function(_QuranPageEntity) _then;

  /// Create a copy of QuranPageEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? pageNumber = null,
    Object? ayahs = null,
    Object? juz = null,
    Object? hizb = null,
  }) {
    return _then(
      _QuranPageEntity(
        pageNumber: null == pageNumber
            ? _self.pageNumber
            : pageNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        ayahs: null == ayahs
            ? _self._ayahs
            : ayahs // ignore: cast_nullable_to_non_nullable
                  as List<PageAyahInfo>,
        juz: null == juz
            ? _self.juz
            : juz // ignore: cast_nullable_to_non_nullable
                  as int,
        hizb: null == hizb
            ? _self.hizb
            : hizb // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$PageAyahInfo {
  int get surahNumber;
  String get surahName;
  String get surahNameEnglish;
  int get ayahNumber;
  String get text;
  List<QuranWord>? get words;

  /// Create a copy of PageAyahInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PageAyahInfoCopyWith<PageAyahInfo> get copyWith =>
      _$PageAyahInfoCopyWithImpl<PageAyahInfo>(
        this as PageAyahInfo,
        _$identity,
      );

  /// Serializes this PageAyahInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PageAyahInfo &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber) &&
            (identical(other.surahName, surahName) ||
                other.surahName == surahName) &&
            (identical(other.surahNameEnglish, surahNameEnglish) ||
                other.surahNameEnglish == surahNameEnglish) &&
            (identical(other.ayahNumber, ayahNumber) ||
                other.ayahNumber == ayahNumber) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other.words, words));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    surahNumber,
    surahName,
    surahNameEnglish,
    ayahNumber,
    text,
    const DeepCollectionEquality().hash(words),
  );

  @override
  String toString() {
    return 'PageAyahInfo(surahNumber: $surahNumber, surahName: $surahName, surahNameEnglish: $surahNameEnglish, ayahNumber: $ayahNumber, text: $text, words: $words)';
  }
}

/// @nodoc
abstract mixin class $PageAyahInfoCopyWith<$Res> {
  factory $PageAyahInfoCopyWith(
    PageAyahInfo value,
    $Res Function(PageAyahInfo) _then,
  ) = _$PageAyahInfoCopyWithImpl;
  @useResult
  $Res call({
    int surahNumber,
    String surahName,
    String surahNameEnglish,
    int ayahNumber,
    String text,
    List<QuranWord>? words,
  });
}

/// @nodoc
class _$PageAyahInfoCopyWithImpl<$Res> implements $PageAyahInfoCopyWith<$Res> {
  _$PageAyahInfoCopyWithImpl(this._self, this._then);

  final PageAyahInfo _self;
  final $Res Function(PageAyahInfo) _then;

  /// Create a copy of PageAyahInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? surahNumber = null,
    Object? surahName = null,
    Object? surahNameEnglish = null,
    Object? ayahNumber = null,
    Object? text = null,
    Object? words = freezed,
  }) {
    return _then(
      _self.copyWith(
        surahNumber: null == surahNumber
            ? _self.surahNumber
            : surahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        surahName: null == surahName
            ? _self.surahName
            : surahName // ignore: cast_nullable_to_non_nullable
                  as String,
        surahNameEnglish: null == surahNameEnglish
            ? _self.surahNameEnglish
            : surahNameEnglish // ignore: cast_nullable_to_non_nullable
                  as String,
        ayahNumber: null == ayahNumber
            ? _self.ayahNumber
            : ayahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        words: freezed == words
            ? _self.words
            : words // ignore: cast_nullable_to_non_nullable
                  as List<QuranWord>?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PageAyahInfo].
extension PageAyahInfoPatterns on PageAyahInfo {
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
    TResult Function(_PageAyahInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PageAyahInfo() when $default != null:
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
    TResult Function(_PageAyahInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PageAyahInfo():
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
    TResult? Function(_PageAyahInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PageAyahInfo() when $default != null:
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
      int surahNumber,
      String surahName,
      String surahNameEnglish,
      int ayahNumber,
      String text,
      List<QuranWord>? words,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PageAyahInfo() when $default != null:
        return $default(
          _that.surahNumber,
          _that.surahName,
          _that.surahNameEnglish,
          _that.ayahNumber,
          _that.text,
          _that.words,
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
      int surahNumber,
      String surahName,
      String surahNameEnglish,
      int ayahNumber,
      String text,
      List<QuranWord>? words,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PageAyahInfo():
        return $default(
          _that.surahNumber,
          _that.surahName,
          _that.surahNameEnglish,
          _that.ayahNumber,
          _that.text,
          _that.words,
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
      int surahNumber,
      String surahName,
      String surahNameEnglish,
      int ayahNumber,
      String text,
      List<QuranWord>? words,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PageAyahInfo() when $default != null:
        return $default(
          _that.surahNumber,
          _that.surahName,
          _that.surahNameEnglish,
          _that.ayahNumber,
          _that.text,
          _that.words,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PageAyahInfo implements PageAyahInfo {
  const _PageAyahInfo({
    required this.surahNumber,
    required this.surahName,
    required this.surahNameEnglish,
    required this.ayahNumber,
    required this.text,
    final List<QuranWord>? words,
  }) : _words = words;
  factory _PageAyahInfo.fromJson(Map<String, dynamic> json) =>
      _$PageAyahInfoFromJson(json);

  @override
  final int surahNumber;
  @override
  final String surahName;
  @override
  final String surahNameEnglish;
  @override
  final int ayahNumber;
  @override
  final String text;
  final List<QuranWord>? _words;
  @override
  List<QuranWord>? get words {
    final value = _words;
    if (value == null) return null;
    if (_words is EqualUnmodifiableListView) return _words;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Create a copy of PageAyahInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PageAyahInfoCopyWith<_PageAyahInfo> get copyWith =>
      __$PageAyahInfoCopyWithImpl<_PageAyahInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PageAyahInfoToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PageAyahInfo &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber) &&
            (identical(other.surahName, surahName) ||
                other.surahName == surahName) &&
            (identical(other.surahNameEnglish, surahNameEnglish) ||
                other.surahNameEnglish == surahNameEnglish) &&
            (identical(other.ayahNumber, ayahNumber) ||
                other.ayahNumber == ayahNumber) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other._words, _words));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    surahNumber,
    surahName,
    surahNameEnglish,
    ayahNumber,
    text,
    const DeepCollectionEquality().hash(_words),
  );

  @override
  String toString() {
    return 'PageAyahInfo(surahNumber: $surahNumber, surahName: $surahName, surahNameEnglish: $surahNameEnglish, ayahNumber: $ayahNumber, text: $text, words: $words)';
  }
}

/// @nodoc
abstract mixin class _$PageAyahInfoCopyWith<$Res>
    implements $PageAyahInfoCopyWith<$Res> {
  factory _$PageAyahInfoCopyWith(
    _PageAyahInfo value,
    $Res Function(_PageAyahInfo) _then,
  ) = __$PageAyahInfoCopyWithImpl;
  @override
  @useResult
  $Res call({
    int surahNumber,
    String surahName,
    String surahNameEnglish,
    int ayahNumber,
    String text,
    List<QuranWord>? words,
  });
}

/// @nodoc
class __$PageAyahInfoCopyWithImpl<$Res>
    implements _$PageAyahInfoCopyWith<$Res> {
  __$PageAyahInfoCopyWithImpl(this._self, this._then);

  final _PageAyahInfo _self;
  final $Res Function(_PageAyahInfo) _then;

  /// Create a copy of PageAyahInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? surahNumber = null,
    Object? surahName = null,
    Object? surahNameEnglish = null,
    Object? ayahNumber = null,
    Object? text = null,
    Object? words = freezed,
  }) {
    return _then(
      _PageAyahInfo(
        surahNumber: null == surahNumber
            ? _self.surahNumber
            : surahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        surahName: null == surahName
            ? _self.surahName
            : surahName // ignore: cast_nullable_to_non_nullable
                  as String,
        surahNameEnglish: null == surahNameEnglish
            ? _self.surahNameEnglish
            : surahNameEnglish // ignore: cast_nullable_to_non_nullable
                  as String,
        ayahNumber: null == ayahNumber
            ? _self.ayahNumber
            : ayahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        words: freezed == words
            ? _self._words
            : words // ignore: cast_nullable_to_non_nullable
                  as List<QuranWord>?,
      ),
    );
  }
}

/// @nodoc
mixin _$QuranWord {
  int get id;
  int get position;
  String get text;
  @JsonKey(name: 'text_uthmani')
  String? get textUthmani;
  @JsonKey(name: 'audio_url')
  String? get audioUrl;
  @JsonKey(name: 'code_v1')
  String? get codeV1;
  @JsonKey(name: 'char_type_name')
  String? get charTypeName;
  @JsonKey(name: 'translation')
  WordTranslation? get translation;
  @JsonKey(name: 'transliteration')
  WordTransliteration? get transliteration;

  /// Create a copy of QuranWord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QuranWordCopyWith<QuranWord> get copyWith =>
      _$QuranWordCopyWithImpl<QuranWord>(this as QuranWord, _$identity);

  /// Serializes this QuranWord to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QuranWord &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.textUthmani, textUthmani) ||
                other.textUthmani == textUthmani) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.codeV1, codeV1) || other.codeV1 == codeV1) &&
            (identical(other.charTypeName, charTypeName) ||
                other.charTypeName == charTypeName) &&
            (identical(other.translation, translation) ||
                other.translation == translation) &&
            (identical(other.transliteration, transliteration) ||
                other.transliteration == transliteration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    position,
    text,
    textUthmani,
    audioUrl,
    codeV1,
    charTypeName,
    translation,
    transliteration,
  );

  @override
  String toString() {
    return 'QuranWord(id: $id, position: $position, text: $text, textUthmani: $textUthmani, audioUrl: $audioUrl, codeV1: $codeV1, charTypeName: $charTypeName, translation: $translation, transliteration: $transliteration)';
  }
}

/// @nodoc
abstract mixin class $QuranWordCopyWith<$Res> {
  factory $QuranWordCopyWith(QuranWord value, $Res Function(QuranWord) _then) =
      _$QuranWordCopyWithImpl;
  @useResult
  $Res call({
    int id,
    int position,
    String text,
    @JsonKey(name: 'text_uthmani') String? textUthmani,
    @JsonKey(name: 'audio_url') String? audioUrl,
    @JsonKey(name: 'code_v1') String? codeV1,
    @JsonKey(name: 'char_type_name') String? charTypeName,
    @JsonKey(name: 'translation') WordTranslation? translation,
    @JsonKey(name: 'transliteration') WordTransliteration? transliteration,
  });

  $WordTranslationCopyWith<$Res>? get translation;
  $WordTransliterationCopyWith<$Res>? get transliteration;
}

/// @nodoc
class _$QuranWordCopyWithImpl<$Res> implements $QuranWordCopyWith<$Res> {
  _$QuranWordCopyWithImpl(this._self, this._then);

  final QuranWord _self;
  final $Res Function(QuranWord) _then;

  /// Create a copy of QuranWord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? position = null,
    Object? text = null,
    Object? textUthmani = freezed,
    Object? audioUrl = freezed,
    Object? codeV1 = freezed,
    Object? charTypeName = freezed,
    Object? translation = freezed,
    Object? transliteration = freezed,
  }) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        position: null == position
            ? _self.position
            : position // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        textUthmani: freezed == textUthmani
            ? _self.textUthmani
            : textUthmani // ignore: cast_nullable_to_non_nullable
                  as String?,
        audioUrl: freezed == audioUrl
            ? _self.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        codeV1: freezed == codeV1
            ? _self.codeV1
            : codeV1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        charTypeName: freezed == charTypeName
            ? _self.charTypeName
            : charTypeName // ignore: cast_nullable_to_non_nullable
                  as String?,
        translation: freezed == translation
            ? _self.translation
            : translation // ignore: cast_nullable_to_non_nullable
                  as WordTranslation?,
        transliteration: freezed == transliteration
            ? _self.transliteration
            : transliteration // ignore: cast_nullable_to_non_nullable
                  as WordTransliteration?,
      ),
    );
  }

  /// Create a copy of QuranWord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WordTranslationCopyWith<$Res>? get translation {
    if (_self.translation == null) {
      return null;
    }

    return $WordTranslationCopyWith<$Res>(_self.translation!, (value) {
      return _then(_self.copyWith(translation: value));
    });
  }

  /// Create a copy of QuranWord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WordTransliterationCopyWith<$Res>? get transliteration {
    if (_self.transliteration == null) {
      return null;
    }

    return $WordTransliterationCopyWith<$Res>(_self.transliteration!, (value) {
      return _then(_self.copyWith(transliteration: value));
    });
  }
}

/// Adds pattern-matching-related methods to [QuranWord].
extension QuranWordPatterns on QuranWord {
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
    TResult Function(_QuranWord value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QuranWord() when $default != null:
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
    TResult Function(_QuranWord value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranWord():
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
    TResult? Function(_QuranWord value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranWord() when $default != null:
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
      int id,
      int position,
      String text,
      @JsonKey(name: 'text_uthmani') String? textUthmani,
      @JsonKey(name: 'audio_url') String? audioUrl,
      @JsonKey(name: 'code_v1') String? codeV1,
      @JsonKey(name: 'char_type_name') String? charTypeName,
      @JsonKey(name: 'translation') WordTranslation? translation,
      @JsonKey(name: 'transliteration') WordTransliteration? transliteration,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QuranWord() when $default != null:
        return $default(
          _that.id,
          _that.position,
          _that.text,
          _that.textUthmani,
          _that.audioUrl,
          _that.codeV1,
          _that.charTypeName,
          _that.translation,
          _that.transliteration,
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
      int id,
      int position,
      String text,
      @JsonKey(name: 'text_uthmani') String? textUthmani,
      @JsonKey(name: 'audio_url') String? audioUrl,
      @JsonKey(name: 'code_v1') String? codeV1,
      @JsonKey(name: 'char_type_name') String? charTypeName,
      @JsonKey(name: 'translation') WordTranslation? translation,
      @JsonKey(name: 'transliteration') WordTransliteration? transliteration,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranWord():
        return $default(
          _that.id,
          _that.position,
          _that.text,
          _that.textUthmani,
          _that.audioUrl,
          _that.codeV1,
          _that.charTypeName,
          _that.translation,
          _that.transliteration,
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
      int id,
      int position,
      String text,
      @JsonKey(name: 'text_uthmani') String? textUthmani,
      @JsonKey(name: 'audio_url') String? audioUrl,
      @JsonKey(name: 'code_v1') String? codeV1,
      @JsonKey(name: 'char_type_name') String? charTypeName,
      @JsonKey(name: 'translation') WordTranslation? translation,
      @JsonKey(name: 'transliteration') WordTransliteration? transliteration,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranWord() when $default != null:
        return $default(
          _that.id,
          _that.position,
          _that.text,
          _that.textUthmani,
          _that.audioUrl,
          _that.codeV1,
          _that.charTypeName,
          _that.translation,
          _that.transliteration,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _QuranWord implements QuranWord {
  const _QuranWord({
    required this.id,
    required this.position,
    required this.text,
    @JsonKey(name: 'text_uthmani') this.textUthmani,
    @JsonKey(name: 'audio_url') this.audioUrl,
    @JsonKey(name: 'code_v1') this.codeV1,
    @JsonKey(name: 'char_type_name') this.charTypeName,
    @JsonKey(name: 'translation') this.translation,
    @JsonKey(name: 'transliteration') this.transliteration,
  });
  factory _QuranWord.fromJson(Map<String, dynamic> json) =>
      _$QuranWordFromJson(json);

  @override
  final int id;
  @override
  final int position;
  @override
  final String text;
  @override
  @JsonKey(name: 'text_uthmani')
  final String? textUthmani;
  @override
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  @override
  @JsonKey(name: 'code_v1')
  final String? codeV1;
  @override
  @JsonKey(name: 'char_type_name')
  final String? charTypeName;
  @override
  @JsonKey(name: 'translation')
  final WordTranslation? translation;
  @override
  @JsonKey(name: 'transliteration')
  final WordTransliteration? transliteration;

  /// Create a copy of QuranWord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$QuranWordCopyWith<_QuranWord> get copyWith =>
      __$QuranWordCopyWithImpl<_QuranWord>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$QuranWordToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _QuranWord &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.textUthmani, textUthmani) ||
                other.textUthmani == textUthmani) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.codeV1, codeV1) || other.codeV1 == codeV1) &&
            (identical(other.charTypeName, charTypeName) ||
                other.charTypeName == charTypeName) &&
            (identical(other.translation, translation) ||
                other.translation == translation) &&
            (identical(other.transliteration, transliteration) ||
                other.transliteration == transliteration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    position,
    text,
    textUthmani,
    audioUrl,
    codeV1,
    charTypeName,
    translation,
    transliteration,
  );

  @override
  String toString() {
    return 'QuranWord(id: $id, position: $position, text: $text, textUthmani: $textUthmani, audioUrl: $audioUrl, codeV1: $codeV1, charTypeName: $charTypeName, translation: $translation, transliteration: $transliteration)';
  }
}

/// @nodoc
abstract mixin class _$QuranWordCopyWith<$Res>
    implements $QuranWordCopyWith<$Res> {
  factory _$QuranWordCopyWith(
    _QuranWord value,
    $Res Function(_QuranWord) _then,
  ) = __$QuranWordCopyWithImpl;
  @override
  @useResult
  $Res call({
    int id,
    int position,
    String text,
    @JsonKey(name: 'text_uthmani') String? textUthmani,
    @JsonKey(name: 'audio_url') String? audioUrl,
    @JsonKey(name: 'code_v1') String? codeV1,
    @JsonKey(name: 'char_type_name') String? charTypeName,
    @JsonKey(name: 'translation') WordTranslation? translation,
    @JsonKey(name: 'transliteration') WordTransliteration? transliteration,
  });

  @override
  $WordTranslationCopyWith<$Res>? get translation;
  @override
  $WordTransliterationCopyWith<$Res>? get transliteration;
}

/// @nodoc
class __$QuranWordCopyWithImpl<$Res> implements _$QuranWordCopyWith<$Res> {
  __$QuranWordCopyWithImpl(this._self, this._then);

  final _QuranWord _self;
  final $Res Function(_QuranWord) _then;

  /// Create a copy of QuranWord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? position = null,
    Object? text = null,
    Object? textUthmani = freezed,
    Object? audioUrl = freezed,
    Object? codeV1 = freezed,
    Object? charTypeName = freezed,
    Object? translation = freezed,
    Object? transliteration = freezed,
  }) {
    return _then(
      _QuranWord(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        position: null == position
            ? _self.position
            : position // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        textUthmani: freezed == textUthmani
            ? _self.textUthmani
            : textUthmani // ignore: cast_nullable_to_non_nullable
                  as String?,
        audioUrl: freezed == audioUrl
            ? _self.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        codeV1: freezed == codeV1
            ? _self.codeV1
            : codeV1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        charTypeName: freezed == charTypeName
            ? _self.charTypeName
            : charTypeName // ignore: cast_nullable_to_non_nullable
                  as String?,
        translation: freezed == translation
            ? _self.translation
            : translation // ignore: cast_nullable_to_non_nullable
                  as WordTranslation?,
        transliteration: freezed == transliteration
            ? _self.transliteration
            : transliteration // ignore: cast_nullable_to_non_nullable
                  as WordTransliteration?,
      ),
    );
  }

  /// Create a copy of QuranWord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WordTranslationCopyWith<$Res>? get translation {
    if (_self.translation == null) {
      return null;
    }

    return $WordTranslationCopyWith<$Res>(_self.translation!, (value) {
      return _then(_self.copyWith(translation: value));
    });
  }

  /// Create a copy of QuranWord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WordTransliterationCopyWith<$Res>? get transliteration {
    if (_self.transliteration == null) {
      return null;
    }

    return $WordTransliterationCopyWith<$Res>(_self.transliteration!, (value) {
      return _then(_self.copyWith(transliteration: value));
    });
  }
}

/// @nodoc
mixin _$WordTranslation {
  String get text;
  @JsonKey(name: 'language_name')
  String? get languageName;

  /// Create a copy of WordTranslation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WordTranslationCopyWith<WordTranslation> get copyWith =>
      _$WordTranslationCopyWithImpl<WordTranslation>(
        this as WordTranslation,
        _$identity,
      );

  /// Serializes this WordTranslation to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WordTranslation &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.languageName, languageName) ||
                other.languageName == languageName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, text, languageName);

  @override
  String toString() {
    return 'WordTranslation(text: $text, languageName: $languageName)';
  }
}

/// @nodoc
abstract mixin class $WordTranslationCopyWith<$Res> {
  factory $WordTranslationCopyWith(
    WordTranslation value,
    $Res Function(WordTranslation) _then,
  ) = _$WordTranslationCopyWithImpl;
  @useResult
  $Res call({
    String text,
    @JsonKey(name: 'language_name') String? languageName,
  });
}

/// @nodoc
class _$WordTranslationCopyWithImpl<$Res>
    implements $WordTranslationCopyWith<$Res> {
  _$WordTranslationCopyWithImpl(this._self, this._then);

  final WordTranslation _self;
  final $Res Function(WordTranslation) _then;

  /// Create a copy of WordTranslation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? text = null, Object? languageName = freezed}) {
    return _then(
      _self.copyWith(
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        languageName: freezed == languageName
            ? _self.languageName
            : languageName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [WordTranslation].
extension WordTranslationPatterns on WordTranslation {
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
    TResult Function(_WordTranslation value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WordTranslation() when $default != null:
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
    TResult Function(_WordTranslation value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordTranslation():
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
    TResult? Function(_WordTranslation value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordTranslation() when $default != null:
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
      String text,
      @JsonKey(name: 'language_name') String? languageName,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WordTranslation() when $default != null:
        return $default(_that.text, _that.languageName);
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
      String text,
      @JsonKey(name: 'language_name') String? languageName,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordTranslation():
        return $default(_that.text, _that.languageName);
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
      String text,
      @JsonKey(name: 'language_name') String? languageName,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordTranslation() when $default != null:
        return $default(_that.text, _that.languageName);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WordTranslation implements WordTranslation {
  const _WordTranslation({
    required this.text,
    @JsonKey(name: 'language_name') this.languageName,
  });
  factory _WordTranslation.fromJson(Map<String, dynamic> json) =>
      _$WordTranslationFromJson(json);

  @override
  final String text;
  @override
  @JsonKey(name: 'language_name')
  final String? languageName;

  /// Create a copy of WordTranslation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WordTranslationCopyWith<_WordTranslation> get copyWith =>
      __$WordTranslationCopyWithImpl<_WordTranslation>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WordTranslationToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WordTranslation &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.languageName, languageName) ||
                other.languageName == languageName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, text, languageName);

  @override
  String toString() {
    return 'WordTranslation(text: $text, languageName: $languageName)';
  }
}

/// @nodoc
abstract mixin class _$WordTranslationCopyWith<$Res>
    implements $WordTranslationCopyWith<$Res> {
  factory _$WordTranslationCopyWith(
    _WordTranslation value,
    $Res Function(_WordTranslation) _then,
  ) = __$WordTranslationCopyWithImpl;
  @override
  @useResult
  $Res call({
    String text,
    @JsonKey(name: 'language_name') String? languageName,
  });
}

/// @nodoc
class __$WordTranslationCopyWithImpl<$Res>
    implements _$WordTranslationCopyWith<$Res> {
  __$WordTranslationCopyWithImpl(this._self, this._then);

  final _WordTranslation _self;
  final $Res Function(_WordTranslation) _then;

  /// Create a copy of WordTranslation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? text = null, Object? languageName = freezed}) {
    return _then(
      _WordTranslation(
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        languageName: freezed == languageName
            ? _self.languageName
            : languageName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$WordTransliteration {
  String? get text;
  @JsonKey(name: 'language_name')
  String? get languageName;

  /// Create a copy of WordTransliteration
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WordTransliterationCopyWith<WordTransliteration> get copyWith =>
      _$WordTransliterationCopyWithImpl<WordTransliteration>(
        this as WordTransliteration,
        _$identity,
      );

  /// Serializes this WordTransliteration to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WordTransliteration &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.languageName, languageName) ||
                other.languageName == languageName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, text, languageName);

  @override
  String toString() {
    return 'WordTransliteration(text: $text, languageName: $languageName)';
  }
}

/// @nodoc
abstract mixin class $WordTransliterationCopyWith<$Res> {
  factory $WordTransliterationCopyWith(
    WordTransliteration value,
    $Res Function(WordTransliteration) _then,
  ) = _$WordTransliterationCopyWithImpl;
  @useResult
  $Res call({
    String? text,
    @JsonKey(name: 'language_name') String? languageName,
  });
}

/// @nodoc
class _$WordTransliterationCopyWithImpl<$Res>
    implements $WordTransliterationCopyWith<$Res> {
  _$WordTransliterationCopyWithImpl(this._self, this._then);

  final WordTransliteration _self;
  final $Res Function(WordTransliteration) _then;

  /// Create a copy of WordTransliteration
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? text = freezed, Object? languageName = freezed}) {
    return _then(
      _self.copyWith(
        text: freezed == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String?,
        languageName: freezed == languageName
            ? _self.languageName
            : languageName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [WordTransliteration].
extension WordTransliterationPatterns on WordTransliteration {
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
    TResult Function(_WordTransliteration value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WordTransliteration() when $default != null:
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
    TResult Function(_WordTransliteration value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordTransliteration():
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
    TResult? Function(_WordTransliteration value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordTransliteration() when $default != null:
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
      String? text,
      @JsonKey(name: 'language_name') String? languageName,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WordTransliteration() when $default != null:
        return $default(_that.text, _that.languageName);
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
      String? text,
      @JsonKey(name: 'language_name') String? languageName,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordTransliteration():
        return $default(_that.text, _that.languageName);
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
      String? text,
      @JsonKey(name: 'language_name') String? languageName,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordTransliteration() when $default != null:
        return $default(_that.text, _that.languageName);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WordTransliteration implements WordTransliteration {
  const _WordTransliteration({
    required this.text,
    @JsonKey(name: 'language_name') this.languageName,
  });
  factory _WordTransliteration.fromJson(Map<String, dynamic> json) =>
      _$WordTransliterationFromJson(json);

  @override
  final String? text;
  @override
  @JsonKey(name: 'language_name')
  final String? languageName;

  /// Create a copy of WordTransliteration
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WordTransliterationCopyWith<_WordTransliteration> get copyWith =>
      __$WordTransliterationCopyWithImpl<_WordTransliteration>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$WordTransliterationToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WordTransliteration &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.languageName, languageName) ||
                other.languageName == languageName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, text, languageName);

  @override
  String toString() {
    return 'WordTransliteration(text: $text, languageName: $languageName)';
  }
}

/// @nodoc
abstract mixin class _$WordTransliterationCopyWith<$Res>
    implements $WordTransliterationCopyWith<$Res> {
  factory _$WordTransliterationCopyWith(
    _WordTransliteration value,
    $Res Function(_WordTransliteration) _then,
  ) = __$WordTransliterationCopyWithImpl;
  @override
  @useResult
  $Res call({
    String? text,
    @JsonKey(name: 'language_name') String? languageName,
  });
}

/// @nodoc
class __$WordTransliterationCopyWithImpl<$Res>
    implements _$WordTransliterationCopyWith<$Res> {
  __$WordTransliterationCopyWithImpl(this._self, this._then);

  final _WordTransliteration _self;
  final $Res Function(_WordTransliteration) _then;

  /// Create a copy of WordTransliteration
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? text = freezed, Object? languageName = freezed}) {
    return _then(
      _WordTransliteration(
        text: freezed == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String?,
        languageName: freezed == languageName
            ? _self.languageName
            : languageName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
