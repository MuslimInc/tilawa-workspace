# Research: Android Prayer Notification Hardening

## Comparison with HisnAlmuslim APK

We analyzed the `HisnAlmuslim` APK (path: `apks/HisnAlmuslim`) to benchmark our background notification implementation.

### Key Findings

| Area | HisnAlmuslim | Tilawa (Current) | Comparison |
| :--- | :--- | :--- | :--- |
| **Notification Engine** | `flutter_local_notifications` | Custom Native + FLN Fallback | **Tilawa is stronger**; custom native playback service allows for long-duration audio and better system priority. |
| **Exact Alarms** | `setExactAndAllowWhileIdle` | `setAlarmClock` | **Tilawa is stronger**; `setAlarmClock` is the highest-priority alarm type on Android. |
| **Audio Playback** | Notification Channel Sound | **Foreground Service (mediaPlayback)** | **Tilawa is stronger**; notification sounds are often capped at 30s. Tilawa supports full Adhan. |
| **Boot Recovery** | `BootReceiver` | **Native Boot re-arm** | **Equivalent intent**, but Tilawa's current implementation is not yet Direct Boot aware. |

### Technical Risks

1. **Direct Boot**: Current implementation uses `credential-protected storage`, which is inaccessible before the first unlock after reboot. This breaks overnight Fajr notifications if a system update reboots the phone.
2. **OEM Constraints**: OPPO/ColorOS devices are extremely aggressive. Standard background services are often killed within 60 seconds. We must use `mediaPlayback` type foreground services to survive.
3. **Storage Split**: Mixing boot-time data and runtime data in one storage file can cause "split-brain" scenarios or data corruption.

## Proposed Technical Approach

### 1. Split Storage (CPS vs DPS)
* **DPS (Device-Protected Storage)**: Minimal JSON file (`prayer_adhan_boot`) containing only `(id, prayer, trigger_ms, sound)`.
* **CPS (Credential-Protected Storage)**: Full user preferences and complex prayer configurations.

### 2. Native Re-arming logic
* A native Kotlin receiver that handles `LOCKED_BOOT_COMPLETED` and `BOOT_COMPLETED`.
* It reads the DPS manifest and re-schedules alarms via `AlarmManager` without launching the Flutter engine.

### 3. Observability Hooks
* We will implement a "Start-to-Completion" metric to detect if the service was killed by the system early.
* `trigger_delta` metric to detect OS throttling (scheduled vs actual trigger time).
