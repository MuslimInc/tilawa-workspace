import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_current_location_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_location_name_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_prayer_times_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/save_prayer_settings_use_case.dart';
import 'package:tilawa_core/core.dart';

import '../../domain/entities/home_dashboard.dart';
import '../../domain/entities/home_prayer_day_boundaries.dart';
import '../../domain/entities/home_prayer_slot.dart';
import '../../domain/repositories/home_dashboard_repository.dart';

typedef HomeDashboardNow = DateTime Function();

/// Composes Home data from auth and prayer-time domain services.
final class HomeDashboardRepositoryImpl implements HomeDashboardRepository {
  const HomeDashboardRepositoryImpl({
    required this._getCurrentUser,
    required this._loadPrayerSettings,
    required this._getCurrentLocation,
    required this._getLocationName,
    required this._getPrayerTimes,
    required this._savePrayerSettings,
    this._now = DateTime.now,
  });

  final GetCurrentUserUseCase _getCurrentUser;
  final LoadPrayerSettingsUseCase _loadPrayerSettings;
  final GetCurrentLocationUseCase _getCurrentLocation;
  final GetLocationNameUseCase _getLocationName;
  final GetPrayerTimesUseCase _getPrayerTimes;
  final SavePrayerSettingsUseCase _savePrayerSettings;
  final HomeDashboardNow _now;

  @override
  Future<HomeDashboard> getDashboard({String? localeIdentifier}) async {
    final DateTime generatedAt = _now();
    final _HomeUserProfile? profile = _currentUserProfile();
    final PrayerSettingsEntity settings = await _loadSettings();
    final _HomeLocation? location = await _resolveLocation(
      settings,
      localeIdentifier: localeIdentifier,
    );

    return _composeDashboard(
      generatedAt: generatedAt,
      displayName: profile?.displayName,
      photoUrl: profile?.photoUrl,
      settings: settings,
      location: location,
    );
  }

  @override
  Future<HomeDashboard> refreshLocation({String? localeIdentifier}) async {
    final Either<Failure, LocationResult> result = await _getCurrentLocation(
      forceRefresh: true,
      allowOpenSettings: true,
      requestIfDenied: true,
      localeIdentifier: localeIdentifier,
    );

    return result.fold(
      (failure) => throw HomeDashboardLocationRefreshException(
        failure.message ?? 'Location refresh failed',
      ),
      (location) async {
        final DateTime generatedAt = _now();
        final _HomeUserProfile? profile = _currentUserProfile();
        final PrayerSettingsEntity settings = await _persistGpsLocation(
          await _loadSettings(),
          location,
        );
        final String? label = await _localizedLocationLabel(
          latitude: location.latitude,
          longitude: location.longitude,
          fallback: location.locationName,
          localeIdentifier: localeIdentifier,
        );
        final _HomeLocation homeLocation = _HomeLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          label: label,
        );

        return _composeDashboard(
          generatedAt: generatedAt,
          displayName: profile?.displayName,
          photoUrl: profile?.photoUrl,
          settings: settings,
          location: homeLocation,
        );
      },
    );
  }

  Future<HomeDashboard> _composeDashboard({
    required DateTime generatedAt,
    required String? displayName,
    required String? photoUrl,
    required PrayerSettingsEntity settings,
    required _HomeLocation? location,
  }) async {
    if (location == null) {
      return HomeDashboard(
        generatedAt: generatedAt,
        displayName: displayName,
        photoUrl: photoUrl,
        locationLabel: settings.effectiveSchedulingLocationName,
      );
    }

    final _HomePrayerSnapshot? prayerSnapshot = await _loadPrayerSnapshot(
      settings: settings,
      location: location,
      generatedAt: generatedAt,
    );

    return HomeDashboard(
      generatedAt: generatedAt,
      displayName: displayName,
      photoUrl: photoUrl,
      locationLabel: location.label,
      nextPrayer: prayerSnapshot?.nextPrayer,
      prayerBoundaries: prayerSnapshot?.boundaries,
      todayPrayers: prayerSnapshot?.todayPrayers ?? const [],
    );
  }

  _HomeUserProfile? _currentUserProfile() {
    final user = _getCurrentUser();
    if (user == null) {
      return null;
    }
    return _HomeUserProfile(
      displayName: user.displayName.trimOrNull,
      photoUrl: user.photoUrl.trimOrNull,
    );
  }

  Future<PrayerSettingsEntity> _persistGpsLocation(
    PrayerSettingsEntity settings,
    LocationResult location,
  ) async {
    final PrayerSettingsEntity updatedSettings = settings.copyWith(
      savedLatitude: location.latitude,
      savedLongitude: location.longitude,
      savedLocationName: location.locationName,
      lastResolvedLatitude: location.latitude,
      lastResolvedLongitude: location.longitude,
      lastResolvedLocationName: location.locationName,
    );
    final Either<Failure, void> result = await _savePrayerSettings(
      settings: updatedSettings,
    );
    return result.fold((_) => settings, (_) => updatedSettings);
  }

  Future<PrayerSettingsEntity> _loadSettings() async {
    final Either<Failure, PrayerSettingsEntity> result =
        await _loadPrayerSettings();
    return result.fold((_) => const PrayerSettingsEntity(), (settings) {
      return settings;
    });
  }

  Future<_HomeLocation?> _resolveLocation(
    PrayerSettingsEntity settings, {
    String? localeIdentifier,
  }) async {
    final double? latitude = settings.effectiveSchedulingLatitude;
    final double? longitude = settings.effectiveSchedulingLongitude;
    if (latitude != null && longitude != null) {
      final String? label = await _localizedLocationLabel(
        latitude: latitude,
        longitude: longitude,
        fallback: settings.effectiveSchedulingLocationName,
        localeIdentifier: localeIdentifier,
      );
      return _HomeLocation(
        latitude: latitude,
        longitude: longitude,
        label: label,
      );
    }

    final Either<Failure, LocationResult> result = await _getCurrentLocation(
      requestIfDenied: false,
      localeIdentifier: localeIdentifier,
    );
    return result.fold((_) => null, (location) {
      return _HomeLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        label: location.locationName,
      );
    });
  }

  Future<String?> _localizedLocationLabel({
    required double latitude,
    required double longitude,
    required String? fallback,
    required String? localeIdentifier,
  }) async {
    if (localeIdentifier == null || localeIdentifier.isEmpty) {
      return fallback;
    }

    final String? localized = await _getLocationName(
      latitude: latitude,
      longitude: longitude,
      localeIdentifier: localeIdentifier,
    );
    return localized ?? fallback;
  }

  Future<_HomePrayerSnapshot?> _loadPrayerSnapshot({
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
      final HomePrayerDayBoundaries boundaries =
          HomePrayerDayBoundaries.fromPrayerTimes(prayerTimes);
      final PrayerTimeItem? item = _nextPrayerFor(prayerTimes, generatedAt);
      final HomeNextPrayer? nextPrayer = switch (item) {
        null => null,
        final prayer => HomeNextPrayer(
          type: prayer.type,
          time: prayer.time,
          timeUntil: prayer.time.difference(generatedAt),
        ),
      };
      final List<HomePrayerSlot> todayPrayers = _todayPrayerSlots(
        prayerTimes: prayerTimes,
        now: generatedAt,
        nextType: nextPrayer?.type,
      );
      return _HomePrayerSnapshot(
        nextPrayer: nextPrayer,
        boundaries: boundaries,
        todayPrayers: todayPrayers,
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

  List<HomePrayerSlot> _todayPrayerSlots({
    required PrayerTimeEntity prayerTimes,
    required DateTime now,
    required PrayerType? nextType,
  }) {
    return [
      for (final PrayerTimeItem prayer in prayerTimes.mainPrayers)
        HomePrayerSlot(
          type: prayer.type,
          time: prayer.time,
          isNext: prayer.type == nextType,
          hasPassed: !prayer.time.isAfter(now),
        ),
    ];
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

final class _HomePrayerSnapshot {
  const _HomePrayerSnapshot({
    required this.nextPrayer,
    required this.boundaries,
    required this.todayPrayers,
  });

  final HomeNextPrayer? nextPrayer;
  final HomePrayerDayBoundaries boundaries;
  final List<HomePrayerSlot> todayPrayers;
}

final class _HomeUserProfile {
  const _HomeUserProfile({
    required this.displayName,
    required this.photoUrl,
  });

  final String? displayName;
  final String? photoUrl;
}

/// Thrown when the user-initiated home location refresh fails.
final class HomeDashboardLocationRefreshException implements Exception {
  const HomeDashboardLocationRefreshException(this.message);

  final String message;

  @override
  String toString() => message;
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
