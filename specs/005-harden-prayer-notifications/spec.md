# Feature Specification: Hardening Android Prayer Notifications

**Feature Branch**: `005-harden-prayer-notifications`  
**Created**: 2026-05-02  
**Status**: Draft  
**Input**: User description: "Harden Android prayer notifications and implement Direct Boot support"

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
