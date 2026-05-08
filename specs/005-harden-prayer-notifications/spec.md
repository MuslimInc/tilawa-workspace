# Feature Specification: Hardening Android Prayer Notifications

**Feature Branch**: `005-harden-prayer-notifications`  
**Created**: 2026-05-02  
**Status**: Frozen — QA Blocker Fix Completed (2026-05-02)
**Input**: User description: "Harden Android prayer notifications and implement Direct Boot support"

> [!IMPORTANT]
> **FREEZE NOTE**: This feature branch was temporarily unfrozen on 2026-05-02 only for the notification tap / Adhan stop redirect blocker. The targeted fix is complete, Flutter and native automated tests pass, and the branch is re-frozen. No further code, UI, architecture, or documentation changes should be made unless physical QA finds a real blocker.

## Final Verified Status
- **Implementation**: Completed
- **Automated Tests**: Passed (`146/146` Flutter prayer notification coverage, `64/64` native Android JVM tests)
- **Architecture Audit Verdict**: GO
- **Production Code/Test Verdict**: GO
- **Android Release QA Verdict**: CONDITIONAL GO
- **Overall Android Release Readiness**: CONDITIONAL GO (pending physical QA evidence gaps)
- **Physical QA**: Partially completed (see QA validation snapshot)
- **Branch**: Re-frozen after blocker fix
- **Limited Rollout**: Allowed under CONDITIONAL GO with follow-up closure of remaining partial QA items
- **Full Production**: Not GO yet

## QA Validation Snapshot (2026-05-08)

### Passed
- Prayer tap routing (runtime evidence)
- Athkar routing (runtime evidence)
- Duplicate tap guard (runtime evidence)
- FCM reciter routing (tests)
- FCM prayer routing without local markers (tests)
- FCM matcher excludes local prayer payloads (tests)
- Download routing (tests)
- Download payload not handled by FCM matcher (tests)
- Permission denied scenario (manual toggle + runtime capture)

### Permission Denied PASS Evidence
- `android.permission.POST_NOTIFICATIONS: granted=false`
- Notification manager app setting for `com.tilawa.app`: `importance=NONE userSet=true`
- Valid prayer deep-link/tap intent still reaches app routing path and opens prayer status.
- This behavior matches Android expectations: posting notifications is blocked when permission is denied, but explicit deep-link intent handling can still execute.

### Remaining Partial Items
1. Same-target explicit AppRouter skip log: PARTIAL / not proven.
	- Duplicate tap guard is PASS.
	- Not treated as functional failure unless a real notification tray tap reproduces duplicate navigation.
	- Current adb native method-channel simulation can remain buffered with `awaiting_dart_ack`, so the flow may not reliably reach Dart-side AppRouter skip logging.
2. Reboot re-arm observability: PARTIAL.
	- Post-boot ingress evidence improved.
	- Full re-arm/watchdog log evidence remains sparse.

### Conditions to Upgrade Android Release QA from CONDITIONAL GO to GO
1. Capture explicit same-target AppRouter skip evidence from a real system tray tap flow (`Notification navigation skipped` or `Duplicate notification navigation ignored`).
2. Capture clear, end-to-end reboot re-arm/watchdog evidence after reboot.
3. Confirm no duplicate navigation under real tray tap same-target scenarios.

### Post-Release Technical Debt
**IMPORTANT**: These items are NOT release blockers. Do not start any architecture refactor before release.
1. Extract notification routing state from `AppRouter` into a dedicated service.
2. Add `VibrationService` abstraction for `QiblaBloc` instead of direct plugin invocation.
3. Replace hardcoded `PrayerNotificationStatusRoute` same-target logic with generalized route matching.
4. Review `AppSystemChromeStyle` target enum if more special chrome routes appear.

## QA Blocker Fix - Notification Tap / Adhan Stop Redirect

**Finding**: Native Adhan notification taps and some Flutter local prayer taps could fail to open `/prayer-notification-status`, especially on cold start.

**Root cause**:
- Native Adhan tap payloads did not match Flutter's prayer notification contract (`type`, `prayer`/`prayer_name`, `scheduled_time_ms`), so Flutter could reject or fail to parse them.
- Cold-start native taps were emitted before Dart had attached the tap listener, so the pending tap could be dropped.
- Launch notification processing could mark unhandled local prayer taps as consumed before the prayer handler was initialized.
- The in-app Stop path stopped the service directly instead of sending the native `ACTION_STOP` command path.

**Fix**: Payload keys are now normalized across native and Flutter local notifications, native taps are buffered until Dart explicitly consumes/acks them, the prayer handler is registered during startup launch handling, router readiness/navigation logging was added, and app Stop now routes through the native `ACTION_STOP` foreground-service path.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reliable Adhan after Reboot (Priority: P1)

As a user, I want my Adhan notifications to fire correctly even if my phone reboots at night (e.g., due to a system update) and I haven't unlocked it yet, so that I don't miss the Fajr prayer.

**Why this priority**: Missing Fajr is a critical failure for a prayer app. Modern Android devices often reboot for updates overnight.

**Independent Test**: Can be fully tested by scheduling a prayer, rebooting the device, and staying on the lock screen (Direct Boot) until the prayer time.

**Acceptance Scenarios**:

1. **Given** a prayer is scheduled in the future, **When** the device reboots and remains at the lock screen (un-decrypted), **Then** the Adhan audio must play exactly at the scheduled time.
2. **Given** the device is in Direct Boot mode, **When** the Adhan fires, **Then** the notification must be visible and allow the user to stop the audio from the lock screen.

---

### User Story 2 - Consistent Playback on Aggressive OEMs (Priority: P1)

As a user with an OPPO, Xiaomi, or other aggressive OEM device, I want the Adhan to play for its full duration without being killed by system battery optimizations, so that I can hear the complete call to prayer.

**Why this priority**: Many users in target markets use these devices. If the system kills the service after 60 seconds, the user experience is broken.

**Independent Test**: Can be tested on an OPPO A98 5G with battery optimizations enabled.

**Acceptance Scenarios**:

1. **Given** the app is in the background and the screen is off, **When** the Adhan fires, **Then** it must play to completion (e.g., 3 minutes) without interruption.
2. **Given** the system is under RAM pressure, **When** the Adhan starts, **Then** the foreground service must maintain priority and not be terminated early.

---

### User Story 3 - Automatic Cleanup on Permission Revocation (Priority: P2)

As a user, I want the app to stop playing Adhans if I revoke notification permissions, so that I don't have "ghost" audio playing that I cannot easily stop.

**Why this priority**: Prevents user frustration and potential "malware-like" behavior where audio plays without a way to stop it.

**Independent Test**: Revoke notification permission in system settings and verify no alarms fire.

**Acceptance Scenarios**:

1. **Given** Adhan alarms are scheduled, **When** the user revokes notification permission, **Then** all pending native alarms must be cancelled.

---

### Edge Cases

- **Direct Boot Storage Isolation**: System must not attempt to access credential-protected storage (CPS) while the device is locked.
- **Clock Drift/Throttling**: Detect if the OS delayed the alarm by more than a reasonable threshold (e.g., 10 seconds).
- **Missing Sound Resource**: If the specified Adhan sound is missing or deleted, the system must fallback to a default sound instead of failing or crashing.
- **Multiple Reboots**: Repeated reboots must not result in duplicate alarms or lost scheduling state.
- **Manual Force Stop**: Acknowledge that a manual "Force Stop" by the user will clear all alarms (Standard Android behavior).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support **Direct Boot** by marking the boot receiver as `directBootAware="true"`.
- **FR-002**: System MUST use **Split Storage** architecture: minimal scheduling metadata (ID, trigger_ms, sound) in **Device-Protected Storage (DPS)**, and all other data in Credential-Protected Storage (CPS).
- **FR-003**: System MUST re-arm alarms natively at boot using the DPS manifest **without starting the Flutter engine**.
- **FR-004**: System MUST use `AlarmManager.setAlarmClock` for the highest possible scheduling priority.
- **FR-005**: System MUST play Adhan audio via a **Foreground Service** of type `mediaPlayback` to ensure survival under OEM constraints.
- **FR-006**: System MUST log high-fidelity observability metrics: `scheduled_time`, `trigger_time`, `service_start_time`, `completion_time`, and an `abnormal_termination` flag.
- **FR-007**: System MUST fallback to the default `R.raw.adhan` if a specific sound resource (e.g., `adhan_fajr`) is missing.
- **FR-008**: System MUST synchronize the DPS manifest whenever a new scheduling pass occurs in the Flutter layer.

### Key Entities

- **DPS Boot Manifest**: A JSON array stored in device-protected storage containing the minimal data for re-arming alarms.
- **Adhan Alarm**: A native `AlarmManager` entry associated with a specific prayer time.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of Fajr Adhans fire correctly after an overnight reboot in Direct Boot mode.
- **SC-002**: Adhan playback duration matches the audio file length within 1 second on OPPO/ColorOS devices.
- **SC-003**: Native re-arming logic executes in under 500ms without initializing the Dart isolate.
- **SC-004**: Observability logs successfully capture 100% of "Service Killed" events with a progress timestamp.

## Assumptions

- **Target Device**: Primary validation target is OPPO A98 5G / Android 15.
- **Device-Protected Storage**: Available on all target devices (Android 7.0+).
- **Native Implementation**: Kotlin-based native layer is preferred for this hardening work.
- **No Dart isolates at boot**: Re-arming is strictly a native-to-native operation to maximize reliability and speed.
