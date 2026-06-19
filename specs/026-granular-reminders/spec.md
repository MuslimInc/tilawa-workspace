# Spec 026 — Granular Worship Reminders

**Created**: 2026-06-20
**Status**: Draft
**Priority**: P1 — highest-friction daily retention lever after the worship tracker

---

## Problem

MeMuslim currently schedules morning and evening athkar reminders at fixed times
with prayer-time-relative offsets (hardcoded in `athkar_notification_service.dart`).
There is no UI for users to configure them, and voluntary prayers (Duha, Tahajjud,
Jumu'ah sunnah, white-days fasting) have no reminders at all. Athkar iOS offers
per-reminder timing with user-defined offsets relative to Athan, which dramatically
increases the feeling that the app "knows your day."

---

## Goal

A Reminders settings screen where users can toggle and configure each Islamic
reminder type, with time either fixed or offset from the nearest prayer.

**Success criteria**

- User can enable/disable each reminder type independently
- User can set a custom offset (before/after Athan) for prayer-adjacent reminders
- Reminders fire reliably even when app is backgrounded (existing
  `flutter_local_notifications` infrastructure)
- Settings persist across restarts
- `dart analyze` clean, `flutter test test/features/reminders/` green

---

## Reminder types (MVP)

| Reminder | Default trigger | Default time | Configurable? |
|---|---|---|---|
| Morning athkar | After Fajr | +30 min | Offset ±120 min |
| Evening athkar | Before Maghrib | −30 min | Offset ±120 min |
| Duha prayer | After Sunrise | +30 min | Offset ±60 min |
| Jumu'ah sunnah | Before Dhuhr (Friday) | −30 min | Toggle only |
| Tahajjud | Last third of night | Computed | Toggle only |
| White-days fasting | 13th / 14th / 15th Hijri | 6:00 AM | Toggle only |
| Quran daily goal | Fixed time | 8:00 PM | User picks time |

---

## Architecture

```
features/reminders/
  data/
    datasources/reminder_preferences_datasource.dart  # SharedPreferences
    repositories/reminder_preferences_repository_impl.dart
  domain/
    entities/reminder_config.dart     # type, enabled, offsetMinutes, fixedTime
    entities/reminder_type.dart       # enum
    repositories/reminder_preferences_repository.dart
    usecases/
      get_reminder_configs_use_case.dart
      save_reminder_config_use_case.dart
      schedule_all_reminders_use_case.dart  # replaces hardcoded service calls
  presentation/
    cubit/reminders_cubit.dart
    cubit/reminders_state.dart
    screens/reminders_screen.dart
    widgets/
      reminder_toggle_row.dart
      reminder_offset_picker.dart     # bottom sheet with slider (−120 → +120 min)
```

**Scheduling**: `ScheduleAllRemindersUseCase` replaces the hardcoded calls in
`AthkarNotificationService`. It reads all `ReminderConfig` entities and calls
`flutter_local_notifications` `zonedSchedule` for each enabled reminder.
Re-schedules automatically when prayer times update (hook into existing
`PrayerTimesBloc` state changes).

**Hijri calendar** (for white-days fasting): Use `hijri` package already
evaluated in prayer times feature, or compute from `PrayerCalculator` data.

---

## UX notes

- Group reminders by theme: Prayers, Athkar, Quran, Fasting
- Each row: toggle + label + subtitle showing effective time ("Tomorrow 5:42 AM")
- Offset pickers use bottom sheet with a simple ±step selector (not a full time
  picker) — less intimidating, aligns with Athkar iOS pattern
- Remind users that Tahajjud time is computed and varies nightly

---

## Out of scope (MVP)

- Per-day-of-week scheduling
- In-app reminder content preview
- Ramadan-specific Suhoor/Taraweeh reminders (separate Ramadan mode spec)
- Voice notification (text-to-speech)

---

## References

- Athkar iOS: per-reminder offset from Athan (iOS 16+), Duha / Jumu'ah / Tahajjud reminders
- Existing service: `apps/tilawa/lib/core/services/athkar_notification_service.dart`
- Spec 020: `specs/020-tasbeeh-history-reminders/spec.md`
