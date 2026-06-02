# Implementation Plan: Prayer Times Notifications (Android-First)

**Branch**: `003-prayer-times-notifications` | **Date**: 2026-04-28 (revised 2026-05-10) | **Spec**: [spec.md](spec.md)
**Status**: Production-ready design
**Input**: Feature specification from `specs/003-prayer-times-notifications/spec.md`
**Research**: Phase 0 + package evaluation in [research.md](research.md)
**GitHub Tracking**: [GitHub Projects — tilawa-workspace](https://github.com/muhammadkamel/tilawa-workspace/projects)

---

## Summary

A production-ready prayer times notification feature for Android, designed for
long-term stability and maintainability. Exact timing is achieved via native Android
`AlarmManager` and a custom `AdhanPlaybackService` (foreground service) for the highest
reliability even when the app is killed. `flutter_local_notifications` provides
the visual UI component, routed to a silent channel when native audio is active.

A `WorkManager` watchdog ensures the 14-day rolling schedule remains fresh.
Native capability gaps are covered by both native checks and FLN capability APIs.

All scheduling logic lives in a new `PrayerAdhanNotificationService` isolated behind
`IPrayerAdhanNotificationService`. All adhan audio logic is isolated behind `IAdhanAlarmPlayer`.
Centralized constants live in `PrayerNotificationConfig`. Comprehensive use cases
cover scheduling, cancellation, capability check, and permission request — ensuring BLoC
and UI never call platform APIs directly. Comprehensive error handling ensures no crash
on any permission state, platform API failure, or scheduling edge case. iOS is future work.

Current implementation note (2026-05-10): Sunrise is now schedulable as a
notification-only prayer time entry. It uses the same `PrayerNotificationSettings`
shape as the five prayers, but UI/domain update logic prevents Adhan mode.

### Device clock freshness and scheduling recovery (2026-05-10)

**Problem addressed**: Stale Prayer Times UI (countdown, today, monthly) and
missed notify-only notifications after manual device date/time/timezone changes,
including watchdog paths that skipped scheduling when only auto-location was
available (`skippedNoSavedLocation`).

**UI / domain (Clean Architecture)**:

- `ShouldRefreshPrayerTimesUseCase` — pure domain predicate: reload if loaded
  date ≠ `PrayerTimesClock.now()` local date, or UTC offset changed.
- `PrayerTimesBloc` — `PrayerTimesEvent.refreshIfStale` delegates to the use
  case; if stale, dispatches `loadPrayerTimes(forceReschedule: true)`.
- `PrayerTimesScreen` — `WidgetsBindingObserver` on `resumed` + one-shot
  `Timer` to next local midnight (using `PrayerTimesClock`); dispatches
  `refreshIfStale` only (no business rules in the widget).
- `MonthlyPrayerTimesView` — uses `PrayerTimesClock.now()` for current
  month/year and “is today” comparisons.

**Scheduling coordinates and native recovery**:

- `PrayerSettingsEntity` — `lastResolvedLatitude`, `lastResolvedLongitude`,
  `lastResolvedLocationName`; getters `effectiveSchedulingLatitude` /
  `effectiveSchedulingLongitude` / `effectiveSchedulingLocationName` prefer
  `saved*` over `lastResolved*`.
- `PrayerTimesBloc` — after successful auto-location prayer load, persists
  `lastResolved*` when `saved*` is absent; manual location sets both.
- `EnsurePrayerNotificationsScheduledUseCase` and
  `AppStartupTasks.initializePrayerNotifications` — schedule using effective
  coordinates; on forced reschedule with missing coords or schedule `Left`,
  call `IAdhanAlarmPlayer.markNeedsReschedule()` on Android.
- Native — `MethodChannelLogic` handles `markNeedsReschedule`;
  `PrayerBootReceiver` registers `ACTION_DATE_CHANGED` in the manifest in
  addition to existing boot/time intents.

**Tests**: Unit tests for `ShouldRefreshPrayerTimesUseCase`, effective-location
getters, `EnsurePrayerNotificationsScheduledUseCase` (effective coords + dirty
re-mark), and `PrayerTimesBloc` persistence behavior.

---

## Package Evaluation — Options A–E

> Full evaluation details and compatibility matrix are in [research.md §11–§14](research.md).

| Option | Package(s) | Summary | Verdict |
|---|---|---|---|
| **A** | `flutter_local_notifications` + `flutter_timezone` | FLN `zonedSchedule` + exact alarm; `flutter_timezone` for device TZ; FLN Android API for permission check | ✅ **Visual Baseline — Selected** |
| **B** | `alarm: ^5.2.1` | Full alarm-clock lifecycle, foreground service, custom audio; ideal for adhan-sound mode | ✅ **Phase 2 — Abstraction-ready; validate before adopting** |
| C | `android_alarm_manager_plus` | Background Dart execution on alarm; requires isolate wiring; heavier than FLN for this use case | ❌ **Excluded per user constraints** |
| D | `flutter_background_service` | Persistent foreground service; overkill for periodic prayer alarms | ❌ **Excluded per user constraints** |
| **E** | Custom MethodChannel | `canScheduleExactAlarms()` + `requestExactAlarmPermission()` in Kotlin; native Adhan playback service | ✅ **Production Implementation — Selected** |

### Recommended Architecture

```
Production baseline  →  Option E: Native AlarmManager + AdhanPlaybackService
Phase 2 (adhan)      →  Option B: alarm package behind IAdhanAlarmPlayer abstraction (future)
Visual Component     →  Option A: FLN + flutter_timezone
```

---

## Technical Context

**Language/Version**: Flutter 3.41.7, Dart 3.11.5 (via fvm), `sdk: ^3.12.1`
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
- **Native Kotlin Implementation**: **PASS** — `AdhanScheduler`, `AdhanReceiver`, and `AdhanPlaybackService` provide the highest level of reliability for prayer alarms on Android.
- **No Direct Platform Calls from UI or BLoC**: **PASS** — UI only dispatches BLoC events; BLoC calls use cases only; use cases call service interfaces only; `AndroidFlutterLocalNotificationsPlugin` is accessed only inside `PrayerAdhanNotificationService`.
- **BLoC and GoRouter**: **PASS** — `PrayerTimesBloc` handles reschedule trigger and capability check via use cases; settings sheet reads capability from BLoC state; no direct service calls from widgets.
- **Atomic Design and Tilawa UI Kit**: **PASS** — Notification settings UI uses existing `PrayerSettingsSheet` pattern, `SwitchListTile`, Tilawa tokens (`theme.tokens`), `context.l10n`; no hard-coded colors or spacing.
- **Responsive and Adaptive UI**: **PASS** — Settings sheet uses `DraggableScrollableSheet`; new section follows same pattern; RTL labels tested via l10n.
- **Performance and Low Jank**: **PASS** — Scheduling is fire-and-forget via `unawaited()` in bloc; Phase 3 runs in non-critical background path; no build-method I/O.
- **Error Resilience**: **PASS** — Every `PrayerAdhanNotificationService` method is wrapped in try/catch; errors are logged at `e` level with `[PrayerNotificationConfig.logTag]`; no exception propagates to BLoC or UI.
- **Centralized Configuration**: **PASS** — All notification IDs, channel IDs, timing constants, SharedPreferences keys, log tags, and schedule parameters defined in `PrayerNotificationConfig`; no magic numbers anywhere else.
- **Structured Logging**: **PASS** — All service methods log at `d` / `w` / `e` levels using `[PrayerNotificationConfig.logTag]`; scheduling attempts log prayer name, date, scheduled time, and alarm mode (exact/inexact).
- **Testing Discipline**: **PASS** — Unit tests for service, use cases, and BLoC are planned; FLN plugin and adhan player tested via mocks; coverage target ≥ 90% on new code.
- **Safe Refactoring and Delivery**: **PASS** — No existing code is restructured; changes are additive; `PrayerTimesBloc` constructor change handled by `build_runner` regeneration; `PrayerSettingsSheet` is additive-only.
- **Google Play Compliance**: **PASS** — `USE_EXACT_ALARM` requires Store justification (documented in §Permission Strategy); foreground service is appropriately typed as `mediaPlayback`.

---

## Project Structure

### Documentation (this feature)

- [spec.md](spec.md) — Requirement definition, acceptance scenarios, edge cases
- [plan.md](plan.md) — (this file) Implementation strategy, architecture, tasks
- [research.md](research.md) — Package evaluation, technical findings, reference links

### Core / Shared

- [prayer_notification_config.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/core/services/prayer_notification_config.dart) — Centralized IDs and keys
- [prayer_adhan_notification_service.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/core/services/prayer_adhan_notification_service.dart) — Concrete implementation of scheduling logic

### Domain (tilawa_core)

- [prayer_adhan_notification_service_interface.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart) — IPrayerAdhanNotificationService
- [adhan_alarm_player_interface.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/prayer_times/domain/services/adhan_alarm_player_interface.dart) — IAdhanAlarmPlayer

### Presentation

- [prayer_notification_settings_sheet.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/prayer_times/presentation/widgets/prayer_notification_settings_sheet.dart) — Global and per-prayer notification controls
- [prayer_settings_sheet.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/prayer_times/presentation/widgets/prayer_settings_sheet.dart) — Calculation/display settings
- [prayer_times_bloc.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/prayer_times/presentation/bloc/prayer_times_bloc.dart) — Triggers rescheduling on settings change; persists `lastResolved*`; handles `refreshIfStale`
- [prayer_times_screen.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/prayer_times/presentation/screens/prayer_times_screen.dart) — App lifecycle + midnight timer → `refreshIfStale`
- [monthly_prayer_times_view.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/prayer_times/presentation/widgets/monthly_prayer_times_view.dart) — `PrayerTimesClock` for month/today

### Domain (use cases)

- [should_refresh_prayer_times_use_case.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/prayer_times/domain/usecases/should_refresh_prayer_times_use_case.dart) — Stale check vs clock
- [ensure_prayer_notifications_scheduled_use_case.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/prayer_times/domain/usecases/ensure_prayer_notifications_scheduled_use_case.dart) — Effective coords + `markNeedsReschedule` on forced failure

---

## Notification Channels

| Channel ID | Name | Sound | Used when |
|---|---|---|---|
| `prayer_adhan_silent` | Prayer Notifications (Silent) | None | Native Adhan audio is active |
| `prayer_adhan` | Adhan Notifications | `adhan.mp3` | Native Adhan fails or is unsupported |
| `prayer_times` | Prayer Notifications | Default | Standard prayer notification (no Adhan), including Sunrise |

---

## Fallback Behavior

- **Native Exact Alarm Success**:
  - `IAdhanAlarmPlayer` schedules native `AlarmManager.setAlarmClock`.
  - `PrayerAdhanNotificationService` schedules visual FLN on `prayer_adhan_silent` channel.
  - **Result**: Native Adhan audio plays; visual notification is silent.
- **Native Exact Alarm Failure**:
  - `IAdhanAlarmPlayer` fails or is unsupported.
  - `PrayerAdhanNotificationService` schedules visual FLN on `prayer_adhan` channel (with sound).
  - **Result**: Notification system plays `adhan.mp3`; visual notification is audible.

> No duplicate sound path exists because `adhanHandledNatively` flag ensures channel selection is exclusive.

### Sunrise Notification Behavior

- Sunrise is included in the scheduling loop when `sunriseNotification.enabled`
  is true.
- Sunrise always resolves to `playAdhan = false`.
- Sunrise uses the standard `prayer_times` notification channel.
- Sunrise is included in watchdog "any enabled notification" checks.
- The UI exposes Sunrise as Off/Notify only in row-level controls and Manage
  Alerts.

---

## Permission Strategy

### Android 13+ (API 33+) — POST_NOTIFICATIONS
- Handled via `NotificationPermissionService`.
- If revoked, `PrayerAdhanNotificationService.schedulePrayerNotifications` calls `cancelAllPrayerNotifications` and clears dedup state.

### Android 12+ (API 31+) — USE_EXACT_ALARM
- Only `USE_EXACT_ALARM` is declared in `AndroidManifest.xml`. `SCHEDULE_EXACT_ALARM` is intentionally NOT declared because Tilawa qualifies for the auto-grant `USE_EXACT_ALARM` category and we do not want to present the user-facing exact-alarm permission prompt.
- **Justification (Play Console form)**: "Tilawa schedules prayer notifications at precise times for religious observance; accurate timing is required by the feature's core purpose."
- Acceptable for the "Religious Observance / Alarms" category on Google Play.
- **Fallback plan**: If Google Play rejects the `USE_EXACT_ALARM` declaration during review, switch the manifest to `SCHEDULE_EXACT_ALARM` and surface the request flow via `MethodChannelLogic.requestIgnoreBatteryOptimizations`-style intent (`Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM`). The capability check / fallback to `inexact` mode in `PrayerAdhanNotificationService` already covers this path.

---

## Tests

### Use Case Tests
- `CheckPrayerAlarmCapabilityUseCaseTest`: Verifies correct capability reporting.
- `SchedulePrayerNotificationsUseCaseTest`: Verifies rescheduling logic.
- `CancelAllPrayerNotificationsUseCaseTest`: Verifies comprehensive cancellation.

### Service Tests
- `PrayerAdhanNotificationServiceTest`:
  - `reschedule Alarms on Fingerprint Change`
  - `suppress Scheduling When Notification Permission Denied`
  - `routing - Success Path (Silent Channel)`
  - `routing - Failure Path (Standard Adhan Channel)`
  - `deduplication logic`
  - `timezone change detection`

### Device clock and scheduling recovery (2026-05-10)
- `should_refresh_prayer_times_use_case_test.dart` — stale date / offset behavior.
- `prayer_settings_entity_test.dart` — effective scheduling getters.
- `ensure_prayer_notifications_scheduled_use_case_test.dart` — effective coords,
  `markNeedsReschedule` when forced reschedule lacks location.
- `prayer_times_bloc_test.dart` — `lastResolved*` persistence vs manual saved.

### Native Cleanup Verification
- `cancelAll` in `AdhanScheduler.kt` verified to clear `AlarmManager` and `PrayerBootReceiver` persistent storage.
