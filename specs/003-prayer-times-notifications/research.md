# Research: Prayer Times Notifications — Android-First MethodChannel

**Phase**: 0 — Codebase & Platform Investigation
**Date**: 2026-04-28
**Spec**: [specs/003-prayer-times-notifications/spec.md](spec.md)
**GitHub Tracking**: [GitHub Projects — tilawa-workspace](https://github.com/MuslimInc/tilawa-workspace/projects) *(no project item created yet — see spec.md OD-6)*

---

## 1. Existing Infrastructure Confirmed

### 1.1 Domain Layer (no changes required)

| Entity / Class | File | Status |
|---|---|---|
| `PrayerNotificationSettings` | `prayer_settings_entity.dart` | ✅ Exists — has `enabled`, `minutesBefore`, `playAdhan`, `customAdhanUrl` |
| `PrayerSettingsEntity` | `prayer_settings_entity.dart` | ✅ Exists — has per-prayer fields: `fajrNotification`, `dhuhrNotification`, `asrNotification`, `maghribNotification`, `ishaNotification` |
| `PrayerTimeEntity` | `prayer_time_entity.dart` | ✅ Exists — `allPrayers` list, `mainPrayers` list, per-type `DateTime` |
| `PrayerType` enum | `prayer_time_entity.dart` | ✅ `fajr, sunrise, dhuhr, asr, maghrib, isha, midnight, lastThird` |

### 1.2 Notification Infrastructure (no changes required)

| Class / Package | Status |
|---|---|
| `flutter_local_notifications: ^21.0.0-dev.1` | ✅ In pubspec |
| `timezone` package | ✅ Used in `AthkarNotificationService` |
| `permission_handler: ^12.0.1` | ✅ In pubspec |
| `INotificationDispatcher` interface | ✅ In `tilawa_core` |
| `NotificationDispatcher` | ✅ Central plugin owner; ID-based routing |
| `AthkarNotificationService` | ✅ Production scheduling template; exact pattern to mirror |
| `NotificationPermissionService` | ✅ Exists; handles `POST_NOTIFICATIONS` |

### 1.3 Android Manifest Permissions (no changes required)

All required permissions are declared (current production manifest):
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />          <!-- API 33+ -->
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />             <!-- API 33+, auto-granted for alarm/calendar/religious-observance apps -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>       <!-- Reboot rescheduling -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```

`SCHEDULE_EXACT_ALARM` is intentionally NOT declared — Tilawa qualifies for the auto-grant `USE_EXACT_ALARM` category, which avoids prompting the user for the exact-alarm permission. A Play-rejection fallback to `SCHEDULE_EXACT_ALARM` is documented in [plan.md §Permission Strategy](plan.md).

### 1.4 Bootstrap Pattern

`AthkarNotificationService` is initialized in Phase 3 (`runPhase3NotificationsAndAudio`) via
`initializeAthkarNotifications()`. The same pattern will be followed for `PrayerAdhanNotificationService`:
- `AppLaunchConfig.prayerNotificationsInit = true` flag added
- `initializePrayerNotifications()` added to `app_startup_tasks.dart`
- Phase 3 calls it in parallel with athkar initialization

### 1.5 Notification IDs — Reservation Map

| Range | Owner |
|---|---|
| 1001, 1002 | Athkar static (morning/evening) |
| 11_000_000 + dateKey | Athkar dynamic morning |
| 12_000_000 + dateKey | Athkar dynamic evening |
| **2001–2006** | **Prayer static test IDs (reserved for new service)** |
| **20_000_000 + (dayOffset × 10) + prayerIndex** | **Prayer dynamic scheduled (range: 20M–20M+95)** |

Prayer index mapping: fajr=0, sunrise=1, dhuhr=2, asr=3, maghrib=4, isha=5

---

## 2. `flutter_local_notifications` — Exact Alarm Analysis

### What it calls under the hood (Android)

`zonedSchedule()` + `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle`
→ `AlarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)`

This is the correct API for prayer time alarms. It:
- Fires at the exact time even if the device is in idle/Doze mode (best-effort — see §4)
- Does NOT wake the screen or bypass DND
- Requires `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM` (already declared)

### What requires MethodChannel

`flutter_local_notifications` does NOT expose:
- Programmatic check of `AlarmManager.canScheduleExactAlarms()` (Android 12+)
- Direct request of exact alarm permission via `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`
- Ability to query how many alarms are currently pending

These three capabilities require a `MethodChannel`. All other scheduling can
remain with `flutter_local_notifications`.

### Conclusion: Hybrid approach (recommended for MVP)

Use `flutter_local_notifications` for all scheduling (proven, stable, already used).
Add a thin `MethodChannel` only for the capabilities that the plugin does not expose:
- `canScheduleExactAlarms()` → Java/Kotlin: `alarmManager.canScheduleExactAlarms()`
- `requestExactAlarmPermission()` → Kotlin: start `ACTION_REQUEST_SCHEDULE_EXACT_ALARM` activity
- (Optional future) `getPendingAlarmCount()` for debug/diagnostics

This keeps native code minimal, avoids re-implementing alarm scheduling in Kotlin,
and reduces maintenance surface.

---

## 3. `AthkarNotificationService` — Scheduling Pattern (Template)

Key implementation details to mirror exactly:

```dart
// Channel creation (Android-specific)
AndroidNotificationChannel(
  _channelId,
  _channelName,
  description: _channelDescription,
  importance: Importance.high,
)

// Scheduling
await _notifications.zonedSchedule(
  id: notificationId,
  title: title,
  body: body,
  scheduledDate: tzScheduledDate,
  notificationDetails: _notificationDetails,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // or .inexact on fallback
  matchDateTimeComponents: null,
  payload: payloadJson,
);

// Exact alarm fallback
// NOTE: Use AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications()
// instead of a MethodChannel — see §11 Option A for details.
final bool canScheduleExact = await _canScheduleExactAlarms();
final scheduleMode = canScheduleExact
    ? AndroidScheduleMode.exactAllowWhileIdle
    : AndroidScheduleMode.inexact;
```

Deduplication: `SharedPreferences` key `_lastPrayerScheduledDateKey` stores last
scheduled date string; skip if already scheduled today (same approach as athkar).

---

## 4. Android Platform Limitations

### 4.1 Doze Mode

Android Doze mode (introduced API 23) enters when:
- Screen off + stationary + unplugged for a sustained period

`setExactAndAllowWhileIdle()` behavior in Doze:
- Alarm is deferred until the next Doze **maintenance window**
- In Doze, maintenance windows occur at ~15 min, then 30 min, then 60 min intervals
- **Worst case**: a prayer notification may be delayed by up to ~15 minutes in deep Doze

**Mitigation**: Document this in the settings UI as "notifications may be delayed
slightly on battery-saving devices". No code workaround without `USE_EXACT_ALARM`
(Android 13+ API 33+), which is already declared.

`USE_EXACT_ALARM` (API 33+): Grants exact alarm without user prompt. Available for
clock and calendar apps. Tilawa qualifies as a time-critical religious app. This
permission is already in the manifest.

### 4.2 Battery Optimization (Aggressive OEM)

Some OEM Android variants (Xiaomi MIUI, Huawei EMUI, OnePlus OxygenOS) aggressively
kill background apps and disable alarms. This is documented as a known limitation.
The settings UI will guide users to Battery Optimization settings if needed.

### 4.3 App Force-Stop

Android 10+ (and some earlier versions): AlarmManager alarms are NOT delivered to
a force-stopped app. This is an OS-level restriction with no programmatic workaround.
`WorkManager` with `RECEIVE_BOOT_COMPLETED` can partially address reboot scenarios
but not force-stop. Document as known limitation.

### 4.4 BOOT_COMPLETED

`RECEIVE_BOOT_COMPLETED` is declared ✅. `flutter_local_notifications` registers a
`BootBroadcastReceiver` that calls the Dart background service on boot. The app
needs to reschedule via `PrayerAdhanNotificationService.schedulePrayerNotifications()`
during the startup notification init phase (Phase 3).

### 4.5 Android Notification Channel Sound Lock

Once an Android `NotificationChannel` is created with a sound setting, the sound
**cannot be changed** without deleting and recreating the channel. This means if
the user installs the app with "default sound" and later enables "adhan sound", the
channel must change.

**Solution**: Use two channels:
- `com.tilawa.app.prayer` — default sound (MVP)
- `com.tilawa.app.prayer_adhan` — adhan sound (future, requires asset)

The `playAdhan` flag determines which channel to use at scheduling time.

---

## 5. MethodChannel Design *(Superseded — see §11 Option E and §11 Option A)*

> **Note**: The MethodChannel approach documented in this section was the original design.
> It has been superseded for MVP: `AndroidFlutterLocalNotificationsPlugin` already exposes
> `canScheduleExactNotifications()` and `requestExactAlarmsPermission()`, making a custom
> MethodChannel unnecessary. This section is retained for reference in case the FLN API
> proves insufficient on specific edge devices.

### 5.1 Channel Name

`com.tilawa.app/prayer_alarm_scheduler`

### 5.2 Dart Interface

```dart
abstract interface class IPrayerAlarmScheduler {
  Future<bool> canScheduleExactAlarms();
  Future<void> requestExactAlarmPermission();
}
```

### 5.3 Flutter Implementation (MethodChannel bridge)

```dart
class PrayerAlarmSchedulerMethodChannel implements IPrayerAlarmScheduler {
  static const _channel = MethodChannel('com.tilawa.app/prayer_alarm_scheduler');

  @override
  Future<bool> canScheduleExactAlarms() async {
    try {
      return await _channel.invokeMethod<bool>('canScheduleExactAlarms') ?? true;
    } catch (e) {
      return true; // safe default — try scheduling; let the OS reject if needed
    }
  }

  @override
  Future<void> requestExactAlarmPermission() async {
    try {
      await _channel.invokeMethod<void>('requestExactAlarmPermission');
    } catch (_) {}
  }
}
```

### 5.4 Android Native (Kotlin)

```kotlin
// MainActivity.kt or a dedicated MethodCallHandler
class PrayerAlarmSchedulerPlugin(private val context: Context) : MethodChannel.MethodCallHandler {
  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "canScheduleExactAlarms" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
          val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
          result.success(am.canScheduleExactAlarms())
        } else {
          result.success(true)
        }
      }
      "requestExactAlarmPermission" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
          val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
          intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
          context.startActivity(intent)
        }
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }
}
```

---

## 6. Use Case Analysis

### New use cases required

| Use Case | Input | Output | Description |
|---|---|---|---|
| `SchedulePrayerNotificationsUseCase` | `PrayerSettingsEntity`, `List<PrayerTimeEntity>` | `Either<Failure, Unit>` | Schedule/reschedule all enabled prayer alarms |
| `CancelPrayerNotificationsUseCase` | — | `Either<Failure, Unit>` | Cancel all prayer alarms |
| `CheckPrayerAlarmCapabilityUseCase` | — | `Either<Failure, PrayerAlarmCapability>` | Check exact alarm permission status |

### `PrayerAlarmCapability` value object

```dart
class PrayerAlarmCapability {
  final bool canScheduleExact;
  final bool hasNotificationPermission;
}
```

---

## 7. BLoC Integration Points

| Event | Trigger | Action |
|---|---|---|
| `PrayerTimesLoaded` (after `_onLoadPrayerTimes` success) | Location + prayer times available | Fire-and-forget `SchedulePrayerNotificationsUseCase` |
| `PrayerTimesEvent.updateSettings` (in `_onUpdateSettings`) | User saves settings | Fire-and-forget `SchedulePrayerNotificationsUseCase` with new settings |
| App startup (Phase 3) | Boot / app open | `PrayerAdhanNotificationService.initialize()` → loads settings + schedules |

The bloc receives `SchedulePrayerNotificationsUseCase` as a constructor parameter.
It does NOT import `IPrayerAlarmScheduler` directly.

---

## 8. Bloc Constructor Change Impact

`PrayerTimesBloc` currently has 6 constructor parameters. Adding
`SchedulePrayerNotificationsUseCase` makes it 7. Since `@injectable` is used with
`build_runner`, the generated DI code will update automatically after `build_runner build`.

No other blocs need modification.

---

## 9. l10n Keys Needed

| Key | English | Arabic |
|---|---|---|
| `prayerNotifications` | Prayer Notifications | إشعارات أوقات الصلاة |
| `prayerNotificationsDescription` | Get notified at prayer times | احصل على إشعار عند أوقات الصلاة |
| `enablePrayerNotifications` | Enable prayer notifications | تفعيل إشعارات الصلاة |
| `minutesBeforeLabel` | Minutes before | دقائق قبل |
| `playAdhan` | Play Adhan | تشغيل الأذان |
| `playAdhanDescription` | Play adhan sound when notification fires | تشغيل صوت الأذان عند الإشعار |
| `exactAlarmPermissionRequired` | Exact alarm permission required | مطلوب إذن التنبيه الدقيق |
| `exactAlarmPermissionDescription` | To receive prayer notifications on time, grant exact alarm permission in Settings | لاستقبال إشعارات الصلاة في الوقت المحدد، امنح إذن التنبيه الدقيق في الإعدادات |
| `openSettings` | Open Settings | فتح الإعدادات |
| `notificationPermissionRequired` | Notification permission required | مطلوب إذن الإشعارات |

---

## 10. Existing Prayer l10n Keys (confirmed in app_en.arb)

Already present, no duplication needed:
- `fajr` (line ~1426), `dhuhr`, `asr`, `maghrib`, `isha`
- `prayerSettings` (line 1420)
- `prayerTimes` (line 1416)
- `nextPrayer` (line 1456)

Prayer names are available via `PrayerType` extension in `prayer_type_ui.dart` —
these will be used for notification titles.

---

## 11. Package Evaluation — Options A–E

### Overview

All five options were evaluated against the following constraints:
- No `android_alarm_manager_plus` or `flutter_background_service`
- No reuse of `just_audio` / `audio_service` for alarm audio
- No `^latest` version constraints
- No duplicate of existing functionality
- Prefer package solutions over custom MethodChannel

### Option A — `flutter_local_notifications` + `flutter_timezone` (MVP Recommended)

**Summary**: Use FLN's `zonedSchedule` + `AndroidScheduleMode.exactAllowWhileIdle` for scheduling. Use `flutter_timezone` for reliable IANA timezone name lookup. Use FLN's own Android implementation API for exact alarm permission check/request.

**Key finding**: `AndroidFlutterLocalNotificationsPlugin` exposes both:
- `canScheduleExactNotifications()` → wraps `AlarmManager.canScheduleExactAlarms()` (API 31+)
- `requestExactAlarmsPermission()` → starts `ACTION_REQUEST_SCHEDULE_EXACT_ALARM` intent

These were the only two capabilities previously identified as requiring a MethodChannel. They are already in FLN v14+ and confirmed present in v21.0.0. **No Kotlin code changes required.**

| Criterion | Assessment |
|---|---|
| Already in project | ✅ FLN + timezone already present |
| New package needed | `flutter_timezone: ^5.0.2` (small, platform-specific, actively maintained) |
| Native code changes | None |
| Adhan audio support | No — default OS notification sound only |
| Exact alarm permission | ✅ Via FLN Android API |
| Timezone reliability | ✅ Via `flutter_timezone` (`FlutterTimezone.getLocalTimezone()`) |
| Compatibility risk | Minimal — FLN is already in production use in this app |
| `audio_service` conflict | None |

**Verdict**: ✅ **Recommended for MVP**

---

### Option B — `alarm: ^5.2.1` (Phase 2 Candidate)

**Summary**: The `alarm` package provides a full alarm-clock lifecycle: schedules via Android `AlarmManager`, wakes the device, starts a foreground service, and plays custom audio. Suitable for adhan-style notifications that play a sound at the exact prayer time.

**Package metadata**:
- Latest: `5.2.1` (recent versions: 5.0.2 → 5.2.1, actively maintained)
- Dart SDK: `>=3.0.0 <4.0.0` ✅
- Flutter: `>=2.5.0` ✅
- Android plugin class: `com.gdelataillade.alarm.alarm.AlarmPlugin`
- iOS plugin class: `SwiftAlarmPlugin`
- Dependencies: `equatable`, `flutter_fgbg`, `json_annotation`, `logging`, `rxdart`, `shared_preferences`

**Compatibility assessment**:

| Criterion | Assessment |
|---|---|
| Dart SDK >=3.11.5 | ✅ Compatible (`>=3.0.0`) |
| Kotlin 2.1.0 / AGP 8.9.1 | Likely compatible — no known incompatibility; requires build verification |
| `coreLibraryDesugaringEnabled` | Not required by `alarm` itself; already enabled in project |
| `audio_service` coexistence | ⚠️ **MEDIUM RISK** — see below |
| `just_audio` conflict | None — `alarm` has own audio pipeline (not based on `just_audio`) |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | ⚠️ `alarm` requests `FOREGROUND_SERVICE` — type may conflict with existing `mediaPlayback` service |
| iOS support | ✅ Via `SwiftAlarmPlugin` |

**`audio_service` conflict analysis**:
- `MainActivity.kt` extends `AudioServiceActivity` (from `audio_service`)
- `audio_service` registers `com.ryanheise.audioservice.AudioService` as a foreground media service
- `alarm` v5.x registers its own separate foreground service for audio playback
- These are **different service components** and can coexist at the OS level
- Risk: if both services attempt MediaSession ownership simultaneously (Quran playing + adhan alarm firing), there may be a MediaSession conflict causing one to lose focus
- Mitigation: `alarm` package should pause/stop when Quran player is active; requires custom integration logic

**Verdict**: ✅ **Phase 2 candidate — do not add to main branch until validated in isolation**

---

### Option C — `android_alarm_manager_plus` (Excluded)

- Requires running Dart code in a separate isolate on alarm trigger
- Isolate wiring adds significant complexity beyond what FLN provides
- Heavy for periodic prayer alarm use case
- **Excluded per user constraint**

---

### Option D — `flutter_background_service` (Excluded)

- Creates a persistent foreground service running continuously
- Overkill for scheduled prayer alarms that only need to fire once per event
- Conflicts conceptually with the lightweight scheduling model used for athkar
- **Excluded per user constraint**

---

### Option E — Custom MethodChannel (Superseded for MVP)

- Originally proposed for `canScheduleExactAlarms()` and `requestExactAlarmPermission()`
- **Superseded**: FLN's `AndroidFlutterLocalNotificationsPlugin` already exposes both methods
- Retained as fallback option: if FLN's API is found unreliable on specific OEM devices at runtime, a thin MethodChannel (~20 lines Kotlin in `MainActivity.kt`) can be added without changing the service architecture
- `MainActivity.kt` is clean (no existing MethodChannel registrations); adding one is low-risk

**Verdict**: ⚠️ **Available as fallback — not needed for MVP**

---

## 12. Package Version Compatibility Matrix

| Package | Constraint | Resolved | Dart SDK | Flutter | Notes |
|---|---|---|---|---|---|
| `flutter_local_notifications` | `^21.0.0-dev.1` | 21.0.0 | — | — | Already in project; dev.1 stable in production |
| `timezone` | `^0.11.0` | 0.11.0 | — | — | Already in project |
| `permission_handler` | `^12.0.1` | 12.0.1 | — | — | Already in project |
| **`flutter_timezone`** | **`^5.0.2`** | **5.0.2** | **>=3.4.0** | **>=3.22.0** | **ADD — required for TZ fix** |
| `alarm` (Phase 2) | `^5.2.1` | 5.2.1 | >=3.0.0 | >=2.5.0 | Phase 2 only; validate before adopting |

Project Dart SDK: `^3.11.5` ✅ compatible with `flutter_timezone ^5.0.2` (requires `>=3.4.0`).

---

## 13. `alarm` Package Compatibility — Detailed Assessment

### Android Manifest additions required by `alarm`

The `alarm` package requires the following in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.VIBRATE"/>               <!-- already present ✅ -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/><!-- already present ✅ -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>             <!-- already present ✅ -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>    <!-- already present ✅ -->
```

Additional `alarm`-specific receiver/service entries are added automatically via
its AAR manifest merger. Manual edits are not required.

### Foreground service type conflict risk

The project already declares:
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
```

`alarm` v5.x registers a foreground service for audio. The service type used by
`alarm` is typically untyped or `phoneCall` depending on version. If it attempts
`mediaPlayback`, a conflict with `audio_service`'s media service could occur.
This must be verified during Phase 2 vetting.

### MediaSession ownership conflict (Quran player + adhan alarm)

Both `audio_service` and `alarm` may attempt to claim the Android MediaSession:
- `audio_service` owns the session during Quran playback
- `alarm` may claim it when an alarm fires with audio

**Mitigation strategy for Phase 2**:
1. Pause Quran playback before triggering adhan alarm (via `AudioPlayerHandler.pause()`)
2. Resume Quran playback after alarm dismissal
3. This requires custom integration between `PrayerAdhanNotificationService` and `AudioPlayerHandler`

This integration is out of scope for MVP.

---

## 14. `flutter_timezone` Integration

### Why `flutter_timezone` is required

`AthkarNotificationService.getLocalTimeZone()` uses a naive UTC offset → IANA name mapping:
- `+2:00:00` → `Africa/Cairo`
- `+3:00:00` → `Asia/Riyadh`
- `+4:00:00` → `Asia/Dubai`
- All other offsets → `null` (falls back to UTC)

This means any user outside Egypt/Saudi/UAE gets UTC-based notification scheduling.
For prayer times, this is a **critical correctness bug**: a user in London (UTC+1 summer)
or Jakarta (UTC+7) would receive notifications offset by hours.

`FlutterTimezone.getLocalTimezone()` returns the correct IANA timezone name from the
device's system settings (e.g., `Europe/London`, `Asia/Jakarta`). This is the only
correct approach.

### Fix scope

The fix is applied in two places:
1. `AthkarNotificationService.getLocalTimeZone()` — fix the existing naive implementation
2. `PrayerAdhanNotificationService.initialize()` — use `FlutterTimezone.getLocalTimezone()` from the start

### Platform behavior

| Platform | Method | Reliability |
|---|---|---|
| Android | `TimeZone.getDefault().getID()` via platform channel | ✅ Returns IANA name |
| iOS | `TimeZone.current.identifier` via platform channel | ✅ Returns IANA name |

`flutter_timezone` v5.0.2 is a thin platform channel wrapper with no transitive dependencies.
