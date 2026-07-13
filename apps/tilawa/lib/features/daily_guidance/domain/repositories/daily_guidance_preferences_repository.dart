import '../entities/daily_guidance_preferences.dart';

/// Domain contract for user preference persistence.
abstract class DailyGuidancePreferencesRepository {
  /// Loads the current preferences.
  Future<DailyGuidancePreferences> getPreferences();

  /// Saves updated preferences.
  Future<void> savePreferences(DailyGuidancePreferences preferences);

  /// Clears all preferences (reset to defaults).
  Future<void> clearPreferences();
}
