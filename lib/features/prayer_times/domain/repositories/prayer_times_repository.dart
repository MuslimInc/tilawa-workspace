import '../entities/prayer_settings_entity.dart';
import '../entities/prayer_time_entity.dart';

/// Repository interface for prayer times operations
abstract class PrayerTimesRepository {
  /// Get prayer times for a specific date and location
  Future<PrayerTimeEntity> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerSettingsEntity settings,
  });

  /// Get prayer times for a date range
  Future<List<PrayerTimeEntity>> getPrayerTimesForRange({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    required PrayerSettingsEntity settings,
  });

  /// Get prayer times for the current month
  Future<List<PrayerTimeEntity>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    required PrayerSettingsEntity settings,
  });

  /// Get the user's current location
  Future<LocationResult> getCurrentLocation();

  /// Get location name from coordinates
  Future<String?> getLocationName({
    required double latitude,
    required double longitude,
  });

  /// Save prayer settings
  Future<void> saveSettings(PrayerSettingsEntity settings);

  /// Load prayer settings
  Future<PrayerSettingsEntity> loadSettings();

  /// Check if location permission is granted
  Future<bool> hasLocationPermission();

  /// Request location permission
  Future<bool> requestLocationPermission();
}

/// Result class for location operations
class LocationResult {
  LocationResult({
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.error,
  });

  factory LocationResult.error(String message) =>
      LocationResult(latitude: 0, longitude: 0, error: message);

  final double latitude;
  final double longitude;
  final String? locationName;
  final String? error;

  bool get hasError => error != null;
}
