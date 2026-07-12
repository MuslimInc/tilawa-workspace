# Tasks & Traceability: Core Trust & Reliability

## Requirement-to-Task Traceability Matrix

| Requirement ID | Task IDs | Test Coverage |
|---|---|---|
| FR-001 (Build Hash) | T-Q00, T-Q01 | CI pipeline asserts |
| FR-006 (Exact Alarm) | T-A00, T-A01 | Baseline architecture tests |
| FR-008 (Health UI) | T-A02 | `adhan_health_check_viewed` |
| FR-015 (Loc State Machine)| T-L01, T-L02 | `state_machine_test.dart` |
| FR-016 (Offline DB) | T-L00, T-L03 | ADR Approval |

## Phase 1: Foundational Audits and ADRs (DO THESE FIRST)
- [ ] **T-A00**: `apps/tilawa/android/app/src/test/kotlin/` - Audit and characterize the existing Athan scheduling (WorkManager, `PrayerBootReceiver`). Document exact baseline tests and log behavior for schedule creation, OS acceptance, and trigger success.
- [ ] **T-L00**: `specs/043-core-trust-and-reliability/adr-offline-city-db.md` - Create and approve the offline location data ADR covering SQLite/JSON, licensing, size, and performance.
- [ ] **T-L01**: `apps/tilawa/test/features/location/` - Implement tests for the location-resolution state machine (Permission Denied -> Manual Fallback) before creating persistence or UI.
- [ ] **T-Q00**: `scripts/audit_quran_pipeline.dart` - Audit the Quran content and asset-generation pipeline against the authoritative QCF v4 source. Verify Surah/Ayah mapping.
- [ ] **T-Q01**: `scripts/generate_quran_manifest.dart` - Implement build-time Quran integrity validation and CI tests.

## Phase 2: Location Fallback (Unblocks Users)
- [ ] **T-L02**: `apps/tilawa/assets/data/` - Implement the offline database format chosen in T-L00 ADR.
- [ ] **T-L03**: `apps/tilawa/lib/features/location/data/offline_city_repository.dart` - Implement querying logic according to ADR.
- [ ] **T-L04**: `apps/tilawa/lib/features/location/presentation/manual_city_sheet.dart` - UI for searching and selecting.

## Phase 3: Athan Reliability Hardening
- [ ] **T-A01**: `apps/tilawa/lib/features/prayer_times/data/adhan_permission_handler.dart` - Implement observable permission-state handling, including fallback behavior and user education for `canScheduleExactAlarms()`.
- [ ] **T-A02**: `apps/tilawa/lib/features/prayer_times/presentation/screens/adhan_health_check_screen.dart` - Diagnostic UI providing explicit degraded modes and actionable deep-links to OS settings.
- [ ] **T-A03**: `apps/tilawa/lib/features/prayer_times/` - Add discrete observability events for scheduling, trigger, notification presentation, and audio playback stages.

## Phase 4: Quran Integrity
- [ ] **T-Q02**: `apps/tilawa/lib/features/quran/data/quran_validation_service.dart` - Implement lightweight post-update validation utilizing `contracts/quran-validation-result.md`.
- [ ] **T-Q03**: `apps/tilawa/lib/features/quran/presentation/dialogs/report_error_dialog.dart` - Privacy-safe user reporting flow.
