// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prayer_times_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PrayerTimesEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PrayerTimesEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerTimesEvent()';
  }
}

/// @nodoc
class $PrayerTimesEventCopyWith<$Res> {
  $PrayerTimesEventCopyWith(
    PrayerTimesEvent _,
    $Res Function(PrayerTimesEvent) __,
  );
}

/// Adds pattern-matching-related methods to [PrayerTimesEvent].
extension PrayerTimesEventPatterns on PrayerTimesEvent {
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
    TResult Function(_LoadPrayerTimes value)? loadPrayerTimes,
    TResult Function(_LoadMonthlyPrayerTimes value)? loadMonthlyPrayerTimes,
    TResult Function(_UpdateLocation value)? updateLocation,
    TResult Function(_UpdateSettings value)? updateSettings,
    TResult Function(_RefreshCountdown value)? refreshCountdown,
    TResult Function(_SetManualLocation value)? setManualLocation,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LoadPrayerTimes() when loadPrayerTimes != null:
        return loadPrayerTimes(_that);
      case _LoadMonthlyPrayerTimes() when loadMonthlyPrayerTimes != null:
        return loadMonthlyPrayerTimes(_that);
      case _UpdateLocation() when updateLocation != null:
        return updateLocation(_that);
      case _UpdateSettings() when updateSettings != null:
        return updateSettings(_that);
      case _RefreshCountdown() when refreshCountdown != null:
        return refreshCountdown(_that);
      case _SetManualLocation() when setManualLocation != null:
        return setManualLocation(_that);
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
    required TResult Function(_LoadPrayerTimes value) loadPrayerTimes,
    required TResult Function(_LoadMonthlyPrayerTimes value)
    loadMonthlyPrayerTimes,
    required TResult Function(_UpdateLocation value) updateLocation,
    required TResult Function(_UpdateSettings value) updateSettings,
    required TResult Function(_RefreshCountdown value) refreshCountdown,
    required TResult Function(_SetManualLocation value) setManualLocation,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadPrayerTimes():
        return loadPrayerTimes(_that);
      case _LoadMonthlyPrayerTimes():
        return loadMonthlyPrayerTimes(_that);
      case _UpdateLocation():
        return updateLocation(_that);
      case _UpdateSettings():
        return updateSettings(_that);
      case _RefreshCountdown():
        return refreshCountdown(_that);
      case _SetManualLocation():
        return setManualLocation(_that);
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
    TResult? Function(_LoadPrayerTimes value)? loadPrayerTimes,
    TResult? Function(_LoadMonthlyPrayerTimes value)? loadMonthlyPrayerTimes,
    TResult? Function(_UpdateLocation value)? updateLocation,
    TResult? Function(_UpdateSettings value)? updateSettings,
    TResult? Function(_RefreshCountdown value)? refreshCountdown,
    TResult? Function(_SetManualLocation value)? setManualLocation,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadPrayerTimes() when loadPrayerTimes != null:
        return loadPrayerTimes(_that);
      case _LoadMonthlyPrayerTimes() when loadMonthlyPrayerTimes != null:
        return loadMonthlyPrayerTimes(_that);
      case _UpdateLocation() when updateLocation != null:
        return updateLocation(_that);
      case _UpdateSettings() when updateSettings != null:
        return updateSettings(_that);
      case _RefreshCountdown() when refreshCountdown != null:
        return refreshCountdown(_that);
      case _SetManualLocation() when setManualLocation != null:
        return setManualLocation(_that);
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
    TResult Function()? loadPrayerTimes,
    TResult Function(int year, int month)? loadMonthlyPrayerTimes,
    TResult Function()? updateLocation,
    TResult Function(PrayerSettingsEntity settings)? updateSettings,
    TResult Function()? refreshCountdown,
    TResult Function(double latitude, double longitude, String? locationName)?
    setManualLocation,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LoadPrayerTimes() when loadPrayerTimes != null:
        return loadPrayerTimes();
      case _LoadMonthlyPrayerTimes() when loadMonthlyPrayerTimes != null:
        return loadMonthlyPrayerTimes(_that.year, _that.month);
      case _UpdateLocation() when updateLocation != null:
        return updateLocation();
      case _UpdateSettings() when updateSettings != null:
        return updateSettings(_that.settings);
      case _RefreshCountdown() when refreshCountdown != null:
        return refreshCountdown();
      case _SetManualLocation() when setManualLocation != null:
        return setManualLocation(
          _that.latitude,
          _that.longitude,
          _that.locationName,
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
  TResult when<TResult extends Object?>({
    required TResult Function() loadPrayerTimes,
    required TResult Function(int year, int month) loadMonthlyPrayerTimes,
    required TResult Function() updateLocation,
    required TResult Function(PrayerSettingsEntity settings) updateSettings,
    required TResult Function() refreshCountdown,
    required TResult Function(
      double latitude,
      double longitude,
      String? locationName,
    )
    setManualLocation,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadPrayerTimes():
        return loadPrayerTimes();
      case _LoadMonthlyPrayerTimes():
        return loadMonthlyPrayerTimes(_that.year, _that.month);
      case _UpdateLocation():
        return updateLocation();
      case _UpdateSettings():
        return updateSettings(_that.settings);
      case _RefreshCountdown():
        return refreshCountdown();
      case _SetManualLocation():
        return setManualLocation(
          _that.latitude,
          _that.longitude,
          _that.locationName,
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadPrayerTimes,
    TResult? Function(int year, int month)? loadMonthlyPrayerTimes,
    TResult? Function()? updateLocation,
    TResult? Function(PrayerSettingsEntity settings)? updateSettings,
    TResult? Function()? refreshCountdown,
    TResult? Function(double latitude, double longitude, String? locationName)?
    setManualLocation,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadPrayerTimes() when loadPrayerTimes != null:
        return loadPrayerTimes();
      case _LoadMonthlyPrayerTimes() when loadMonthlyPrayerTimes != null:
        return loadMonthlyPrayerTimes(_that.year, _that.month);
      case _UpdateLocation() when updateLocation != null:
        return updateLocation();
      case _UpdateSettings() when updateSettings != null:
        return updateSettings(_that.settings);
      case _RefreshCountdown() when refreshCountdown != null:
        return refreshCountdown();
      case _SetManualLocation() when setManualLocation != null:
        return setManualLocation(
          _that.latitude,
          _that.longitude,
          _that.locationName,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LoadPrayerTimes implements PrayerTimesEvent {
  const _LoadPrayerTimes();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _LoadPrayerTimes);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerTimesEvent.loadPrayerTimes()';
  }
}

/// @nodoc

class _LoadMonthlyPrayerTimes implements PrayerTimesEvent {
  const _LoadMonthlyPrayerTimes({required this.year, required this.month});

  final int year;
  final int month;

  /// Create a copy of PrayerTimesEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LoadMonthlyPrayerTimesCopyWith<_LoadMonthlyPrayerTimes> get copyWith =>
      __$LoadMonthlyPrayerTimesCopyWithImpl<_LoadMonthlyPrayerTimes>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LoadMonthlyPrayerTimes &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month));
  }

  @override
  int get hashCode => Object.hash(runtimeType, year, month);

  @override
  String toString() {
    return 'PrayerTimesEvent.loadMonthlyPrayerTimes(year: $year, month: $month)';
  }
}

/// @nodoc
abstract mixin class _$LoadMonthlyPrayerTimesCopyWith<$Res>
    implements $PrayerTimesEventCopyWith<$Res> {
  factory _$LoadMonthlyPrayerTimesCopyWith(
    _LoadMonthlyPrayerTimes value,
    $Res Function(_LoadMonthlyPrayerTimes) _then,
  ) = __$LoadMonthlyPrayerTimesCopyWithImpl;
  @useResult
  $Res call({int year, int month});
}

/// @nodoc
class __$LoadMonthlyPrayerTimesCopyWithImpl<$Res>
    implements _$LoadMonthlyPrayerTimesCopyWith<$Res> {
  __$LoadMonthlyPrayerTimesCopyWithImpl(this._self, this._then);

  final _LoadMonthlyPrayerTimes _self;
  final $Res Function(_LoadMonthlyPrayerTimes) _then;

  /// Create a copy of PrayerTimesEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? year = null, Object? month = null}) {
    return _then(
      _LoadMonthlyPrayerTimes(
        year: null == year
            ? _self.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        month: null == month
            ? _self.month
            : month // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _UpdateLocation implements PrayerTimesEvent {
  const _UpdateLocation();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _UpdateLocation);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerTimesEvent.updateLocation()';
  }
}

/// @nodoc

class _UpdateSettings implements PrayerTimesEvent {
  const _UpdateSettings(this.settings);

  final PrayerSettingsEntity settings;

  /// Create a copy of PrayerTimesEvent
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
    return 'PrayerTimesEvent.updateSettings(settings: $settings)';
  }
}

/// @nodoc
abstract mixin class _$UpdateSettingsCopyWith<$Res>
    implements $PrayerTimesEventCopyWith<$Res> {
  factory _$UpdateSettingsCopyWith(
    _UpdateSettings value,
    $Res Function(_UpdateSettings) _then,
  ) = __$UpdateSettingsCopyWithImpl;
  @useResult
  $Res call({PrayerSettingsEntity settings});

  $PrayerSettingsEntityCopyWith<$Res> get settings;
}

/// @nodoc
class __$UpdateSettingsCopyWithImpl<$Res>
    implements _$UpdateSettingsCopyWith<$Res> {
  __$UpdateSettingsCopyWithImpl(this._self, this._then);

  final _UpdateSettings _self;
  final $Res Function(_UpdateSettings) _then;

  /// Create a copy of PrayerTimesEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? settings = null}) {
    return _then(
      _UpdateSettings(
        null == settings
            ? _self.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as PrayerSettingsEntity,
      ),
    );
  }

  /// Create a copy of PrayerTimesEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerSettingsEntityCopyWith<$Res> get settings {
    return $PrayerSettingsEntityCopyWith<$Res>(_self.settings, (value) {
      return _then(_self.copyWith(settings: value));
    });
  }
}

/// @nodoc

class _RefreshCountdown implements PrayerTimesEvent {
  const _RefreshCountdown();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _RefreshCountdown);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerTimesEvent.refreshCountdown()';
  }
}

/// @nodoc

class _SetManualLocation implements PrayerTimesEvent {
  const _SetManualLocation({
    required this.latitude,
    required this.longitude,
    this.locationName,
  });

  final double latitude;
  final double longitude;
  final String? locationName;

  /// Create a copy of PrayerTimesEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SetManualLocationCopyWith<_SetManualLocation> get copyWith =>
      __$SetManualLocationCopyWithImpl<_SetManualLocation>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SetManualLocation &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, latitude, longitude, locationName);

  @override
  String toString() {
    return 'PrayerTimesEvent.setManualLocation(latitude: $latitude, longitude: $longitude, locationName: $locationName)';
  }
}

/// @nodoc
abstract mixin class _$SetManualLocationCopyWith<$Res>
    implements $PrayerTimesEventCopyWith<$Res> {
  factory _$SetManualLocationCopyWith(
    _SetManualLocation value,
    $Res Function(_SetManualLocation) _then,
  ) = __$SetManualLocationCopyWithImpl;
  @useResult
  $Res call({double latitude, double longitude, String? locationName});
}

/// @nodoc
class __$SetManualLocationCopyWithImpl<$Res>
    implements _$SetManualLocationCopyWith<$Res> {
  __$SetManualLocationCopyWithImpl(this._self, this._then);

  final _SetManualLocation _self;
  final $Res Function(_SetManualLocation) _then;

  /// Create a copy of PrayerTimesEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
    Object? locationName = freezed,
  }) {
    return _then(
      _SetManualLocation(
        latitude: null == latitude
            ? _self.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _self.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        locationName: freezed == locationName
            ? _self.locationName
            : locationName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$PrayerTimesState {
  PrayerTimesStatus get status;
  PrayerTimeEntity? get todayPrayerTimes;
  List<PrayerTimeEntity> get monthlyPrayerTimes;
  PrayerSettingsEntity get settings;
  double? get latitude;
  double? get longitude;
  String? get locationName;
  PrayerTimeItem? get currentOrNextPrayer;
  Duration? get timeUntilNextPrayer;
  String get errorMessage;
  bool get isLoadingLocation;

  /// Create a copy of PrayerTimesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PrayerTimesStateCopyWith<PrayerTimesState> get copyWith =>
      _$PrayerTimesStateCopyWithImpl<PrayerTimesState>(
        this as PrayerTimesState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PrayerTimesState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.todayPrayerTimes, todayPrayerTimes) ||
                other.todayPrayerTimes == todayPrayerTimes) &&
            const DeepCollectionEquality().equals(
              other.monthlyPrayerTimes,
              monthlyPrayerTimes,
            ) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName) &&
            (identical(other.currentOrNextPrayer, currentOrNextPrayer) ||
                other.currentOrNextPrayer == currentOrNextPrayer) &&
            (identical(other.timeUntilNextPrayer, timeUntilNextPrayer) ||
                other.timeUntilNextPrayer == timeUntilNextPrayer) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.isLoadingLocation, isLoadingLocation) ||
                other.isLoadingLocation == isLoadingLocation));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    todayPrayerTimes,
    const DeepCollectionEquality().hash(monthlyPrayerTimes),
    settings,
    latitude,
    longitude,
    locationName,
    currentOrNextPrayer,
    timeUntilNextPrayer,
    errorMessage,
    isLoadingLocation,
  );

  @override
  String toString() {
    return 'PrayerTimesState(status: $status, todayPrayerTimes: $todayPrayerTimes, monthlyPrayerTimes: $monthlyPrayerTimes, settings: $settings, latitude: $latitude, longitude: $longitude, locationName: $locationName, currentOrNextPrayer: $currentOrNextPrayer, timeUntilNextPrayer: $timeUntilNextPrayer, errorMessage: $errorMessage, isLoadingLocation: $isLoadingLocation)';
  }
}

/// @nodoc
abstract mixin class $PrayerTimesStateCopyWith<$Res> {
  factory $PrayerTimesStateCopyWith(
    PrayerTimesState value,
    $Res Function(PrayerTimesState) _then,
  ) = _$PrayerTimesStateCopyWithImpl;
  @useResult
  $Res call({
    PrayerTimesStatus status,
    PrayerTimeEntity? todayPrayerTimes,
    List<PrayerTimeEntity> monthlyPrayerTimes,
    PrayerSettingsEntity settings,
    double? latitude,
    double? longitude,
    String? locationName,
    PrayerTimeItem? currentOrNextPrayer,
    Duration? timeUntilNextPrayer,
    String errorMessage,
    bool isLoadingLocation,
  });

  $PrayerTimeEntityCopyWith<$Res>? get todayPrayerTimes;
  $PrayerSettingsEntityCopyWith<$Res> get settings;
}

/// @nodoc
class _$PrayerTimesStateCopyWithImpl<$Res>
    implements $PrayerTimesStateCopyWith<$Res> {
  _$PrayerTimesStateCopyWithImpl(this._self, this._then);

  final PrayerTimesState _self;
  final $Res Function(PrayerTimesState) _then;

  /// Create a copy of PrayerTimesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? todayPrayerTimes = freezed,
    Object? monthlyPrayerTimes = null,
    Object? settings = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? locationName = freezed,
    Object? currentOrNextPrayer = freezed,
    Object? timeUntilNextPrayer = freezed,
    Object? errorMessage = null,
    Object? isLoadingLocation = null,
  }) {
    return _then(
      _self.copyWith(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PrayerTimesStatus,
        todayPrayerTimes: freezed == todayPrayerTimes
            ? _self.todayPrayerTimes
            : todayPrayerTimes // ignore: cast_nullable_to_non_nullable
                  as PrayerTimeEntity?,
        monthlyPrayerTimes: null == monthlyPrayerTimes
            ? _self.monthlyPrayerTimes
            : monthlyPrayerTimes // ignore: cast_nullable_to_non_nullable
                  as List<PrayerTimeEntity>,
        settings: null == settings
            ? _self.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as PrayerSettingsEntity,
        latitude: freezed == latitude
            ? _self.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _self.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        locationName: freezed == locationName
            ? _self.locationName
            : locationName // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentOrNextPrayer: freezed == currentOrNextPrayer
            ? _self.currentOrNextPrayer
            : currentOrNextPrayer // ignore: cast_nullable_to_non_nullable
                  as PrayerTimeItem?,
        timeUntilNextPrayer: freezed == timeUntilNextPrayer
            ? _self.timeUntilNextPrayer
            : timeUntilNextPrayer // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        errorMessage: null == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String,
        isLoadingLocation: null == isLoadingLocation
            ? _self.isLoadingLocation
            : isLoadingLocation // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }

  /// Create a copy of PrayerTimesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerTimeEntityCopyWith<$Res>? get todayPrayerTimes {
    if (_self.todayPrayerTimes == null) {
      return null;
    }

    return $PrayerTimeEntityCopyWith<$Res>(_self.todayPrayerTimes!, (value) {
      return _then(_self.copyWith(todayPrayerTimes: value));
    });
  }

  /// Create a copy of PrayerTimesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerSettingsEntityCopyWith<$Res> get settings {
    return $PrayerSettingsEntityCopyWith<$Res>(_self.settings, (value) {
      return _then(_self.copyWith(settings: value));
    });
  }
}

/// Adds pattern-matching-related methods to [PrayerTimesState].
extension PrayerTimesStatePatterns on PrayerTimesState {
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
    TResult Function(_PrayerTimesState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PrayerTimesState() when $default != null:
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
    TResult Function(_PrayerTimesState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerTimesState():
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
    TResult? Function(_PrayerTimesState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerTimesState() when $default != null:
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
      PrayerTimesStatus status,
      PrayerTimeEntity? todayPrayerTimes,
      List<PrayerTimeEntity> monthlyPrayerTimes,
      PrayerSettingsEntity settings,
      double? latitude,
      double? longitude,
      String? locationName,
      PrayerTimeItem? currentOrNextPrayer,
      Duration? timeUntilNextPrayer,
      String errorMessage,
      bool isLoadingLocation,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PrayerTimesState() when $default != null:
        return $default(
          _that.status,
          _that.todayPrayerTimes,
          _that.monthlyPrayerTimes,
          _that.settings,
          _that.latitude,
          _that.longitude,
          _that.locationName,
          _that.currentOrNextPrayer,
          _that.timeUntilNextPrayer,
          _that.errorMessage,
          _that.isLoadingLocation,
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
      PrayerTimesStatus status,
      PrayerTimeEntity? todayPrayerTimes,
      List<PrayerTimeEntity> monthlyPrayerTimes,
      PrayerSettingsEntity settings,
      double? latitude,
      double? longitude,
      String? locationName,
      PrayerTimeItem? currentOrNextPrayer,
      Duration? timeUntilNextPrayer,
      String errorMessage,
      bool isLoadingLocation,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerTimesState():
        return $default(
          _that.status,
          _that.todayPrayerTimes,
          _that.monthlyPrayerTimes,
          _that.settings,
          _that.latitude,
          _that.longitude,
          _that.locationName,
          _that.currentOrNextPrayer,
          _that.timeUntilNextPrayer,
          _that.errorMessage,
          _that.isLoadingLocation,
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
      PrayerTimesStatus status,
      PrayerTimeEntity? todayPrayerTimes,
      List<PrayerTimeEntity> monthlyPrayerTimes,
      PrayerSettingsEntity settings,
      double? latitude,
      double? longitude,
      String? locationName,
      PrayerTimeItem? currentOrNextPrayer,
      Duration? timeUntilNextPrayer,
      String errorMessage,
      bool isLoadingLocation,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PrayerTimesState() when $default != null:
        return $default(
          _that.status,
          _that.todayPrayerTimes,
          _that.monthlyPrayerTimes,
          _that.settings,
          _that.latitude,
          _that.longitude,
          _that.locationName,
          _that.currentOrNextPrayer,
          _that.timeUntilNextPrayer,
          _that.errorMessage,
          _that.isLoadingLocation,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PrayerTimesState implements PrayerTimesState {
  const _PrayerTimesState({
    this.status = PrayerTimesStatus.initial,
    this.todayPrayerTimes,
    final List<PrayerTimeEntity> monthlyPrayerTimes = const [],
    this.settings = const PrayerSettingsEntity(),
    this.latitude,
    this.longitude,
    this.locationName,
    this.currentOrNextPrayer,
    this.timeUntilNextPrayer,
    this.errorMessage = '',
    this.isLoadingLocation = false,
  }) : _monthlyPrayerTimes = monthlyPrayerTimes;

  @override
  @JsonKey()
  final PrayerTimesStatus status;
  @override
  final PrayerTimeEntity? todayPrayerTimes;
  final List<PrayerTimeEntity> _monthlyPrayerTimes;
  @override
  @JsonKey()
  List<PrayerTimeEntity> get monthlyPrayerTimes {
    if (_monthlyPrayerTimes is EqualUnmodifiableListView)
      return _monthlyPrayerTimes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_monthlyPrayerTimes);
  }

  @override
  @JsonKey()
  final PrayerSettingsEntity settings;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  final String? locationName;
  @override
  final PrayerTimeItem? currentOrNextPrayer;
  @override
  final Duration? timeUntilNextPrayer;
  @override
  @JsonKey()
  final String errorMessage;
  @override
  @JsonKey()
  final bool isLoadingLocation;

  /// Create a copy of PrayerTimesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PrayerTimesStateCopyWith<_PrayerTimesState> get copyWith =>
      __$PrayerTimesStateCopyWithImpl<_PrayerTimesState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PrayerTimesState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.todayPrayerTimes, todayPrayerTimes) ||
                other.todayPrayerTimes == todayPrayerTimes) &&
            const DeepCollectionEquality().equals(
              other._monthlyPrayerTimes,
              _monthlyPrayerTimes,
            ) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName) &&
            (identical(other.currentOrNextPrayer, currentOrNextPrayer) ||
                other.currentOrNextPrayer == currentOrNextPrayer) &&
            (identical(other.timeUntilNextPrayer, timeUntilNextPrayer) ||
                other.timeUntilNextPrayer == timeUntilNextPrayer) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.isLoadingLocation, isLoadingLocation) ||
                other.isLoadingLocation == isLoadingLocation));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    todayPrayerTimes,
    const DeepCollectionEquality().hash(_monthlyPrayerTimes),
    settings,
    latitude,
    longitude,
    locationName,
    currentOrNextPrayer,
    timeUntilNextPrayer,
    errorMessage,
    isLoadingLocation,
  );

  @override
  String toString() {
    return 'PrayerTimesState(status: $status, todayPrayerTimes: $todayPrayerTimes, monthlyPrayerTimes: $monthlyPrayerTimes, settings: $settings, latitude: $latitude, longitude: $longitude, locationName: $locationName, currentOrNextPrayer: $currentOrNextPrayer, timeUntilNextPrayer: $timeUntilNextPrayer, errorMessage: $errorMessage, isLoadingLocation: $isLoadingLocation)';
  }
}

/// @nodoc
abstract mixin class _$PrayerTimesStateCopyWith<$Res>
    implements $PrayerTimesStateCopyWith<$Res> {
  factory _$PrayerTimesStateCopyWith(
    _PrayerTimesState value,
    $Res Function(_PrayerTimesState) _then,
  ) = __$PrayerTimesStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    PrayerTimesStatus status,
    PrayerTimeEntity? todayPrayerTimes,
    List<PrayerTimeEntity> monthlyPrayerTimes,
    PrayerSettingsEntity settings,
    double? latitude,
    double? longitude,
    String? locationName,
    PrayerTimeItem? currentOrNextPrayer,
    Duration? timeUntilNextPrayer,
    String errorMessage,
    bool isLoadingLocation,
  });

  @override
  $PrayerTimeEntityCopyWith<$Res>? get todayPrayerTimes;
  @override
  $PrayerSettingsEntityCopyWith<$Res> get settings;
}

/// @nodoc
class __$PrayerTimesStateCopyWithImpl<$Res>
    implements _$PrayerTimesStateCopyWith<$Res> {
  __$PrayerTimesStateCopyWithImpl(this._self, this._then);

  final _PrayerTimesState _self;
  final $Res Function(_PrayerTimesState) _then;

  /// Create a copy of PrayerTimesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? status = null,
    Object? todayPrayerTimes = freezed,
    Object? monthlyPrayerTimes = null,
    Object? settings = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? locationName = freezed,
    Object? currentOrNextPrayer = freezed,
    Object? timeUntilNextPrayer = freezed,
    Object? errorMessage = null,
    Object? isLoadingLocation = null,
  }) {
    return _then(
      _PrayerTimesState(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PrayerTimesStatus,
        todayPrayerTimes: freezed == todayPrayerTimes
            ? _self.todayPrayerTimes
            : todayPrayerTimes // ignore: cast_nullable_to_non_nullable
                  as PrayerTimeEntity?,
        monthlyPrayerTimes: null == monthlyPrayerTimes
            ? _self._monthlyPrayerTimes
            : monthlyPrayerTimes // ignore: cast_nullable_to_non_nullable
                  as List<PrayerTimeEntity>,
        settings: null == settings
            ? _self.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as PrayerSettingsEntity,
        latitude: freezed == latitude
            ? _self.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _self.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        locationName: freezed == locationName
            ? _self.locationName
            : locationName // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentOrNextPrayer: freezed == currentOrNextPrayer
            ? _self.currentOrNextPrayer
            : currentOrNextPrayer // ignore: cast_nullable_to_non_nullable
                  as PrayerTimeItem?,
        timeUntilNextPrayer: freezed == timeUntilNextPrayer
            ? _self.timeUntilNextPrayer
            : timeUntilNextPrayer // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        errorMessage: null == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String,
        isLoadingLocation: null == isLoadingLocation
            ? _self.isLoadingLocation
            : isLoadingLocation // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }

  /// Create a copy of PrayerTimesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerTimeEntityCopyWith<$Res>? get todayPrayerTimes {
    if (_self.todayPrayerTimes == null) {
      return null;
    }

    return $PrayerTimeEntityCopyWith<$Res>(_self.todayPrayerTimes!, (value) {
      return _then(_self.copyWith(todayPrayerTimes: value));
    });
  }

  /// Create a copy of PrayerTimesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrayerSettingsEntityCopyWith<$Res> get settings {
    return $PrayerSettingsEntityCopyWith<$Res>(_self.settings, (value) {
      return _then(_self.copyWith(settings: value));
    });
  }
}
