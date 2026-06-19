# Spec 024 — Worship Tracker

**Created**: 2026-06-20
**Status**: Draft
**Priority**: P1 — highest retention gap; grows naturally from existing Today Plan scaffold

---

## Problem

MeMuslim has no daily worship logging or streak system. Users have no reason to
open the app every day once their immediate need (play surah, look up athkar) is
met. Athkar (Athkar iOS) retains users with a daily prayer log + streak card +
heatmap. This is the single largest engagement gap vs. the competition.

---

## Goal

A daily worship tracker that lets users log their acts of worship, see a streak,
and feel a sense of continuity with their deen — without adding friction or
turning worship into a game.

**Success criteria**

- User can log prayer, Quran reading, morning/evening athkar, and nawafil in
  ≤ 3 taps from the home screen
- Streak count is visible on the home screen Today zone
- 14-day heatmap available; no paywall
- Shareable streak card (image) exportable to social media
- `dart analyze` clean, `flutter test test/features/worship_tracker/` green

---

## Scope

### Log entries (MVP)

| Entry | Type | Notes |
|---|---|---|
| Fajr / Dhuhr / Asr / Maghrib / Isha | Boolean per prayer | 5 prayers |
| Morning athkar | Boolean | |
| Evening athkar | Boolean | |
| Quran pages read | Integer (0–604) | |
| Nawafil (voluntary prayers) | Integer (rakaat count) | |
| Fasting | Boolean | optional; not surfaced during Ramadan mode |

### Streak rules

- A day is "complete" if all 5 prayers + both athkar sessions are logged
- Quran and nawafil contribute to a separate "consistency score" but don't gate
  the streak — worship isn't all-or-nothing
- Streak resets at midnight (local time) if incomplete
- Exemptions: user can mark a day "travelling" or "excused" without breaking
  streak (Hanafi/Maliki fiqh consideration)

### Heatmap

- 14-day rolling heatmap in the Today zone — free
- Full 365-day annual heatmap + 30-day wide view behind Support tier
- Color intensity = completion percentage (0 → transparent, 100% → primary)

### Streak card

- Shareable image: current streak count, username, date
- Uses existing `ScreenshotService` + `ShareService` infrastructure

### Fasting suggestions

- When the tracker detects today is the 13th, 14th, or 15th of the Hijri month
  (white days), surface a subtle nudge in the Today zone: "Today is a white day
  — consider fasting"
- When the user has logged fasting ≥ 3 times in the past 30 days, suggest Mondays
  and Thursdays (sunnah fasts)
- Suggestions are dismissible per-day and never shown as notifications (that is
  handled by spec 026)

---

## Architecture

```
features/worship_tracker/
  data/
    datasources/worship_log_local_datasource.dart   # Hive or SQLite
    repositories/worship_log_repository_impl.dart
  domain/
    entities/worship_log_entry.dart                 # date + fields
    repositories/worship_log_repository.dart
    usecases/
      get_today_log_use_case.dart
      save_log_entry_use_case.dart
      get_streak_use_case.dart
      get_heatmap_use_case.dart                     # returns List<DayCompletion>
  presentation/
    cubit/worship_log_cubit.dart
    cubit/worship_log_state.dart
    widgets/
      worship_log_card.dart                         # compact home Today zone entry
      worship_log_sheet.dart                        # bottom sheet full log
      worship_heatmap.dart
      worship_streak_badge.dart
```

**State management**: `Cubit<WorshipLogState>` — one state per day entry.

**Persistence**: Hive box `worship_log` keyed by ISO date string. No cloud
sync in MVP (see spec 008 for eventual cloud sync).

**Home integration**: `HomeTodaySection` (Zone 2) renders `WorshipLogCard`
below the prayer strip. Tapping opens `WorshipLogSheet` modal.

---

## Out of scope (MVP)

- Cloud sync — defer to spec 008
- Achievement badges
- Social comparison / leaderboard
- Ramadan-specific mode (separate spec)
- Apple Watch / widget — depends on spec 025
- 365-day heatmap in free tier — Support tier only (matches Athkar iOS Pro gating)

---

## Open questions

1. Should the streak reset at Fajr time (Islamic day boundary) rather than
   midnight? Fajr boundary is more correct but harder to implement across
   timezones.
2. Do we surface nawafil count to the home screen or keep it in the sheet only?
3. How do we handle users who don't pray all 5 (e.g. new Muslims)? Consider
   a "personalise my tracker" step on first open.
4. Should fasting suggestions appear only after the user has logged fasting at
   least once, to avoid feeling presumptuous?

---

## References

- Athkar iOS app: streak + 14-day free / 365-day Pro heatmap + shareable cards + fasting suggestions
- Today Plan scaffold: `specs/021-today-plan/spec.md`
- Feature flag: `AppLaunchConfig.todayPlanEnabled` (currently false)
- Spec 026: granular reminders (white-days fasting notification handled there)
