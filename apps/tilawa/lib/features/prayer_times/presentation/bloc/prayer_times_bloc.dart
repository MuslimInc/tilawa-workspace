import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../../domain/usecases/usecases.dart';
import '../../domain/value_objects/prayer_alarm_capability.dart';

part 'prayer_times_bloc.freezed.dart';

// Events
@freezed
class PrayerTimesEvent with _$PrayerTimesEvent {
  const factory PrayerTimesEvent.loadPrayerTimes() = _LoadPrayerTimes;
  const factory PrayerTimesEvent.loadMonthlyPrayerTimes({
    required int year,
    required int month,
  }) = _LoadMonthlyPrayerTimes;
  const factory PrayerTimesEvent.updateLocation() = _UpdateLocation;
  const factory PrayerTimesEvent.updateSettings(PrayerSettingsEntity settings) =
      _UpdateSettings;
  const factory PrayerTimesEvent.refreshCountdown() = _RefreshCountdown;
  const factory PrayerTimesEvent.setManualLocation({
    required double latitude,
    required double longitude,
    String? locationName,
  }) = _SetManualLocation;
  const factory PrayerTimesEvent.checkAlarmCapability() = _CheckAlarmCapability;
  const factory PrayerTimesEvent.requestExactAlarmPermission() =
      _RequestExactAlarmPermission;
}

// States
@freezed
abstract class PrayerTimesState with _$PrayerTimesState {
  const factory PrayerTimesState({
    @Default(PrayerTimesStatus.initial) PrayerTimesStatus status,
    PrayerTimeEntity? todayPrayerTimes,
    @Default([]) List<PrayerTimeEntity> monthlyPrayerTimes,
    @Default(PrayerSettingsEntity()) PrayerSettingsEntity settings,
    double? latitude,
    double? longitude,
    String? locationName,
    PrayerTimeItem? currentOrNextPrayer,
    Duration? timeUntilNextPrayer,
    @Default('') String errorMessage,
    @Default(false) bool isLoadingLocation,
    PrayerAlarmCapability? alarmCapability,
  }) = _PrayerTimesState;
}

enum PrayerTimesStatus { initial, loading, loaded, error, locationRequired }

@injectable
class PrayerTimesBloc extends Bloc<PrayerTimesEvent, PrayerTimesState> {
  PrayerTimesBloc(
    this._getPrayerTimesUseCase,
    this._getMonthlyPrayerTimesUseCase,
    this._getCurrentLocationUseCase,
    this._getCountryCodeUseCase,
    this._savePrayerSettingsUseCase,
    this._loadPrayerSettingsUseCase,
    this._schedulePrayerNotificationsUseCase,
    this._cancelPrayerNotificationsUseCase,
    this._checkPrayerAlarmCapabilityUseCase,
    this._requestExactAlarmPermissionUseCase,
  ) : super(const PrayerTimesState()) {
    on<_LoadPrayerTimes>(_onLoadPrayerTimes);
    on<_LoadMonthlyPrayerTimes>(_onLoadMonthlyPrayerTimes);
    on<_UpdateLocation>(_onUpdateLocation);
    on<_UpdateSettings>(_onUpdateSettings);
    on<_RefreshCountdown>(_onRefreshCountdown);
    on<_SetManualLocation>(_onSetManualLocation);
    on<_CheckAlarmCapability>(_onCheckAlarmCapability);
    on<_RequestExactAlarmPermission>(_onRequestExactAlarmPermission);
  }

  final GetPrayerTimesUseCase _getPrayerTimesUseCase;
  final GetMonthlyPrayerTimesUseCase _getMonthlyPrayerTimesUseCase;
  final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  final GetCountryCodeUseCase _getCountryCodeUseCase;
  final SavePrayerSettingsUseCase _savePrayerSettingsUseCase;
  final LoadPrayerSettingsUseCase _loadPrayerSettingsUseCase;
  final SchedulePrayerNotificationsUseCase _schedulePrayerNotificationsUseCase;
  // ignore: unused_field
  final CancelPrayerNotificationsUseCase _cancelPrayerNotificationsUseCase;
  final CheckPrayerAlarmCapabilityUseCase _checkPrayerAlarmCapabilityUseCase;
  final RequestExactAlarmPermissionUseCase _requestExactAlarmPermissionUseCase;

  /// Set to `true` by user-initiated handlers (settings change, location
  /// change, manual-location set) so that the next [_onLoadPrayerTimes]
  /// schedule call bypasses the same-day fingerprint dedup guard. Reset to
  /// `false` once consumed.
  bool _pendingForceReschedule = false;

  Timer? _countdownTimer;
  bool _isCountdownActive = false;

  void _startCountdownTimer() {
    if (_countdownTimer != null) {
      return;
    }

    // Ensure the timer fires right on the second boundary to avoid drift
    final now = DateTime.now();
    final delayToNextSecond = 1000 - now.millisecond;

    Future.delayed(Duration(milliseconds: delayToNextSecond), () {
      if (!_isCountdownActive || isClosed) return;

      // Fire immediately on the second mark
      add(const PrayerTimesEvent.refreshCountdown());

      // Then start periodic
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => add(const PrayerTimesEvent.refreshCountdown()),
      );
    });
  }

  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// Controls countdown refresh activity based on Prayer Times tab visibility.
  void setCountdownActive(bool isActive) {
    if (_isCountdownActive == isActive || isClosed) {
      return;
    }

    _isCountdownActive = isActive;
    if (isActive) {
      _startCountdownTimer();
      add(const PrayerTimesEvent.refreshCountdown());
    } else {
      _stopCountdownTimer();
    }
  }

  @override
  Future<void> close() {
    _stopCountdownTimer();
    return super.close();
  }

  Future<void> _onLoadPrayerTimes(
    _LoadPrayerTimes event,
    Emitter<PrayerTimesState> emit,
  ) async {
    emit(state.copyWith(status: PrayerTimesStatus.loading));

    // Load settings first
    final Either<Failure, PrayerSettingsEntity> settingsResult =
        await _loadPrayerSettingsUseCase.call();
    final PrayerSettingsEntity settings = settingsResult.fold(
      (_) => const PrayerSettingsEntity(),
      (settings) => settings,
    );

    emit(state.copyWith(settings: settings));

    // We need to use the potentially updated settings
    var effectiveSettings = settings;

    // Check for saved location or get current location
    double? latitude = settings.savedLatitude;
    double? longitude = settings.savedLongitude;
    String? locationName = settings.savedLocationName;

    if (latitude == null || longitude == null) {
      // Try to get current location
      emit(state.copyWith(isLoadingLocation: true));

      final Either<Failure, LocationResult> locationResult =
          await _getCurrentLocationUseCase.call();

      var locationFound = false;
      String? detectedCountryCode;

      await locationResult.fold(
        (failure) async {
          emit(
            state.copyWith(
              status: PrayerTimesStatus.locationRequired,
              isLoadingLocation: false,
              errorMessage: failure.message ?? 'Unknown error',
            ),
          );
        },
        (location) async {
          latitude = location.latitude;
          longitude = location.longitude;
          locationName = location.locationName;
          detectedCountryCode = location.countryCode;
          locationFound = true;
        },
      );

      emit(state.copyWith(isLoadingLocation: false));

      if (!locationFound) {
        return;
      }

      // Auto-detect calculation method if using default
      if (detectedCountryCode != null &&
          effectiveSettings.calculationMethod == CalculationMethod.ummAlQura) {
        final CalculationMethod? recommendedMethod =
            PrayerSettingsEntity.defaultForCountry(detectedCountryCode);

        if (recommendedMethod != null &&
            recommendedMethod != effectiveSettings.calculationMethod) {
          final newSettings = effectiveSettings.copyWith(
            calculationMethod: recommendedMethod,
          );
          await _savePrayerSettingsUseCase.call(settings: newSettings);
          emit(state.copyWith(settings: newSettings));
          effectiveSettings = newSettings;
        }
      }
    } else if (effectiveSettings.calculationMethod ==
        CalculationMethod.ummAlQura) {
      // Location is saved, but we might need to auto-detect method
      final String? countryCode = await _getCountryCodeUseCase.call(
        latitude: latitude,
        longitude: longitude,
      );

      if (countryCode != null) {
        final CalculationMethod? recommendedMethod =
            PrayerSettingsEntity.defaultForCountry(countryCode);

        if (recommendedMethod != null &&
            recommendedMethod != effectiveSettings.calculationMethod) {
          final newSettings = effectiveSettings.copyWith(
            calculationMethod: recommendedMethod,
          );
          await _savePrayerSettingsUseCase.call(settings: newSettings);
          emit(state.copyWith(settings: newSettings));
          effectiveSettings = newSettings;
        }
      }
    }

    if (latitude == null || longitude == null) {
      emit(
        state.copyWith(
          status: PrayerTimesStatus.locationRequired,
          errorMessage: 'Location required to calculate prayer times',
        ),
      );
      return;
    }

    // Calculate prayer times
    final Either<Failure, PrayerTimeEntity> result =
        await _getPrayerTimesUseCase.call(
          latitude: latitude!,
          longitude: longitude!,
          date: DateTime.now(),
          settings: effectiveSettings,
        );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PrayerTimesStatus.error,
          errorMessage: failure.message ?? 'Unknown error',
        ),
      ),
      (prayerTimes) {
        final PrayerTimeItem? currentOrNext = prayerTimes
            .getCurrentOrNextPrayer();
        final Duration? timeUntil = prayerTimes.getTimeUntilNextPrayer();

        emit(
          state.copyWith(
            status: PrayerTimesStatus.loaded,
            todayPrayerTimes: prayerTimes,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
            currentOrNextPrayer: currentOrNext,
            timeUntilNextPrayer: timeUntil,
          ),
        );

        // Single-source schedule trigger: every successful load triggers a
        // (deduped) reschedule. Settings/location/manual-location handlers
        // set `_pendingForceReschedule = true` before recursing here so the
        // service's same-day fingerprint guard is bypassed.
        final bool force = _pendingForceReschedule;
        _pendingForceReschedule = false;
        unawaited(
          _schedulePrayerNotificationsUseCase.call(
            settings: effectiveSettings,
            latitude: latitude!,
            longitude: longitude!,
            forceReschedule: force,
          ),
        );
      },
    );
  }

  Future<void> _onCheckAlarmCapability(
    _CheckAlarmCapability event,
    Emitter<PrayerTimesState> emit,
  ) async {
    final Either<Failure, PrayerAlarmCapability> result =
        await _checkPrayerAlarmCapabilityUseCase.call();
    result.fold(
      (_) {},
      (capability) => emit(state.copyWith(alarmCapability: capability)),
    );
  }

  Future<void> _onRequestExactAlarmPermission(
    _RequestExactAlarmPermission event,
    Emitter<PrayerTimesState> emit,
  ) async {
    await _requestExactAlarmPermissionUseCase.call();
    // Re-check capability so the UI updates after the user returns from the
    // system settings screen.
    add(const PrayerTimesEvent.checkAlarmCapability());
  }

  Future<void> _onLoadMonthlyPrayerTimes(
    _LoadMonthlyPrayerTimes event,
    Emitter<PrayerTimesState> emit,
  ) async {
    if (state.latitude == null || state.longitude == null) {
      return;
    }

    final Either<Failure, List<PrayerTimeEntity>> result =
        await _getMonthlyPrayerTimesUseCase.call(
          latitude: state.latitude!,
          longitude: state.longitude!,
          year: event.year,
          month: event.month,
          settings: state.settings,
        );

    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: failure.message ?? 'Unknown error'),
      ),
      (prayerTimes) => emit(state.copyWith(monthlyPrayerTimes: prayerTimes)),
    );
  }

  Future<void> _onUpdateLocation(
    _UpdateLocation event,
    Emitter<PrayerTimesState> emit,
  ) async {
    emit(state.copyWith(isLoadingLocation: true));

    final Either<Failure, LocationResult> locationResult =
        await _getCurrentLocationUseCase.call(forceRefresh: true);

    locationResult.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingLocation: false,
          errorMessage: failure.message ?? 'Unknown error',
        ),
      ),
      (location) {
        emit(
          state.copyWith(
            latitude: location.latitude,
            longitude: location.longitude,
            locationName: location.locationName,
            isLoadingLocation: false,
          ),
        );

        // Reload prayer times with new location; force reschedule on next
        // schedule attempt because location materially changes timings.
        _pendingForceReschedule = true;
        add(const PrayerTimesEvent.loadPrayerTimes());
      },
    );
  }

  Future<void> _onUpdateSettings(
    _UpdateSettings event,
    Emitter<PrayerTimesState> emit,
  ) async {
    await _savePrayerSettingsUseCase.call(settings: event.settings);

    emit(state.copyWith(settings: event.settings));

    // Reload prayer times with new settings; force reschedule on the next
    // schedule pass because user-edited settings must propagate immediately
    // even on the same day (bypasses the dedup fingerprint guard).
    if (state.latitude != null && state.longitude != null) {
      _pendingForceReschedule = true;
      add(const PrayerTimesEvent.loadPrayerTimes());
    }
  }

  void _onRefreshCountdown(
    _RefreshCountdown event,
    Emitter<PrayerTimesState> emit,
  ) {
    if (!_isCountdownActive) {
      return;
    }

    if (state.todayPrayerTimes == null) {
      return;
    }

    final PrayerTimeItem? currentOrNext = state.todayPrayerTimes!
        .getCurrentOrNextPrayer();
    final Duration? timeUntil = state.todayPrayerTimes!
        .getTimeUntilNextPrayer();

    // Only emit if values changed
    if (currentOrNext?.type != state.currentOrNextPrayer?.type ||
        timeUntil?.inSeconds != state.timeUntilNextPrayer?.inSeconds) {
      emit(
        state.copyWith(
          currentOrNextPrayer: currentOrNext,
          timeUntilNextPrayer: timeUntil,
        ),
      );
    }
  }

  Future<void> _onSetManualLocation(
    _SetManualLocation event,
    Emitter<PrayerTimesState> emit,
  ) async {
    emit(
      state.copyWith(
        latitude: event.latitude,
        longitude: event.longitude,
        locationName: event.locationName,
      ),
    );

    // Save location to settings
    final PrayerSettingsEntity updatedSettings = state.settings.copyWith(
      savedLatitude: event.latitude,
      savedLongitude: event.longitude,
      savedLocationName: event.locationName,
    );

    await _savePrayerSettingsUseCase.call(settings: updatedSettings);
    emit(state.copyWith(settings: updatedSettings));

    // Reload prayer times; manual location overrides force a reschedule.
    _pendingForceReschedule = true;
    add(const PrayerTimesEvent.loadPrayerTimes());
  }
}
