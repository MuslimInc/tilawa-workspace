// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prayer_settings_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PrayerNotificationSettings {
  bool get enabled;
  int get minutesBefore;
  bool get playAdhan;
  String? get customAdhanUrl;

  /// Create a copy of PrayerNotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PrayerNotificationSettingsCopyWith<PrayerNotificationSettings>
  get copyWith =>
      _$PrayerNotificationSettingsCopyWithImpl<PrayerNotificationSettings>(
        this as PrayerNotificationSettings,
        _$identity,
      );

  /// Serializes this PrayerNotificationSettings to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PrayerNotificationSettings &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.minutesBefore, minutesBefore) ||
                other.minutesBefore == minutesBefore) &&
            (identical(other.playAdhan, playAdhan) ||
                other.playAdhan == playAdhan) &&
            (identical(other.customAdhanUrl, customAdhanUrl) ||
                other.customAdhanUrl == customAdhanUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    enabled,
    minutesBefore,
    playAdhan,
    customAdhanUrl,
  );

  @override
  String toString() {
    return 'PrayerNotificationSettings(enabled: $enabled, minutesBefore: $minutesBefore, playAdhan: $playAdhan, customAdhanUrl: $customAdhanUrl)';
  }
}

/// @nodoc
abstract mixin class $PrayerNotificationSettingsCopyWith<$Res> {
  factory $PrayerNotificationSettingsCopyWith(
    PrayerNotificationSettings value,
    $Res Function(PrayerNotificationSettings) _then,
  ) = _$PrayerNotificationSettingsCopyWithImpl;
  @useResult
  $Res call({
    bool enabled,
    int minutesBefore,
    bool playAdhan,
    String? customAdhanUrl,
  });
}

/// @nodoc
class _$PrayerNotificationSettingsCopyWithImpl<$Res>
    implements $PrayerNotificationSettingsCopyWith<$Res> {
  _$PrayerNotificationSettingsCopyWithImpl(this._self, this._then);

  final PrayerNotificationSettings _self;
  final $Res Function(PrayerNotificationSettings) _then;

  /// Create a copy of PrayerNotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? minutesBefore = null,
    Object? playAdhan = null,
    Object? customAdhanUrl = freezed,
  }) {
    return _then(
      _self.copyWith(
        enabled: null == enabled
            ? _self.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        minutesBefore: null == minutesBefore
            ? _self.minutesBefore
            : minutesBefore // ignore: cast_nullable_to_non_nullable
                  as int,
        playAdhan: null == playAdhan
            ? _self.playAdhan
            : playAdhan // ignore: cast_nullable_to_non_nullable
                  as bool,
        customAdhanUrl: freezed == customAdhanUrl
            ? _self.customAdhanUrl
            : customAdhanUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PrayerNotificationSettings].
extension PrayerNotificationSettingsPatterns on PrayerNotificationSettings {
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
    TResult Function(_PrayerNotificationSettings value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PrayerNotificationSettings() when $default != null:
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
    TResult Function(_PrayerNotificationSettings value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerNotificationSettings():
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
    TResult? Function(_PrayerNotificationSettings value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerNotificationSettings() when $default != null:
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
      bool enabled,
      int minutesBefore,
      bool playAdhan,
      String? customAdhanUrl,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PrayerNotificationSettings() when $default != null:
        return $default(
          _that.enabled,
          _that.minutesBefore,
          _that.playAdhan,
          _that.customAdhanUrl,
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
      bool enabled,
      int minutesBefore,
      bool playAdhan,
      String? customAdhanUrl,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerNotificationSettings():
        return $default(
          _that.enabled,
          _that.minutesBefore,
          _that.playAdhan,
          _that.customAdhanUrl,
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
      bool enabled,
      int minutesBefore,
      bool playAdhan,
      String? customAdhanUrl,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerNotificationSettings() when $default != null:
        return $default(
          _that.enabled,
          _that.minutesBefore,
          _that.playAdhan,
          _that.customAdhanUrl,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PrayerNotificationSettings implements PrayerNotificationSettings {
  const _PrayerNotificationSettings({
    this.enabled = true,
    this.minutesBefore = 0,
    this.playAdhan = false,
    this.customAdhanUrl,
  });
  factory _PrayerNotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$PrayerNotificationSettingsFromJson(json);

  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final int minutesBefore;
  @override
  @JsonKey()
  final bool playAdhan;
  @override
  final String? customAdhanUrl;

  /// Create a copy of PrayerNotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PrayerNotificationSettingsCopyWith<_PrayerNotificationSettings>
  get copyWith =>
      __$PrayerNotificationSettingsCopyWithImpl<_PrayerNotificationSettings>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$PrayerNotificationSettingsToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PrayerNotificationSettings &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.minutesBefore, minutesBefore) ||
                other.minutesBefore == minutesBefore) &&
            (identical(other.playAdhan, playAdhan) ||
                other.playAdhan == playAdhan) &&
            (identical(other.customAdhanUrl, customAdhanUrl) ||
                other.customAdhanUrl == customAdhanUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    enabled,
    minutesBefore,
    playAdhan,
    customAdhanUrl,
  );

  @override
  String toString() {
    return 'PrayerNotificationSettings(enabled: $enabled, minutesBefore: $minutesBefore, playAdhan: $playAdhan, customAdhanUrl: $customAdhanUrl)';
  }
}

/// @nodoc
abstract mixin class _$PrayerNotificationSettingsCopyWith<$Res>
    implements $PrayerNotificationSettingsCopyWith<$Res> {
  factory _$PrayerNotificationSettingsCopyWith(
    _PrayerNotificationSettings value,
    $Res Function(_PrayerNotificationSettings) _then,
  ) = __$PrayerNotificationSettingsCopyWithImpl;
  @override
  @useResult
  $Res call({
    bool enabled,
    int minutesBefore,
    bool playAdhan,
    String? customAdhanUrl,
  });
}

/// @nodoc
class __$PrayerNotificationSettingsCopyWithImpl<$Res>
    implements _$PrayerNotificationSettingsCopyWith<$Res> {
  __$PrayerNotificationSettingsCopyWithImpl(this._self, this._then);

  final _PrayerNotificationSettings _self;
  final $Res Function(_PrayerNotificationSettings) _then;

  /// Create a copy of PrayerNotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? enabled = null,
    Object? minutesBefore = null,
    Object? playAdhan = null,
    Object? customAdhanUrl = freezed,
  }) {
    return _then(
      _PrayerNotificationSettings(
        enabled: null == enabled
            ? _self.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        minutesBefore: null == minutesBefore
            ? _self.minutesBefore
            : minutesBefore // ignore: cast_nullable_to_non_nullable
                  as int,
        playAdhan: null == playAdhan
            ? _self.playAdhan
            : playAdhan // ignore: cast_nullable_to_non_nullable
                  as bool,
        customAdhanUrl: freezed == customAdhanUrl
            ? _self.customAdhanUrl
            : customAdhanUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$PrayerSettingsEntity {
  CalculationMethod get calculationMethod;
  AsrJuristicMethod get asrJuristicMethod;
  HighLatitudeMethod get highLatitudeMethod;
  int get fajrAdjustment;
  int get sunriseAdjustment;
  int get dhuhrAdjustment;
  int get asrAdjustment;
  int get maghribAdjustment;
  int get ishaAdjustment;
  PrayerNotificationSettings get fajrNotification;
  PrayerNotificationSettings get dhuhrNotification;
  PrayerNotificationSettings get asrNotification;
  PrayerNotificationSettings get maghribNotification;
  PrayerNotificationSettings get ishaNotification;
  bool get use24HourFormat;
  bool get showSunrise;
  double? get savedLatitude;
  double? get savedLongitude;
  String? get savedLocationName;

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PrayerSettingsEntityCopyWith<PrayerSettingsEntity> get copyWith =>
      _$PrayerSettingsEntityCopyWithImpl<PrayerSettingsEntity>(
        this as PrayerSettingsEntity,
        _$identity,
      );

  /// Serializes this PrayerSettingsEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PrayerSettingsEntity &&
            (identical(other.calculationMethod, calculationMethod) ||
                other.calculationMethod == calculationMethod) &&
            (identical(other.asrJuristicMethod, asrJuristicMethod) ||
                other.asrJuristicMethod == asrJuristicMethod) &&
            (identical(other.highLatitudeMethod, highLatitudeMethod) ||
                other.highLatitudeMethod == highLatitudeMethod) &&
            (identical(other.fajrAdjustment, fajrAdjustment) ||
                other.fajrAdjustment == fajrAdjustment) &&
            (identical(other.sunriseAdjustment, sunriseAdjustment) ||
                other.sunriseAdjustment == sunriseAdjustment) &&
            (identical(other.dhuhrAdjustment, dhuhrAdjustment) ||
                other.dhuhrAdjustment == dhuhrAdjustment) &&
            (identical(other.asrAdjustment, asrAdjustment) ||
                other.asrAdjustment == asrAdjustment) &&
            (identical(other.maghribAdjustment, maghribAdjustment) ||
                other.maghribAdjustment == maghribAdjustment) &&
            (identical(other.ishaAdjustment, ishaAdjustment) ||
                other.ishaAdjustment == ishaAdjustment) &&
            (identical(other.fajrNotification, fajrNotification) ||
                other.fajrNotification == fajrNotification) &&
            (identical(other.dhuhrNotification, dhuhrNotification) ||
                other.dhuhrNotification == dhuhrNotification) &&
            (identical(other.asrNotification, asrNotification) ||
                other.asrNotification == asrNotification) &&
            (identical(other.maghribNotification, maghribNotification) ||
                other.maghribNotification == maghribNotification) &&
            (identical(other.ishaNotification, ishaNotification) ||
                other.ishaNotification == ishaNotification) &&
            (identical(other.use24HourFormat, use24HourFormat) ||
                other.use24HourFormat == use24HourFormat) &&
            (identical(other.showSunrise, showSunrise) ||
                other.showSunrise == showSunrise) &&
            (identical(other.savedLatitude, savedLatitude) ||
                other.savedLatitude == savedLatitude) &&
            (identical(other.savedLongitude, savedLongitude) ||
                other.savedLongitude == savedLongitude) &&
            (identical(other.savedLocationName, savedLocationName) ||
                other.savedLocationName == savedLocationName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    calculationMethod,
    asrJuristicMethod,
    highLatitudeMethod,
    fajrAdjustment,
    sunriseAdjustment,
    dhuhrAdjustment,
    asrAdjustment,
    maghribAdjustment,
    ishaAdjustment,
    fajrNotification,
    dhuhrNotification,
    asrNotification,
    maghribNotification,
    ishaNotification,
    use24HourFormat,
    showSunrise,
    savedLatitude,
    savedLongitude,
    savedLocationName,
  ]);

  @override
  String toString() {
    return 'PrayerSettingsEntity(calculationMethod: $calculationMethod, asrJuristicMethod: $asrJuristicMethod, highLatitudeMethod: $highLatitudeMethod, fajrAdjustment: $fajrAdjustment, sunriseAdjustment: $sunriseAdjustment, dhuhrAdjustment: $dhuhrAdjustment, asrAdjustment: $asrAdjustment, maghribAdjustment: $maghribAdjustment, ishaAdjustment: $ishaAdjustment, fajrNotification: $fajrNotification, dhuhrNotification: $dhuhrNotification, asrNotification: $asrNotification, maghribNotification: $maghribNotification, ishaNotification: $ishaNotification, use24HourFormat: $use24HourFormat, showSunrise: $showSunrise, savedLatitude: $savedLatitude, savedLongitude: $savedLongitude, savedLocationName: $savedLocationName)';
  }
}

/// @nodoc
abstract mixin class $PrayerSettingsEntityCopyWith<$Res> {
  factory $PrayerSettingsEntityCopyWith(
    PrayerSettingsEntity value,
    $Res Function(PrayerSettingsEntity) _then,
  ) = _$PrayerSettingsEntityCopyWithImpl;
  @useResult
  $Res call({
    CalculationMethod calculationMethod,
    AsrJuristicMethod asrJuristicMethod,
    HighLatitudeMethod highLatitudeMethod,
    int fajrAdjustment,
    int sunriseAdjustment,
    int dhuhrAdjustment,
    int asrAdjustment,
    int maghribAdjustment,
    int ishaAdjustment,
    PrayerNotificationSettings fajrNotification,
    PrayerNotificationSettings dhuhrNotification,
    PrayerNotificationSettings asrNotification,
    PrayerNotificationSettings maghribNotification,
    PrayerNotificationSettings ishaNotification,
    bool use24HourFormat,
    bool showSunrise,
    double? savedLatitude,
    double? savedLongitude,
    String? savedLocationName,
  });

  $PrayerNotificationSettingsCopyWith<$Res> get fajrNotification;
  $PrayerNotificationSettingsCopyWith<$Res> get dhuhrNotification;
  $PrayerNotificationSettingsCopyWith<$Res> get asrNotification;
  $PrayerNotificationSettingsCopyWith<$Res> get maghribNotification;
  $PrayerNotificationSettingsCopyWith<$Res> get ishaNotification;
}

/// @nodoc
class _$PrayerSettingsEntityCopyWithImpl<$Res>
    implements $PrayerSettingsEntityCopyWith<$Res> {
  _$PrayerSettingsEntityCopyWithImpl(this._self, this._then);

  final PrayerSettingsEntity _self;
  final $Res Function(PrayerSettingsEntity) _then;

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calculationMethod = null,
    Object? asrJuristicMethod = null,
    Object? highLatitudeMethod = null,
    Object? fajrAdjustment = null,
    Object? sunriseAdjustment = null,
    Object? dhuhrAdjustment = null,
    Object? asrAdjustment = null,
    Object? maghribAdjustment = null,
    Object? ishaAdjustment = null,
    Object? fajrNotification = null,
    Object? dhuhrNotification = null,
    Object? asrNotification = null,
    Object? maghribNotification = null,
    Object? ishaNotification = null,
    Object? use24HourFormat = null,
    Object? showSunrise = null,
    Object? savedLatitude = freezed,
    Object? savedLongitude = freezed,
    Object? savedLocationName = freezed,
  }) {
    return _then(
      _self.copyWith(
        calculationMethod: null == calculationMethod
            ? _self.calculationMethod
            : calculationMethod // ignore: cast_nullable_to_non_nullable
                  as CalculationMethod,
        asrJuristicMethod: null == asrJuristicMethod
            ? _self.asrJuristicMethod
            : asrJuristicMethod // ignore: cast_nullable_to_non_nullable
                  as AsrJuristicMethod,
        highLatitudeMethod: null == highLatitudeMethod
            ? _self.highLatitudeMethod
            : highLatitudeMethod // ignore: cast_nullable_to_non_nullable
                  as HighLatitudeMethod,
        fajrAdjustment: null == fajrAdjustment
            ? _self.fajrAdjustment
            : fajrAdjustment // ignore: cast_nullable_to_non_nullable
                  as int,
        sunriseAdjustment: null == sunriseAdjustment
            ? _self.sunriseAdjustment
            : sunriseAdjustment // ignore: cast_nullable_to_non_nullable
                  as int,
        dhuhrAdjustment: null == dhuhrAdjustment
            ? _self.dhuhrAdjustment
            : dhuhrAdjustment // ignore: cast_nullable_to_non_nullable
                  as int,
        asrAdjustment: null == asrAdjustment
            ? _self.asrAdjustment
            : asrAdjustment // ignore: cast_nullable_to_non_nullable
                  as int,
        maghribAdjustment: null == maghribAdjustment
            ? _self.maghribAdjustment
            : maghribAdjustment // ignore: cast_nullable_to_non_nullable
                  as int,
        ishaAdjustment: null == ishaAdjustment
            ? _self.ishaAdjustment
            : ishaAdjustment // ignore: cast_nullable_to_non_nullable
                  as int,
        fajrNotification: null == fajrNotification
            ? _self.fajrNotification
            : fajrNotification // ignore: cast_nullable_to_non_nullable
                  as PrayerNotificationSettings,
        dhuhrNotification: null == dhuhrNotification
            ? _self.dhuhrNotification
            : dhuhrNotification // ignore: cast_nullable_to_non_nullable
                  as PrayerNotificationSettings,
        asrNotification: null == asrNotification
            ? _self.asrNotification
            : asrNotification // ignore: cast_nullable_to_non_nullable
                  as PrayerNotificationSettings,
        maghribNotification: null == maghribNotification
            ? _self.maghribNotification
            : maghribNotification // ignore: cast_nullable_to_non_nullable
                  as PrayerNotificationSettings,
        ishaNotification: null == ishaNotification
            ? _self.ishaNotification
            : ishaNotification // ignore: cast_nullable_to_non_nullable
                  as PrayerNotificationSettings,
        use24HourFormat: null == use24HourFormat
            ? _self.use24HourFormat
            : use24HourFormat // ignore: cast_nullable_to_non_nullable
                  as bool,
        showSunrise: null == showSunrise
            ? _self.showSunrise
            : showSunrise // ignore: cast_nullable_to_non_nullable
                  as bool,
        savedLatitude: freezed == savedLatitude
            ? _self.savedLatitude
            : savedLatitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        savedLongitude: freezed == savedLongitude
            ? _self.savedLongitude
            : savedLongitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        savedLocationName: freezed == savedLocationName
            ? _self.savedLocationName
            : savedLocationName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerNotificationSettingsCopyWith<$Res> get fajrNotification {
    return $PrayerNotificationSettingsCopyWith<$Res>(_self.fajrNotification, (
      value,
    ) {
      return _then(_self.copyWith(fajrNotification: value));
    });
  }

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerNotificationSettingsCopyWith<$Res> get dhuhrNotification {
    return $PrayerNotificationSettingsCopyWith<$Res>(_self.dhuhrNotification, (
      value,
    ) {
      return _then(_self.copyWith(dhuhrNotification: value));
    });
  }

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerNotificationSettingsCopyWith<$Res> get asrNotification {
    return $PrayerNotificationSettingsCopyWith<$Res>(_self.asrNotification, (
      value,
    ) {
      return _then(_self.copyWith(asrNotification: value));
    });
  }

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerNotificationSettingsCopyWith<$Res> get maghribNotification {
    return $PrayerNotificationSettingsCopyWith<$Res>(
      _self.maghribNotification,
      (value) {
        return _then(_self.copyWith(maghribNotification: value));
      },
    );
  }

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerNotificationSettingsCopyWith<$Res> get ishaNotification {
    return $PrayerNotificationSettingsCopyWith<$Res>(_self.ishaNotification, (
      value,
    ) {
      return _then(_self.copyWith(ishaNotification: value));
    });
  }
}

/// Adds pattern-matching-related methods to [PrayerSettingsEntity].
extension PrayerSettingsEntityPatterns on PrayerSettingsEntity {
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
    TResult Function(_PrayerSettingsEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PrayerSettingsEntity() when $default != null:
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
    TResult Function(_PrayerSettingsEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerSettingsEntity():
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
    TResult? Function(_PrayerSettingsEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerSettingsEntity() when $default != null:
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
      CalculationMethod calculationMethod,
      AsrJuristicMethod asrJuristicMethod,
      HighLatitudeMethod highLatitudeMethod,
      int fajrAdjustment,
      int sunriseAdjustment,
      int dhuhrAdjustment,
      int asrAdjustment,
      int maghribAdjustment,
      int ishaAdjustment,
      PrayerNotificationSettings fajrNotification,
      PrayerNotificationSettings dhuhrNotification,
      PrayerNotificationSettings asrNotification,
      PrayerNotificationSettings maghribNotification,
      PrayerNotificationSettings ishaNotification,
      bool use24HourFormat,
      bool showSunrise,
      double? savedLatitude,
      double? savedLongitude,
      String? savedLocationName,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PrayerSettingsEntity() when $default != null:
        return $default(
          _that.calculationMethod,
          _that.asrJuristicMethod,
          _that.highLatitudeMethod,
          _that.fajrAdjustment,
          _that.sunriseAdjustment,
          _that.dhuhrAdjustment,
          _that.asrAdjustment,
          _that.maghribAdjustment,
          _that.ishaAdjustment,
          _that.fajrNotification,
          _that.dhuhrNotification,
          _that.asrNotification,
          _that.maghribNotification,
          _that.ishaNotification,
          _that.use24HourFormat,
          _that.showSunrise,
          _that.savedLatitude,
          _that.savedLongitude,
          _that.savedLocationName,
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
      CalculationMethod calculationMethod,
      AsrJuristicMethod asrJuristicMethod,
      HighLatitudeMethod highLatitudeMethod,
      int fajrAdjustment,
      int sunriseAdjustment,
      int dhuhrAdjustment,
      int asrAdjustment,
      int maghribAdjustment,
      int ishaAdjustment,
      PrayerNotificationSettings fajrNotification,
      PrayerNotificationSettings dhuhrNotification,
      PrayerNotificationSettings asrNotification,
      PrayerNotificationSettings maghribNotification,
      PrayerNotificationSettings ishaNotification,
      bool use24HourFormat,
      bool showSunrise,
      double? savedLatitude,
      double? savedLongitude,
      String? savedLocationName,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerSettingsEntity():
        return $default(
          _that.calculationMethod,
          _that.asrJuristicMethod,
          _that.highLatitudeMethod,
          _that.fajrAdjustment,
          _that.sunriseAdjustment,
          _that.dhuhrAdjustment,
          _that.asrAdjustment,
          _that.maghribAdjustment,
          _that.ishaAdjustment,
          _that.fajrNotification,
          _that.dhuhrNotification,
          _that.asrNotification,
          _that.maghribNotification,
          _that.ishaNotification,
          _that.use24HourFormat,
          _that.showSunrise,
          _that.savedLatitude,
          _that.savedLongitude,
          _that.savedLocationName,
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
      CalculationMethod calculationMethod,
      AsrJuristicMethod asrJuristicMethod,
      HighLatitudeMethod highLatitudeMethod,
      int fajrAdjustment,
      int sunriseAdjustment,
      int dhuhrAdjustment,
      int asrAdjustment,
      int maghribAdjustment,
      int ishaAdjustment,
      PrayerNotificationSettings fajrNotification,
      PrayerNotificationSettings dhuhrNotification,
      PrayerNotificationSettings asrNotification,
      PrayerNotificationSettings maghribNotification,
      PrayerNotificationSettings ishaNotification,
      bool use24HourFormat,
      bool showSunrise,
      double? savedLatitude,
      double? savedLongitude,
      String? savedLocationName,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerSettingsEntity() when $default != null:
        return $default(
          _that.calculationMethod,
          _that.asrJuristicMethod,
          _that.highLatitudeMethod,
          _that.fajrAdjustment,
          _that.sunriseAdjustment,
          _that.dhuhrAdjustment,
          _that.asrAdjustment,
          _that.maghribAdjustment,
          _that.ishaAdjustment,
          _that.fajrNotification,
          _that.dhuhrNotification,
          _that.asrNotification,
          _that.maghribNotification,
          _that.ishaNotification,
          _that.use24HourFormat,
          _that.showSunrise,
          _that.savedLatitude,
          _that.savedLongitude,
          _that.savedLocationName,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PrayerSettingsEntity extends PrayerSettingsEntity {
  const _PrayerSettingsEntity({
    this.calculationMethod = CalculationMethod.ummAlQura,
    this.asrJuristicMethod = AsrJuristicMethod.shafii,
    this.highLatitudeMethod = HighLatitudeMethod.none,
    this.fajrAdjustment = 0,
    this.sunriseAdjustment = 0,
    this.dhuhrAdjustment = 0,
    this.asrAdjustment = 0,
    this.maghribAdjustment = 0,
    this.ishaAdjustment = 0,
    this.fajrNotification = const PrayerNotificationSettings(),
    this.dhuhrNotification = const PrayerNotificationSettings(),
    this.asrNotification = const PrayerNotificationSettings(),
    this.maghribNotification = const PrayerNotificationSettings(),
    this.ishaNotification = const PrayerNotificationSettings(),
    this.use24HourFormat = true,
    this.showSunrise = false,
    this.savedLatitude,
    this.savedLongitude,
    this.savedLocationName,
  }) : super._();
  factory _PrayerSettingsEntity.fromJson(Map<String, dynamic> json) =>
      _$PrayerSettingsEntityFromJson(json);

  @override
  @JsonKey()
  final CalculationMethod calculationMethod;
  @override
  @JsonKey()
  final AsrJuristicMethod asrJuristicMethod;
  @override
  @JsonKey()
  final HighLatitudeMethod highLatitudeMethod;
  @override
  @JsonKey()
  final int fajrAdjustment;
  @override
  @JsonKey()
  final int sunriseAdjustment;
  @override
  @JsonKey()
  final int dhuhrAdjustment;
  @override
  @JsonKey()
  final int asrAdjustment;
  @override
  @JsonKey()
  final int maghribAdjustment;
  @override
  @JsonKey()
  final int ishaAdjustment;
  @override
  @JsonKey()
  final PrayerNotificationSettings fajrNotification;
  @override
  @JsonKey()
  final PrayerNotificationSettings dhuhrNotification;
  @override
  @JsonKey()
  final PrayerNotificationSettings asrNotification;
  @override
  @JsonKey()
  final PrayerNotificationSettings maghribNotification;
  @override
  @JsonKey()
  final PrayerNotificationSettings ishaNotification;
  @override
  @JsonKey()
  final bool use24HourFormat;
  @override
  @JsonKey()
  final bool showSunrise;
  @override
  final double? savedLatitude;
  @override
  final double? savedLongitude;
  @override
  final String? savedLocationName;

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PrayerSettingsEntityCopyWith<_PrayerSettingsEntity> get copyWith =>
      __$PrayerSettingsEntityCopyWithImpl<_PrayerSettingsEntity>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$PrayerSettingsEntityToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PrayerSettingsEntity &&
            (identical(other.calculationMethod, calculationMethod) ||
                other.calculationMethod == calculationMethod) &&
            (identical(other.asrJuristicMethod, asrJuristicMethod) ||
                other.asrJuristicMethod == asrJuristicMethod) &&
            (identical(other.highLatitudeMethod, highLatitudeMethod) ||
                other.highLatitudeMethod == highLatitudeMethod) &&
            (identical(other.fajrAdjustment, fajrAdjustment) ||
                other.fajrAdjustment == fajrAdjustment) &&
            (identical(other.sunriseAdjustment, sunriseAdjustment) ||
                other.sunriseAdjustment == sunriseAdjustment) &&
            (identical(other.dhuhrAdjustment, dhuhrAdjustment) ||
                other.dhuhrAdjustment == dhuhrAdjustment) &&
            (identical(other.asrAdjustment, asrAdjustment) ||
                other.asrAdjustment == asrAdjustment) &&
            (identical(other.maghribAdjustment, maghribAdjustment) ||
                other.maghribAdjustment == maghribAdjustment) &&
            (identical(other.ishaAdjustment, ishaAdjustment) ||
                other.ishaAdjustment == ishaAdjustment) &&
            (identical(other.fajrNotification, fajrNotification) ||
                other.fajrNotification == fajrNotification) &&
            (identical(other.dhuhrNotification, dhuhrNotification) ||
                other.dhuhrNotification == dhuhrNotification) &&
            (identical(other.asrNotification, asrNotification) ||
                other.asrNotification == asrNotification) &&
            (identical(other.maghribNotification, maghribNotification) ||
                other.maghribNotification == maghribNotification) &&
            (identical(other.ishaNotification, ishaNotification) ||
                other.ishaNotification == ishaNotification) &&
            (identical(other.use24HourFormat, use24HourFormat) ||
                other.use24HourFormat == use24HourFormat) &&
            (identical(other.showSunrise, showSunrise) ||
                other.showSunrise == showSunrise) &&
            (identical(other.savedLatitude, savedLatitude) ||
                other.savedLatitude == savedLatitude) &&
            (identical(other.savedLongitude, savedLongitude) ||
                other.savedLongitude == savedLongitude) &&
            (identical(other.savedLocationName, savedLocationName) ||
                other.savedLocationName == savedLocationName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    calculationMethod,
    asrJuristicMethod,
    highLatitudeMethod,
    fajrAdjustment,
    sunriseAdjustment,
    dhuhrAdjustment,
    asrAdjustment,
    maghribAdjustment,
    ishaAdjustment,
    fajrNotification,
    dhuhrNotification,
    asrNotification,
    maghribNotification,
    ishaNotification,
    use24HourFormat,
    showSunrise,
    savedLatitude,
    savedLongitude,
    savedLocationName,
  ]);

  @override
  String toString() {
    return 'PrayerSettingsEntity(calculationMethod: $calculationMethod, asrJuristicMethod: $asrJuristicMethod, highLatitudeMethod: $highLatitudeMethod, fajrAdjustment: $fajrAdjustment, sunriseAdjustment: $sunriseAdjustment, dhuhrAdjustment: $dhuhrAdjustment, asrAdjustment: $asrAdjustment, maghribAdjustment: $maghribAdjustment, ishaAdjustment: $ishaAdjustment, fajrNotification: $fajrNotification, dhuhrNotification: $dhuhrNotification, asrNotification: $asrNotification, maghribNotification: $maghribNotification, ishaNotification: $ishaNotification, use24HourFormat: $use24HourFormat, showSunrise: $showSunrise, savedLatitude: $savedLatitude, savedLongitude: $savedLongitude, savedLocationName: $savedLocationName)';
  }
}

/// @nodoc
abstract mixin class _$PrayerSettingsEntityCopyWith<$Res>
    implements $PrayerSettingsEntityCopyWith<$Res> {
  factory _$PrayerSettingsEntityCopyWith(
    _PrayerSettingsEntity value,
    $Res Function(_PrayerSettingsEntity) _then,
  ) = __$PrayerSettingsEntityCopyWithImpl;
  @override
  @useResult
  $Res call({
    CalculationMethod calculationMethod,
    AsrJuristicMethod asrJuristicMethod,
    HighLatitudeMethod highLatitudeMethod,
    int fajrAdjustment,
    int sunriseAdjustment,
    int dhuhrAdjustment,
    int asrAdjustment,
    int maghribAdjustment,
    int ishaAdjustment,
    PrayerNotificationSettings fajrNotification,
    PrayerNotificationSettings dhuhrNotification,
    PrayerNotificationSettings asrNotification,
    PrayerNotificationSettings maghribNotification,
    PrayerNotificationSettings ishaNotification,
    bool use24HourFormat,
    bool showSunrise,
    double? savedLatitude,
    double? savedLongitude,
    String? savedLocationName,
  });

  @override
  $PrayerNotificationSettingsCopyWith<$Res> get fajrNotification;
  @override
  $PrayerNotificationSettingsCopyWith<$Res> get dhuhrNotification;
  @override
  $PrayerNotificationSettingsCopyWith<$Res> get asrNotification;
  @override
  $PrayerNotificationSettingsCopyWith<$Res> get maghribNotification;
  @override
  $PrayerNotificationSettingsCopyWith<$Res> get ishaNotification;
}

/// @nodoc
class __$PrayerSettingsEntityCopyWithImpl<$Res>
    implements _$PrayerSettingsEntityCopyWith<$Res> {
  __$PrayerSettingsEntityCopyWithImpl(this._self, this._then);

  final _PrayerSettingsEntity _self;
  final $Res Function(_PrayerSettingsEntity) _then;

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? calculationMethod = null,
    Object? asrJuristicMethod = null,
    Object? highLatitudeMethod = null,
    Object? fajrAdjustment = null,
    Object? sunriseAdjustment = null,
    Object? dhuhrAdjustment = null,
    Object? asrAdjustment = null,
    Object? maghribAdjustment = null,
    Object? ishaAdjustment = null,
    Object? fajrNotification = null,
    Object? dhuhrNotification = null,
    Object? asrNotification = null,
    Object? maghribNotification = null,
    Object? ishaNotification = null,
    Object? use24HourFormat = null,
    Object? showSunrise = null,
    Object? savedLatitude = freezed,
    Object? savedLongitude = freezed,
    Object? savedLocationName = freezed,
  }) {
    return _then(
      _PrayerSettingsEntity(
        calculationMethod: null == calculationMethod
            ? _self.calculationMethod
            : calculationMethod // ignore: cast_nullable_to_non_nullable
                  as CalculationMethod,
        asrJuristicMethod: null == asrJuristicMethod
            ? _self.asrJuristicMethod
            : asrJuristicMethod // ignore: cast_nullable_to_non_nullable
                  as AsrJuristicMethod,
        highLatitudeMethod: null == highLatitudeMethod
            ? _self.highLatitudeMethod
            : highLatitudeMethod // ignore: cast_nullable_to_non_nullable
                  as HighLatitudeMethod,
        fajrAdjustment: null == fajrAdjustment
            ? _self.fajrAdjustment
            : fajrAdjustment // ignore: cast_nullable_to_non_nullable
                  as int,
        sunriseAdjustment: null == sunriseAdjustment
            ? _self.sunriseAdjustment
            : sunriseAdjustment // ignore: cast_nullable_to_non_nullable
                  as int,
        dhuhrAdjustment: null == dhuhrAdjustment
            ? _self.dhuhrAdjustment
            : dhuhrAdjustment // ignore: cast_nullable_to_non_nullable
                  as int,
        asrAdjustment: null == asrAdjustment
            ? _self.asrAdjustment
            : asrAdjustment // ignore: cast_nullable_to_non_nullable
                  as int,
        maghribAdjustment: null == maghribAdjustment
            ? _self.maghribAdjustment
            : maghribAdjustment // ignore: cast_nullable_to_non_nullable
                  as int,
        ishaAdjustment: null == ishaAdjustment
            ? _self.ishaAdjustment
            : ishaAdjustment // ignore: cast_nullable_to_non_nullable
                  as int,
        fajrNotification: null == fajrNotification
            ? _self.fajrNotification
            : fajrNotification // ignore: cast_nullable_to_non_nullable
                  as PrayerNotificationSettings,
        dhuhrNotification: null == dhuhrNotification
            ? _self.dhuhrNotification
            : dhuhrNotification // ignore: cast_nullable_to_non_nullable
                  as PrayerNotificationSettings,
        asrNotification: null == asrNotification
            ? _self.asrNotification
            : asrNotification // ignore: cast_nullable_to_non_nullable
                  as PrayerNotificationSettings,
        maghribNotification: null == maghribNotification
            ? _self.maghribNotification
            : maghribNotification // ignore: cast_nullable_to_non_nullable
                  as PrayerNotificationSettings,
        ishaNotification: null == ishaNotification
            ? _self.ishaNotification
            : ishaNotification // ignore: cast_nullable_to_non_nullable
                  as PrayerNotificationSettings,
        use24HourFormat: null == use24HourFormat
            ? _self.use24HourFormat
            : use24HourFormat // ignore: cast_nullable_to_non_nullable
                  as bool,
        showSunrise: null == showSunrise
            ? _self.showSunrise
            : showSunrise // ignore: cast_nullable_to_non_nullable
                  as bool,
        savedLatitude: freezed == savedLatitude
            ? _self.savedLatitude
            : savedLatitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        savedLongitude: freezed == savedLongitude
            ? _self.savedLongitude
            : savedLongitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        savedLocationName: freezed == savedLocationName
            ? _self.savedLocationName
            : savedLocationName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerNotificationSettingsCopyWith<$Res> get fajrNotification {
    return $PrayerNotificationSettingsCopyWith<$Res>(_self.fajrNotification, (
      value,
    ) {
      return _then(_self.copyWith(fajrNotification: value));
    });
  }

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerNotificationSettingsCopyWith<$Res> get dhuhrNotification {
    return $PrayerNotificationSettingsCopyWith<$Res>(_self.dhuhrNotification, (
      value,
    ) {
      return _then(_self.copyWith(dhuhrNotification: value));
    });
  }

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerNotificationSettingsCopyWith<$Res> get asrNotification {
    return $PrayerNotificationSettingsCopyWith<$Res>(_self.asrNotification, (
      value,
    ) {
      return _then(_self.copyWith(asrNotification: value));
    });
  }

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerNotificationSettingsCopyWith<$Res> get maghribNotification {
    return $PrayerNotificationSettingsCopyWith<$Res>(
      _self.maghribNotification,
      (value) {
        return _then(_self.copyWith(maghribNotification: value));
      },
    );
  }

  /// Create a copy of PrayerSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerNotificationSettingsCopyWith<$Res> get ishaNotification {
    return $PrayerNotificationSettingsCopyWith<$Res>(_self.ishaNotification, (
      value,
    ) {
      return _then(_self.copyWith(ishaNotification: value));
    });
  }
}
