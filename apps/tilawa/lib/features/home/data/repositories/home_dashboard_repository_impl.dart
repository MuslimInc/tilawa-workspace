import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_current_location_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_prayer_times_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';
import 'package:tilawa_core/core.dart';

import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_dashboard_repository.dart';

typedef HomeDashboardNow = DateTime Function();

/// Composes Home data from auth and prayer-time domain services.
final class HomeDashboardRepositoryImpl implements HomeDashboardRepository {
  const HomeDashboardRepositoryImpl({
    required this._getCurrentUser,
    required this._loadPrayerSettings,
    required this._getCurrentLocation,
    required this._getPrayerTimes,
    this._now = DateTime.now,
  });

  final GetCurrentUserUseCase _getCurrentUser;
  final LoadPrayerSettingsUseCase _loadPrayerSettings;
  final GetCurrentLocationUseCase _getCurrentLocation;
  final GetPrayerTimesUseCase _getPrayerTimes;
  final HomeDashboardNow _now;

  @override
  Future<HomeDashboard> getDashboard() async {
    final DateTime generatedAt = _now();
    final String? displayName = _getCurrentUser()?.displayName.trimOrNull;
    final PrayerSettingsEntity settings = await _loadSettings();
    final _HomeLocation? location = await _resolveLocation(settings);

    if (location == null) {
      return HomeDashboard(
        generatedAt: generatedAt,
        displayName: displayName,
        locationLabel: settings.effectiveSchedulingLocationName,
      );
    }

    final HomeNextPrayer? nextPrayer = await _loadNextPrayer(
      settings: settings,
      location: location,
      generatedAt: generatedAt,
    );

    return HomeDashboard(
      generatedAt: generatedAt,
      displayName: displayName,
      locationLabel: location.label,
      nextPrayer: nextPrayer,
    );
  }

  Future<PrayerSettingsEntity> _loadSettings() async {
    final Either<Failure, PrayerSettingsEntity> result =
        await _loadPrayerSettings();
    return result.fold((_) => const PrayerSettingsEntity(), (settings) {
      return settings;
    });
  }

  Future<_HomeLocation?> _resolveLocation(PrayerSettingsEntity settings) async {
    final double? latitude = settings.effectiveSchedulingLatitude;
    final double? longitude = settings.effectiveSchedulingLongitude;
    if (latitude != null && longitude != null) {
      return _HomeLocation(
        latitude: latitude,
        longitude: longitude,
        label: settings.effectiveSchedulingLocationName,
      );
    }

    final Either<Failure, LocationResult> result = await _getCurrentLocation(
      requestIfDenied: false,
    );
    return result.fold((_) => null, (location) {
      return _HomeLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        label: location.locationName,
      );
    });
  }

  Future<HomeNextPrayer?> _loadNextPrayer({
    required PrayerSettingsEntity settings,
    required _HomeLocation location,
    required DateTime generatedAt,
  }) async {
    final Either<Failure, PrayerTimeEntity> result = await _getPrayerTimes(
      latitude: location.latitude,
      longitude: location.longitude,
      date: generatedAt,
      settings: settings,
    );
    return result.fold((_) => null, (prayerTimes) {
      final PrayerTimeItem? item = _nextPrayerFor(prayerTimes, generatedAt);
      if (item == null) {
        return null;
      }
      return HomeNextPrayer(
        type: item.type,
        time: item.time,
        timeUntil: item.time.difference(generatedAt),
      );
    });
  }

  PrayerTimeItem? _nextPrayerFor(PrayerTimeEntity prayerTimes, DateTime now) {
    for (final PrayerTimeItem prayer in prayerTimes.mainPrayers) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    return PrayerTimeItem(
      type: PrayerType.fajr,
      time: prayerTimes.fajr.add(const Duration(days: 1)),
    );
  }
}

final class _HomeLocation {
  const _HomeLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String? label;
}

extension on String? {
  String? get trimOrNull {
    final String? value = this;
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
