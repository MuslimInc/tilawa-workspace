# Implementation Plan: Hardening Android Prayer Notifications

**Branch**: `005-harden-prayer-notifications` | **Date**: 2026-05-02 | **Spec**: [spec.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/005-harden-prayer-notifications/spec.md)
**Input**: Feature specification for hardening and Direct Boot support.

## Summary

This plan implements a hardened background notification system for prayer times on Android. The primary focus is **Direct Boot support** (firing alarms after reboot without unlocking) and **OEM reliability** (surviving OPPO/ColorOS background kills). We achieve this through a split-storage architecture and a native-only re-arming logic that bypasses the Flutter engine at boot time.

## Technical Context

**Language/Version**: Flutter 3.x, Kotlin 1.9+, Java 17
**Primary Dependencies**: Android SDK 34, Android WorkManager, Firebase Analytics
**Storage**: Split Storage (DPS for boot metadata, CPS for runtime state)
**Target Platform**: Android 8.0+ (Full Direct Boot support on 7.0+)
**Constraints**: 
- Must not launch Flutter engine during boot re-arming.
- Must fallback safely to `R.raw.adhan` if specific resources are missing.
- Must capture metrics to distinguish OS throttling from service kills.

## Constitution Check

- **Clean Architecture Boundaries**: PASS - Native layer is separated from Flutter via MethodChannels and explicit interfaces.
- **Structured Logging and Diagnostics**: PASS - Detailed metrics for trigger delays and abnormal termination are planned.
- **Testing Discipline**: PASS - Unit tests for JSON parsing and fallback logic are included.
- **Safe Refactoring and Delivery**: PASS - Split storage approach avoids breaking existing configuration.

## Project Structure

### Documentation (this feature)

```text
specs/005-harden-prayer-notifications/
├── spec.md              # Requirement definition
├── research.md          # Comparison with HisnAlmuslim and technical approach
├── data-model.md        # Split storage and intent schemas
├── plan.md              # This file
└── tasks.md             # Task breakdown (to be generated)
```

### Source Code

```text
apps/tilawa/android/app/src/main/kotlin/com/tilawa/app/prayer/
├── AdhanPlaybackService.kt  # Add observability and dynamic sound resource
├── AdhanReceiver.kt         # Add trigger metrics
├── BootLogic.kt            # Update parsing for new DPS schema
├── DefaultPrayerImplementations.kt # Implement Split Storage
├── PrayerBootReceiver.kt   # Enable directBootAware
└── AdhanScheduler.kt       # Update scheduling signatures
```

## Proposed Changes

### Phase 1: Storage and Manifest Hardening

1. **`AndroidManifest.xml`**: Update `PrayerBootReceiver` to `directBootAware="true"`.
2. **`DefaultPrayerStorage`**: Implement `cpsPrefs` and `dpsPrefs`. Move `pending_alarms_json` to `dpsPrefs`.
3. **`BootLogic`**: Update JSON parsing to handle `sound` field and derive `active_ids` from DPS manifest.

### Phase 2: Playback and Observability

1. **`AdhanPlaybackService`**: 
    - Implement `completedSuccessfully` flag.
    - Extract `EXTRA_SOUND` and use dynamic resource loading.
    - Log `TRIGGER_DELTA` and `SERVICE_START_LATENCY`.
    - Log `ABNORMAL_TERMINATION` in `onDestroy` if playback wasn't completed.
2. **`AdhanScheduler`**: Update to pass sound resource name during scheduling.

### Phase 3: Verification and QA

1. **Unit Tests**:
    - `DefaultPrayerStorageTest`: Verify split storage migration and access.
    - `BootLogicTest`: Verify parsing of old and new JSON schemas.
2. **Manual QA**: Execute the high-impact QA matrix (Direct Boot, OPPO survival, Doze).

## Final Verified Changes
- **Direct Boot + DPS/CPS Split Storage**: Robust scheduling metadata isolation in Device-Protected Storage.
- **Native Adhan Pipeline Hardening**: Improved reliability and resource management.
- **QA Persistent Logs**: File-based diagnostic logging for field debugging.
- **Firebase Observability**: High-fidelity native analytics for scheduling and playback events.
- **Notification Tap Deep Link**: Unified path from both native and local notifications.
- **Prayer/Adhan Status Screen**: Real-time status UI using Tilawa UI Kit and atomic design.
- **Stop Adhan Integration**: Native stop path invoked directly from the status screen.
- **Cold-Start Buffer**: Implementation of a pending notification tap buffer in `PrayerAdhanMethodChannel.kt` to prevent tap loss during app launch.
- **Tilawa UI Kit Compliance**: 100% adherence to design tokens and component usage.

## Final Automated Test Evidence
### Flutter Tests
- **Feature Tests**: `fvm flutter test test/features/prayer_times/` -> **102/102 PASSED**
- **Service Tests**: `fvm flutter test test/core/services/prayer_adhan_notification_service_test.dart` -> **18/18 PASSED**

### Native Android Tests
- **Command**: `./gradlew clean :app:testDebugUnitTest`
- **Status**: **PASSED**
- **Key Coverage**: Added `notifyNotificationTapped buffers if channel not registered and flushes on register` test case.

## Remaining Physical QA Blockers
- **Direct Boot**: Verified locked reboot behavior (Native re-arm).
- **Screen-Off Behavior**: Survival of foreground service on aggressive OEMs (OPPO/ColorOS).
- **App Swiped/Killed**: Playback survival and notification dismissal.
- **Playback Lifecycle**: Full completion and abnormal termination logging.
- **Permission Revocation**: Automated cleanup of pending alarms.
- **Cold-Start Taps**: Tap from killed/background/foreground states.
- **Duplicate Prevention**: Verification of navigation stack hygiene.

## Release Decision
- **Status**: **GO WITH CONDITIONS**
- **Condition**: Only eligible for limited rollout after physical smoke QA passes.
- **Full Production**: NO-GO until the full physical QA matrix passes.

**Frozen commit**: `<TO_BE_FILLED_AFTER_COMMIT>`
