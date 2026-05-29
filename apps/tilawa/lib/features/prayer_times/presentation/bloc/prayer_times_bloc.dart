import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/entities.dart';
import '../../domain/prayer_times_clock.dart';
import '../../domain/usecases/usecases.dart';

part 'prayer_times_bloc.freezed.dart';

// Events
@freezed
class PrayerTimesEvent with _$PrayerTimesEvent {
  const factory PrayerTimesEvent.loadPrayerTimes({
    @Default(false) bool forceReschedule,
  }) = _LoadPrayerTimes;
  const factory PrayerTimesEvent.loadMonthlyPrayerTimes({
    required int year,
    required int month,
  }) = _LoadMonthlyPrayerTimes;
  const factory PrayerTimesEvent.updateLocation() = _UpdateLocation;
  const factory PrayerTimesEvent.updateSettings(PrayerSettingsEntity settings) =
      _UpdateSettings;
  const factory PrayerTimesEvent.refreshCountdown() = _RefreshCountdown;
  const factory PrayerTimesEvent.refreshIfStale() = _RefreshIfStale;
  const factory PrayerTimesEvent.setManualLocation({
    required double latitude,
    required double longitude,
    String? locationName,
  }) = _SetManualLocation;
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
    this._cancelPrayerNotificationsUseCase, [
    this._shouldRefreshPrayerTimesUseCase =
        const ShouldRefreshPrayerTimesUseCase(),
  ]) : super(const PrayerTimesState()) {
    on<_LoadPrayerTimes>(_onLoadPrayerTimes);
    on<_LoadMonthlyPrayerTimes>(_onLoadMonthlyPrayerTimes);
    on<_UpdateLocation>(_onUpdateLocation);
    on<_UpdateSettings>(_onUpdateSettings);
    on<_RefreshIfStale>(_onRefreshIfStale);
    on<_SetManualLocation>(_onSetManualLocation);
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
  final ShouldRefreshPrayerTimesUseCase _shouldRefreshPrayerTimesUseCase;

  Future<void> _onLoadPrayerTimes(
    _LoadPrayerTimes event,
    Emitter<PrayerTimesState> emit,
  ) async {
    if (state.status == PrayerTimesStatus.loading && !event.forceReschedule) {
      return;
    }

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

      final LocationResult? resolvedLocation = locationResult.fold<LocationResult?>(
        (failure) {
          emit(
            state.copyWith(
              status: PrayerTimesStatus.locationRequired,
              isLoadingLocation: false,
              errorMessage: failure.message ?? 'Unknown error',
            ),
          );
          return null;
        },
        (location) {
          emit(state.copyWith(isLoadingLocation: false));
          return location;
        },
      );

      if (resolvedLocation == null) {
        return;
      }

      latitude = resolvedLocation.latitude;
      longitude = resolvedLocation.longitude;
      locationName = resolvedLocation.locationName;
      final String? detectedCountryCode = resolvedLocation.countryCode;

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

      effectiveSettings = await _persistLastResolvedLocationIfNeeded(
        settings: effectiveSettings,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
      );
      emit(state.copyWith(settings: effectiveSettings));
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

    final double resolvedLatitude = latitude;
    final double resolvedLongitude = longitude;

    // Calculate prayer times
    final Either<Failure, PrayerTimeEntity> result =
        await _getPrayerTimesUseCase.call(
          latitude: resolvedLatitude,
          longitude: resolvedLongitude,
          date: PrayerTimesClock.now(),
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
        emit(
          state.copyWith(
            status: PrayerTimesStatus.loaded,
            todayPrayerTimes: prayerTimes,
            latitude: resolvedLatitude,
            longitude: resolvedLongitude,
            locationName: locationName,
          ),
        );

        unawaited(
          _schedulePrayerNotificationsUseCase.call(
            settings: effectiveSettings,
            latitude: resolvedLatitude,
            longitude: resolvedLongitude,
            forceReschedule: event.forceReschedule,
          ),
        );
      },
    );
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
        add(const PrayerTimesEvent.loadPrayerTimes(forceReschedule: true));
      },
    );
  }

  Future<void> _onUpdateSettings(
    _UpdateSettings event,
    Emitter<PrayerTimesState> emit,
  ) async {
    final oldSettings = state.settings;
    final newSettings = event.settings;

    await _savePrayerSettingsUseCase.call(settings: newSettings);
    emit(state.copyWith(settings: newSettings));

    // Only reload prayer times if calculation-affecting settings changed.
    // Otherwise, just reschedule notifications silently to avoid UI flicker.
    if (newSettings.requiresRecalculation(oldSettings)) {
      if (state.latitude != null && state.longitude != null) {
        add(const PrayerTimesEvent.loadPrayerTimes(forceReschedule: true));
      }
    } else {
      if (state.latitude != null && state.longitude != null) {
        unawaited(
          _schedulePrayerNotificationsUseCase.call(
            settings: newSettings,
            latitude: state.latitude!,
            longitude: state.longitude!,
            forceReschedule: true,
          ),
        );
      }
    }
  }

  Future<void> _onRefreshIfStale(
    _RefreshIfStale event,
    Emitter<PrayerTimesState> emit,
  ) async {
    if (state.status == PrayerTimesStatus.loading) {
      return;
    }

    final PrayerTimeEntity? prayerTimes = state.todayPrayerTimes;
    final bool shouldRefresh = _shouldRefreshPrayerTimesUseCase(
      loadedDate: prayerTimes?.date,
      loadedUtcOffset: prayerTimes?.date.timeZoneOffset,
    );

    if (!shouldRefresh) {
      return;
    }

    add(const PrayerTimesEvent.loadPrayerTimes(forceReschedule: true));
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
      lastResolvedLatitude: event.latitude,
      lastResolvedLongitude: event.longitude,
      lastResolvedLocationName: event.locationName,
    );

    await _savePrayerSettingsUseCase.call(settings: updatedSettings);
    emit(state.copyWith(settings: updatedSettings));

    // Reload prayer times; manual location overrides force a reschedule.
    add(const PrayerTimesEvent.loadPrayerTimes(forceReschedule: true));
  }

  Future<PrayerSettingsEntity> _persistLastResolvedLocationIfNeeded({
    required PrayerSettingsEntity settings,
    required double latitude,
    required double longitude,
    required String? locationName,
  }) async {
    if (settings.savedLatitude != null && settings.savedLongitude != null) {
      return settings;
    }

    if (settings.lastResolvedLatitude == latitude &&
        settings.lastResolvedLongitude == longitude &&
        settings.lastResolvedLocationName == locationName) {
      return settings;
    }

    final updatedSettings = settings.copyWith(
      lastResolvedLatitude: latitude,
      lastResolvedLongitude: longitude,
      lastResolvedLocationName: locationName,
    );
    await _savePrayerSettingsUseCase.call(settings: updatedSettings);
    return updatedSettings;
  }
}
