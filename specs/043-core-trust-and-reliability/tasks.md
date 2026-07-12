# Tasks & Traceability: Core Trust & Reliability

## Requirement-to-Task Traceability Matrix
Research IDs (K##) reference Khatmah review rows in `research.md` §4. **Preventive** rows
are labeled; they carry no confirmed MeMuslim defect.

| Requirement ID | Research IDs | Task IDs | Test Coverage | Class |
|---|---|---|---|---|
| FR-001 (Build hash, text/glyph) | K12,K22,K34,K45 | T-Q00, T-Q01 | CI pipeline asserts | PREV |
| FR-001a (**CDN font integrity**) | K12,K22 | T-Q04 (new) | Post-download hash test | PREV |
| FR-002 (Runtime val + failure matrix) | K12,K45 | T-Q02 | Post-update check | PREV |
| FR-003a (**Ayah/surah numbering**) | K46 | T-Q00, T-Q01 | CI index asserts | PREV |
| FR-003b (**Juz/Hizb/page boundary**) | K27 | T-Q00, T-Q01 | CI boundary asserts | PREV (data; plan=Spec 023) |
| FR-004 (Immutable) | — | T-Q00 | Code review / Arch | PREV |
| FR-005 (Report UI) | K45,K46,K28 | T-Q03 | `report_error_dialog.dart` | GAP |
| FR-006 (Exact Alarm) | K16,K29,K42 | T-A00, T-A01 | Extend existing arch tests | PART |
| FR-007 (Receivers) | K42,K44 | T-A00, T-A01 | Extend existing tests | PART |
| FR-008 (Health UI + timing diag) | K19,K25,K36 | T-A02 | `adhan_health_check_viewed` | GAP |
| FR-009 (Audio Focus / completion) | K33 | T-A03 | Audio playback tests | PREV |
| FR-011 (iOS Notifications) | K04 | T-A00 | iOS limitations | PART |
| FR-012 (iOS Audio, abridged file — **missing from repo**) | — | T-A04 (new) | Provisioning task | GAP |
| FR-013 (iOS Timezone) | — | T-A00 | Background refresh | PART |
| FR-014 (iOS Expectations) | — | T-A02 | UI disclaimers | PART |
| FR-015 (Loc State Machine) | K13 | T-L01, T-L02 | `state_machine_test.dart` | GAP |
| FR-016 (Offline DB — ADR **Accepted**) | K13 | T-L02, T-L03 | `cities_prototype.db` exists | GAP |
| FR-017 (Offline Boot) | K13 | T-L01 | State machine test | GAP |
| GOV-001 (Quran codeowners — corrected path) | K12,K45 | T-Q01 | Repository config | PREV |
| GOV-002 (Quran kill switch) | K12 | T-Q02 | Firebase Remote Config | PREV |
| GOV-003 (**Athkar content governance**) | K15 | T-Q05 (new) | Codeowners + kill switch | PREV |
| OFF-001 (Zero Network; font DL exempt) | K13 | T-L02, T-Q02 | Unit tests | — |
| PERF-001 (post-update async, not cold start) | — | T-Q02 | Performance benchmarks | — |

## Phase 1: Foundational Audits and ADRs (DO THESE FIRST)
- [ ] **T-A00**: `apps/tilawa/android/app/src/test/kotlin/` - **Extend** the existing Athan characterization (`PrayerWatchdogCharacterizationTest.kt`, `AdhanSchedulerTest.kt`, `PrayerBootReceiverTest.kt` already exist) with long-run (7–14 day) delivery, boot, timezone, and battery-optimization scenarios. *(Corrected: baseline tests already exist — this task audits/extends, it does not create them.)*
- [x] **T-L00**: `specs/043-core-trust-and-reliability/adr-offline-city-db.md` - Offline location data ADR. **Accepted** — GeoNames/SQLite; prototype `cities_prototype.db` built and measured.
- [ ] **T-L01**: `apps/tilawa/test/features/location/` - Implement tests for the location-resolution state machine (Permission Denied -> Manual Fallback) before creating persistence or UI.
- [ ] **T-Q00**: `scripts/audit_quran_pipeline.dart` - Audit the **actual** Quran assets (`assets/data/quran.json`, `quran_image` JSON, `quran_qcf` fonts — NOT a nonexistent `quran.db`) against QCF v4. Verify text, ayah/surah numbering (FR-003a), and Juz/Hizb boundaries (FR-003b).
- [ ] **T-Q01**: `scripts/generate_quran_manifest.dart` (**already scaffolded in repo**) - Complete build-time integrity manifest over the real bundled assets + CI tests.

## Phase 2: Location Fallback (Unblocks Users)
- [ ] **T-L02**: `apps/tilawa/assets/data/` - Implement the offline database format chosen in T-L00 ADR.
- [ ] **T-L03**: `apps/tilawa/lib/features/location/data/offline_city_repository.dart` - Implement querying logic according to ADR.
- [ ] **T-L04**: `apps/tilawa/lib/features/location/presentation/manual_city_sheet.dart` - UI for searching and selecting.

## Phase 3: Athan Reliability Hardening
- [ ] **T-A01**: `apps/tilawa/lib/features/prayer_times/data/adhan_permission_handler.dart` - Implement observable permission-state handling, including fallback behavior and user education for `canScheduleExactAlarms()`.
- [ ] **T-A02**: `apps/tilawa/lib/features/prayer_times/presentation/screens/adhan_health_check_screen.dart` - Diagnostic UI: permission/battery states + **timing diagnostics** (system time, timezone, calc method, per-prayer offset) for late-adhan reports (K19,K25,K36).
- [ ] **T-A03**: `apps/tilawa/lib/features/prayer_times/` - Add discrete observability events for scheduling, trigger, notification presentation, and audio playback stages.
- [ ] **T-A04** (**new, FR-012**): Provision the iOS abridged (<30s) Athan audio in a supported format (`.caf`/`.aiff`/`.wav`) — currently missing from the repo; hard iOS release blocker.

## Phase 4: Quran & Content Integrity
- [ ] **T-Q02**: `apps/tilawa/lib/features/quran/data/quran_validation_service.dart` - Implement lightweight post-update validation utilizing `contracts/quran-validation-result.md` and the **failure-reason → behavior matrix** (FR-002).
- [ ] **T-Q03**: `apps/tilawa/lib/features/quran/presentation/dialogs/report_error_dialog.dart` - Privacy-safe user reporting flow (K45,K46,K28).
- [ ] **T-Q04** (**new, FR-001a**): Verify the **downloaded QCF page-font archive** against manifest hashes post-download, fail-closed to bundled Uthmanic fallback in `packages/quran_qcf/.../quran_font_service.dart`.
- [ ] **T-Q05** (**new, GOV-003**): Athkar/Dua content governance — dual codeowner sign-off, per-item source references, and a Remote Config content kill switch (K15). Distinct from the Quran pipeline.

## Phase 5: Cross-spec follow-ups (owned elsewhere — tracked, not implemented in 043)
- **Spec 041**: add a **Khatma/Wird-progress widget** (K48,K51) fed by Spec 023 `KhatmaTodayTarget` — the strongest currently unowned retention opportunity observed in this extremes-only review sample (cannot estimate total market demand).
- **Spec 023**: amend for a **gentle adherence streak** (K51) and **continue-listening** progress (K35); keep non-punitive.
