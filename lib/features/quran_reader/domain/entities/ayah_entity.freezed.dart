// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ayah_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AyahEntity {
  int get number;
  int get numberInSurah;
  int get surahNumber;
  String get text;
  String? get textUthmani;
  String? get textSimple;
  String? get translation;
  String? get transliteration;
  int? get juz;
  int? get manzil;
  int? get page;
  int? get ruku;
  int? get hizbQuarter;
  bool? get sajda;

  /// Create a copy of AyahEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AyahEntityCopyWith<AyahEntity> get copyWith =>
      _$AyahEntityCopyWithImpl<AyahEntity>(this as AyahEntity, _$identity);

  /// Serializes this AyahEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AyahEntity &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.numberInSurah, numberInSurah) ||
                other.numberInSurah == numberInSurah) &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.textUthmani, textUthmani) ||
                other.textUthmani == textUthmani) &&
            (identical(other.textSimple, textSimple) ||
                other.textSimple == textSimple) &&
            (identical(other.translation, translation) ||
                other.translation == translation) &&
            (identical(other.transliteration, transliteration) ||
                other.transliteration == transliteration) &&
            (identical(other.juz, juz) || other.juz == juz) &&
            (identical(other.manzil, manzil) || other.manzil == manzil) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.ruku, ruku) || other.ruku == ruku) &&
            (identical(other.hizbQuarter, hizbQuarter) ||
                other.hizbQuarter == hizbQuarter) &&
            (identical(other.sajda, sajda) || other.sajda == sajda));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    number,
    numberInSurah,
    surahNumber,
    text,
    textUthmani,
    textSimple,
    translation,
    transliteration,
    juz,
    manzil,
    page,
    ruku,
    hizbQuarter,
    sajda,
  );

  @override
  String toString() {
    return 'AyahEntity(number: $number, numberInSurah: $numberInSurah, surahNumber: $surahNumber, text: $text, textUthmani: $textUthmani, textSimple: $textSimple, translation: $translation, transliteration: $transliteration, juz: $juz, manzil: $manzil, page: $page, ruku: $ruku, hizbQuarter: $hizbQuarter, sajda: $sajda)';
  }
}

/// @nodoc
abstract mixin class $AyahEntityCopyWith<$Res> {
  factory $AyahEntityCopyWith(
    AyahEntity value,
    $Res Function(AyahEntity) _then,
  ) = _$AyahEntityCopyWithImpl;
  @useResult
  $Res call({
    int number,
    int numberInSurah,
    int surahNumber,
    String text,
    String? textUthmani,
    String? textSimple,
    String? translation,
    String? transliteration,
    int? juz,
    int? manzil,
    int? page,
    int? ruku,
    int? hizbQuarter,
    bool? sajda,
  });
}

/// @nodoc
class _$AyahEntityCopyWithImpl<$Res> implements $AyahEntityCopyWith<$Res> {
  _$AyahEntityCopyWithImpl(this._self, this._then);

  final AyahEntity _self;
  final $Res Function(AyahEntity) _then;

  /// Create a copy of AyahEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? numberInSurah = null,
    Object? surahNumber = null,
    Object? text = null,
    Object? textUthmani = freezed,
    Object? textSimple = freezed,
    Object? translation = freezed,
    Object? transliteration = freezed,
    Object? juz = freezed,
    Object? manzil = freezed,
    Object? page = freezed,
    Object? ruku = freezed,
    Object? hizbQuarter = freezed,
    Object? sajda = freezed,
  }) {
    return _then(
      _self.copyWith(
        number: null == number
            ? _self.number
            : number // ignore: cast_nullable_to_non_nullable
                  as int,
        numberInSurah: null == numberInSurah
            ? _self.numberInSurah
            : numberInSurah // ignore: cast_nullable_to_non_nullable
                  as int,
        surahNumber: null == surahNumber
            ? _self.surahNumber
            : surahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        textUthmani: freezed == textUthmani
            ? _self.textUthmani
            : textUthmani // ignore: cast_nullable_to_non_nullable
                  as String?,
        textSimple: freezed == textSimple
            ? _self.textSimple
            : textSimple // ignore: cast_nullable_to_non_nullable
                  as String?,
        translation: freezed == translation
            ? _self.translation
            : translation // ignore: cast_nullable_to_non_nullable
                  as String?,
        transliteration: freezed == transliteration
            ? _self.transliteration
            : transliteration // ignore: cast_nullable_to_non_nullable
                  as String?,
        juz: freezed == juz
            ? _self.juz
            : juz // ignore: cast_nullable_to_non_nullable
                  as int?,
        manzil: freezed == manzil
            ? _self.manzil
            : manzil // ignore: cast_nullable_to_non_nullable
                  as int?,
        page: freezed == page
            ? _self.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int?,
        ruku: freezed == ruku
            ? _self.ruku
            : ruku // ignore: cast_nullable_to_non_nullable
                  as int?,
        hizbQuarter: freezed == hizbQuarter
            ? _self.hizbQuarter
            : hizbQuarter // ignore: cast_nullable_to_non_nullable
                  as int?,
        sajda: freezed == sajda
            ? _self.sajda
            : sajda // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AyahEntity].
extension AyahEntityPatterns on AyahEntity {
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
    TResult Function(_AyahEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AyahEntity() when $default != null:
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
    TResult Function(_AyahEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AyahEntity():
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
    TResult? Function(_AyahEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AyahEntity() when $default != null:
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
      int numberInSurah,
      int surahNumber,
      String text,
      String? textUthmani,
      String? textSimple,
      String? translation,
      String? transliteration,
      int? juz,
      int? manzil,
      int? page,
      int? ruku,
      int? hizbQuarter,
      bool? sajda,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AyahEntity() when $default != null:
        return $default(
          _that.number,
          _that.numberInSurah,
          _that.surahNumber,
          _that.text,
          _that.textUthmani,
          _that.textSimple,
          _that.translation,
          _that.transliteration,
          _that.juz,
          _that.manzil,
          _that.page,
          _that.ruku,
          _that.hizbQuarter,
          _that.sajda,
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
      int numberInSurah,
      int surahNumber,
      String text,
      String? textUthmani,
      String? textSimple,
      String? translation,
      String? transliteration,
      int? juz,
      int? manzil,
      int? page,
      int? ruku,
      int? hizbQuarter,
      bool? sajda,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AyahEntity():
        return $default(
          _that.number,
          _that.numberInSurah,
          _that.surahNumber,
          _that.text,
          _that.textUthmani,
          _that.textSimple,
          _that.translation,
          _that.transliteration,
          _that.juz,
          _that.manzil,
          _that.page,
          _that.ruku,
          _that.hizbQuarter,
          _that.sajda,
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
      int numberInSurah,
      int surahNumber,
      String text,
      String? textUthmani,
      String? textSimple,
      String? translation,
      String? transliteration,
      int? juz,
      int? manzil,
      int? page,
      int? ruku,
      int? hizbQuarter,
      bool? sajda,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AyahEntity() when $default != null:
        return $default(
          _that.number,
          _that.numberInSurah,
          _that.surahNumber,
          _that.text,
          _that.textUthmani,
          _that.textSimple,
          _that.translation,
          _that.transliteration,
          _that.juz,
          _that.manzil,
          _that.page,
          _that.ruku,
          _that.hizbQuarter,
          _that.sajda,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AyahEntity extends AyahEntity {
  const _AyahEntity({
    required this.number,
    required this.numberInSurah,
    required this.surahNumber,
    required this.text,
    this.textUthmani,
    this.textSimple,
    this.translation,
    this.transliteration,
    this.juz,
    this.manzil,
    this.page,
    this.ruku,
    this.hizbQuarter,
    this.sajda,
  }) : super._();
  factory _AyahEntity.fromJson(Map<String, dynamic> json) =>
      _$AyahEntityFromJson(json);

  @override
  final int number;
  @override
  final int numberInSurah;
  @override
  final int surahNumber;
  @override
  final String text;
  @override
  final String? textUthmani;
  @override
  final String? textSimple;
  @override
  final String? translation;
  @override
  final String? transliteration;
  @override
  final int? juz;
  @override
  final int? manzil;
  @override
  final int? page;
  @override
  final int? ruku;
  @override
  final int? hizbQuarter;
  @override
  final bool? sajda;

  /// Create a copy of AyahEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AyahEntityCopyWith<_AyahEntity> get copyWith =>
      __$AyahEntityCopyWithImpl<_AyahEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AyahEntityToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AyahEntity &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.numberInSurah, numberInSurah) ||
                other.numberInSurah == numberInSurah) &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.textUthmani, textUthmani) ||
                other.textUthmani == textUthmani) &&
            (identical(other.textSimple, textSimple) ||
                other.textSimple == textSimple) &&
            (identical(other.translation, translation) ||
                other.translation == translation) &&
            (identical(other.transliteration, transliteration) ||
                other.transliteration == transliteration) &&
            (identical(other.juz, juz) || other.juz == juz) &&
            (identical(other.manzil, manzil) || other.manzil == manzil) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.ruku, ruku) || other.ruku == ruku) &&
            (identical(other.hizbQuarter, hizbQuarter) ||
                other.hizbQuarter == hizbQuarter) &&
            (identical(other.sajda, sajda) || other.sajda == sajda));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    number,
    numberInSurah,
    surahNumber,
    text,
    textUthmani,
    textSimple,
    translation,
    transliteration,
    juz,
    manzil,
    page,
    ruku,
    hizbQuarter,
    sajda,
  );

  @override
  String toString() {
    return 'AyahEntity(number: $number, numberInSurah: $numberInSurah, surahNumber: $surahNumber, text: $text, textUthmani: $textUthmani, textSimple: $textSimple, translation: $translation, transliteration: $transliteration, juz: $juz, manzil: $manzil, page: $page, ruku: $ruku, hizbQuarter: $hizbQuarter, sajda: $sajda)';
  }
}

/// @nodoc
abstract mixin class _$AyahEntityCopyWith<$Res>
    implements $AyahEntityCopyWith<$Res> {
  factory _$AyahEntityCopyWith(
    _AyahEntity value,
    $Res Function(_AyahEntity) _then,
  ) = __$AyahEntityCopyWithImpl;
  @override
  @useResult
  $Res call({
    int number,
    int numberInSurah,
    int surahNumber,
    String text,
    String? textUthmani,
    String? textSimple,
    String? translation,
    String? transliteration,
    int? juz,
    int? manzil,
    int? page,
    int? ruku,
    int? hizbQuarter,
    bool? sajda,
  });
}

/// @nodoc
class __$AyahEntityCopyWithImpl<$Res> implements _$AyahEntityCopyWith<$Res> {
  __$AyahEntityCopyWithImpl(this._self, this._then);

  final _AyahEntity _self;
  final $Res Function(_AyahEntity) _then;

  /// Create a copy of AyahEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? number = null,
    Object? numberInSurah = null,
    Object? surahNumber = null,
    Object? text = null,
    Object? textUthmani = freezed,
    Object? textSimple = freezed,
    Object? translation = freezed,
    Object? transliteration = freezed,
    Object? juz = freezed,
    Object? manzil = freezed,
    Object? page = freezed,
    Object? ruku = freezed,
    Object? hizbQuarter = freezed,
    Object? sajda = freezed,
  }) {
    return _then(
      _AyahEntity(
        number: null == number
            ? _self.number
            : number // ignore: cast_nullable_to_non_nullable
                  as int,
        numberInSurah: null == numberInSurah
            ? _self.numberInSurah
            : numberInSurah // ignore: cast_nullable_to_non_nullable
                  as int,
        surahNumber: null == surahNumber
            ? _self.surahNumber
            : surahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        textUthmani: freezed == textUthmani
            ? _self.textUthmani
            : textUthmani // ignore: cast_nullable_to_non_nullable
                  as String?,
        textSimple: freezed == textSimple
            ? _self.textSimple
            : textSimple // ignore: cast_nullable_to_non_nullable
                  as String?,
        translation: freezed == translation
            ? _self.translation
            : translation // ignore: cast_nullable_to_non_nullable
                  as String?,
        transliteration: freezed == transliteration
            ? _self.transliteration
            : transliteration // ignore: cast_nullable_to_non_nullable
                  as String?,
        juz: freezed == juz
            ? _self.juz
            : juz // ignore: cast_nullable_to_non_nullable
                  as int?,
        manzil: freezed == manzil
            ? _self.manzil
            : manzil // ignore: cast_nullable_to_non_nullable
                  as int?,
        page: freezed == page
            ? _self.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int?,
        ruku: freezed == ruku
            ? _self.ruku
            : ruku // ignore: cast_nullable_to_non_nullable
                  as int?,
        hizbQuarter: freezed == hizbQuarter
            ? _self.hizbQuarter
            : hizbQuarter // ignore: cast_nullable_to_non_nullable
                  as int?,
        sajda: freezed == sajda
            ? _self.sajda
            : sajda // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}
