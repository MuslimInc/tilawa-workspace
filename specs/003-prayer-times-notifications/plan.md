# Implementation Plan: Prayer Times Notifications (Android-First)

**Branch**: `003-prayer-times-notifications` | **Date**: 2026-04-28 (revised 2026-04-28) | **Spec**: [spec.md](spec.md)
**Status**: Production-ready design
**Input**: Feature specification from `specs/003-prayer-times-notifications/spec.md`
**Research**: Phase 0 + package evaluation in [research.md](research.md)
**GitHub Tracking**: [GitHub Projects — tilawa-workspace](https://github.com/muhammadkamel/tilawa-workspace/projects) *(no project item created yet — see spec.md OD-6)*

---

## Summary

A production-ready prayer times notification feature for Android, designed for
long-term stability and maintainability. Scheduling uses `flutter_local_notifications`
(`zonedSchedule` + `AndroidScheduleMode.exactAllowWhileIdle`) backed by `flutter_timezone`
for correct IANA timezone detection. **No custom MethodChannel is required**: FLN v21.0.0
exposes `canScheduleExactNotifications()` and `requestExactAlarmsPermission()` on its Android
implementation, covering all native capability gaps.

All scheduling logic lives in a new `PrayerAdhanNotificationService` isolated behind
`IPrayerAdhanNotificationService`. All adhan audio logic is isolated behind `IAdhanAlarmPlayer`
so that the `alarm` package (or any replacement) can be adopted in Phase 2 without touching
domain, BLoC, or UI. Centralized constants live in `PrayerNotificationConfig`. Four use cases
cover scheduling, cancellation, capability check, and permission request — ensuring BLoC
and UI never call platform APIs directly. Comprehensive error handling ensures no crash
on any permission state, platform API failure, or scheduling edge case. iOS is future work.

---

## Package Evaluation — Options A–E

> Full evaluation details and compatibility matrix are in [research.md §11–§14](research.md).

| Option | Package(s) | Summary | Verdict |
|---|---|---|---|
| **A** | `flutter_local_notifications` + `flutter_timezone` | FLN `zonedSchedule` + exact alarm; `flutter_timezone` for device TZ; FLN Android API for permission check | ✅ **Production Baseline — Selected** |
| **B** | `alarm: ^5.2.1` | Full alarm-clock lifecycle, foreground service, custom audio; ideal for adhan-sound mode | ✅ **Phase 2 — Abstraction-ready; validate before adopting** |
| C | `android_alarm_manager_plus` | Background Dart execution on alarm; requires isolate wiring; heavier than FLN for this use case | ❌ **Excluded per user constraints** |
| D | `flutter_background_service` | Persistent foreground service; overkill for periodic prayer alarms | ❌ **Excluded per user constraints** |
| E | Custom MethodChannel | `canScheduleExactAlarms()` + `requestExactAlarmPermission()` in Kotlin; ~20 lines | ⚠️ **Superseded — FLN already exposes these; only needed if FLN API proves insufficient at runtime** |

### Recommended Architecture

```
Production baseline  →  Option A: FLN + flutter_timezone
Phase 2 (adhan)      →  Option B: alarm package behind IAdhanAlarmPlayer abstraction
Fallback             →  Option E: thin MethodChannel if FLN API unreliable on edge devices
```

---

## Technical Context

**Language/Version**: Flutter 3.41.7, Dart 3.11.5 (via fvm), `sdk: ^3.11.5`
**Target Platform**: **Android 8.0+ (API 26+).** iOS is future work (documented; no iOS code added in this feature).
**Performance Goals**: Scheduling completes in background Phase 3; no UI-thread blocking; zero jank
**Constraints**: RTL/LTR, offline-first (scheduling from saved location), exact alarm fallback to inexact

### Pinned Package Versions

| Package | Current | To Add/Change | Constraint |
|---|---|---|---|
| `flutter_local_notifications` | `^21.0.0-dev.1` | No change | Already in pubspec |
| `timezone` | `^0.11.0` | No change | Already in pubspec |
| `flutter_timezone` | — | **ADD `^5.0.2`** | Required for reliable TZ detection |
| `permission_handler` | `^12.0.1` | No change | Already in pubspec |
| `alarm` | — | *Phase 2 only — behind `IAdhanAlarmPlayer` abstraction* | Candidate `^5.2.1`; validate before adopting |

> **Do not add `adhan_dart`** — the custom `PrayerTimeCalculator` is production-complete (337 lines, 11 calculation methods, no external dependencies).
>
> **Do not reuse `just_audio` or `audio_service`** — these own the Quran player lifecycle. The `alarm` package (Phase 2) has its own isolated audio pipeline.
>
> **`alarm` package MUST be wrapped behind `IAdhanAlarmPlayer`** — the `alarm` package import MUST NOT appear in any file outside its own implementation class. This allows replacing it without touching domain, BLoC, or UI.

---

## Constitution Check

- **Clean Architecture Boundaries**: **PASS** — `IPrayerAdhanNotificationService` and `IAdhanAlarmPlayer` (domain interfaces) owned in `tilawa_core`; implementations in `apps/tilawa/lib/core/services/`; BLoC depends on use cases only; use cases depend on service interfaces only; no cross-layer leakage; UI never imports service or platform classes directly.
- **SOLID — Single Responsibility**: **PASS** — `PrayerAdhanNotificationService` handles scheduling/cancellation only; `IAdhanAlarmPlayer` implementation handles adhan audio only; `PrayerNotificationConfig` owns all constants; each use case has one responsibility.
- **SOLID — Open/Closed (adhan abstraction)**: **PASS** — `IAdhanAlarmPlayer` interface allows Phase 2 `alarm` package adoption without modifying any existing class.
- **No Custom MethodChannel**: **PASS** — FLN's `AndroidFlutterLocalNotificationsPlugin` exposes `canScheduleExactNotifications()` and `requestExactAlarmsPermission()`. No Kotlin changes required.
- **No Direct Platform Calls from UI or BLoC**: **PASS** — UI only dispatches BLoC events; BLoC calls use cases only; use cases call service interfaces only; `AndroidFlutterLocalNotificationsPlugin` is accessed only inside `PrayerAdhanNotificationService`.
- **BLoC and GoRouter**: **PASS** — `PrayerTimesBloc` handles reschedule trigger and capability check via use cases; settings sheet reads capability from BLoC state; no direct service calls from widgets.
- **Atomic Design and Tilawa UI Kit**: **PASS** — Notification settings UI uses existing `PrayerSettingsSheet` pattern, `SwitchListTile`, Tilawa tokens (`theme.tokens`), `context.l10n`; no hard-coded colors or spacing.
- **Responsive and Adaptive UI**: **PASS** — Settings sheet uses `DraggableScrollableSheet`; new section follows same pattern; RTL labels tested via l10n.
- **Performance and Low Jank**: **PASS** — Scheduling is fire-and-forget via `unawaited()` in bloc; Phase 3 runs in non-critical background path; no build-method I/O.
- **Error Resilience**: **PASS** — Every `PrayerAdhanNotificationService` method is wrapped in try/catch; errors are logged at `e` level with `[PrayerNotificationConfig.logTag]`; no exception propagates to BLoC or UI.
- **Centralized Configuration**: **PASS** — All notification IDs, channel IDs, timing constants, SharedPreferences keys, log tags, and schedule parameters defined in `PrayerNotificationConfig`; no magic numbers anywhere else.
- **Structured Logging**: **PASS** — All service methods log at `d` / `w` / `e` levels using `[PrayerNotificationConfig.logTag]`; scheduling attempts log prayer name, date, scheduled time, and alarm mode (exact/inexact).
- **Testing Discipline**: **PASS** — Unit tests for service, use cases, and BLoC are planned; FLN plugin and adhan player tested via mocks; coverage target ≥ 80% on new code.
- **Safe Refactoring and Delivery**: **PASS** — No existing code is restructured; changes are additive; `PrayerTimesBloc` constructor change handled by `build_runner` regeneration; `PrayerSettingsSheet` is additive-only.
- **Google Play Compliance**: **PASS** — `USE_EXACT_ALARM` requires Store justification (documented in §Permission Strategy); no background service added; no wake lock abuse; battery impact documented.

---

## Project Structure

### Documentation (this feature)

```text
specs/003-prayer-times-notifications/
├── plan.md              ← this file
├── research.md          ← Phase 0 + package evaluation (§11–§14)
├── data-model.md        ← Phase 1 output (value objects, channel protocol)
└── tasks.md             ← Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
packages/core/lib/services/interfaces/
├── prayer_adhan_notification_service_interface.dart   [NEW] IPrayerAdhanNotificationService
└── adhan_alarm_player_interface.dart                  [NEW] IAdhanAlarmPlayer (Phase 2 abstraction, defined now)

apps/tilawa/
├── pubspec.yaml                                        [UPDATE] +flutter_timezone ^5.0.2
├── lib/
│   ├── core/services/
│   │   ├── prayer_notification_config.dart             [NEW] Centralized constants (IDs, keys, log tag, schedule range)
│   │   ├── athkar_notification_service.dart            [UPDATE] fix getLocalTimeZone() to use flutter_timezone
│   │   ├── prayer_adhan_notification_service.dart      [NEW] Scheduling service (FLN + flutter_timezone + config)
│   │   └── noop_adhan_alarm_player.dart                [NEW] NoOpAdhanAlarmPlayer — does nothing (Phase 1 default)
│   ├── core/bootstrap/
│   │   ├── app_launch_config.dart                      [UPDATE] +prayerNotificationsInit flag
│   │   ├── app_startup_phases.dart                     [UPDATE] Phase 3: initializePrayerNotifications()
│   │   └── app_startup_tasks.dart                      [UPDATE] initializePrayerNotifications() method
│   ├── features/prayer_times/
│   │   ├── domain/usecases/
│   │   │   ├── schedule_prayer_notifications_use_case.dart       [NEW]
│   │   │   ├── cancel_prayer_notifications_use_case.dart         [NEW]
│   │   │   ├── check_prayer_alarm_capability_use_case.dart       [NEW]
│   │   │   ├── request_exact_alarm_permission_use_case.dart      [NEW]
│   │   │   └── usecases.dart                                     [UPDATE] +4 exports
│   │   └── presentation/
│   │       ├── bloc/prayer_times_bloc.dart                       [UPDATE] +4 use cases, +alarmCapability state
│   │       └── widgets/prayer_settings_sheet.dart                [UPDATE] +notification settings section
│   └── l10n/
│       ├── app_en.arb                                  [UPDATE] +10 new keys
│       └── app_ar.arb                                  [UPDATE] +10 Arabic translations
└── test/
    └── features/prayer_times/
        ├── prayer_adhan_notification_service_test.dart            [NEW]
        ├── schedule_prayer_notifications_use_case_test.dart       [NEW]
        ├── cancel_prayer_notifications_use_case_test.dart         [NEW]
        ├── check_prayer_alarm_capability_use_case_test.dart       [NEW]
        └── prayer_times_bloc_reschedule_test.dart                 [NEW]
```

**No Android/Kotlin changes required.** `MainActivity.kt` (extends `AudioServiceActivity`) is untouched. No MethodChannel registration needed.

---

## Phase 0: Research Findings Summary

*See [research.md](research.md) for full details.*

### Key Findings

1. **All domain entities already exist** — `PrayerNotificationSettings`, `PrayerSettingsEntity`, `PrayerTimeEntity`. No domain changes needed.
2. **All Android permissions already declared** — `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`. No manifest changes needed.
3. **`flutter_local_notifications` v21.0.0 is sufficient for scheduling AND permission check** — `zonedSchedule` + `exactAllowWhileIdle` schedules the alarm; `AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications()` checks the permission; `requestExactAlarmsPermission()` opens system settings.
4. **No MethodChannel needed for MVP** — FLN's Android implementation already exposes the two capabilities previously identified as MethodChannel-only.
5. **`flutter_timezone` is required** — `AthkarNotificationService.getLocalTimeZone()` uses a naive +2/+3/+4 UTC-offset-to-name mapping that returns `null` (→ UTC fallback) for all non-Arab timezones. The prayer notification service needs correct timezone detection globally.
6. **`AthkarNotificationService` is the exact template** — notification IDs, deduplication, channel creation, timezone init, exact alarm fallback, handler registration patterns all copy directly.
7. **`PrayerTimesBloc._onUpdateSettings`** is the injection point for reschedule trigger — 1 line addition.
8. **Notification ID space**: Prayer static 2001–2006; dynamic `20_000_000 + (dayOffset × 10) + prayerIndex`.
9. **Doze mode worst case**: 15-minute delay. `USE_EXACT_ALARM` (API 33+) already declared and mitigates on modern devices.
10. **`adhan_dart` NOT needed** — custom `PrayerTimeCalculator` is production-complete.
11. **`alarm` package v5.2.1** — compatible (Dart SDK >=3.0.0), actively maintained, has Android+iOS support. Phase 2 path for adhan audio. Requires isolated vetting against `audio_service` for MediaSession conflict before adoption.

---

## Phase 1: Design Artifacts

### `PrayerNotificationConfig` (centralized constants)

```dart
// apps/tilawa/lib/core/services/prayer_notification_config.dart

/// All notification IDs, channel IDs, SharedPreferences keys, timing constants,
/// log tags, and schedule parameters for prayer time notifications.
/// No magic numbers anywhere else in the feature.
final class PrayerNotificationConfig {
  PrayerNotificationConfig._();

  // --- Notification Channels ---
  static const String channelId      = 'com.tilawa.app.prayer';
  static const String adhanChannelId = 'com.tilawa.app.prayer_adhan';
  static const String channelName      = 'Prayer Times';
  static const String adhanChannelName = 'Prayer Times (Adhan)';

  // --- Notification IDs ---
  // Static (test/debug): fajr=2001, dhuhr=2002, asr=2003, maghrib=2004, isha=2005, sunrise=2006
  static const int staticIdBase  = 2001;
  // Dynamic: 20_000_000 + (dayOffset × 10) + prayerType.index
  // Range: 20_000_000 – 20_000_145 (14 days × 6 prayers × slot of 10)
  static const int dynamicIdBase = 20_000_000;

  // --- Scheduling ---
  static const int scheduleDaysAhead = 14; // 2 weeks of coverage

  // --- Deduplication & Fingerprint ---
  // SharedPreferences keys — must not change after first release
  static const String dedupDateKey         = 'prayer_notifications_last_scheduled_date';
  static const String settingsFingerprintKey = 'prayer_notifications_settings_fingerprint';

  // --- Payload keys ---
  static const String payloadTypeKey   = 'type';
  static const String payloadTypeValue = 'prayer';
  static const String payloadPrayerKey = 'prayer';
  static const String payloadDateKey   = 'date';

  // --- Logging ---
  static const String logTag = '[PrayerAdhanNotificationService]';

  // --- ID helpers ---
  static int staticId(PrayerType prayer) => staticIdBase + prayer.index;
  static int dynamicId(int dayOffset, PrayerType prayer) =>
      dynamicIdBase + (dayOffset * 10) + prayer.index;
}
```

---

### `IAdhanAlarmPlayer` (tilawa_core interface — Phase 2 abstraction)

Defined now so the architecture is closed for modification when Phase 2 is implemented.

```dart
// packages/core/lib/services/interfaces/adhan_alarm_player_interface.dart

/// Abstraction over the adhan audio playback mechanism.
///
/// Phase 1 implementation: [NoOpAdhanAlarmPlayer] — does nothing.
/// Phase 2 implementation: [AlarmPackageAdhanPlayer] — wraps the `alarm` package.
///
/// Implementations may be replaced without touching domain, BLoC, or UI.
abstract interface class IAdhanAlarmPlayer {
  /// Whether this implementation can play adhan audio on this device/platform.
  bool get isSupported;

  /// Schedule adhan audio playback at [scheduledTime].
  Future<void> scheduleAdhan({
    required int id,
    required DateTime scheduledTime,
    required String prayerName,
  });

  /// Cancel a previously scheduled adhan by [id].
  Future<void> cancelAdhan(int id);

  /// Cancel all scheduled adhans in the prayer ID range.
  Future<void> cancelAllAdhans();
}
```

Phase 1 implementation:
```dart
// apps/tilawa/lib/core/services/noop_adhan_alarm_player.dart
@LazySingleton(as: IAdhanAlarmPlayer)
class NoOpAdhanAlarmPlayer implements IAdhanAlarmPlayer {
  @override bool get isSupported => false;
  @override Future<void> scheduleAdhan({required int id, required DateTime scheduledTime, required String prayerName}) async {}
  @override Future<void> cancelAdhan(int id) async {}
  @override Future<void> cancelAllAdhans() async {}
}
```

---

### `IPrayerAdhanNotificationService` (tilawa_core interface)

```dart
// packages/core/lib/services/interfaces/prayer_adhan_notification_service_interface.dart
abstract interface class IPrayerAdhanNotificationService {
  Future<void> initialize();

  /// Schedule prayer notifications for the given settings and days.
  /// [forceReschedule]: if true, bypasses the deduplication fingerprint guard.
  /// Use true when triggered by a user action (settings change, location change).
  /// Use false when triggered by app startup or boot.
  Future<void> schedulePrayerNotifications({
    required PrayerSettingsEntity settings,
    required List<PrayerTimeEntity> prayerTimesForDays,
    bool forceReschedule = false,
  });

  Future<void> cancelAllPrayerNotifications();
  Future<void> handleNotificationResponse(NotificationResponse response);

  /// Returns true if exact alarms can be scheduled on this device/OS version.
  /// Always true on Android < 12 and iOS.
  Future<bool> canScheduleExactAlarms();

  /// Opens system settings for exact alarm permission. No-op on Android < 12.
  Future<void> requestExactAlarmPermission();
}
```

---

### Deduplication & Fingerprint Strategy

**Problem**: A simple date-based dedup guard would block rescheduling when settings or
location change on the same day, causing stale alarms.

**Solution**: Two-key dedup check in `schedulePrayerNotifications()`:

```
fingerprint = SHA-256(
    settings.json +
    lat.toStringAsFixed(4) +
    lon.toStringAsFixed(4) +
    calculationMethod.name
)
```

| Condition | Action |
|---|---|
| `forceReschedule = true` | Always cancel + schedule; update both keys |
| Today's date ≠ stored date | Cancel + schedule; update both keys |
| Today's date = stored date AND fingerprint differs | Cancel + schedule; update both keys |
| Today's date = stored date AND fingerprint matches | Skip (already up to date) |

**Rescheduling triggers** (all call `forceReschedule` appropriately):

| Trigger | `forceReschedule` | Where |
|---|---|---|
| App cold start / Phase 3 init | `false` | `app_startup_tasks.dart` |
| Device reboot / `BOOT_COMPLETED` | `false` | FLN boot receiver → Phase 3 on next launch |
| Prayer settings changed | `true` | `PrayerTimesBloc._onUpdateSettings` |
| Location updated | `true` | `PrayerTimesBloc._onUpdateLocation` |
| Calculation method changed | `true` | `PrayerTimesBloc._onUpdateSettings` |
| Prayer times successfully loaded | `false` | `PrayerTimesBloc._onLoadPrayerTimes` success |
| Timezone change (detected at init) | `true` | Service detects TZ name mismatch at init |

---

### Notification Channels

| Channel ID | Name | Sound | Used when |
|---|---|---|---|
| `com.tilawa.app.prayer` | Prayer Times | Default OS sound | `playAdhan = false` (current default) |
| `com.tilawa.app.prayer_adhan` | Prayer Times (Adhan) | `adhan` raw resource | Phase 2: `playAdhan = true` + asset confirmed present |

Both channels created at service init. Adhan channel is future-ready; inactive until Phase 2.

**Android channel sound lock**: Once a channel is created with a sound, the sound cannot
be changed without deleting and recreating the channel. Both channels are created at first
init to avoid requiring channel migration later.

### Notification Payload Format

```json
{ "type": "prayer", "prayer": "fajr", "date": "20260428" }
```

Key names come from `PrayerNotificationConfig.payload*` constants.

### Logging Specification

Every significant step in `PrayerAdhanNotificationService` logs at the appropriate level
using `logger` with `PrayerNotificationConfig.logTag` as prefix:

| Level | Condition | Example |
|---|---|---|
| `d` | Scheduling an alarm | `[PANS] Scheduled Fajr 2026-04-29 at 04:32 (exact)` |
| `d` | Skipping past alarm | `[PANS] Skipping Fajr 2026-04-28 — time in past` |
| `d` | Dedup hit | `[PANS] Dedup hit — already scheduled for 2026-04-28 (fingerprint match)` |
| `d` | Cancel complete | `[PANS] Cancelled 60 dynamic alarm IDs` |
| `w` | Exact alarm denied | `[PANS] Exact alarm permission denied — using inexact mode` |
| `w` | No location | `[PANS] No saved location — scheduling skipped` |
| `w` | Notification permission denied | `[PANS] POST_NOTIFICATIONS denied — scheduling suppressed` |
| `e` | Any exception | `[PANS] Error scheduling Fajr 2026-04-28: $e` |

---

## Step-by-Step Implementation Plan

### Step 1 — Add `flutter_timezone` to pubspec

**File**: `apps/tilawa/pubspec.yaml`

```yaml
flutter_timezone: ^5.0.2
```

Run `flutter pub get` after adding.

### Step 2 — Fix timezone detection in `AthkarNotificationService`

**File**: `apps/tilawa/lib/core/services/athkar_notification_service.dart`

- Replace `getLocalTimeZone()` body with `FlutterTimezone.getLocalTimezone()`
- Add `import 'package:flutter_timezone/flutter_timezone.dart';`
- Keep the same error handling and fallback-to-UTC behavior
- All existing tests continue to pass (mock `getLocalTimeZone` via override)

### Step 3 — `PrayerNotificationConfig` constants class

**File**: `apps/tilawa/lib/core/services/prayer_notification_config.dart`

- Define all IDs, channel names, keys, log tag, `scheduleDaysAhead = 14` (see Phase 1)
- No logic; pure constants + two static ID helper methods
- Annotate `final class PrayerNotificationConfig` with private constructor

### Step 4 — `IAdhanAlarmPlayer` + `NoOpAdhanAlarmPlayer` (tilawa_core)

**Files**:
- `packages/core/lib/services/interfaces/adhan_alarm_player_interface.dart`
- `apps/tilawa/lib/core/services/noop_adhan_alarm_player.dart`

- Define interface (see Phase 1)
- `NoOpAdhanAlarmPlayer`: `@LazySingleton(as: IAdhanAlarmPlayer)` — all methods are no-ops
- Export interface from `packages/core/lib/services/services.dart`

### Step 5 — `IPrayerAdhanNotificationService` interface (tilawa_core)

**File**: `packages/core/lib/services/interfaces/prayer_adhan_notification_service_interface.dart`

- Define interface with `forceReschedule` parameter (see Phase 1)
- Export from `packages/core/lib/services/services.dart`

### Step 6 — `PrayerAdhanNotificationService` (core service)

**File**: `apps/tilawa/lib/core/services/prayer_adhan_notification_service.dart`

1. `@LazySingleton(as: IPrayerAdhanNotificationService)`
2. Constructor injects: `INotificationDispatcher`, `PrayerTimesRepository`, `SharedPreferencesAsync`, `NavigationService`, `AnalyticsService`, `IAdhanAlarmPlayer`
3. `initialize()`:
   - Detect timezone via `FlutterTimezone.getLocalTimezone()`; store as `_currentTzName`
   - Compare against stored fingerprint timezone component; if changed, force reschedule flag
   - `await tz.initializeTimeZones()`; `tz.setLocalLocation(tz.getLocation(_currentTzName))`
   - `_dispatcher.initialize(createHighImportanceChannel: false)` → register handler → create both channels
   - Wrap entire `initialize()` body in try/catch; log at `e` level; never rethrow
4. `schedulePrayerNotifications(settings, days, {forceReschedule})`:
   - **ALL scheduling logic wrapped in outer try/catch — log `e`, return, do not throw**
   - Compute fingerprint from settings + lat/lon + calculationMethod
   - Run dedup check (see Deduplication section); skip if not needed
   - Call `cancelAllPrayerNotifications()` before scheduling new alarms
   - For each day (0 to `scheduleDaysAhead - 1`), for each prayer in `PrayerType.mainPrayers`:
     - Check `settings.*Notification.enabled` — skip + log `d` if disabled
     - Compute `scheduledTime = prayerTime - minutesBefore`
     - Guard: `if scheduledTime < tz.TZDateTime.now(tz.local)` → skip + log `d`
     - Check `canScheduleExactAlarms()` → pick `exactAllowWhileIdle` or `inexact`
     - Call `_notifications.zonedSchedule(...)` with ID from `PrayerNotificationConfig.dynamicId()`
     - Log `d` with prayer name, date, scheduled time, and alarm mode
   - If `settings.playAdhan` and `_adhanPlayer.isSupported`:
     - Call `_adhanPlayer.scheduleAdhan(...)` for each enabled prayer
   - Update dedup date + fingerprint in SharedPreferences
5. `cancelAllPrayerNotifications()`:
   - Cancel static IDs 2001–2006 individually
   - Cancel dynamic IDs `20_000_000` through `20_000_000 + (scheduleDaysAhead × 10) + 5`
   - Call `_adhanPlayer.cancelAllAdhans()`
   - Log `d` with count of cancelled IDs
   - Wrap in try/catch; log `e` on failure; never rethrow
6. `canScheduleExactAlarms()`:
   ```dart
   final impl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
   return await impl?.canScheduleExactNotifications() ?? true;
   ```
7. `requestExactAlarmPermission()`:
   ```dart
   final impl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
   await impl?.requestExactAlarmsPermission();
   ```
8. `handleNotificationResponse(response)`: parse payload → navigate to Prayer Times screen via `NavigationService`

### Step 7 — Use cases (domain)

**Files**: 4 new use cases + updated `usecases.dart`

**`SchedulePrayerNotificationsUseCase`**:
```dart
@injectable
class SchedulePrayerNotificationsUseCase {
  const SchedulePrayerNotificationsUseCase(this._service, this._repo);
  final IPrayerAdhanNotificationService _service;
  final PrayerTimesRepository _repo;

  Future<void> call({
    required PrayerSettingsEntity settings,
    required double latitude,
    required double longitude,
    bool forceReschedule = false,
  }) async {
    final days = await _repo.getPrayerTimesForRange(
      latitude: latitude,
      longitude: longitude,
      days: PrayerNotificationConfig.scheduleDaysAhead,
    );
    await _service.schedulePrayerNotifications(
      settings: settings,
      prayerTimesForDays: days,
      forceReschedule: forceReschedule,
    );
  }
}
```

**`CancelPrayerNotificationsUseCase`**: delegates to `service.cancelAllPrayerNotifications()`.

**`CheckPrayerAlarmCapabilityUseCase`**:
```dart
@injectable
class CheckPrayerAlarmCapabilityUseCase {
  const CheckPrayerAlarmCapabilityUseCase(this._service, this._permissionService);

  Future<PrayerAlarmCapability> call() async {
    final canScheduleExact = await _service.canScheduleExactAlarms();
    final hasNotificationPermission = await _permissionService.isPermissionGranted();
    return PrayerAlarmCapability(
      canScheduleExact: canScheduleExact,
      hasNotificationPermission: hasNotificationPermission,
    );
  }
}
```

**`RequestExactAlarmPermissionUseCase`**: delegates to `service.requestExactAlarmPermission()`.

> `PrayerAlarmCapability` value object: `{canScheduleExact: bool, hasNotificationPermission: bool}`
> Getter: `bool get isFullyCapable => canScheduleExact && hasNotificationPermission`

Update `usecases.dart` barrel with 4 new exports.

### Step 8 — `PrayerTimesBloc` integration

**File**: `apps/tilawa/lib/features/prayer_times/presentation/bloc/prayer_times_bloc.dart`

Add to constructor: `SchedulePrayerNotificationsUseCase`, `CancelPrayerNotificationsUseCase`, `CheckPrayerAlarmCapabilityUseCase`, `RequestExactAlarmPermissionUseCase`.

Add to state: `PrayerAlarmCapability? alarmCapability` (nullable; null = not yet checked).

Add events: `PrayerTimesEvent.checkAlarmCapability`, `PrayerTimesEvent.requestExactAlarmPermission`.

**Reschedule triggers**:
```dart
// _onLoadPrayerTimes — after PrayerTimesStatus.loaded emit:
unawaited(_schedulePrayerNotificationsUseCase.call(
  settings: state.settings,
  latitude: latitude!,
  longitude: longitude!,
  forceReschedule: false, // startup/boot path — respect dedup
));

// _onUpdateSettings — after _savePrayerSettingsUseCase:
unawaited(_schedulePrayerNotificationsUseCase.call(
  settings: event.settings,
  latitude: state.latitude,
  longitude: state.longitude,
  forceReschedule: true, // user changed settings — always reschedule
));

// _onUpdateLocation — after location update:
unawaited(_schedulePrayerNotificationsUseCase.call(
  settings: state.settings,
  latitude: event.latitude,
  longitude: event.longitude,
  forceReschedule: true, // location changed — always reschedule
));

// _onCheckAlarmCapability:
final capability = await _checkPrayerAlarmCapabilityUseCase.call();
emit(state.copyWith(alarmCapability: capability));

// _onRequestExactAlarmPermission:
await _requestExactAlarmPermissionUseCase.call();
```

Run `dart run build_runner build --delete-conflicting-outputs` after.

### Step 9 — Bootstrap integration

**Files**: `app_launch_config.dart`, `app_startup_phases.dart`, `app_startup_tasks.dart`

- `app_launch_config.dart`: add `prayerNotificationsInit` bool param with `bool.fromEnvironment('PRAYER_NOTIFICATIONS_INIT', defaultValue: true)` + add to `props`
- `app_startup_phases.dart`: add `initializePrayerNotifications()` to Phase 3 task list (guarded by flag)
- `app_startup_tasks.dart`: `initializePrayerNotifications()` — gets `IPrayerAdhanNotificationService` via `getIt`, calls `initialize()` then `schedulePrayerNotifications()` with `forceReschedule: false`; entire method wrapped in try/catch

### Step 10 — Settings UI

**File**: `apps/tilawa/lib/features/prayer_times/presentation/widgets/prayer_settings_sheet.dart`

Append a new `_SectionTitle` section. **All interactions dispatch BLoC events; no direct service or use case calls from the widget.**

- Global `SwitchListTile` — enable/disable all at once
- Per-prayer `SwitchListTile` rows (5 rows: fajr, dhuhr, asr, maghrib, isha)
- `minutesBefore` segmented picker: 0 / 5 / 10 / 15 minutes
- "Play Adhan" `SwitchListTile` — visible but disabled with tooltip "Coming soon" until Phase 2
- Conditional warning banners (read from `state.alarmCapability`):
  - If `!alarmCapability.hasNotificationPermission`: notification permission banner
  - If `!alarmCapability.canScheduleExact`: exact alarm permission banner + "Open Settings" button dispatching `PrayerTimesEvent.requestExactAlarmPermission`
- `initState`: dispatch `PrayerTimesEvent.checkAlarmCapability` when settings sheet opens

### Step 11 — l10n

**Files**: `app_en.arb`, `app_ar.arb`

Add 10 new keys (see [research.md §9](research.md)). Run `flutter gen-l10n`.

### Step 12 — `build_runner`

```bash
cd apps/tilawa
dart run build_runner build --delete-conflicting-outputs
```

---

## Permission Strategy

### Android 13+ (API 33+) — POST_NOTIFICATIONS

- Permission declared in manifest ✅
- `NotificationPermissionService.requestPermission()` handles first-launch request (already Phase 4 startup)
- If denied: show non-blocking informational banner in settings; never re-prompt automatically
- Scheduling is suppressed when permission is denied; no silent failures — state surfaced in `PrayerAlarmCapability.hasNotificationPermission`

### Android 12+ (API 31+) — SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM

- Both declared in manifest ✅
- `USE_EXACT_ALARM` (API 34+): auto-granted for clock/calendar class apps. Tilawa qualifies as a time-critical religious scheduling app.
- `SCHEDULE_EXACT_ALARM` (API 31–33): user may revoke. Checked via `canScheduleExactAlarms()` at scheduling time.
- If denied: fallback to `AndroidScheduleMode.inexact` + log warning + surface banner in settings UI
- `requestExactAlarmPermission()` dispatched as `PrayerTimesEvent.requestExactAlarmPermission` from UI → use case → service; never called directly from a widget

### Google Play Store — `USE_EXACT_ALARM` Justification

Google Play requires apps using `USE_EXACT_ALARM` to justify it in the Play Console's Data Safety and Store listing. Required actions before release:

- [ ] Add justification in Play Console: "Tilawa schedules prayer time notifications at precise religious observance times; exact timing is required by the nature of the feature."
- [ ] Review [Google Play policy for exact alarms](https://support.google.com/googleplay/android-developer/answer/9888170)
- [ ] Confirm `USE_EXACT_ALARM` is appropriate vs `SCHEDULE_EXACT_ALARM` for target API level (34+)

### No Aggressive Background Behavior

- No persistent foreground service added (neither ForegroundService nor WorkManager)
- No wake lock held outside a brief alarm delivery window
- No continuous polling or background GPS
- Battery impact: negligible (scheduling 84 alarms in a single batch at startup; no ongoing work)

---

## Risks & Platform Limitations

| Risk | Severity | Mitigation |
|---|---|---|
| Doze mode delays notification by up to ~15 min | Medium | `USE_EXACT_ALARM` (API 33+) reduces this; document as known limitation in settings UI |
| OEM battery optimization kills alarms — Xiaomi MIUI | High | Guide user to Battery → App autostart + Allow background activity; document per-OEM in user-facing help |
| OEM battery optimization kills alarms — Huawei EMUI | High | Guide to Protected Apps list; document |
| OEM battery optimization kills alarms — OPPO ColorOS / Vivo FuntouchOS | High | Guide to Permission → Autostart + Battery Saver exceptions; document |
| OEM battery optimization kills alarms — Samsung One UI | Medium | Samsung has improved in recent versions; guide to Battery → Unrestricted if still affected |
| App force-stopped → alarms not delivered | High | Android 10+ OS restriction; no workaround without foreground service; document clearly |
| Device reboot cancels all alarms | High | `RECEIVE_BOOT_COMPLETED` + FLN `ScheduledNotificationBootReceiver` (already registered) + Phase 3 rescheduling on first launch |
| `SCHEDULE_EXACT_ALARM` revoked by user | Medium | `canScheduleExactAlarms()` at scheduling time; fallback to inexact; surface capability in settings banner |
| Android notification channel sound lock | Medium | Two channels pre-created at init; channel selection based on `playAdhan` flag; never delete channels |
| `minutesBefore` pushes alarm into past | Low | Guard: skip if `scheduledTime < tz.TZDateTime.now(tz.local)`; log `d` |
| Dedup blocks same-day reschedule after settings change | Medium | **Fixed by fingerprint strategy**: settings changes pass `forceReschedule: true` |
| `PrayerTimesBloc` constructor change | Low | `build_runner` regeneration resolves DI config automatically |
| Duplicate alarms on rapid settings changes | Low | `cancelAll` before every `schedule`; dedup fingerprint ensures idempotency |
| iOS: not supported | Intended | Future work; no iOS code paths added |
| `sunrise` has no `PrayerNotificationSettings` field | Low | Only schedule sunrise if `settings.showSunrise == true` |
| **`alarm` package + `audio_service` MediaSession conflict (Phase 2)** | **Medium** | **`alarm` import is isolated to `AlarmPackageAdhanPlayer`; validate in isolated branch before adopting** |
| `flutter_local_notifications` v21.0.0-dev.1 pre-release | Low | dev.1 is in production for Athkar service; `canScheduleExactNotifications()` API is stable since FLN v14 |
| `flutter_timezone` platform channel failure | Low | Wrapped in try/catch; falls back to UTC; logged at `w` |
| Google Play `USE_EXACT_ALARM` policy review | Medium | Justification required in Play Console before release (see §Permission Strategy) |
| Scheduling exception on any device | Critical | **Entire scheduling loop wrapped in try/catch; never rethrows to BLoC or UI** |

---

## Test Plan

### Unit Tests

| Test | File | Coverage |
|---|---|---|
| `schedulePrayerNotifications` schedules correct count (14 days × enabled prayers) | `prayer_adhan_notification_service_test.dart` | Service |
| `minutesBefore = 10` → notification time = prayerTime − 10 min | same | Service |
| Prayer with `enabled = false` → 0 notifications for that prayer | same | Service |
| All 5 prayers enabled → 70 notifications scheduled (14 days) | same | Service |
| No location saved → scheduling skipped gracefully, no throw | same | Service |
| `cancelAllPrayerNotifications` → cancel IDs called for full range (2001–2006 + 20M range) | same | Service |
| Past alarm time → skipped + logged, not scheduled | same | Service |
| Exact alarm denied → `AndroidScheduleMode.inexact` used | same | Service |
| `canScheduleExactAlarms()` delegates to FLN Android plugin | same | Service |
| Exception during scheduling → caught, logged at `e`, no rethrow | same | Service |
| Dedup: same date + same fingerprint → skip | same | Service |
| Dedup: same date + different fingerprint → reschedule | same | Service |
| Dedup: `forceReschedule = true` → always reschedule regardless | same | Service |
| `PrayerNotificationConfig.dynamicId(0, fajr)` = 20_000_000 | `prayer_notification_config_test.dart` | Config |
| `PrayerNotificationConfig.dynamicId(13, isha)` = 20_000_135 (no overflow) | same | Config |
| `SchedulePrayerNotificationsUseCase.call()` → delegates to service with correct params | `schedule_prayer_notifications_use_case_test.dart` | Use case |
| `SchedulePrayerNotificationsUseCase` passes `forceReschedule` through | same | Use case |
| `CancelPrayerNotificationsUseCase.call()` → delegates to service | `cancel_prayer_notifications_use_case_test.dart` | Use case |
| `CheckPrayerAlarmCapabilityUseCase.call()` → returns correct capability | `check_prayer_alarm_capability_use_case_test.dart` | Use case |
| `PrayerTimesBloc._onUpdateSettings` → `SchedulePrayerNotificationsUseCase.call(forceReschedule: true)` | `prayer_times_bloc_reschedule_test.dart` | BLoC |
| `PrayerTimesBloc._onLoadPrayerTimes` success → use case called with `forceReschedule: false` | same | BLoC |
| `PrayerTimesBloc._onCheckAlarmCapability` → emits `alarmCapability` in state | same | BLoC |
| `NoOpAdhanAlarmPlayer.isSupported` → false; scheduleAdhan completes without error | `noop_adhan_alarm_player_test.dart` | Phase 1 impl |

### Widget Tests

| Test | File | Coverage |
|---|---|---|
| Prayer Notifications section renders section title | `prayer_settings_sheet_notification_test.dart` | UI |
| "All Prayer Notifications" global toggle visible and tappable | same | UI |
| "Play Adhan" toggle visible and tappable | same | UI |
| `checkAlarmCapability` event dispatched on `initState` | same | UI/BLoC |
| No permission banner when fully capable | same | UI |
| Notification permission banner shown when `hasNotificationPermission = false` | same | UI |
| Exact alarm banner shown when `hasNotificationPermission = true`, `canScheduleExact = false` | same | UI |
| RTL locale renders without overflow | same | UI |

### Maestro E2E Smoke Tests

> **Strategy**: Maestro targets Flutter through the Semantics tree using
> `Semantics(identifier: ...)` on interactive elements. Keys (`ValueKey`,
> `GlobalKey`) are invisible to Maestro — always use semantic identifiers.
> All identifiers are defined in `PrayerNotificationSemanticsIds` and are
> locale-independent.

#### Identifiers map

| Identifier constant | Semantic ID string | Widget |
|---|---|---|
| `prayerTimesTab` | `prayer_times_tab` | Bottom-nav Prayer Times tab |
| `prayerSettingsButton` | `prayer_settings_button` | AppBar settings `IconButton` |
| `notificationsSection` | `prayer_notifications_section` | Section header |
| `globalToggle` | `prayer_notifications_global_toggle` | All-prayers switch |
| `fajrToggle` | `prayer_notification_fajr_toggle` | Fajr switch |
| `dhuhrToggle` | `prayer_notification_dhuhr_toggle` | Dhuhr switch |
| `asrToggle` | `prayer_notification_asr_toggle` | Asr switch |
| `maghribToggle` | `prayer_notification_maghrib_toggle` | Maghrib switch |
| `ishaToggle` | `prayer_notification_isha_toggle` | Isha switch |
| `minutesBefore` | `prayer_notifications_minutes_before` | `SegmentedButton` |
| `soundToggle` | `prayer_notifications_sound_toggle` | Play Adhan switch |

#### Flow files

| File | Scenario |
|---|---|
| `.maestro/prayer_notifications_settings.yaml` | Happy path: navigate → open → toggle global + Fajr → no crash |
| `.maestro/prayer_notifications_rtl.yaml` | RTL (Arabic locale): assert section + toggles visible without overflow |

#### How to run

```bash
# Single flow
maestro test .maestro/prayer_notifications_settings.yaml

# RTL flow (set device locale to Arabic first — see file header for instructions)
maestro test .maestro/prayer_notifications_rtl.yaml

# All Maestro flows in the repo
maestro test .maestro/
```

#### Android permission dialog handling

The flows include `runFlow: when: visible: "Allow"` guards to dismiss the
`POST_NOTIFICATIONS` system dialog if it appears. This uses Maestro's
system-level interaction which in-app Dart frameworks cannot reach.

#### Checklist

- [x] `maestro test .maestro/prayer_notifications_settings.yaml` — passes on Android 13+ device/emulator
- [ ] `maestro test .maestro/prayer_notifications_settings.yaml` — passes on iOS 16+ simulator
- [x] `maestro test .maestro/prayer_notifications_rtl.yaml` — passes with device locale set to Arabic
- [x] No overflow errors visible in Maestro screenshots for RTL flow

### Manual QA Checklist — Core

- [ ] Android 14 (Pixel) — first launch: notification permission dialog shown; prayer alarms scheduled
- [ ] Android 13 (Pixel) — permission dialog; alarms scheduled
- [ ] Android 12 (Pixel) — exact alarm permission check; `SCHEDULE_EXACT_ALARM` revocation → inexact fallback + banner shown
- [ ] Android 11 — scheduling works without exact alarm permission screen
- [ ] Android 8 (minSdk 24 equivalent) — scheduling completes; no crash
- [ ] Device reboot — prayer alarms rescheduled within 30s of boot
- [ ] App in background + Doze mode — notification fires (possibly delayed ≤15 min)
- [ ] App force-stopped — document: notification may not fire; verify no crash on restart
- [ ] Toggle Fajr off → Fajr notification does not fire; other prayers unaffected
- [ ] Change `minutesBefore` from 0 → 10 → verify alarm time updated on same day (fingerprint change)
- [ ] Change calculation method → alarms rescheduled immediately
- [ ] Update location → alarms rescheduled with new prayer times
- [ ] Non-Arab timezone (London, Jakarta, New York) — `flutter_timezone` returns correct IANA name; alarms fire at correct local times
- [ ] RTL Arabic locale — all settings text renders right-to-left
- [ ] Athkar notifications still fire correctly after `AthkarNotificationService` timezone fix

### Manual QA Checklist — OEM-Specific

- [ ] **Xiaomi MIUI** — test autostart permission; verify alarms fire from background; guide to Autostart + Battery > No restrictions
- [ ] **OPPO ColorOS** — test autostart; verify `AlarmManager` not suppressed; guide to Permission Manager > Autostart
- [ ] **Vivo FuntouchOS** — test background service management; verify alarms survive background kill
- [ ] **Samsung One UI (Android 12+)** — test with "Sleeping apps" disabled for Tilawa; verify exact alarms fire correctly
- [ ] **Huawei EMUI (no GMS)** — if targeted: test with Protected Apps enabled
- [ ] Low-end device (< 2GB RAM, Android 8) — scheduling completes; settings sheet opens without jank; no OOM

---

## Final Implementation Checklist

### Pre-implementation
- [ ] Create feature branch `003-prayer-times-notifications` from `stable`
- [ ] Confirm `flutter_local_notifications ^21.0.0-dev.1` resolves to `21.0.0` in pubspec.lock
- [ ] Verify `AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications()` is accessible with resolved FLN version (compile-time check)
- [ ] Confirm `adhan.mp3` is NOT bundled in `res/raw/` — adhan channel declared but silent until Phase 2

### Implementation (in order)
- [ ] Step 1: Add `flutter_timezone: ^5.0.2` to `apps/tilawa/pubspec.yaml`; run `flutter pub get`
- [ ] Step 2: Fix `AthkarNotificationService.getLocalTimeZone()` to use `FlutterTimezone.getLocalTimezone()`
- [ ] Step 3: `PrayerNotificationConfig` constants class — all IDs, keys, log tag, `scheduleDaysAhead = 14`
- [ ] Step 4: `IAdhanAlarmPlayer` interface + `NoOpAdhanAlarmPlayer` + services.dart export
- [ ] Step 5: `IPrayerAdhanNotificationService` interface + services.dart export
- [ ] Step 6: `PrayerAdhanNotificationService` — full implementation: channels, schedule, cancel, dedup+fingerprint, FLN alarm check, logging, error handling, adhan player delegation
- [ ] Step 7: 4 new use cases + `usecases.dart` barrel updates
- [ ] Step 8: `PrayerTimesBloc` — 4 new use cases, `alarmCapability` state, 2 new events, 3 reschedule trigger points (`forceReschedule` where appropriate)
- [ ] Step 9: Bootstrap flags + Phase 3 init + startup task method (try/catch)
- [ ] Step 10: Settings UI — all interactions via BLoC events; no direct service calls; capability banners read from state
- [ ] Step 11: l10n keys (EN + AR); run `flutter gen-l10n`
- [ ] Step 12: Run `dart run build_runner build --delete-conflicting-outputs`

### Verification — Code Quality
- [ ] `flutter analyze` — zero new errors
- [ ] `flutter test test/features/prayer_times/` — all new tests pass
- [ ] `flutter test test/core/` — athkar notification tests still pass (regression)
- [ ] `PrayerSettingsSheet` existing sections (calculation method, asr method) still work
- [ ] `PrayerNotificationConfig` has no magic numbers outside itself (grep for `20_000_000`, `2001`, `com.tilawa.app.prayer` — should only appear in config)
- [ ] No `AndroidFlutterLocalNotificationsPlugin` import anywhere except `PrayerAdhanNotificationService`
- [ ] No `alarm` package import anywhere (Phase 1 — `NoOpAdhanAlarmPlayer` only)

### Verification — Runtime
- [ ] App starts and Phase 3 completes without crash on Android 8, 12, 13, 14
- [ ] Settings change triggers reschedule on same day (fingerprint test)
- [ ] Boot → reschedule within 30s
- [ ] Manual QA core checklist complete
- [ ] Manual QA OEM checklist complete (at minimum Xiaomi + Samsung)

### Google Play Release Gate
- [ ] `USE_EXACT_ALARM` justification written in Play Console (see §Permission Strategy)
- [ ] Data Safety form updated: notification scheduling, no user data in payloads
- [ ] No foreground service added — verify `adb shell dumpsys activity services | grep tilawa` shows no persistent service from this feature

### Phase 2 Gate (before `alarm` package adoption)
- [ ] Define `AlarmPackageAdhanPlayer implements IAdhanAlarmPlayer` in a separate file
- [ ] Validate `alarm: ^5.2.1` compiles with Kotlin 2.1.0 / AGP 8.9.1
- [ ] Confirm no MediaSession conflict between `AlarmPlugin` and `AudioServiceActivity`
- [ ] Confirm `alarm` foreground service type does not collide with `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
- [ ] Verify Quran player resumes correctly after adhan alarm dismissal
- [ ] Register `AlarmPackageAdhanPlayer` in DI only after all Phase 2 gates pass
- [ ] Do not touch domain, BLoC, or UI when swapping the implementation


---
