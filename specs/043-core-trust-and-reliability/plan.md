# Implementation Plan: Core Trust & Reliability

## 1. Feature Boundaries and Architectural Justification
- **Quran Integrity**: Implemented as a build-time script and lightweight runtime checker within the existing `features/quran` bounded context.
- **Athan Reliability**: Extends the existing `features/prayer_times`. We explicitly **Keep and Harden** the existing `PrayerBootReceiver` and `PrayerNotificationsWatchdogScheduler`.
- **Location Fallback**: While currently part of `core/services/location` or `features/prayer_times`, we will establish a dedicated `features/location` bounded context for the offline city database. *Justification*: Location resolution (GPS vs Manual offline DB) is a complex state machine that feeds multiple downstream domains (Prayer Times, Qibla, Weather). It warrants its own isolated domain with clear contracts (`LocationPreference`).

## 2. Workstream Details

### Workstream 1: Athan Reliability Hardening (Existing Architecture)
- **Audit**: Run baseline tests to characterize schedule success, alarm triggers, and audio playback.
- **UI**: Add `AdhanHealthCubit` to query `canScheduleExactAlarms()` and battery optimization status, feeding into `AdhanHealthCheckScreen`.

### Workstream 2: Location Fallback
- **ADR Required**: Before adding any database, `adr-offline-city-db.md` must be approved, analyzing SQLite vs JSON, coverage, size, and licensing.
- **Implementation**: `LocationStateMachine` handles `GpsSearching`, `GpsDenied`, `ManualSelection`.

### Workstream 3: Quran Integrity
- **Build-Time**: Add `scripts/validate_quran_pipeline.dart` to assert Surah/Ayah counts and generate `quran_manifest.json`.
- **Runtime**: `QuranValidationService` runs post-update (not cold-start) to verify the manifest against the asset payload to prevent silent corruption.

## 3. Threat Model for Runtime Hashing
- *Threat*: OTA update corrupts asset bundle.
- *Mitigation*: Lightweight versioned integrity manifest checked once post-update.
- *Threat*: Malicious local manipulation of files.
- *Mitigation*: App sandbox protection; full runtime hashing rejected due to cold-start performance cost.

## 4. Rollback Strategy
- **Location**: Feature flag `enable_manual_location` disables the UI.
- **Athan**: No native architecture changes to roll back; Health UI hidden via `enable_adhan_health_ui`.
- **Quran**: Validation bypassed via `enable_quran_integrity_check`.
