# Data Model: Prayer Times Notifications

**Feature**: `003-prayer-times-notifications`
**Created**: 2026-04-28
**Status**: Implemented (Phase 1 complete)

---

## Overview

This feature introduces no new persistence models. It operates entirely on
existing domain entities (`PrayerSettingsEntity`, `PrayerTimeEntity`) and adds
two new domain constructs: a value object (`PrayerAlarmCapability`) and
centralized constants (`PrayerNotificationConfig`). All scheduling state is
stored in `SharedPreferences` via two deduplication keys.

---

## Existing Entities (Pre-existing — no change)

### `PrayerNotificationSettings`

Location: `apps/tilawa/lib/features/prayer_times/domain/entities/`
(embedded in `PrayerSettingsEntity`)

| Field | Type | Description |
|---|---|---|
| `enabled` | `bool` | Whether this prayer's notification is active |
| `minutesBefore` | `int` | Minutes before prayer time to fire (0/5/10/15) |
| `playAdhan` | `bool` | Play bundled adhan sound instead of default tone |
| `customAdhanUrl` | `String?` | Future: custom adhan URL (out of scope for Phase 1–2) |

### `PrayerSettingsEntity`

Location: `apps/tilawa/lib/features/prayer_times/domain/entities/prayer_settings_entity.dart`
Generated with: Freezed + `@HydratedBloc`-compatible JSON

| Field | Type | Description |
|---|---|---|
| `fajrNotification` | `PrayerNotificationSettings` | Fajr alarm config |
| `dhuhrNotification` | `PrayerNotificationSettings` | Dhuhr alarm config |
| `asrNotification` | `PrayerNotificationSettings` | Asr alarm config |
| `maghribNotification` | `PrayerNotificationSettings` | Maghrib alarm config |
| `ishaNotification` | `PrayerNotificationSettings` | Isha alarm config |
| *(other fields)* | *(various)* | Calculation method, asr method, etc. |

### `PrayerTimeEntity`

Location: `apps/tilawa/lib/features/prayer_times/domain/entities/prayer_time_entity.dart`

| Field | Type | Description |
|---|---|---|
| `date` | `DateTime` | Calendar date for this entry |
| `fajr` | `DateTime` | Fajr prayer time |
| `sunrise` | `DateTime` | Sunrise time |
| `dhuhr` | `DateTime` | Dhuhr prayer time |
| `asr` | `DateTime` | Asr prayer time |
| `maghrib` | `DateTime` | Maghrib prayer time |
| `isha` | `DateTime` | Isha prayer time |

---

## New Domain Constructs (Added by this feature)

### `PrayerAlarmCapability` (Value Object)

Location: `apps/tilawa/lib/features/prayer_times/domain/value_objects/prayer_alarm_capability.dart`

Represents the result of checking whether this device can schedule prayer
alarms reliably. Read from `PrayerTimesBloc.state.alarmCapability` in the UI.

| Field | Type | Description |
|---|---|---|
| `canScheduleExact` | `bool` | Device supports exact alarm scheduling (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` granted) |
| `hasNotificationPermission` | `bool` | `POST_NOTIFICATIONS` permission is granted (required on Android 13+) |

**Computed getter**:
```dart
bool get isFullyCapable => canScheduleExact && hasNotificationPermission;
```

**Used by**: `PrayerTimesBloc` (state), `PrayerSettingsSheet` (capability banners).

---

## New Interfaces (tilawa_core / domain/services)

### `IPrayerAdhanNotificationService`

Location: `apps/tilawa/lib/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart`

The primary service abstraction. BLoC depends on this only via use cases — never directly.

| Method | Returns | Description |
|---|---|---|
| `initialize()` | `Future<void>` | Init FLN channels, detect TZ, register tap handler |
| `schedulePrayerNotifications(settings, days, {forceReschedule})` | `Future<void>` | Schedule/reschedule all enabled alarms for 14 days |
| `cancelAllPrayerNotifications()` | `Future<void>` | Cancel all static (2001–2006) and dynamic (20M range) IDs |
| `canScheduleExactAlarms()` | `Future<bool>` | Check exact alarm permission via FLN Android plugin |
| `requestExactAlarmPermission()` | `Future<void>` | Open system settings for exact alarm permission |
| `handleNotificationResponse(response)` | `Future<void>` | Handle tap → navigate to Prayer Times screen |
| `fireTestNotification({prayer, playAdhan})` | `Future<void>` | Debug-only: fire immediate notification for testing |

### `IAdhanAlarmPlayer`

Location: `apps/tilawa/lib/features/prayer_times/domain/services/adhan_alarm_player_interface.dart`

Abstraction over adhan audio playback. Allows Phase 2 (`alarm` package) to be
adopted without modifying domain, BLoC, or UI.

| Method | Returns | Description |
|---|---|---|
| `isSupported` (getter) | `bool` | Whether this implementation can play adhan audio |
| `scheduleAdhan({id, scheduledTime, prayerName})` | `Future<void>` | Schedule adhan audio playback |
| `cancelAdhan(id)` | `Future<void>` | Cancel a scheduled adhan by ID |
| `cancelAllAdhans()` | `Future<void>` | Cancel all adhans in the prayer ID range |

---

## Implementations

### `PrayerAdhanNotificationService`

Location: `apps/tilawa/lib/core/services/prayer_adhan_notification_service.dart`
DI: `@LazySingleton(as: IPrayerAdhanNotificationService)`

Concrete implementation of `IPrayerAdhanNotificationService` using
`flutter_local_notifications` + `flutter_timezone`. All methods are wrapped
in try/catch — no exception propagates to BLoC or UI.

**Key behaviors**:
- Channel version guard: reads `adhanChannelVersionKey` from SharedPrefs; if
  version < `adhanChannelVersion` (currently 2), deletes and recreates the
  adhan channel with `RawResourceAndroidNotificationSound('adhan')`.
- Dedup check: compares stored date + settings fingerprint; skips scheduling
  when fingerprint matches unless `forceReschedule = true`.
- Dynamic ID formula: `20_000_000 + (dayOffset × 10) + prayerType.index`
- Sound routing: `playAdhan = true` → `adhan` channel; `playAdhan = false` →
  default channel.

### `NoOpAdhanAlarmPlayer`

Location: `apps/tilawa/lib/core/services/noop_adhan_alarm_player.dart`
DI: `@LazySingleton(as: IAdhanAlarmPlayer)`

Phase 1 no-op implementation. `isSupported = false`. All methods are
immediate async returns. Replaced in Phase 2 by `AlarmPackageAdhanPlayer`
without touching domain, BLoC, or UI.

---

## Configuration

### `PrayerNotificationConfig`

Location: `apps/tilawa/lib/core/services/prayer_notification_config.dart`

All constants for the feature. **No magic numbers or string literals exist
outside this class.**

| Constant | Value | Description |
|---|---|---|
| `channelId` | `'com.tilawa.app.prayer'` | Default notification channel |
| `adhanChannelId` | `'com.tilawa.app.prayer_adhan'` | Adhan sound channel |
| `channelName` | `'Prayer Times'` | Channel display name |
| `adhanChannelName` | `'Prayer Times (Adhan)'` | Adhan channel display name |
| `staticIdBase` | `2001` | Static IDs: fajr=2001..isha=2005, sunrise=2006 |
| `dynamicIdBase` | `20_000_000` | Base for dynamic IDs (dayOffset × 10 + prayer.index) |
| `scheduleDaysAhead` | `14` | Number of days to schedule in advance |
| `dedupDateKey` | `'prayer_notifications_last_scheduled_date'` | SharedPrefs key |
| `settingsFingerprintKey` | `'prayer_notifications_settings_fingerprint'` | SharedPrefs key |
| `adhanChannelVersionKey` | `'prayer_notifications_adhan_channel_version'` | SharedPrefs key |
| `adhanChannelVersion` | `2` | Current channel version (bump to force channel recreate) |
| `adhanSoundRawName` | `'adhan'` | Android `res/raw` filename (no extension) |
| `adhanSoundFilename` | `'adhan.mp3'` | Full filename for iOS |
| `adhanAssetPath` | `'assets/audio/adhan.mp3'` | Flutter asset path |
| `logTag` | `'[PrayerTimes]'` | Prefix for all service log messages |
| `payloadTypeKey` | `'type'` | Notification payload key |
| `payloadTypeValue` | `'prayer'` | Notification payload value |
| `payloadPrayerKey` | `'prayer'` | Payload: prayer name key |
| `payloadDateKey` | `'date'` | Payload: date key (`'yyyyMMdd'`) |

**Static helpers**:
```dart
static int staticId(PrayerType prayer)  // → 2001 + prayer.index
static int dynamicId(int dayOffset, PrayerType prayer)  // → 20_000_000 + dayOffset*10 + prayer.index
```

---

## SharedPreferences Keys (Persistence)

All keys owned by `PrayerNotificationConfig`. Never changed after first release.

| Key | Type | Description |
|---|---|---|
| `prayer_notifications_last_scheduled_date` | `String` (`'yyyy-MM-dd'`) | Date of last full schedule run |
| `prayer_notifications_settings_fingerprint` | `String` (SHA-256 hex) | Hash of settings+location+method |
| `prayer_notifications_adhan_channel_version` | `int` | Current adhan channel version; triggers channel recreate when stale |

---

## Notification ID Space

| Range | Purpose |
|---|---|
| `2001–2006` | Static (test/debug) IDs: fajr=2001, dhuhr=2002, asr=2003, maghrib=2004, isha=2005, sunrise=2006 |
| `20_000_000–20_000_145` | Dynamic: 14 days × 6 prayers × 10-slot stride. Never overlaps static range. |

---

## Scheduling State Machine

```
App start / settings change / location change / reboot
       │
       ▼
PrayerTimesBloc._on* ──unawaited──► SchedulePrayerNotificationsUseCase
                                            │
                                            ▼
                              PrayerAdhanNotificationService
                              .schedulePrayerNotifications()
                                            │
                         ┌──────────────────┼──────────────────┐
                         ▼                  ▼                  ▼
                  Dedup check?        cancelAll()         schedule loop
                  (date+fingerprint)   static+dynamic      14 days × 5 prayers
                         │                  │                  │
                   hit → skip        IDs 2001–2006       zonedSchedule()
                                    + 20M range          exactAllowWhileIdle
                                                         (or inexact fallback)
```
