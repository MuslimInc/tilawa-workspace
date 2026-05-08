# Tasks: Hardening Android Prayer Notifications

**Feature Branch**: `005-harden-prayer-notifications` | **Date**: 2026-05-02
**Source Plan**: [plan.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/005-harden-prayer-notifications/plan.md)

## Implementation Strategy
Implementation is **COMPLETED**. The branch was temporarily unfrozen on 2026-05-02 only for the notification tap / Adhan stop redirect QA blocker. The blocker fix has been implemented, verified via automated Flutter and native suites, and the branch is re-frozen for Physical QA.

> [!IMPORTANT]
> **FREEZE NOTE**: This branch is re-frozen after the targeted blocker fix. No further code changes are permitted unless physical QA finds a real blocker.

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
- [x] T021 Unfreeze only for notification tap / Adhan stop redirect QA blocker
- [x] T022 Normalize native and Flutter prayer notification tap payload keys
- [x] T023 Add native pending tap consume/ack buffering for cold-start delivery
- [x] T024 Register prayer notification handler during startup launch notification handling
- [x] T025 Route Stop from app screen through native `ACTION_STOP`
- [x] T026 Add automated coverage for native tap routing, payload parsing, buffering, and Stop action

## Verification Status
- **Implementation**: Completed
- **Automated Tests**: PASSED (`146/146` Flutter, `64/64` native Android JVM)
- **Architecture Audit Verdict**: GO
- **Production Code/Test Verdict**: GO
- **Android Release QA Verdict**: CONDITIONAL GO
- **Overall Android Release Readiness**: CONDITIONAL GO
- **Physical QA**: PARTIAL (permission-denied scenario is now PASS)
- **Limited Rollout**: Allowed under CONDITIONAL GO (do not mark full production GO yet)
- **Remaining QA Gaps**:
	- Same-target explicit AppRouter skip log is PARTIAL / not proven by current adb native method-channel simulation.
	- Reboot re-arm observability is PARTIAL (post-boot ingress seen, full re-arm/watchdog logs sparse).
- **Post-Release Technical Debt** (Not release blockers; do not refactor before release):
	- Extract notification routing state from `AppRouter` into a dedicated service.
	- Add `VibrationService` abstraction for `QiblaBloc` instead of direct plugin invocation.
	- Replace hardcoded `PrayerNotificationStatusRoute` same-target logic with generalized route matching.
	- Review `AppSystemChromeStyle` target enum if more special chrome routes appear.
- **Frozen commit**: `<TO_BE_FILLED_AFTER_COMMIT>`
