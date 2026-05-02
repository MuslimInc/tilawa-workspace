# Tasks: Hardening Android Prayer Notifications

**Feature Branch**: `005-harden-prayer-notifications` | **Date**: 2026-05-02
**Source Plan**: [plan.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/005-harden-prayer-notifications/plan.md)

## Implementation Strategy
Implementation is **COMPLETED**. All native and Flutter tasks have been executed and verified via automated test suites. The branch is now frozen for Physical QA.

> [!IMPORTANT]
> **FREEZE NOTE**: This branch is frozen. No further code changes are permitted.

- [x] T001 Initialize feature branch and project structure for hardening
- [x] T002 Configure `AndroidManifest.xml` with `android:directBootAware="true"` for `PrayerBootReceiver`
- [x] T003 [P] Implement `prayer_adhan_boot` DPS storage context
- [x] T004 [P] Update `DefaultPrayerStorage` to use `cpsPrefs` (CPS) and `dpsPrefs` (DPS)
- [x] T005 [P] Implement CPS-to-DPS migration/cleanup logic
- [x] T006 Add unit test for `DefaultPrayerStorage` split storage
- [x] T007 [US1] Update `AdhanScheduler` constants
- [x] T008 [US1] Modify `BootLogic.kt` to parse the new DPS JSON schema
- [x] T009 [US1] Update `BootLogic.reArmAlarms`
- [x] T010 [US1] Add unit test for `BootLogic`
- [x] T011 [US1] Verify native re-arming fires successfully (Automated)
- [x] T012 [US2] Add `TRIGGER_DELTA` and `SERVICE_START_LATENCY` metrics
- [x] T013 [US2] Implement `completedSuccessfully` flag and `SERVICE_KILLED` log
- [x] T014 [US2] Update `AdhanPlaybackService` sound resource loading
- [x] T015 [US2] Add unit test for sound fallback
- [x] T016 [US2] Verify 3-minute playback survival (Automated)
- [x] T017 [US3] Implement native cleanup check
- [x] T018 [US3] Verify notification permission revocation (Automated)
- [x] T019 Final code review of native Kotlin implementation
- [x] T020 Run full automated test suites (Flutter & Native)

## Verification Status
- **Implementation**: Completed
- **Automated Tests**: PASSED
- **Physical QA**: PENDING
- **Frozen commit**: `<TO_BE_FILLED_AFTER_COMMIT>`
