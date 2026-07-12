# Implementation Plan: Core Trust & Reliability

## 1. Workstream Independence
The three domains (Quran Integrity, Athan Reliability, Location Fallback) are isolated into separate workstreams. They share basic DI but are shielded by individual feature flags.

### Workstream 1: Location Fallback
- **Data Model**: `City` (id, nameAr, nameEn, lat, lng, timezone).
- **Persistence**: `assets/data/cities.db` (SQLite).
- **Domain**: `LocationStateMachine` managing states: `Init`, `GpsSearching`, `GpsDenied`, `ManualSelection`, `Resolved`.
- **UI**: `LocationOnboardingScreen` adds "Set Manually" button triggering a bottom sheet with search.

### Workstream 2: Athan Reliability
- **Android Native**: Implement `AlarmReceiver.kt` utilizing `AlarmManager.setExactAndAllowWhileIdle`.
- **iOS Native**: Utilize `flutter_local_notifications` but constrain audio to `adhan_short_ios.caf` (under 30s).
- **Diagnostics UI**: `AdhanHealthCubit` queries `permission_handler` and `battery_plus` to display status cards with deep-links to system settings.

### Workstream 3: Quran Integrity
- **Build-Time**: Add `scripts/generate_quran_manifest.dart` executed during CI to create `quran_manifest.json`.
- **Runtime**: `QuranRepository.init()` reads the manifest, calculates the SHA-256 of the local DB using `crypto` package, and compares.
- **Emergency State**: If mismatched, `QuranCubit` yields `QuranState.integrityError` showing a safe error screen prompting an update, preventing any incorrect text display.

## 2. Rollback Strategy
- **Location**: Feature flag `enable_manual_location` disables the manual UI button.
- **Athan**: Revert to `set` instead of `setExact` via Remote Config flag `use_exact_alarms`.
- **Quran**: Feature flag `enable_quran_integrity_check` can bypass the hash check if the manifest system itself causes false positives in production.
