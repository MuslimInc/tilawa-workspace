# Data Models: Core Trust & Reliability

## 1. Location Fallback
- **Entity**: `CityOffline`
- **Fields**: `id` (int), `nameAr` (String), `nameEn` (String), `lat` (double), `lng` (double), `timezone` (String).
- **Persistence**: Read-only from `assets/data/cities.db`.
- **Privacy**: User's selected manual location is stored in `SharedPreferences` (`prefs_manual_location_id`). It is classified as **Pii-Sensitive** but since it's city-level, it's safer than exact GPS. Analytics must ONLY log `country_code` and `city_id`, NOT lat/lng.

## 2. Athan Reliability
- **Entity**: `PrayerDiagnosticState`
- **Fields**: `hasExactAlarmPerm` (bool), `hasNotificationPerm` (bool), `isBatteryOptimized` (bool), `systemVolume` (double).
- **Persistence**: Ephemeral, fetched at runtime.

## 3. Quran Integrity
- **Entity**: `QuranManifest`
- **Fields**: `version` (String), `files` (Map<String, String> mapping filename to sha256).
- **Persistence**: Bundled `assets/quran_manifest.json`. Checked at runtime.
- **Migration**: Version updates replace the manifest. Any local user bookmarks must map to Ayah IDs independently of the underlying text DB version to avoid breaking on migration.
