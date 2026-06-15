import 'package:injectable/injectable.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../datasources/datasources.dart';
import '../services/prayer_time_calculator.dart';

@LazySingleton(as: PrayerTimesRepository)
class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  PrayerTimesRepositoryImpl(this._settingsDataSource, this._locationDataSource);

  final PrayerSettingsDataSource _settingsDataSource;
  final LocationDataSource _locationDataSource;
  final PrayerTimeCalculator _calculator = PrayerTimeCalculator();

  @override
  Future<PrayerTimeEntity> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerSettingsEntity settings,
  }) async {
    return _calculator.calculatePrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: date,
      settings: settings,
    );
  }

  @override
  Future<List<PrayerTimeEntity>> getPrayerTimesForRange({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    required PrayerSettingsEntity settings,
  }) async {
    return _calculator.calculatePrayerTimesForRange(
      latitude: latitude,
      longitude: longitude,
      startDate: startDate,
      endDate: endDate,
      settings: settings,
    );
  }

  @override
  Future<List<PrayerTimeEntity>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    required PrayerSettingsEntity settings,
  }) async {
    final startDate = DateTime(year, month);
    final endDate = DateTime(year, month + 1, 0); // Last day of month

    return _calculator.calculatePrayerTimesForRange(
      latitude: latitude,
      longitude: longitude,
      startDate: startDate,
      endDate: endDate,
      settings: settings,
    );
  }

  @override
  Future<LocationResult> getCurrentLocation({
    bool forceRefresh = false,
    String? localeIdentifier,
  }) {
    return _locationDataSource.getCurrentLocation(
      forceRefresh: forceRefresh,
      localeIdentifier: localeIdentifier,
    );
  }

  @override
  Future<String?> getLocationName({
    required double latitude,
    required double longitude,
    String? localeIdentifier,
  }) {
    return _locationDataSource.getLocationName(
      latitude,
      longitude,
      localeIdentifier: localeIdentifier,
    );
  }

  @override
  Future<String?> getCountryCode({
    required double latitude,
    required double longitude,
  }) async {
    return _locationDataSource.getCountryCode(latitude, longitude);
  }

  @override
  Future<void> saveSettings(PrayerSettingsEntity settings) async {
    await _settingsDataSource.saveSettings(settings);
  }

  @override
  Future<PrayerSettingsEntity> loadSettings() async {
    return _settingsDataSource.loadSettings();
  }

  @override
  Future<bool> hasLocationPermission() async {
    return _locationDataSource.hasPermission();
  }

  @override
  Future<bool> requestLocationPermission({
    bool allowOpenSettings = false,
  }) async {
    return _locationDataSource.requestPermission(
      allowOpenSettings: allowOpenSettings,
    );
  }
}
