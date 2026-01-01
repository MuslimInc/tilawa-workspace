// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reciter_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Mosahf {
  int get id;
  String get name;
  String get server;
  @JsonKey(name: 'surah_total')
  int get surahTotal;
  @JsonKey(name: 'moshaf_type')
  int get moshafType;
  @JsonKey(name: 'surah_list')
  String get surahList;

  /// Create a copy of Mosahf
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MosahfCopyWith<Mosahf> get copyWith =>
      _$MosahfCopyWithImpl<Mosahf>(this as Mosahf, _$identity);

  /// Serializes this Mosahf to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Mosahf &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.server, server) || other.server == server) &&
            (identical(other.surahTotal, surahTotal) ||
                other.surahTotal == surahTotal) &&
            (identical(other.moshafType, moshafType) ||
                other.moshafType == moshafType) &&
            (identical(other.surahList, surahList) ||
                other.surahList == surahList));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    server,
    surahTotal,
    moshafType,
    surahList,
  );

  @override
  String toString() {
    return 'Mosahf(id: $id, name: $name, server: $server, surahTotal: $surahTotal, moshafType: $moshafType, surahList: $surahList)';
  }
}

/// @nodoc
abstract mixin class $MosahfCopyWith<$Res> {
  factory $MosahfCopyWith(Mosahf value, $Res Function(Mosahf) _then) =
      _$MosahfCopyWithImpl;
  @useResult
  $Res call({
    int id,
    String name,
    String server,
    @JsonKey(name: 'surah_total') int surahTotal,
    @JsonKey(name: 'moshaf_type') int moshafType,
    @JsonKey(name: 'surah_list') String surahList,
  });
}

/// @nodoc
class _$MosahfCopyWithImpl<$Res> implements $MosahfCopyWith<$Res> {
  _$MosahfCopyWithImpl(this._self, this._then);

  final Mosahf _self;
  final $Res Function(Mosahf) _then;

  /// Create a copy of Mosahf
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? server = null,
    Object? surahTotal = null,
    Object? moshafType = null,
    Object? surahList = null,
  }) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        server: null == server
            ? _self.server
            : server // ignore: cast_nullable_to_non_nullable
                  as String,
        surahTotal: null == surahTotal
            ? _self.surahTotal
            : surahTotal // ignore: cast_nullable_to_non_nullable
                  as int,
        moshafType: null == moshafType
            ? _self.moshafType
            : moshafType // ignore: cast_nullable_to_non_nullable
                  as int,
        surahList: null == surahList
            ? _self.surahList
            : surahList // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [Mosahf].
extension MosahfPatterns on Mosahf {
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
    TResult Function(_Mosahf value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Mosahf() when $default != null:
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
    TResult Function(_Mosahf value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Mosahf():
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
    TResult? Function(_Mosahf value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Mosahf() when $default != null:
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
      String name,
      String server,
      @JsonKey(name: 'surah_total') int surahTotal,
      @JsonKey(name: 'moshaf_type') int moshafType,
      @JsonKey(name: 'surah_list') String surahList,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Mosahf() when $default != null:
        return $default(
          _that.id,
          _that.name,
          _that.server,
          _that.surahTotal,
          _that.moshafType,
          _that.surahList,
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
      String name,
      String server,
      @JsonKey(name: 'surah_total') int surahTotal,
      @JsonKey(name: 'moshaf_type') int moshafType,
      @JsonKey(name: 'surah_list') String surahList,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Mosahf():
        return $default(
          _that.id,
          _that.name,
          _that.server,
          _that.surahTotal,
          _that.moshafType,
          _that.surahList,
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
      String name,
      String server,
      @JsonKey(name: 'surah_total') int surahTotal,
      @JsonKey(name: 'moshaf_type') int moshafType,
      @JsonKey(name: 'surah_list') String surahList,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Mosahf() when $default != null:
        return $default(
          _that.id,
          _that.name,
          _that.server,
          _that.surahTotal,
          _that.moshafType,
          _that.surahList,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Mosahf implements Mosahf {
  const _Mosahf({
    required this.id,
    required this.name,
    required this.server,
    @JsonKey(name: 'surah_total') required this.surahTotal,
    @JsonKey(name: 'moshaf_type') required this.moshafType,
    @JsonKey(name: 'surah_list') required this.surahList,
  });
  factory _Mosahf.fromJson(Map<String, dynamic> json) => _$MosahfFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String server;
  @override
  @JsonKey(name: 'surah_total')
  final int surahTotal;
  @override
  @JsonKey(name: 'moshaf_type')
  final int moshafType;
  @override
  @JsonKey(name: 'surah_list')
  final String surahList;

  /// Create a copy of Mosahf
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MosahfCopyWith<_Mosahf> get copyWith =>
      __$MosahfCopyWithImpl<_Mosahf>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MosahfToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Mosahf &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.server, server) || other.server == server) &&
            (identical(other.surahTotal, surahTotal) ||
                other.surahTotal == surahTotal) &&
            (identical(other.moshafType, moshafType) ||
                other.moshafType == moshafType) &&
            (identical(other.surahList, surahList) ||
                other.surahList == surahList));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    server,
    surahTotal,
    moshafType,
    surahList,
  );

  @override
  String toString() {
    return 'Mosahf(id: $id, name: $name, server: $server, surahTotal: $surahTotal, moshafType: $moshafType, surahList: $surahList)';
  }
}

/// @nodoc
abstract mixin class _$MosahfCopyWith<$Res> implements $MosahfCopyWith<$Res> {
  factory _$MosahfCopyWith(_Mosahf value, $Res Function(_Mosahf) _then) =
      __$MosahfCopyWithImpl;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String server,
    @JsonKey(name: 'surah_total') int surahTotal,
    @JsonKey(name: 'moshaf_type') int moshafType,
    @JsonKey(name: 'surah_list') String surahList,
  });
}

/// @nodoc
class __$MosahfCopyWithImpl<$Res> implements _$MosahfCopyWith<$Res> {
  __$MosahfCopyWithImpl(this._self, this._then);

  final _Mosahf _self;
  final $Res Function(_Mosahf) _then;

  /// Create a copy of Mosahf
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? server = null,
    Object? surahTotal = null,
    Object? moshafType = null,
    Object? surahList = null,
  }) {
    return _then(
      _Mosahf(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        server: null == server
            ? _self.server
            : server // ignore: cast_nullable_to_non_nullable
                  as String,
        surahTotal: null == surahTotal
            ? _self.surahTotal
            : surahTotal // ignore: cast_nullable_to_non_nullable
                  as int,
        moshafType: null == moshafType
            ? _self.moshafType
            : moshafType // ignore: cast_nullable_to_non_nullable
                  as int,
        surahList: null == surahList
            ? _self.surahList
            : surahList // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
mixin _$Reciter {
  int get id;
  String get name;
  String get letter;
  String get date;
  List<Mosahf> get moshaf;

  /// Create a copy of Reciter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReciterCopyWith<Reciter> get copyWith =>
      _$ReciterCopyWithImpl<Reciter>(this as Reciter, _$identity);

  /// Serializes this Reciter to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Reciter &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.letter, letter) || other.letter == letter) &&
            (identical(other.date, date) || other.date == date) &&
            const DeepCollectionEquality().equals(other.moshaf, moshaf));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    letter,
    date,
    const DeepCollectionEquality().hash(moshaf),
  );

  @override
  String toString() {
    return 'Reciter(id: $id, name: $name, letter: $letter, date: $date, moshaf: $moshaf)';
  }
}

/// @nodoc
abstract mixin class $ReciterCopyWith<$Res> {
  factory $ReciterCopyWith(Reciter value, $Res Function(Reciter) _then) =
      _$ReciterCopyWithImpl;
  @useResult
  $Res call({
    int id,
    String name,
    String letter,
    String date,
    List<Mosahf> moshaf,
  });
}

/// @nodoc
class _$ReciterCopyWithImpl<$Res> implements $ReciterCopyWith<$Res> {
  _$ReciterCopyWithImpl(this._self, this._then);

  final Reciter _self;
  final $Res Function(Reciter) _then;

  /// Create a copy of Reciter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? letter = null,
    Object? date = null,
    Object? moshaf = null,
  }) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        letter: null == letter
            ? _self.letter
            : letter // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _self.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        moshaf: null == moshaf
            ? _self.moshaf
            : moshaf // ignore: cast_nullable_to_non_nullable
                  as List<Mosahf>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [Reciter].
extension ReciterPatterns on Reciter {
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
    TResult Function(_Reciter value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Reciter() when $default != null:
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
    TResult Function(_Reciter value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Reciter():
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
    TResult? Function(_Reciter value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Reciter() when $default != null:
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
      String name,
      String letter,
      String date,
      List<Mosahf> moshaf,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Reciter() when $default != null:
        return $default(
          _that.id,
          _that.name,
          _that.letter,
          _that.date,
          _that.moshaf,
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
      String name,
      String letter,
      String date,
      List<Mosahf> moshaf,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Reciter():
        return $default(
          _that.id,
          _that.name,
          _that.letter,
          _that.date,
          _that.moshaf,
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
      String name,
      String letter,
      String date,
      List<Mosahf> moshaf,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Reciter() when $default != null:
        return $default(
          _that.id,
          _that.name,
          _that.letter,
          _that.date,
          _that.moshaf,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Reciter implements Reciter {
  const _Reciter({
    required this.id,
    required this.name,
    required this.letter,
    required this.date,
    required final List<Mosahf> moshaf,
  }) : _moshaf = moshaf;
  factory _Reciter.fromJson(Map<String, dynamic> json) =>
      _$ReciterFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String letter;
  @override
  final String date;
  final List<Mosahf> _moshaf;
  @override
  List<Mosahf> get moshaf {
    if (_moshaf is EqualUnmodifiableListView) return _moshaf;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_moshaf);
  }

  /// Create a copy of Reciter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ReciterCopyWith<_Reciter> get copyWith =>
      __$ReciterCopyWithImpl<_Reciter>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ReciterToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Reciter &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.letter, letter) || other.letter == letter) &&
            (identical(other.date, date) || other.date == date) &&
            const DeepCollectionEquality().equals(other._moshaf, _moshaf));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    letter,
    date,
    const DeepCollectionEquality().hash(_moshaf),
  );

  @override
  String toString() {
    return 'Reciter(id: $id, name: $name, letter: $letter, date: $date, moshaf: $moshaf)';
  }
}

/// @nodoc
abstract mixin class _$ReciterCopyWith<$Res> implements $ReciterCopyWith<$Res> {
  factory _$ReciterCopyWith(_Reciter value, $Res Function(_Reciter) _then) =
      __$ReciterCopyWithImpl;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String letter,
    String date,
    List<Mosahf> moshaf,
  });
}

/// @nodoc
class __$ReciterCopyWithImpl<$Res> implements _$ReciterCopyWith<$Res> {
  __$ReciterCopyWithImpl(this._self, this._then);

  final _Reciter _self;
  final $Res Function(_Reciter) _then;

  /// Create a copy of Reciter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? letter = null,
    Object? date = null,
    Object? moshaf = null,
  }) {
    return _then(
      _Reciter(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        letter: null == letter
            ? _self.letter
            : letter // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _self.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        moshaf: null == moshaf
            ? _self._moshaf
            : moshaf // ignore: cast_nullable_to_non_nullable
                  as List<Mosahf>,
      ),
    );
  }
}

/// @nodoc
mixin _$RecitersModel {
  List<Reciter> get reciters;

  /// Create a copy of RecitersModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecitersModelCopyWith<RecitersModel> get copyWith =>
      _$RecitersModelCopyWithImpl<RecitersModel>(
        this as RecitersModel,
        _$identity,
      );

  /// Serializes this RecitersModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecitersModel &&
            const DeepCollectionEquality().equals(other.reciters, reciters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(reciters));

  @override
  String toString() {
    return 'RecitersModel(reciters: $reciters)';
  }
}

/// @nodoc
abstract mixin class $RecitersModelCopyWith<$Res> {
  factory $RecitersModelCopyWith(
    RecitersModel value,
    $Res Function(RecitersModel) _then,
  ) = _$RecitersModelCopyWithImpl;
  @useResult
  $Res call({List<Reciter> reciters});
}

/// @nodoc
class _$RecitersModelCopyWithImpl<$Res>
    implements $RecitersModelCopyWith<$Res> {
  _$RecitersModelCopyWithImpl(this._self, this._then);

  final RecitersModel _self;
  final $Res Function(RecitersModel) _then;

  /// Create a copy of RecitersModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? reciters = null}) {
    return _then(
      _self.copyWith(
        reciters: null == reciters
            ? _self.reciters
            : reciters // ignore: cast_nullable_to_non_nullable
                  as List<Reciter>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [RecitersModel].
extension RecitersModelPatterns on RecitersModel {
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
    TResult Function(_RecitersModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecitersModel() when $default != null:
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
    TResult Function(_RecitersModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecitersModel():
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
    TResult? Function(_RecitersModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecitersModel() when $default != null:
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
    TResult Function(List<Reciter> reciters)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecitersModel() when $default != null:
        return $default(_that.reciters);
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
    TResult Function(List<Reciter> reciters) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecitersModel():
        return $default(_that.reciters);
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
    TResult? Function(List<Reciter> reciters)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecitersModel() when $default != null:
        return $default(_that.reciters);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RecitersModel implements RecitersModel {
  const _RecitersModel({required final List<Reciter> reciters})
    : _reciters = reciters;
  factory _RecitersModel.fromJson(Map<String, dynamic> json) =>
      _$RecitersModelFromJson(json);

  final List<Reciter> _reciters;
  @override
  List<Reciter> get reciters {
    if (_reciters is EqualUnmodifiableListView) return _reciters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reciters);
  }

  /// Create a copy of RecitersModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RecitersModelCopyWith<_RecitersModel> get copyWith =>
      __$RecitersModelCopyWithImpl<_RecitersModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RecitersModelToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RecitersModel &&
            const DeepCollectionEquality().equals(other._reciters, _reciters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_reciters));

  @override
  String toString() {
    return 'RecitersModel(reciters: $reciters)';
  }
}

/// @nodoc
abstract mixin class _$RecitersModelCopyWith<$Res>
    implements $RecitersModelCopyWith<$Res> {
  factory _$RecitersModelCopyWith(
    _RecitersModel value,
    $Res Function(_RecitersModel) _then,
  ) = __$RecitersModelCopyWithImpl;
  @override
  @useResult
  $Res call({List<Reciter> reciters});
}

/// @nodoc
class __$RecitersModelCopyWithImpl<$Res>
    implements _$RecitersModelCopyWith<$Res> {
  __$RecitersModelCopyWithImpl(this._self, this._then);

  final _RecitersModel _self;
  final $Res Function(_RecitersModel) _then;

  /// Create a copy of RecitersModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? reciters = null}) {
    return _then(
      _RecitersModel(
        reciters: null == reciters
            ? _self._reciters
            : reciters // ignore: cast_nullable_to_non_nullable
                  as List<Reciter>,
      ),
    );
  }
}
