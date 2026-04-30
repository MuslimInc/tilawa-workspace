import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/entities.dart';
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
    this._cancelPrayerNotificationsUseCase,
  ) : super(const PrayerTimesState()) {
    on<_LoadPrayerTimes>(_onLoadPrayerTimes);
    on<_LoadMonthlyPrayerTimes>(_onLoadMonthlyPrayerTimes);
    on<_UpdateLocation>(_onUpdateLocation);
    on<_UpdateSettings>(_onUpdateSettings);
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
        emit(
          state.copyWith(
            status: PrayerTimesStatus.loaded,
            todayPrayerTimes: prayerTimes,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
          ),
        );

        unawaited(
          _schedulePrayerNotificationsUseCase.call(
            settings: effectiveSettings,
            latitude: latitude!,
            longitude: longitude!,
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
    add(const PrayerTimesEvent.loadPrayerTimes(forceReschedule: true));
  }
}
