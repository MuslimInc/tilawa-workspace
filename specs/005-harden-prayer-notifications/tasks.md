# Tasks: Hardening Android Prayer Notifications

**Feature Branch**: `005-harden-prayer-notifications` | **Date**: 2026-05-02
**Source Plan**: [plan.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/005-harden-prayer-notifications/plan.md)

## Implementation Strategy
We follow a "Native-First" approach to ensure maximum reliability during Direct Boot. The implementation starts with the storage split, followed by the boot re-arming logic, and finally the observability hardening. Each phase delivers a testable increment on a real device.

## Phase 1: Setup
- [ ] T001 Initialize feature branch and project structure for hardening
- [ ] T002 Configure `AndroidManifest.xml` with `android:directBootAware="true"` for `PrayerBootReceiver`

## Phase 2: Foundational (Split Storage)
These tasks establish the split storage architecture required for Direct Boot survival.

- [ ] T003 [P] Implement `prayer_adhan_boot` DPS storage context in `apps/tilawa/android/app/src/main/kotlin/com/tilawa/app/prayer/DefaultPrayerImplementations.kt`
- [ ] T004 [P] Update `DefaultPrayerStorage` to use `cpsPrefs` (CPS) and `dpsPrefs` (DPS) for specific keys
- [ ] T005 [P] Implement CPS-to-DPS migration/cleanup logic in `setPendingAlarmsJson`
- [ ] T006 Add unit test for `DefaultPrayerStorage` split storage and migration logic

## Phase 3: [US1] Direct Boot & Boot Re-arming
**Goal**: Ensure alarms fire after a reboot without user unlock.
**Test**: Reboot physical device -> stay at lock screen -> verify Adhan plays.

- [ ] T007 [US1] Update `AdhanScheduler` constants to include `EXTRA_SOUND`
- [ ] T008 [US1] Modify `BootLogic.kt` to parse the new DPS JSON schema (id, prayer, trigger, sound)
- [ ] T009 [US1] Update `BootLogic.reArmAlarms` to pass the `sound` parameter to the scheduler
- [ ] T010 [US1] Add unit test for `BootLogic` parsing both old and new JSON schemas
- [ ] T011 [US1] Verify native re-arming fires successfully in Direct Boot mode on a physical device

## Phase 4: [US2] OEM Survival & Observability
**Goal**: Survive aggressive background kills and log lifecycle metrics.
**Test**: Verify "Service Killed" detection and full 3-min playback on OPPO device.

- [ ] T012 [US2] Add `TRIGGER_DELTA` and `SERVICE_START_LATENCY` metrics to `AdhanPlaybackService.kt`
- [ ] T013 [US2] Implement `completedSuccessfully` flag and `SERVICE_KILLED` log in `AdhanPlaybackService.onDestroy`
- [ ] T014 [US2] Update `AdhanPlaybackService` to use dynamic sound resource loading with fallback to `R.raw.adhan`
- [ ] T015 [US2] Add unit test for missing sound resource fallback logic
- [ ] T016 [US2] Verify 3-minute playback survival on an OPPO A98 5G with battery optimization ON

## Phase 5: [US3] Permission Revocation
**Goal**: Automatically cancel native alarms when notifications are disabled.
**Test**: Disable notification permission -> verify native alarm list is empty.

- [ ] T017 [US3] Implement native cleanup check in `AdhanScheduler.cancelAll` for permission revocation
- [ ] T018 [US3] Verify that revoking notification permissions cancels all pending native alarms

## Phase 6: Polish & Verification
- [ ] T019 Final code review of native Kotlin implementation for memory leaks (e.g. WakeLocks)
- [ ] T020 Run full high-impact QA matrix and document results in `walkthrough.md`

## Dependencies
- US1 depends on Phase 2 (Split Storage)
- US2 depends on US1 (for scheduled context)
- US3 is independent but recommended after US1/US2

## Parallel Execution Examples
- T003, T004, T005 can be implemented in parallel within the storage layer.
- T012, T013, T014 can be implemented in parallel within the playback service.
