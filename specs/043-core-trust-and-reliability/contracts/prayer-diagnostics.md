# Contract: Prayer Diagnostics

**Status**: Active
**Version**: 1.0.0
**Privacy Classification**: Diagnostic / Non-PII

## Purpose
Defines the state structure used by the `AdhanHealthCubit` to communicate device capability and permission status to the diagnostic UI.

## Schema (Dart Class Equivalent)
```dart
class PrayerDiagnosticState {
  final bool hasNotificationPermission;
  final bool hasExactAlarmPermission;
  final bool isBatteryOptimized;
  final double systemVolume;
  final DateTime lastScheduledTime;
}
```

## Fields
- `hasNotificationPermission` (Boolean, Required): True if the OS allows notifications.
- `hasExactAlarmPermission` (Boolean, Required): True if Android 12+ `SCHEDULE_EXACT_ALARM` is granted. Defaults to true on iOS and Android <12.
- `isBatteryOptimized` (Boolean, Required): True if the app is currently subject to OEM or OS background execution limits.
- `systemVolume` (Double, Required): Value between 0.0 and 1.0 indicating alarm/notification volume.
- `lastScheduledTime` (DateTime, Optional): The timestamp of the most recent background alarm scheduling event.

## Invariants
- Polled actively when `AdhanHealthCheckScreen` is in the foreground (e.g., via `WidgetsBindingObserver.didChangeAppLifecycleState`).
- Must not perform blocking OS calls on the main thread.

## Error Behavior
- If a permission state cannot be determined, assume `false` to proactively prompt the user to check settings.
