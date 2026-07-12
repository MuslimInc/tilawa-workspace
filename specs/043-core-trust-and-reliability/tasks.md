# Tasks & Traceability: Core Trust & Reliability

## Requirement-to-Task Traceability Matrix

| Requirement ID | Task IDs | Test Coverage | QA Coverage | Rollout / Monitoring |
|---|---|---|---|---|
| FR-001 (Build Hash) | T-Q01, T-Q02 | `test/integrity/build_hash_test.dart` | N/A | N/A |
| FR-002 (Runtime Val) | T-Q03 | `test/integrity/runtime_val_test.dart` | Trigger corruption manually | Firebase Crashlytics |
| FR-006 (Exact Alarm) | T-A01, T-A02 | `test/prayer/exact_alarm_test.dart` | Test on Android 12+ physical device | `adhan_scheduled` event |
| FR-008 (Health UI) | T-A03, T-A04 | `test/prayer/health_cubit_test.dart` | Verify deep links | `adhan_health_check_viewed` |
| FR-014 (Loc State Machine) | T-L01, T-L02 | `test/location/state_machine_test.dart` | Deny GPS -> search city | `location_manual_selected` |
| FR-015 (Offline DB) | T-L03, T-L04 | `test/location/offline_repo_test.dart` | Airplane mode | N/A |

## Phase 1: Location Fallback
- [ ] **T-L01**: `apps/tilawa/assets/data/cities.db` - Add compressed SQLite offline city database.
- [ ] **T-L02**: `apps/tilawa/lib/features/location/domain/location_state_machine.dart` - Implement the state machine handling missing/denied GPS.
- [ ] **T-L03**: `apps/tilawa/lib/features/location/data/offline_city_repository.dart` - Implement querying logic.
- [ ] **T-L04**: `apps/tilawa/lib/features/location/presentation/manual_city_sheet.dart` - UI for searching and selecting.

## Phase 2: Athan Reliability
- [ ] **T-A01**: `apps/tilawa/android/app/src/main/AndroidManifest.xml` - Add `SCHEDULE_EXACT_ALARM`.
- [ ] **T-A02**: `apps/tilawa/lib/features/prayer_times/data/android_exact_alarm_scheduler.dart` - Implement scheduling.
- [ ] **T-A03**: `apps/tilawa/lib/features/prayer_times/presentation/cubit/adhan_health_cubit.dart` - Expose permissions state.
- [ ] **T-A04**: `apps/tilawa/lib/features/prayer_times/presentation/screens/adhan_health_check_screen.dart` - Diagnostic UI.

## Phase 3: Quran Integrity
- [ ] **T-Q01**: `scripts/generate_quran_manifest.dart` - Dart script to hash `assets/quran/`.
- [ ] **T-Q02**: `.github/workflows/quran_integrity.yml` - CI pipeline invoking the generator and validating boundaries.
- [ ] **T-Q03**: `apps/tilawa/lib/features/quran/data/quran_integrity_validator.dart` - Runtime checker.
- [ ] **T-Q04**: `apps/tilawa/lib/features/quran/presentation/dialogs/report_error_dialog.dart` - User reporting flow.
