# Feature Specification: Prayer Times Notifications (Android-First)

**Feature Branch**: `003-prayer-times-notifications`
**Created**: 2026-04-28
**Status**: Draft
**Type**: Feature Specification
**Platform Scope**: Android (Google Play). iOS documented as future work.
**GitHub Tracking**: [GitHub Projects — tilawa-workspace](https://github.com/muhammadkamel/tilawa-workspace/projects) *(no project item created yet — see OD-6)*
**Input**: User requirement — stable, production-ready prayer time notifications with native Android
reliability, per-prayer configuration, graceful permission handling, and long-term maintainability.

---

## Context

Tilawa currently has `PrayerNotificationSettings` entity fields and `PrayerSettingsEntity`
with per-prayer notification entries, but **no scheduling code exists**. The feature
infrastructure (permission declarations, athkar notification service pattern,
`flutter_local_notifications` package, `timezone` package) is already in place.

`flutter_local_notifications` schedules alarms via `zonedSchedule` +
`AndroidScheduleMode.exactAllowWhileIdle`, which calls `AlarmManager.setExactAndAllowWhileIdle()`
under the hood. The Android-specific FLN implementation (`AndroidFlutterLocalNotificationsPlugin`)
exposes `canScheduleExactNotifications()` and `requestExactAlarmsPermission()`, covering the only
two capabilities previously identified as requiring a custom MethodChannel. **No native Kotlin
changes are required.** `flutter_timezone` is added for reliable IANA timezone detection
(replacing the existing fragile UTC-offset mapping in `AthkarNotificationService`).

Adhan audio is isolated behind `IAdhanAlarmPlayer` so Phase 1 ships with a no-op implementation
and Phase 2 can adopt the `alarm` package without touching domain, BLoC, or UI. All constants
(IDs, keys, log tags, schedule range) are centralized in `PrayerNotificationConfig`. All service
methods are wrapped in try/catch — no scheduling failure can crash the app or propagate to UI.

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

### User Story 4 — Adhan sound support (Priority: P3)

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
- **Exact alarm permission denied** (Android 12+): Fall back to `inexact` scheduling mode; inform user in settings.
- **Notification permission denied** (Android 13+): Show in-app explanation; do not repeatedly prompt.
- **All prayers disabled**: Cancel all existing alarms; schedule nothing.
- **minutesBefore pushes alarm into the past**: Skip that prayer for today; schedule for tomorrow.
- **Device in Doze mode**: `setExactAndAllowWhileIdle()` defers to the next Doze maintenance window (≤15 min). This is documented as a known limitation.
- **App killed / force stopped**: Android 10+ may prevent boot receiver; documented limitation.
- **RTL (Arabic) UI**: All notification text, settings labels, and permission explanations must render correctly in RTL.
- **Duplicate alarms**: Use a unique `requestCode`/`notificationId` per prayer + date. Check before scheduling.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST schedule Android alarms for each enabled prayer using `AlarmManager.setExactAndAllowWhileIdle()` or equivalent.
- **FR-002**: System MUST reschedule alarms after: (a) app cold start, (b) settings change, (c) location/coordinates update, (d) calculation method update, (e) device reboot (`BOOT_COMPLETED`), (f) timezone change detected at startup.
- **FR-003**: System MUST prevent duplicate alarms using a settings+location fingerprint deduplication strategy. Simple date-only dedup is NOT sufficient — settings changes on the same day MUST trigger a full reschedule.
- **FR-004**: System MUST check Android 12+ exact alarm permission before scheduling; fall back to `AndroidScheduleMode.inexact` if denied; surface the degraded state in the settings UI.
- **FR-005**: System MUST handle Android 13+ `POST_NOTIFICATIONS` permission requirement; suppress scheduling when denied; surface state in settings UI.
- **FR-006**: System MUST support per-prayer enable/disable (`PrayerNotificationSettings.enabled`).
- **FR-007**: System MUST support `minutesBefore` offset (0 / 5 / 10 / 15 min) per prayer; a `minutesBefore` offset that pushes the alarm into the past MUST cause that alarm to be skipped, not crash.
- **FR-008**: System MUST play default notification sound on all Phase 1 notifications.
- **FR-009**: System MUST use `AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications()` to check exact alarm permission and `requestExactAlarmsPermission()` to request it. BLoC and UI MUST NOT call these APIs directly — only via use cases and service interface.
- **FR-010**: System MUST cancel all alarms when notifications are globally disabled.
- **FR-011**: System MUST handle tap on a prayer notification and navigate to the Prayer Times screen.
- **FR-012**: All user-facing strings MUST be provided in English and Arabic via ARB localization files.
- **FR-013**: Every `PrayerAdhanNotificationService` method MUST wrap its body in try/catch; no exception from scheduling, cancellation, permission check, or platform API failure may propagate to BLoC or UI.
- **FR-014**: System MUST use a settings+location fingerprint stored in SharedPreferences alongside the last-scheduled date. Scheduling MUST be triggered when the fingerprint changes, even if the date has not changed.
- **FR-015**: All notification IDs, channel IDs, SharedPreferences keys, log tags, schedule day count, and payload key names MUST be defined in a single `PrayerNotificationConfig` class. No magic numbers or string literals outside this class.
- **FR-016**: Adhan audio playback MUST be isolated behind `IAdhanAlarmPlayer`. The `alarm` package (or any audio library) MUST NOT be imported outside its own `IAdhanAlarmPlayer` implementation class. Phase 1 ships `NoOpAdhanAlarmPlayer`.

### Out of Scope

- iOS notification scheduling — documented as future work.
- Bundled adhan sound — channel infrastructure declared; Phase 2 after `IAdhanAlarmPlayer` + `alarm` package vetting.
- Full-screen intent / wake-screen-on-alarm — too aggressive; documented as future work.
- Custom adhan URL streaming.
- Cloud sync of notification settings.
- WorkManager-based guaranteed rescheduling after app force-stop — no foreground service unless justified.

### Key Entities

- **`PrayerNotificationSettings`**: Already exists. Fields: `enabled`, `minutesBefore`, `playAdhan`, `customAdhanUrl`.
- **`PrayerSettingsEntity`**: Already exists. Contains per-prayer notification settings for all 5 prayers.
- **`PrayerTimeEntity`**: Already exists. Contains computed `DateTime` for each prayer.
- **`PrayerAlarmCapability`** *(new — domain value object)*: `{canScheduleExact: bool, hasNotificationPermission: bool}`. Getter `isFullyCapable`.
- **`IPrayerAdhanNotificationService`** *(new — tilawa_core interface)*: Scheduling, cancellation, exact alarm capability. BLoC depends on this via use cases only.
- **`IAdhanAlarmPlayer`** *(new — tilawa_core interface)*: Adhan audio abstraction. Phase 1: `NoOpAdhanAlarmPlayer`. Phase 2: `AlarmPackageAdhanPlayer`.
- **`PrayerNotificationConfig`** *(new)*: All constants (IDs, keys, log tag, schedule range). No magic numbers elsewhere.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Prayer notification fires within ±1 minute of the scheduled time on a real Android device not in Doze mode.
- **SC-002**: After device reboot, all enabled prayer alarms are rescheduled within 30 seconds of boot completion (Phase 3 startup).
- **SC-003**: Toggling a prayer's notification off in settings cancels the alarm and reschedules all others within 2 seconds.
- **SC-004**: Unit test coverage ≥ 80% for scheduling use cases and `PrayerAdhanNotificationService`.
- **SC-005**: No crash or unhandled exception on devices running Android 8–15 across all permission states.
- **SC-006**: Settings change on the same calendar day results in rescheduled alarms (fingerprint dedup test).
- **SC-007**: No direct call to `AndroidFlutterLocalNotificationsPlugin`, `IAdhanAlarmPlayer`, or scheduling APIs exists anywhere in presentation layer or BLoC.
- **SC-008**: `alarm` package import appears in zero files in Phase 1 (confirmed by static analysis / grep).

---

## Assumptions

- Tilawa is published on Google Play only; iOS is not a current release target.
- `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` are already declared in `AndroidManifest.xml` — confirmed by codebase investigation.
- `flutter_local_notifications: ^21.0.0-dev.1` is already a dependency — confirmed.
- `timezone` package is already used by `AthkarNotificationService` — confirmed.
- User's saved location (`savedLatitude`, `savedLongitude`) is the source of truth for scheduling; live GPS is not used during scheduling.
- `PrayerNotificationSettings` entity is not modified — it already has the required fields.
- No payment or premium gating on this feature.
- Bundled adhan sound (`adhan.mp3`) is NOT yet in the project; adhan sound support is feature-flagged and documented as a follow-up.

---

## Open Decisions

| # | Decision | Options | Default for MVP |
|---|---|---|---|
| OD-1 | Exact alarm permission UX | (a) Auto-link to system settings, (b) Show explanation only | (b) Show explanation only |
| OD-2 | Sound for MVP | (a) Default notification sound only, (b) Bundle adhan.mp3 now | (a) Default only |
| OD-3 | Full-screen intent | (a) Use for prayers (wake screen), (b) Omit for MVP | (b) Omit |
| OD-4 | Days to schedule ahead | (a) 7 days, (b) 10 days, (c) 14 days | (b) 10 days |
| OD-5 | minutesBefore scope | (a) Global (one value for all prayers), (b) Per-prayer | (a) Global for MVP, (b) in follow-up |
| OD-6 | GitHub project tracking | Create a GitHub Projects item (or issue) for Prayer Times Notifications in [tilawa-workspace Projects](https://github.com/muhammadkamel/tilawa-workspace/projects) and link it back here. No item exists as of 2026-04-28. | *(unresolved — action required before release)* |

---

## iOS — Future Work

iOS support is documented here for future planning and MUST NOT be implemented in this spec:

- `flutter_local_notifications` `zonedSchedule` works on iOS with `UNCalendarNotificationTrigger`.
- iOS max scheduled notifications: 64. At 5 prayers × 10 days = 50 — within limit.
- Custom adhan sound: requires `.caf` or `.aiff` file bundled in the iOS app target.
- Critical Alerts (bypass silent mode): requires Apple entitlement — not standard for App Store.
- `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` are Android-only — no iOS equivalent needed.
- iOS boot rescheduling: handled via `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)`.
