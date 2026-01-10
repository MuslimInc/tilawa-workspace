// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quran_page_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuranPageData {
  int get pageNumber;
  int get juzNumber;
  int get hizbNumber;
  List<SurahSection> get surahSections;

  /// Create a copy of QuranPageData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QuranPageDataCopyWith<QuranPageData> get copyWith =>
      _$QuranPageDataCopyWithImpl<QuranPageData>(
        this as QuranPageData,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QuranPageData &&
            (identical(other.pageNumber, pageNumber) ||
                other.pageNumber == pageNumber) &&
            (identical(other.juzNumber, juzNumber) ||
                other.juzNumber == juzNumber) &&
            (identical(other.hizbNumber, hizbNumber) ||
                other.hizbNumber == hizbNumber) &&
            const DeepCollectionEquality().equals(
              other.surahSections,
              surahSections,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    pageNumber,
    juzNumber,
    hizbNumber,
    const DeepCollectionEquality().hash(surahSections),
  );

  @override
  String toString() {
    return 'QuranPageData(pageNumber: $pageNumber, juzNumber: $juzNumber, hizbNumber: $hizbNumber, surahSections: $surahSections)';
  }
}

/// @nodoc
abstract mixin class $QuranPageDataCopyWith<$Res> {
  factory $QuranPageDataCopyWith(
    QuranPageData value,
    $Res Function(QuranPageData) _then,
  ) = _$QuranPageDataCopyWithImpl;
  @useResult
  $Res call({
    int pageNumber,
    int juzNumber,
    int hizbNumber,
    List<SurahSection> surahSections,
  });
}

/// @nodoc
class _$QuranPageDataCopyWithImpl<$Res>
    implements $QuranPageDataCopyWith<$Res> {
  _$QuranPageDataCopyWithImpl(this._self, this._then);

  final QuranPageData _self;
  final $Res Function(QuranPageData) _then;

  /// Create a copy of QuranPageData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pageNumber = null,
    Object? juzNumber = null,
    Object? hizbNumber = null,
    Object? surahSections = null,
  }) {
    return _then(
      _self.copyWith(
        pageNumber: null == pageNumber
            ? _self.pageNumber
            : pageNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        juzNumber: null == juzNumber
            ? _self.juzNumber
            : juzNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        hizbNumber: null == hizbNumber
            ? _self.hizbNumber
            : hizbNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        surahSections: null == surahSections
            ? _self.surahSections
            : surahSections // ignore: cast_nullable_to_non_nullable
                  as List<SurahSection>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [QuranPageData].
extension QuranPageDataPatterns on QuranPageData {
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
    TResult Function(_QuranPageData value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QuranPageData() when $default != null:
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
    TResult Function(_QuranPageData value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranPageData():
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
    TResult? Function(_QuranPageData value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranPageData() when $default != null:
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
      int juzNumber,
      int hizbNumber,
      List<SurahSection> surahSections,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QuranPageData() when $default != null:
        return $default(
          _that.pageNumber,
          _that.juzNumber,
          _that.hizbNumber,
          _that.surahSections,
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
      int pageNumber,
      int juzNumber,
      int hizbNumber,
      List<SurahSection> surahSections,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranPageData():
        return $default(
          _that.pageNumber,
          _that.juzNumber,
          _that.hizbNumber,
          _that.surahSections,
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
      int pageNumber,
      int juzNumber,
      int hizbNumber,
      List<SurahSection> surahSections,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranPageData() when $default != null:
        return $default(
          _that.pageNumber,
          _that.juzNumber,
          _that.hizbNumber,
          _that.surahSections,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _QuranPageData extends QuranPageData {
  const _QuranPageData({
    required this.pageNumber,
    required this.juzNumber,
    required this.hizbNumber,
    required final List<SurahSection> surahSections,
  }) : _surahSections = surahSections,
       super._();

  @override
  final int pageNumber;
  @override
  final int juzNumber;
  @override
  final int hizbNumber;
  final List<SurahSection> _surahSections;
  @override
  List<SurahSection> get surahSections {
    if (_surahSections is EqualUnmodifiableListView) return _surahSections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_surahSections);
  }

  /// Create a copy of QuranPageData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$QuranPageDataCopyWith<_QuranPageData> get copyWith =>
      __$QuranPageDataCopyWithImpl<_QuranPageData>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _QuranPageData &&
            (identical(other.pageNumber, pageNumber) ||
                other.pageNumber == pageNumber) &&
            (identical(other.juzNumber, juzNumber) ||
                other.juzNumber == juzNumber) &&
            (identical(other.hizbNumber, hizbNumber) ||
                other.hizbNumber == hizbNumber) &&
            const DeepCollectionEquality().equals(
              other._surahSections,
              _surahSections,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    pageNumber,
    juzNumber,
    hizbNumber,
    const DeepCollectionEquality().hash(_surahSections),
  );

  @override
  String toString() {
    return 'QuranPageData(pageNumber: $pageNumber, juzNumber: $juzNumber, hizbNumber: $hizbNumber, surahSections: $surahSections)';
  }
}

/// @nodoc
abstract mixin class _$QuranPageDataCopyWith<$Res>
    implements $QuranPageDataCopyWith<$Res> {
  factory _$QuranPageDataCopyWith(
    _QuranPageData value,
    $Res Function(_QuranPageData) _then,
  ) = __$QuranPageDataCopyWithImpl;
  @override
  @useResult
  $Res call({
    int pageNumber,
    int juzNumber,
    int hizbNumber,
    List<SurahSection> surahSections,
  });
}

/// @nodoc
class __$QuranPageDataCopyWithImpl<$Res>
    implements _$QuranPageDataCopyWith<$Res> {
  __$QuranPageDataCopyWithImpl(this._self, this._then);

  final _QuranPageData _self;
  final $Res Function(_QuranPageData) _then;

  /// Create a copy of QuranPageData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? pageNumber = null,
    Object? juzNumber = null,
    Object? hizbNumber = null,
    Object? surahSections = null,
  }) {
    return _then(
      _QuranPageData(
        pageNumber: null == pageNumber
            ? _self.pageNumber
            : pageNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        juzNumber: null == juzNumber
            ? _self.juzNumber
            : juzNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        hizbNumber: null == hizbNumber
            ? _self.hizbNumber
            : hizbNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        surahSections: null == surahSections
            ? _self._surahSections
            : surahSections // ignore: cast_nullable_to_non_nullable
                  as List<SurahSection>,
      ),
    );
  }
}

/// @nodoc
mixin _$SurahSection {
  int get surahNumber;
  String get surahNameArabic;
  String get surahNameEnglish;
  bool get isStartOfSurah;
  List<AyahData> get ayahs;

  /// Create a copy of SurahSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SurahSectionCopyWith<SurahSection> get copyWith =>
      _$SurahSectionCopyWithImpl<SurahSection>(
        this as SurahSection,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SurahSection &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber) &&
            (identical(other.surahNameArabic, surahNameArabic) ||
                other.surahNameArabic == surahNameArabic) &&
            (identical(other.surahNameEnglish, surahNameEnglish) ||
                other.surahNameEnglish == surahNameEnglish) &&
            (identical(other.isStartOfSurah, isStartOfSurah) ||
                other.isStartOfSurah == isStartOfSurah) &&
            const DeepCollectionEquality().equals(other.ayahs, ayahs));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    surahNumber,
    surahNameArabic,
    surahNameEnglish,
    isStartOfSurah,
    const DeepCollectionEquality().hash(ayahs),
  );

  @override
  String toString() {
    return 'SurahSection(surahNumber: $surahNumber, surahNameArabic: $surahNameArabic, surahNameEnglish: $surahNameEnglish, isStartOfSurah: $isStartOfSurah, ayahs: $ayahs)';
  }
}

/// @nodoc
abstract mixin class $SurahSectionCopyWith<$Res> {
  factory $SurahSectionCopyWith(
    SurahSection value,
    $Res Function(SurahSection) _then,
  ) = _$SurahSectionCopyWithImpl;
  @useResult
  $Res call({
    int surahNumber,
    String surahNameArabic,
    String surahNameEnglish,
    bool isStartOfSurah,
    List<AyahData> ayahs,
  });
}

/// @nodoc
class _$SurahSectionCopyWithImpl<$Res> implements $SurahSectionCopyWith<$Res> {
  _$SurahSectionCopyWithImpl(this._self, this._then);

  final SurahSection _self;
  final $Res Function(SurahSection) _then;

  /// Create a copy of SurahSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? surahNumber = null,
    Object? surahNameArabic = null,
    Object? surahNameEnglish = null,
    Object? isStartOfSurah = null,
    Object? ayahs = null,
  }) {
    return _then(
      _self.copyWith(
        surahNumber: null == surahNumber
            ? _self.surahNumber
            : surahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        surahNameArabic: null == surahNameArabic
            ? _self.surahNameArabic
            : surahNameArabic // ignore: cast_nullable_to_non_nullable
                  as String,
        surahNameEnglish: null == surahNameEnglish
            ? _self.surahNameEnglish
            : surahNameEnglish // ignore: cast_nullable_to_non_nullable
                  as String,
        isStartOfSurah: null == isStartOfSurah
            ? _self.isStartOfSurah
            : isStartOfSurah // ignore: cast_nullable_to_non_nullable
                  as bool,
        ayahs: null == ayahs
            ? _self.ayahs
            : ayahs // ignore: cast_nullable_to_non_nullable
                  as List<AyahData>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SurahSection].
extension SurahSectionPatterns on SurahSection {
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
    TResult Function(_SurahSection value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SurahSection() when $default != null:
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
    TResult Function(_SurahSection value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SurahSection():
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
    TResult? Function(_SurahSection value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SurahSection() when $default != null:
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
      String surahNameArabic,
      String surahNameEnglish,
      bool isStartOfSurah,
      List<AyahData> ayahs,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SurahSection() when $default != null:
        return $default(
          _that.surahNumber,
          _that.surahNameArabic,
          _that.surahNameEnglish,
          _that.isStartOfSurah,
          _that.ayahs,
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
      String surahNameArabic,
      String surahNameEnglish,
      bool isStartOfSurah,
      List<AyahData> ayahs,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SurahSection():
        return $default(
          _that.surahNumber,
          _that.surahNameArabic,
          _that.surahNameEnglish,
          _that.isStartOfSurah,
          _that.ayahs,
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
      String surahNameArabic,
      String surahNameEnglish,
      bool isStartOfSurah,
      List<AyahData> ayahs,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SurahSection() when $default != null:
        return $default(
          _that.surahNumber,
          _that.surahNameArabic,
          _that.surahNameEnglish,
          _that.isStartOfSurah,
          _that.ayahs,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SurahSection implements SurahSection {
  const _SurahSection({
    required this.surahNumber,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    required this.isStartOfSurah,
    required final List<AyahData> ayahs,
  }) : _ayahs = ayahs;

  @override
  final int surahNumber;
  @override
  final String surahNameArabic;
  @override
  final String surahNameEnglish;
  @override
  final bool isStartOfSurah;
  final List<AyahData> _ayahs;
  @override
  List<AyahData> get ayahs {
    if (_ayahs is EqualUnmodifiableListView) return _ayahs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ayahs);
  }

  /// Create a copy of SurahSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SurahSectionCopyWith<_SurahSection> get copyWith =>
      __$SurahSectionCopyWithImpl<_SurahSection>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SurahSection &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber) &&
            (identical(other.surahNameArabic, surahNameArabic) ||
                other.surahNameArabic == surahNameArabic) &&
            (identical(other.surahNameEnglish, surahNameEnglish) ||
                other.surahNameEnglish == surahNameEnglish) &&
            (identical(other.isStartOfSurah, isStartOfSurah) ||
                other.isStartOfSurah == isStartOfSurah) &&
            const DeepCollectionEquality().equals(other._ayahs, _ayahs));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    surahNumber,
    surahNameArabic,
    surahNameEnglish,
    isStartOfSurah,
    const DeepCollectionEquality().hash(_ayahs),
  );

  @override
  String toString() {
    return 'SurahSection(surahNumber: $surahNumber, surahNameArabic: $surahNameArabic, surahNameEnglish: $surahNameEnglish, isStartOfSurah: $isStartOfSurah, ayahs: $ayahs)';
  }
}

/// @nodoc
abstract mixin class _$SurahSectionCopyWith<$Res>
    implements $SurahSectionCopyWith<$Res> {
  factory _$SurahSectionCopyWith(
    _SurahSection value,
    $Res Function(_SurahSection) _then,
  ) = __$SurahSectionCopyWithImpl;
  @override
  @useResult
  $Res call({
    int surahNumber,
    String surahNameArabic,
    String surahNameEnglish,
    bool isStartOfSurah,
    List<AyahData> ayahs,
  });
}

/// @nodoc
class __$SurahSectionCopyWithImpl<$Res>
    implements _$SurahSectionCopyWith<$Res> {
  __$SurahSectionCopyWithImpl(this._self, this._then);

  final _SurahSection _self;
  final $Res Function(_SurahSection) _then;

  /// Create a copy of SurahSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? surahNumber = null,
    Object? surahNameArabic = null,
    Object? surahNameEnglish = null,
    Object? isStartOfSurah = null,
    Object? ayahs = null,
  }) {
    return _then(
      _SurahSection(
        surahNumber: null == surahNumber
            ? _self.surahNumber
            : surahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        surahNameArabic: null == surahNameArabic
            ? _self.surahNameArabic
            : surahNameArabic // ignore: cast_nullable_to_non_nullable
                  as String,
        surahNameEnglish: null == surahNameEnglish
            ? _self.surahNameEnglish
            : surahNameEnglish // ignore: cast_nullable_to_non_nullable
                  as String,
        isStartOfSurah: null == isStartOfSurah
            ? _self.isStartOfSurah
            : isStartOfSurah // ignore: cast_nullable_to_non_nullable
                  as bool,
        ayahs: null == ayahs
            ? _self._ayahs
            : ayahs // ignore: cast_nullable_to_non_nullable
                  as List<AyahData>,
      ),
    );
  }
}

/// @nodoc
mixin _$AyahData {
  int get ayahNumber;
  String get text;

  /// Create a copy of AyahData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AyahDataCopyWith<AyahData> get copyWith =>
      _$AyahDataCopyWithImpl<AyahData>(this as AyahData, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AyahData &&
            (identical(other.ayahNumber, ayahNumber) ||
                other.ayahNumber == ayahNumber) &&
            (identical(other.text, text) || other.text == text));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ayahNumber, text);

  @override
  String toString() {
    return 'AyahData(ayahNumber: $ayahNumber, text: $text)';
  }
}

/// @nodoc
abstract mixin class $AyahDataCopyWith<$Res> {
  factory $AyahDataCopyWith(AyahData value, $Res Function(AyahData) _then) =
      _$AyahDataCopyWithImpl;
  @useResult
  $Res call({int ayahNumber, String text});
}

/// @nodoc
class _$AyahDataCopyWithImpl<$Res> implements $AyahDataCopyWith<$Res> {
  _$AyahDataCopyWithImpl(this._self, this._then);

  final AyahData _self;
  final $Res Function(AyahData) _then;

  /// Create a copy of AyahData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? ayahNumber = null, Object? text = null}) {
    return _then(
      _self.copyWith(
        ayahNumber: null == ayahNumber
            ? _self.ayahNumber
            : ayahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AyahData].
extension AyahDataPatterns on AyahData {
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
    TResult Function(_AyahData value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AyahData() when $default != null:
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
    TResult Function(_AyahData value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AyahData():
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
    TResult? Function(_AyahData value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AyahData() when $default != null:
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
    TResult Function(int ayahNumber, String text)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AyahData() when $default != null:
        return $default(_that.ayahNumber, _that.text);
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
    TResult Function(int ayahNumber, String text) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AyahData():
        return $default(_that.ayahNumber, _that.text);
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
    TResult? Function(int ayahNumber, String text)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AyahData() when $default != null:
        return $default(_that.ayahNumber, _that.text);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AyahData implements AyahData {
  const _AyahData({required this.ayahNumber, required this.text});

  @override
  final int ayahNumber;
  @override
  final String text;

  /// Create a copy of AyahData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AyahDataCopyWith<_AyahData> get copyWith =>
      __$AyahDataCopyWithImpl<_AyahData>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AyahData &&
            (identical(other.ayahNumber, ayahNumber) ||
                other.ayahNumber == ayahNumber) &&
            (identical(other.text, text) || other.text == text));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ayahNumber, text);

  @override
  String toString() {
    return 'AyahData(ayahNumber: $ayahNumber, text: $text)';
  }
}

/// @nodoc
abstract mixin class _$AyahDataCopyWith<$Res>
    implements $AyahDataCopyWith<$Res> {
  factory _$AyahDataCopyWith(_AyahData value, $Res Function(_AyahData) _then) =
      __$AyahDataCopyWithImpl;
  @override
  @useResult
  $Res call({int ayahNumber, String text});
}

/// @nodoc
class __$AyahDataCopyWithImpl<$Res> implements _$AyahDataCopyWith<$Res> {
  __$AyahDataCopyWithImpl(this._self, this._then);

  final _AyahData _self;
  final $Res Function(_AyahData) _then;

  /// Create a copy of AyahData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? ayahNumber = null, Object? text = null}) {
    return _then(
      _AyahData(
        ayahNumber: null == ayahNumber
            ? _self.ayahNumber
            : ayahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}
