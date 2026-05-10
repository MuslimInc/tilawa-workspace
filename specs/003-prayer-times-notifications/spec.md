# Feature Specification: Prayer Times Notifications (Android-First)

**Feature Branch**: `003-prayer-times-notifications`
**Created**: 2026-04-28
**Status**: Implemented — code complete, release QA pending
**Last Updated**: 2026-05-10
**Type**: Feature Specification
**Platform Scope**: Android (Google Play). iOS documented as future work.
**GitHub Tracking**: [GitHub Projects — tilawa-workspace](https://github.com/muhammadkamel/tilawa-workspace/projects)

**Input**: User requirement — stable, production-ready prayer time notifications with native Android
reliability, per-prayer configuration, graceful permission handling, and long-term maintainability.

---

## Context

Tilawa has `PrayerNotificationSettings` entity fields and `PrayerSettingsEntity`
with per-prayer notification entries. The feature infrastructure (permission 
declarations, athkar notification service pattern, `flutter_local_notifications` 
package, `timezone` package) is in place.

`flutter_local_notifications` schedules alarms via `zonedSchedule`, while native Android
`AlarmManager.setAlarmClock()` is used for exact Adhan fire times through a custom
`AdhanScheduler`. A native `AdhanPlaybackService` (foreground service) handles the
audio playback to ensure reliability even when the app is in the background or killed.
Native Kotlin modules are integrated via `MethodChannel` (`com.tilawa.app/prayer_adhan`).

A native Android `WorkManager` watchdog (`PrayerNotificationsWatchdogWorker`) runs
periodically to refresh the 14-day rolling schedule window, ensuring notifications
continue even if the app is not opened for a long time. The app explicitly avoids
using the Flutter `workmanager` package.

Adhan audio is handled by `AndroidAdhanAlarmPlayer` which delegates to the native
pipeline (`AdhanScheduler`, `AdhanReceiver`, `AdhanPlaybackService`). All constants
(IDs, keys, log tags, schedule range) are centralized in `PrayerNotificationConfig`.
All service methods are wrapped in try/catch — no scheduling failure can crash the
app or propagate to UI.

As of 2026-05-10, Sunrise participates in notification scheduling as a
notification-only item. It is persisted as `sunriseNotification`, defaults to
Off, and never supports Adhan playback.

**Device clock and scheduling recovery (2026-05-10)**:

- **UI freshness**: When the user changes device date, local time, or timezone,
  the Prayer Times experience refreshes without scattering `DateTime.now()` in
  widgets. A domain use case (`ShouldRefreshPrayerTimesUseCase`) compares the
  loaded prayer date and UTC offset to `PrayerTimesClock.now()`. The
  `PrayerTimesBloc` exposes `refreshIfStale`, triggered from
  `PrayerTimesScreen` on app resume and via a one-shot timer at the next local
  midnight. `MonthlyPrayerTimesView` uses `PrayerTimesClock` for “today” and
  month navigation consistency.
- **Background scheduling coordinates**: User-saved location (`savedLatitude` /
  `savedLongitude`) remains the primary source of truth for prayer calculation
  and scheduling. When the user relies on auto-detected location only, the last
  successfully resolved coordinates and optional name are persisted as
  `lastResolvedLatitude`, `lastResolvedLongitude`, and
  `lastResolvedLocationName`. Scheduling and startup “ensure” paths use
  **effective** coordinates (`saved*` if present, else `lastResolved*`) so
  watchdog / boot recovery does not skip with `skippedNoSavedLocation` after the
  UI has already computed times.
- **Dirty flag on forced reschedule failure**: `IAdhanAlarmPlayer` exposes
  `markNeedsReschedule()`, implemented on Android to set native
  `needs_reschedule_after_boot`. If a forced reschedule cannot run (missing
  coordinates or schedule failure), the dirty flag is re-set so a later boot or
  watchdog pass can retry. `PrayerBootReceiver` also handles
  `ACTION_DATE_CHANGED` (manifest filter) alongside existing time/timezone
  intents so calendar rollovers mark the schedule stale.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Receive prayer time notification (Priority: P1)

A user who has granted notification permission receives a heads-up notification on
their Android device at the scheduled prayer time (or N minutes before, if configured).
The notification shows the prayer name and a call-to-action. Tapping it opens the
Prayer Times screen.

**Why this priority**: Core user value. Without reliable notifications, the feature
has no purpose.

**Independent Test**: Enable Fajr notification only, set minutesBefore = 0, wait
for Fajr time → notification appears.

**Acceptance Scenarios**:

1. **Given** notification permission is granted, **When** a prayer's scheduled time
   arrives, **Then** a high-importance heads-up notification appears with the prayer
   name as title.
2. **Given** `minutesBefore = 10` for Asr, **When** Asr is 10 minutes away, **Then**
   the notification fires exactly 10 minutes early.
3. **Given** user taps the notification, **When** app handles the response, **Then**
   the Prayer Times screen is shown.
4. **Given** a prayer notification is disabled by the user, **When** the prayer time
   arrives, **Then** no notification appears for that prayer.

---

### User Story 2 — Configure per-prayer notification settings (Priority: P1)

A user can navigate to Prayer Settings and toggle notifications for each prayer
independently, set how many minutes before each prayer to notify, and choose whether
to use a default notification sound or the bundled adhan sound (if available).

**Why this priority**: Required for MVP — without settings UI, the feature cannot
be toggled by users.

**Independent Test**: Open settings → toggle Maghrib off → confirm no Maghrib
notification fires.

**Acceptance Scenarios**:

1. **Given** the prayer settings sheet is open, **When** user toggles a prayer's
   notification off, **Then** the alarm for that prayer is cancelled immediately.
2. **Given** a change to `minutesBefore`, **When** user saves settings, **Then**
   all alarms are rescheduled with the updated offset.
3. **Given** notification permission is not granted, **When** user tries to enable
   prayer notifications, **Then** a permission explanation is shown with a clear
   action to grant it.
4. **Given** exact alarm permission is not granted (Android 12+), **When** user
   enables notifications, **Then** the app informs the user and, if possible,
   links to the system alarm permission settings.
5. **Given** Sunrise is shown in the Prayer Times schedule, **When** user opens
   Sunrise alert controls, **Then** only Off and Notify only are available.

---

### User Story 3 — Alarms survive device reboot (Priority: P2)

When a user's device reboots, the scheduled prayer alarms are automatically
re-scheduled by the app using the saved settings and location.

**Why this priority**: Android cancels all `AlarmManager` alarms on reboot.
Without rescheduling, notifications disappear silently after device restart.

**Independent Test**: Schedule prayer notifications → reboot device → verify
notifications still fire at correct times.

**Acceptance Scenarios**:

1. **Given** prayer notifications are enabled and alarms are scheduled, **When**
   device reboots, **Then** the app reschedules all enabled prayer alarms on next
   startup within the non-critical services phase.
2. **Given** no location is saved at reboot time, **When** app attempts to
   reschedule, **Then** scheduling is gracefully skipped and logged; no crash.

---

### User Story 4 — Prayer Times stay correct after device clock changes (Priority: P1)

A user who changes the device date, local time, or timezone still sees an
accurate “today” prayer list, countdown / next prayer, and monthly view, and
notification scheduling recovers without requiring a manual saved city if the
app had already resolved location successfully.

**Why this priority**: Incorrect times or missed notifications after clock
changes were reported in the field; this is core trust for the feature.

**Independent Test**: Open Prayer Times with auto location → change system time
or timezone → return to app → verify reload when stale; verify Fajr (or other
notify-only) still schedules in logs without `skippedNoSavedLocation`.

**Acceptance Scenarios**:

1. **Given** prayer times were loaded for “today”, **When** the local calendar
   date changes (midnight or manual date change), **Then** the app refreshes
   loaded data when appropriate so the UI does not show the previous day’s row
   as “today”.
2. **Given** the device timezone or UTC offset changes, **When** the user
   returns to the Prayer Times screen, **Then** stale data triggers a refresh
   (via `refreshIfStale`) rather than leaving countdowns wrong.
3. **Given** the user uses auto-detected location only (no manual saved city),
   **When** a background watchdog or startup path needs coordinates to
   reschedule, **Then** scheduling uses the last persisted resolved coordinates
   and does not skip solely because `saved*` is null.
4. **Given** a forced reschedule fails or coordinates are temporarily missing,
   **When** the failure occurs on Android, **Then** native `needs_reschedule`
   remains set so a later boot or watchdog can retry.

---

### User Story 5 — Adhan sound support (Priority: P3)

A user can opt to play a bundled adhan sound when a prayer notification fires,
instead of the default notification tone.

**Why this priority**: Nice-to-have for MVP. Bundled sound asset must exist in
`android/app/src/main/res/raw/` before this can be enabled. Feature-flagged off
until asset is confirmed present.

**Independent Test**: Place `adhan.mp3` in raw resources → enable "Play Adhan"
toggle → alarm fires → adhan sound plays.

**Acceptance Scenarios**:

1. **Given** `playAdhan = true` and `adhan.mp3` is present in raw resources,
   **When** a prayer alarm fires, **Then** the notification plays the adhan sound.
2. **Given** `playAdhan = true` but the adhan sound asset is missing, **When** a
   prayer alarm fires, **Then** the notification falls back to default sound and
   logs a warning.

---

### Edge Cases

- **No location saved**: Skip scheduling gracefully; log at warning level.
- **Prayer times calculation fails** (e.g., latitude/longitude = 0.0): Skip scheduling; surface error in settings UI.
- **Exact alarm permission denied** (Android 12+): Fall back to `inexact` scheduling mode for Flutter Local Notifications; this uses the bundled `adhan` channel sound via system notification. Inform user in settings via banner.
- **Native Adhan scheduling fails**: The system remains fail-soft. If the native `AdhanAlarmPlayer` fails to schedule (e.g., due to background execution limits or permission revocation), the app falls back to standard `flutter_local_notifications` on the regular (with sound) channel to ensure the user is still notified.
- **Notification permission denied** (Android 13+): Show in-app explanation; do not repeatedly prompt.
- **All prayers disabled**: Cancel all existing alarms; schedule nothing.
- **Sunrise notification**: Sunrise can be scheduled as a standard notification
  only. It must never schedule Adhan audio or expose an Adhan control.
- **minutesBefore pushes alarm into the past**: Skip that prayer for today; schedule for tomorrow.
- **Device in Doze mode**: `setExactAndAllowWhileIdle()` defers to the next Doze maintenance window (≤15 min). This is documented as a known limitation.
- **App killed / force stopped**: Android 10+ OS restriction; no workaround without foreground service; documented limitation.
- **RTL (Arabic) UI**: All notification text, settings labels, and permission explanations must render correctly in RTL.
- **Duplicate alarms**: Use a unique `requestCode`/`notificationId` per prayer + date. Check before scheduling.
- **Manual date/time/timezone change**: Native `TIME_SET` / `TIMEZONE_CHANGED` /
  `DATE_CHANGED` (where registered) and app resume should converge on a full
  reschedule when needed; Flutter watchdog must have coordinates via saved or
  last-resolved persistence.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST schedule Android alarms for each enabled prayer using `AlarmManager.setExactAndAllowWhileIdle()` or equivalent.
- **FR-002**: System MUST reschedule alarms after: (a) app cold start, (b) settings change, (c) location/coordinates update, (d) calculation method update, (e) device reboot (`BOOT_COMPLETED`), (f) timezone change detected at startup, (g) manual time or date changes surfaced by the OS (e.g. `TIME_SET`, `DATE_CHANGED` on Android where applicable), and (h) explicit forced reschedule from prayer-times load paths when dedup/fingerprint requires it.
- **FR-003**: System MUST prevent duplicate alarms using a settings+location fingerprint deduplication strategy. Simple date-only dedup is NOT sufficient — settings changes on the same day MUST trigger a full reschedule.
- **FR-004**: System MUST check Android 12+ exact alarm permission before scheduling; fall back to `AndroidScheduleMode.inexact` if denied; surface the degraded state in the settings UI.
- **FR-005**: System MUST handle Android 13+ `POST_NOTIFICATIONS` permission requirement; suppress scheduling when denied; surface state in settings UI.
- **FR-006**: System MUST support per-prayer enable/disable (`PrayerNotificationSettings.enabled`).
- **FR-007**: System MUST support `minutesBefore` offset (0 / 5 / 10 / 15 min) per prayer; a `minutesBefore` offset that pushes the alarm into the past MUST cause that alarm to be skipped, not crash.
- **FR-008**: System MUST play default notification sound on all Phase 1 notifications.
- **FR-009**: System MUST use native Android `AlarmManager` for exact Adhan timing when enabled.
- **FR-010**: System MUST cancel all alarms when notifications are globally disabled.
- **FR-011**: System MUST handle tap on a prayer notification and navigate to the Prayer Times screen.
- **FR-012**: All user-facing strings MUST be provided in English and Arabic via ARB localization files.
- **FR-013**: Every `PrayerAdhanNotificationService` method MUST wrap its body in try/catch; no exception from scheduling, cancellation, permission check, or platform API failure may propagate to BLoC or UI.
- **FR-014**: System MUST use a settings+location fingerprint stored in SharedPreferences alongside the last-scheduled date. Scheduling MUST be triggered when the fingerprint changes, even if the date has not changed.
- **FR-015**: All notification IDs, channel IDs, SharedPreferences keys, log tags, schedule day count, and payload key names MUST be defined in a single `PrayerNotificationConfig` class. No magic numbers or string literals outside this class.
- **FR-016**: Adhan audio playback MUST be handled by a native Android foreground service (`AdhanPlaybackService`) to ensure reliability.
- **FR-017**: System MUST use a native Android WorkManager watchdog to refresh the rolling 14-day schedule window.
- **FR-018**: Foreground Adhan playback service MUST be silent (no notification sound) to avoid duplication with the Adhan audio.
- **FR-019**: Permission revocation (Notifications or Exact Alarm) MUST trigger an immediate cancellation of all scheduled native and local alarms.
- **FR-020**: System MUST support Sunrise notification as Off or Notify only.
- **FR-021**: System MUST prevent Adhan mode for Sunrise in UI, settings
  mapping, persisted settings updates, and scheduling.
- **FR-022**: System MUST persist last successfully resolved coordinates (and
  optional location label) when the user does not use a manual saved city, and
  MUST use **effective** coordinates (saved if present, else last resolved) for
  `EnsurePrayerNotificationsScheduledUseCase`, startup prayer notification init,
  and equivalent scheduling entry points.
- **FR-023**: On Android, when a forced reschedule cannot complete scheduling
  (missing coordinates or schedule failure), the implementation MUST re-assert
  the native needs-reschedule flag via `IAdhanAlarmPlayer.markNeedsReschedule()`
  where supported so recovery can retry on a later run.
- **FR-024**: Prayer Times presentation MUST refresh stale loaded state after
  local date or UTC-offset change using `PrayerTimesClock` (not ad-hoc
  `DateTime.now()` in widgets), coordinated through `PrayerTimesBloc`
  (`refreshIfStale` → conditional `loadPrayerTimes` with
  `forceReschedule: true`).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Prayer notification fires within ±1 minute of the scheduled time on a real Android device not in Doze mode.
- **SC-002**: After device reboot, all enabled prayer alarms are rescheduled within 30 seconds of boot completion (Phase 3 startup).
- **SC-003**: Toggling a prayer's notification off in settings cancels the alarm and reschedules all others within 2 seconds.
- **SC-004**: Unit test coverage ≥ 90% for scheduling use cases and `PrayerAdhanNotificationService`. (Verified 30+ tests passing, including XOR-routing and fallback scenarios).
- **SC-005**: No crash or unhandled exception on devices running Android 8–15 across all permission states.
- **SC-006**: Settings change on the same calendar day results in rescheduled alarms (fingerprint dedup test).
- **SC-007**: No direct call to `AndroidFlutterLocalNotificationsPlugin`, `IAdhanAlarmPlayer`, or scheduling APIs exists anywhere in presentation layer or BLoC.
- **SC-008**: `alarm` package import appears in zero files in Phase 1 (confirmed by static analysis / grep).
- **SC-009**: Native Adhan scheduling MUST be confirmed as the source of truth for audio AND visual notification when it succeeds. The implementation uses XOR routing — if `IAdhanAlarmPlayer.scheduleAdhan` returns `true`, the service skips Flutter Local Notification scheduling for that prayer entirely, and `AdhanPlaybackService` posts the user-visible mediaPlayback foreground-service notification at fire time. This prevents duplicate notifications. Flutter Local Notification is the fallback path when native scheduling fails or is unsupported, and uses the standard adhan channel (with sound) in that case.
- **SC-010**: Sunrise notifications, when enabled, fire as standard
  notification-only alarms and never trigger Adhan audio.
- **SC-011**: After device date, local time, or timezone change, Prayer Times UI
  reflects the new “today” within one resume or midnight timer cycle without
  requiring an app reinstall.
- **SC-012**: With auto-location only (no manual saved city), post-change
  scheduling logs do not report `skippedNoSavedLocation` once a successful
  resolve has been persisted as `lastResolved*`.

---

## Assumptions

- Tilawa is published on Google Play only; iOS is not a current release target.
- `USE_EXACT_ALARM`, `POST_NOTIFICATIONS`, and `RECEIVE_BOOT_COMPLETED` are declared in `AndroidManifest.xml`. `SCHEDULE_EXACT_ALARM` is intentionally NOT declared — Tilawa qualifies for the auto-grant `USE_EXACT_ALARM` category for religious-observance alarms. A Play-rejection fallback to `SCHEDULE_EXACT_ALARM` is documented in plan.md §Permission Strategy.
- `flutter_local_notifications: ^21.0.0-dev.1` is already a dependency — confirmed.
- `timezone` package is already used by `AthkarNotificationService` — confirmed.
- User's saved location (`savedLatitude`, `savedLongitude`) takes **priority**
  over auto-detected coordinates for scheduling and calculation when both exist.
  If the user has not saved a manual city, the last successfully resolved
  auto-location (`lastResolvedLatitude` / `lastResolvedLongitude`) is used for
  background scheduling and startup ensure paths so watchdogs match UI-derived
  coordinates. Live GPS is not polled ad hoc during scheduling.
- `PrayerNotificationSettings` is reused for Sunrise, but Sunrise is constrained
  to notification-only behavior by settings update logic and presentation mapping.
- No payment or premium gating on this feature.
- Bundled adhan sound (`adhan.mp3`) is already in the project.
