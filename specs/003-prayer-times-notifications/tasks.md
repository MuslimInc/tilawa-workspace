# Tasks: Prayer Times Notifications (Android-First)

**Input**: Design documents from `specs/003-prayer-times-notifications/`
**Prerequisites**: plan.md ✅, spec.md ✅, data-model.md ✅, research.md ✅
**Feature Branch**: `feature/003-prayer-times-notifications`
**Platform**: Android (Google Play). iOS documented as future work.

**Tests**: Unit tests are mandatory for all domain logic, use cases, service
implementations, and BLoC behavior. Widget tests are required for the
notification settings section in `PrayerSettingsSheet`. Omit a test only when an
approved waiver is documented with owner and expiry.

**Organization**: Tasks are grouped by user story to enable independent
implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- `[x]` = completed, `[ ]` = pending

---

## Phase 1: Setup

**Purpose**: Add dependencies and fix pre-existing issues that block this feature.

- [x] T001 [P] Add `flutter_timezone: ^5.0.2` to `apps/tilawa/pubspec.yaml` and run `flutter pub get`
- [x] T002 Fix `AthkarNotificationService.getLocalTimeZone()` to use `FlutterTimezone.getLocalTimezone()` in `apps/tilawa/lib/core/services/athkar_notification_service.dart`
- [x] T003 [P] Verify `AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications()` and `requestExactAlarmsPermission()` are accessible with the resolved FLN version (compile-time check)
- [x] T004 [P] Confirm `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` are declared in `apps/tilawa/android/app/src/main/AndroidManifest.xml` (no changes needed)

---

## Phase 2: Foundational (Must Complete Before All User Stories)

**Purpose**: Define all domain contracts, constants, and abstractions that every
user story depends on. No story can begin until this phase is complete.

⚠️ **CRITICAL**: Interfaces and config in this phase must not import Flutter,
routing, or data layers.

- [x] T005 Create `PrayerNotificationConfig` constants class in `apps/tilawa/lib/core/services/prayer_notification_config.dart` — all IDs, channel names, SharedPrefs keys, log tag, `scheduleDaysAhead = 14`, `adhanChannelVersion`, static ID helpers
- [x] T006 [P] Create `IAdhanAlarmPlayer` interface in `apps/tilawa/lib/features/prayer_times/domain/services/adhan_alarm_player_interface.dart` and export from domain barrel
- [x] T007 [P] Create `NoOpAdhanAlarmPlayer` (Phase 1 no-op) in `apps/tilawa/lib/core/services/noop_adhan_alarm_player.dart` with `@LazySingleton(as: IAdhanAlarmPlayer)`; `isSupported = false`
- [x] T008 [P] Create `IPrayerAdhanNotificationService` interface in `apps/tilawa/lib/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart` and export from domain barrel
- [x] T009 [P] Create `PrayerAlarmCapability` value object in `apps/tilawa/lib/features/prayer_times/domain/value_objects/prayer_alarm_capability.dart` with `canScheduleExact`, `hasNotificationPermission`, and `isFullyCapable` getter

**Checkpoint**: All interfaces compile. `NoOpAdhanAlarmPlayer` resolves via DI. No Flutter imports in domain files.

---

## Phase 3: User Story 1 — Receive Prayer Time Notification (P1)

**Story Goal**: A user with notification permission receives a heads-up notification
at the scheduled prayer time (or N minutes before). Tapping it opens Prayer Times screen.

**Independent Test**: Enable Fajr only, `minutesBefore = 0`, wait for Fajr time →
notification appears.

- [x] T010 Implement `PrayerAdhanNotificationService` in `apps/tilawa/lib/core/services/prayer_adhan_notification_service.dart` — full implementation: channel creation, dedup+fingerprint, schedule loop (14 days × 5 prayers), `cancelAll`, exact/inexact fallback, error handling, `handleNotificationResponse` navigate to Prayer Times
- [x] T011 [P] [US1] Create `SchedulePrayerNotificationsUseCase` in `apps/tilawa/lib/features/prayer_times/domain/usecases/schedule_prayer_notifications_use_case.dart` — calls service with settings + days from repo; passes `forceReschedule` through
- [x] T012 [P] [US1] Create `CancelPrayerNotificationsUseCase` in `apps/tilawa/lib/features/prayer_times/domain/usecases/cancel_prayer_notifications_use_case.dart` — delegates to `service.cancelAllPrayerNotifications()`
- [x] T013 [P] [US1] Create `CheckPrayerAlarmCapabilityUseCase` in `apps/tilawa/lib/features/prayer_times/domain/usecases/check_prayer_alarm_capability_use_case.dart` — checks exact alarm + notification permission; returns `PrayerAlarmCapability`
- [x] T014 [P] [US1] Create `RequestExactAlarmPermissionUseCase` in `apps/tilawa/lib/features/prayer_times/domain/usecases/request_exact_alarm_permission_use_case.dart` — delegates to `service.requestExactAlarmPermission()`
- [x] T015 [US1] Update `apps/tilawa/lib/features/prayer_times/domain/usecases/usecases.dart` barrel with all 4 new use case exports
- [x] T016 [US1] Integrate 4 new use cases into `PrayerTimesBloc` in `apps/tilawa/lib/features/prayer_times/presentation/bloc/prayer_times_bloc.dart` — add constructor params, `alarmCapability` state, `checkAlarmCapability` + `requestExactAlarmPermission` events, 3 reschedule trigger points in `_onLoadPrayerTimes` / `_onUpdateSettings` / `_onUpdateLocation` (with correct `forceReschedule` values)
- [x] T017 [US1] Integrate prayer notifications into bootstrap: add `prayerNotificationsInit` flag to `apps/tilawa/lib/core/bootstrap/app_launch_config.dart`, add Phase 3 task to `apps/tilawa/lib/core/bootstrap/app_startup_phases.dart`, implement `initializePrayerNotifications()` in `apps/tilawa/lib/core/bootstrap/app_startup_tasks.dart` (try/catch, `forceReschedule: false`)
- [x] T018 [US1] Run `dart run build_runner build --delete-conflicting-outputs` in `apps/tilawa` to regenerate DI and Freezed files
- [x] T019 [P] [US1] Write unit tests for `PrayerNotificationConfig` ID helpers in `apps/tilawa/test/core/services/prayer_notification_config_test.dart` — `dynamicId(0, fajr) = 20_000_000`, `dynamicId(13, isha) = 20_000_135`, `staticId(fajr) = 2001`
- [x] T020 [P] [US1] Write unit tests for `PrayerAdhanNotificationService` in `apps/tilawa/test/core/services/prayer_adhan_notification_service_test.dart` — covers: schedules correct count (14×enabled prayers), `minutesBefore` offset, disabled prayer = 0 notifications, past alarm skipped, exact denied → inexact fallback, exception caught + no rethrow, dedup hit → skip, dedup miss → reschedule, `forceReschedule = true` always reschedules, `cancelAll` cancels full ID range
- [x] T021 [P] [US1] Write unit tests for `SchedulePrayerNotificationsUseCase` in `apps/tilawa/test/features/prayer_times/domain/usecases/schedule_prayer_notifications_use_case_test.dart` — delegates to service with correct params; `forceReschedule` passes through
- [x] T022 [P] [US1] Write unit tests for `CancelPrayerNotificationsUseCase` in `apps/tilawa/test/features/prayer_times/domain/usecases/cancel_prayer_notifications_use_case_test.dart` — delegates to service; verifies `cancelAllPrayerNotifications()` called once
- [x] T023 [P] [US1] Write unit tests for `PrayerTimesBloc` notification behaviour in `apps/tilawa/test/features/prayer_times/presentation/bloc/prayer_times_bloc_test.dart` — `_onUpdateSettings` calls `SchedulePrayerNotificationsUseCase` with `forceReschedule: true`; `_onLoadPrayerTimes` success calls with `forceReschedule: false`; `checkAlarmCapability` emits `alarmCapability` in state

**Checkpoint (US1)**: `flutter test test/features/prayer_times/ test/core/services/` passes. Prayer notification fires on real device at scheduled time.

---

## Phase 4: User Story 2 — Configure Per-Prayer Notification Settings (P1)

**Story Goal**: User can toggle per-prayer notifications, set `minutesBefore`,
and enable Play Adhan from the Prayer Settings sheet. Capability banners shown
when permissions are missing.

**Independent Test**: Open settings → toggle Maghrib off → confirm no Maghrib
notification fires.

- [x] T024 [US2] Add notification settings section to `apps/tilawa/lib/features/prayer_times/presentation/widgets/prayer_settings_sheet.dart` — global toggle, per-prayer toggles (5 rows), `minutesBefore` segmented picker (0/5/10/15), "Play Adhan" toggle, permission warning banners from `state.alarmCapability`, dispatch `checkAlarmCapability` in `initState`
- [x] T025 [P] [US2] Add 10+ English l10n keys to `apps/tilawa/lib/l10n/app_en.arb` — notification section title, global toggle, per-prayer label, minutesBefore options, play adhan, permission banners
- [x] T026 [P] [US2] Add corresponding Arabic translations to `apps/tilawa/lib/l10n/app_ar.arb`
- [x] T027 [US2] Run `flutter gen-l10n` to regenerate localisation files
- [x] T028 [US2] Wire "Play Adhan" toggle as fully functional — `_globalPlayAdhan` reads `fajrNotification.playAdhan`; toggle updates all 5 prayers' `playAdhan` field via `_onUpdateSettings`
- [x] T029 [P] [US2] Write unit tests for `CheckPrayerAlarmCapabilityUseCase` in `apps/tilawa/test/features/prayer_times/domain/usecases/check_prayer_alarm_capability_use_case_test.dart` — returns correct `PrayerAlarmCapability` for all permission combinations
- [x] T030 [US2] Write widget test for notification settings section in `apps/tilawa/test/features/prayer_times/presentation/widgets/prayer_settings_sheet_notification_test.dart` — global toggle dispatches event; per-prayer toggle dispatches event; capability banner appears when `canScheduleExact = false`; RTL layout renders correctly

**Checkpoint (US2)**: Settings changes reschedule alarms on same day. Permission banners appear/disappear correctly.

---

## Phase 5: User Story 3 — Alarms Survive Device Reboot (P2)

**Story Goal**: When the device reboots, prayer alarms are automatically
rescheduled by the app using saved settings and saved location.

**Independent Test**: Schedule alarms → reboot → verify alarms still fire.

- [x] T031 [P] [US3] Verify `RECEIVE_BOOT_COMPLETED` is declared in `apps/tilawa/android/app/src/main/AndroidManifest.xml` (was pre-existing; no code change needed)
- [x] T032 [P] [US3] Verify FLN `ScheduledNotificationBootReceiver` is registered in `AndroidManifest.xml` (handled by FLN plugin; confirm in manifest; no code change needed)
- [x] T033 [US3] Confirm `initializePrayerNotifications()` in `apps/tilawa/lib/core/bootstrap/app_startup_tasks.dart` calls `schedulePrayerNotifications()` with `forceReschedule: false` — this is the post-reboot reschedule path triggered on next app launch

**Checkpoint (US3)**: Reboot device → open app → `[PrayerTimes]` log shows alarms rescheduled within 30 seconds.

---

## Phase 6: User Story 4 — Adhan Sound Support (P3)

**Story Goal**: User can opt to play a bundled adhan sound when a prayer
notification fires instead of the default notification tone.

**Independent Test**: `playAdhan = true` → alarm fires → adhan sound plays.

- [x] T034 [P] [US4] Place `adhan.mp3` in `apps/tilawa/assets/audio/adhan.mp3`
- [x] T035 [P] [US4] Add `- assets/audio/` to `apps/tilawa/pubspec.yaml` flutter assets list
- [x] T036 [P] [US4] Copy `adhan.mp3` to `apps/tilawa/android/app/src/main/res/raw/adhan.mp3` (required for Android notification channel custom sound; must be raw resource, not asset)
- [x] T037 [US4] Implement adhan notification channel with `RawResourceAndroidNotificationSound('adhan')` in `PrayerAdhanNotificationService._createAndroidChannels()` in `apps/tilawa/lib/core/services/prayer_adhan_notification_service.dart`
- [x] T038 [US4] Implement adhan channel version guard in `PrayerAdhanNotificationService` — read `adhanChannelVersionKey` from SharedPrefs; if version < `adhanChannelVersion`, delete channel then recreate with updated sound; store new version (handles existing installs with locked channel)
- [ ] T039 [US4] **[MANUAL]** Add `adhan.mp3` to Xcode project as bundle resource: Xcode → Build Phases → Copy Bundle Resources → add `apps/tilawa/ios/Runner/adhan.mp3` (cannot be automated; required for iOS notification sound in future)
- [x] T040 [P] [US4] Write unit tests for `NoOpAdhanAlarmPlayer` in `apps/tilawa/test/core/services/noop_adhan_alarm_player_test.dart` — `isSupported = false`; `scheduleAdhan` completes without error; `cancelAdhan` and `cancelAllAdhans` are no-ops
- [ ] T041 [US4] **[Phase 2 gate]** Implement `AlarmPackageAdhanPlayer implements IAdhanAlarmPlayer` in `apps/tilawa/lib/core/services/alarm_package_adhan_player.dart` — wraps `alarm` package behind `IAdhanAlarmPlayer`; validate against `audio_service` MediaSession conflict first; register in DI only after all Phase 2 gates pass (see plan.md §Phase 2 Gate)

**Checkpoint (US4)**: `playAdhan = true` → alarm fires with adhan sound. Default channel remains silent when `playAdhan = false`.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Code quality, release gate requirements, and manual QA validation.

- [x] T042 Run `flutter analyze --no-fatal-infos` in `apps/tilawa` — zero new errors introduced by this feature
- [x] T043 Add `kDebugMode`-gated debug FAB to `apps/tilawa/lib/features/prayer_times/presentation/screens/prayer_times_screen.dart` — prayer dropdown, adhan toggle, fire button; calls `fireTestNotification()` via `getIt<IPrayerAdhanNotificationService>()`
- [x] T044 Add structured diagnostic logs to `PrayerAdhanNotificationService` in `apps/tilawa/lib/core/services/prayer_adhan_notification_service.dart` with `[PrayerTimes]` tag and `[SCHEDULE]`, `[SCHEDULE OK]`, `[ADHAN CHECK]`, `[TEST]` prefixes
- [ ] T045 **[RELEASE GATE]** Write `USE_EXACT_ALARM` justification in Google Play Console: "Tilawa schedules prayer time notifications at precise religious observance times; exact timing is required by the nature of the feature." Update Data Safety form (no user data in notification payloads).
- [ ] T046 **[MANUAL QA]** Core checklist: Android 8/12/13/14 — notification permission dialog, alarms scheduled, exact alarm revocation → inexact fallback + banner, reboot → reschedule, Doze mode delay documented, settings change → same-day reschedule via fingerprint
- [ ] T047 **[MANUAL QA]** OEM checklist: Xiaomi MIUI (autostart permission, battery → No restrictions), Samsung One UI (sleeping apps disabled for Tilawa), OPPO ColorOS (Permission Manager → Autostart)

---

## Dependencies

```
Phase 1 (Setup)
    └── Phase 2 (Foundational) — blocks all stories
            ├── Phase 3 (US1 - P1) — core scheduling, service, use cases, BLoC, bootstrap
            ├── Phase 4 (US2 - P1) — settings UI, l10n (can start parallel with US1)
            ├── Phase 5 (US3 - P2) — reboot rescheduling (depends on Phase 3 bootstrap)
            └── Phase 6 (US4 - P3) — adhan sound (depends on Phase 3 service)
                    └── Phase 7 (Polish) — runs after all stories
```

- **US1 and US2** are both P1 and can be implemented in parallel once Phase 2 is done
- **US3** depends on Phase 3 bootstrap being complete (T017)
- **US4** depends on Phase 3 service being complete (T010, T037)
- **T041** (Phase 2 AlarmPackageAdhanPlayer) requires MediaSession conflict validation before adoption

---

## Parallel Opportunities

### Phase 3 — US1
```bash
# Can run in parallel:
T011 SchedulePrayerNotificationsUseCase   (different file from T012/T013/T014)
T012 CancelPrayerNotificationsUseCase     (different file)
T013 CheckPrayerAlarmCapabilityUseCase    (different file)
T014 RequestExactAlarmPermissionUseCase   (different file)

T019 prayer_notification_config_test      (different file from T020/T021/T022)
T020 prayer_adhan_notification_service_test
T021 schedule_prayer_notifications_use_case_test
T022 cancel_prayer_notifications_use_case_test
```

### Phase 4 — US2
```bash
# Can run in parallel:
T025 app_en.arb l10n keys   (different file from T026)
T026 app_ar.arb l10n keys
T029 check_prayer_alarm_capability_use_case_test
```

---

## Implementation Strategy

### MVP (US1 + US2 only)

1. ✅ Complete Phase 1 (Setup)
2. ✅ Complete Phase 2 (Foundational)
3. ✅ Complete Phase 3 (US1)
4. ✅ Complete Phase 4 (US2)
5. **VALIDATE**: Run all tests, manual QA core checklist

### Incremental Delivery

1. ✅ Setup + Foundational → Foundation ready
2. ✅ US1 → Notifications fire reliably → **MVP**
3. ✅ US2 → User can configure from settings
4. ✅ US3 → Alarms survive reboot
5. ✅ US4 Phase 1 → Adhan channel infrastructure + bundled sound
6. [ ] US4 Phase 2 → Full `alarm` package adhan playback (after Phase 2 gate)
7. [ ] Polish → Release gate cleared

---

## Completion Summary

| Phase | Tasks | Done | Remaining |
|---|---|---|---|
| Phase 1: Setup | 4 | 4 | 0 |
| Phase 2: Foundational | 5 | 5 | 0 |
| Phase 3: US1 | 13 | 10 | 3 (T020, T022, service tests) |
| Phase 4: US2 | 7 | 6 | 1 (T030 widget test) |
| Phase 5: US3 | 3 | 3 | 0 |
| Phase 6: US4 | 8 | 5 | 3 (T039 iOS, T040 noop test, T041 Phase 2) |
| Phase 7: Polish | 6 | 3 | 3 (T045 Play Store, T046–T047 QA) |
| **Total** | **46** | **36** | **10** |

---

## Notes

- `[P]` tasks use different files — safe to run in parallel
- `[Story]` label maps each task to the user story for traceability
- Verify `flutter analyze` passes after each phase
- `[MANUAL]` tasks require human action outside of code changes
- `[RELEASE GATE]` tasks are required before Google Play submission
- `[Phase 2 gate]` tasks must not be started until MediaSession conflict is validated (see plan.md)
- `IAdhanAlarmPlayer` import MUST NOT appear outside its own implementation class
