// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prayer_time_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PrayerTimeEntity {
  DateTime get date;
  DateTime get fajr;
  DateTime get sunrise;
  DateTime get dhuhr;
  DateTime get asr;
  DateTime get maghrib;
  DateTime get isha;
  String? get timezone;
  String? get locationName;
  double? get latitude;
  double? get longitude;

  /// Create a copy of PrayerTimeEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PrayerTimeEntityCopyWith<PrayerTimeEntity> get copyWith =>
      _$PrayerTimeEntityCopyWithImpl<PrayerTimeEntity>(
        this as PrayerTimeEntity,
        _$identity,
      );

  /// Serializes this PrayerTimeEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PrayerTimeEntity &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.fajr, fajr) || other.fajr == fajr) &&
            (identical(other.sunrise, sunrise) || other.sunrise == sunrise) &&
            (identical(other.dhuhr, dhuhr) || other.dhuhr == dhuhr) &&
            (identical(other.asr, asr) || other.asr == asr) &&
            (identical(other.maghrib, maghrib) || other.maghrib == maghrib) &&
            (identical(other.isha, isha) || other.isha == isha) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    date,
    fajr,
    sunrise,
    dhuhr,
    asr,
    maghrib,
    isha,
    timezone,
    locationName,
    latitude,
    longitude,
  );

  @override
  String toString() {
    return 'PrayerTimeEntity(date: $date, fajr: $fajr, sunrise: $sunrise, dhuhr: $dhuhr, asr: $asr, maghrib: $maghrib, isha: $isha, timezone: $timezone, locationName: $locationName, latitude: $latitude, longitude: $longitude)';
  }
}

/// @nodoc
abstract mixin class $PrayerTimeEntityCopyWith<$Res> {
  factory $PrayerTimeEntityCopyWith(
    PrayerTimeEntity value,
    $Res Function(PrayerTimeEntity) _then,
  ) = _$PrayerTimeEntityCopyWithImpl;
  @useResult
  $Res call({
    DateTime date,
    DateTime fajr,
    DateTime sunrise,
    DateTime dhuhr,
    DateTime asr,
    DateTime maghrib,
    DateTime isha,
    String? timezone,
    String? locationName,
    double? latitude,
    double? longitude,
  });
}

/// @nodoc
class _$PrayerTimeEntityCopyWithImpl<$Res>
    implements $PrayerTimeEntityCopyWith<$Res> {
  _$PrayerTimeEntityCopyWithImpl(this._self, this._then);

  final PrayerTimeEntity _self;
  final $Res Function(PrayerTimeEntity) _then;

  /// Create a copy of PrayerTimeEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? fajr = null,
    Object? sunrise = null,
    Object? dhuhr = null,
    Object? asr = null,
    Object? maghrib = null,
    Object? isha = null,
    Object? timezone = freezed,
    Object? locationName = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
  }) {
    return _then(
      _self.copyWith(
        date: null == date
            ? _self.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        fajr: null == fajr
            ? _self.fajr
            : fajr // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        sunrise: null == sunrise
            ? _self.sunrise
            : sunrise // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        dhuhr: null == dhuhr
            ? _self.dhuhr
            : dhuhr // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        asr: null == asr
            ? _self.asr
            : asr // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        maghrib: null == maghrib
            ? _self.maghrib
            : maghrib // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isha: null == isha
            ? _self.isha
            : isha // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        timezone: freezed == timezone
            ? _self.timezone
            : timezone // ignore: cast_nullable_to_non_nullable
                  as String?,
        locationName: freezed == locationName
            ? _self.locationName
            : locationName // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: freezed == latitude
            ? _self.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _self.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PrayerTimeEntity].
extension PrayerTimeEntityPatterns on PrayerTimeEntity {
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
    TResult Function(_PrayerTimeEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PrayerTimeEntity() when $default != null:
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
    TResult Function(_PrayerTimeEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerTimeEntity():
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
    TResult? Function(_PrayerTimeEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerTimeEntity() when $default != null:
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
      DateTime date,
      DateTime fajr,
      DateTime sunrise,
      DateTime dhuhr,
      DateTime asr,
      DateTime maghrib,
      DateTime isha,
      String? timezone,
      String? locationName,
      double? latitude,
      double? longitude,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PrayerTimeEntity() when $default != null:
        return $default(
          _that.date,
          _that.fajr,
          _that.sunrise,
          _that.dhuhr,
          _that.asr,
          _that.maghrib,
          _that.isha,
          _that.timezone,
          _that.locationName,
          _that.latitude,
          _that.longitude,
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
      DateTime date,
      DateTime fajr,
      DateTime sunrise,
      DateTime dhuhr,
      DateTime asr,
      DateTime maghrib,
      DateTime isha,
      String? timezone,
      String? locationName,
      double? latitude,
      double? longitude,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerTimeEntity():
        return $default(
          _that.date,
          _that.fajr,
          _that.sunrise,
          _that.dhuhr,
          _that.asr,
          _that.maghrib,
          _that.isha,
          _that.timezone,
          _that.locationName,
          _that.latitude,
          _that.longitude,
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
      DateTime date,
      DateTime fajr,
      DateTime sunrise,
      DateTime dhuhr,
      DateTime asr,
      DateTime maghrib,
      DateTime isha,
      String? timezone,
      String? locationName,
      double? latitude,
      double? longitude,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerTimeEntity() when $default != null:
        return $default(
          _that.date,
          _that.fajr,
          _that.sunrise,
          _that.dhuhr,
          _that.asr,
          _that.maghrib,
          _that.isha,
          _that.timezone,
          _that.locationName,
          _that.latitude,
          _that.longitude,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PrayerTimeEntity extends PrayerTimeEntity {
  const _PrayerTimeEntity({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.timezone,
    this.locationName,
    this.latitude,
    this.longitude,
  }) : super._();
  factory _PrayerTimeEntity.fromJson(Map<String, dynamic> json) =>
      _$PrayerTimeEntityFromJson(json);

  @override
  final DateTime date;
  @override
  final DateTime fajr;
  @override
  final DateTime sunrise;
  @override
  final DateTime dhuhr;
  @override
  final DateTime asr;
  @override
  final DateTime maghrib;
  @override
  final DateTime isha;
  @override
  final String? timezone;
  @override
  final String? locationName;
  @override
  final double? latitude;
  @override
  final double? longitude;

  /// Create a copy of PrayerTimeEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PrayerTimeEntityCopyWith<_PrayerTimeEntity> get copyWith =>
      __$PrayerTimeEntityCopyWithImpl<_PrayerTimeEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PrayerTimeEntityToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PrayerTimeEntity &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.fajr, fajr) || other.fajr == fajr) &&
            (identical(other.sunrise, sunrise) || other.sunrise == sunrise) &&
            (identical(other.dhuhr, dhuhr) || other.dhuhr == dhuhr) &&
            (identical(other.asr, asr) || other.asr == asr) &&
            (identical(other.maghrib, maghrib) || other.maghrib == maghrib) &&
            (identical(other.isha, isha) || other.isha == isha) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    date,
    fajr,
    sunrise,
    dhuhr,
    asr,
    maghrib,
    isha,
    timezone,
    locationName,
    latitude,
    longitude,
  );

  @override
  String toString() {
    return 'PrayerTimeEntity(date: $date, fajr: $fajr, sunrise: $sunrise, dhuhr: $dhuhr, asr: $asr, maghrib: $maghrib, isha: $isha, timezone: $timezone, locationName: $locationName, latitude: $latitude, longitude: $longitude)';
  }
}

/// @nodoc
abstract mixin class _$PrayerTimeEntityCopyWith<$Res>
    implements $PrayerTimeEntityCopyWith<$Res> {
  factory _$PrayerTimeEntityCopyWith(
    _PrayerTimeEntity value,
    $Res Function(_PrayerTimeEntity) _then,
  ) = __$PrayerTimeEntityCopyWithImpl;
  @override
  @useResult
  $Res call({
    DateTime date,
    DateTime fajr,
    DateTime sunrise,
    DateTime dhuhr,
    DateTime asr,
    DateTime maghrib,
    DateTime isha,
    String? timezone,
    String? locationName,
    double? latitude,
    double? longitude,
  });
}

/// @nodoc
class __$PrayerTimeEntityCopyWithImpl<$Res>
    implements _$PrayerTimeEntityCopyWith<$Res> {
  __$PrayerTimeEntityCopyWithImpl(this._self, this._then);

  final _PrayerTimeEntity _self;
  final $Res Function(_PrayerTimeEntity) _then;

  /// Create a copy of PrayerTimeEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? date = null,
    Object? fajr = null,
    Object? sunrise = null,
    Object? dhuhr = null,
    Object? asr = null,
    Object? maghrib = null,
    Object? isha = null,
    Object? timezone = freezed,
    Object? locationName = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
  }) {
    return _then(
      _PrayerTimeEntity(
        date: null == date
            ? _self.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        fajr: null == fajr
            ? _self.fajr
            : fajr // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        sunrise: null == sunrise
            ? _self.sunrise
            : sunrise // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        dhuhr: null == dhuhr
            ? _self.dhuhr
            : dhuhr // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        asr: null == asr
            ? _self.asr
            : asr // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        maghrib: null == maghrib
            ? _self.maghrib
            : maghrib // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isha: null == isha
            ? _self.isha
            : isha // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        timezone: freezed == timezone
            ? _self.timezone
            : timezone // ignore: cast_nullable_to_non_nullable
                  as String?,
        locationName: freezed == locationName
            ? _self.locationName
            : locationName // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: freezed == latitude
            ? _self.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _self.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}
