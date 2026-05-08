# Task List: Prayer Times Notifications (Android-First)

**Branch**: `003-prayer-times-notifications` | **Status**: Execution complete, regression tests passing

---

## Phase 1 — Foundation & Abstraction [DONE]

- [x] T001 [F] Define `IPrayerAdhanNotificationService` in `tilawa_core`.
- [x] T002 [F] Define `IAdhanAlarmPlayer` in `tilawa_core`.
- [x] T003 [F] Implement `NoOpAdhanAlarmPlayer` for fallback and Phase 1 testing.
- [x] T004 [F] Define `PrayerNotificationConfig` with all IDs, keys, and constants.

---

## Phase 2 — Implementation [DONE]

- [x] T010 [F] Create `PrayerAdhanNotificationService` skeleton.
- [x] T011 [F] Implement `initialize()` with timezone detection.
- [x] T012 [F] Implement `schedulePrayerNotifications()` with 14-day window.
- [x] T013 [F] Implement fingerprint-based deduplication logic.
- [x] T014 [F] Implement `cancelAllPrayerNotifications()` and `canScheduleExactAlarms()`.
- [x] T015 [F] Create `AdhanScheduler`, `AdhanReceiver`, and `AdhanPlaybackService` in Kotlin.
- [x] T016 [F] Integrate native Kotlin with `AndroidAdhanAlarmPlayer`.

---

## Phase 3 — Integration & UI [DONE]

- [x] T020 [F] Update `PrayerTimesBloc` to handle notification triggers.
- [x] T021 [F] Update `PrayerSettingsSheet` with notification toggles.
- [x] T022 [F] implement `minutesBefore` selector in UI.
- [x] T023 [F] implement "Play Adhan" toggle in UI.

---

## Phase 4 — Testing & Validation [DONE]

- [x] T030 [T] Unit tests for `PrayerAdhanNotificationService`.
- [x] T031 [T] Unit tests for `CheckPrayerAlarmCapabilityUseCase`.
- [x] T032 [T] Manual verification on Android 11, 13, 14 devices.
- [x] T033 [T] Verify reboot persistence.
- [x] T034 [T] Verify silent routing and fallback routing.

---

## Remediation & Finalization [DONE]

- [x] T050 [US1] Fix `prayer_adhan_notification_service_test.dart` compilation errors.
- [x] T051 [US1] Correct `PrayerAlertMode.adhan` verification in tests.
- [x] T052 [US1] Finalize Android cleanup in `AdhanScheduler.kt`.
- [x] T053 [US1] Refactor `CheckPrayerAlarmCapabilityUseCase` tests to use `IAdhanAlarmPlayer` abstraction.
- [x] T054 [US1] Add regression tests for silent routing and fallback routing.

---

## [RELEASE GATE]

- [ ] **[RELEASE GATE]** Justify `USE_EXACT_ALARM` in Google Play Console: "Tilawa schedules prayer notifications at precise times for religious observance; accurate timing is required by the feature's core purpose."
- [ ] **[RELEASE GATE]** Perform manual QA on real devices (Samsung/Xiaomi/Oppo) to verify foreground service behavior under aggressive battery optimization.
