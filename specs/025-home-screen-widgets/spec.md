# Spec 025 — Home Screen Widgets

**Created**: 2026-06-20
**Status**: Draft
**Priority**: P1 — table-stakes for a 2026 Islamic app; drives daily active opens without the app

---

## Problem

MeMuslim has no home screen or lock screen widgets. Prayer time and next-prayer
countdown are the most-consulted data points for Muslim users throughout the day
— yet users must open the app to see them. Athkar iOS has 10+ widget types and
lock screen / Dynamic Island / Apple Watch support; this is now a baseline
expectation.

---

## Goal

Launch a focused set of Android (Glance) and iOS (WidgetKit) widgets covering
the most-requested data. Each widget opens the relevant app section on tap.

**Success criteria**

- Prayer times widget (medium, 2×2) live on Android and iOS
- Next prayer countdown widget (small, 1×1) live on both platforms
- Hijri date widget (small) live on both platforms
- Widgets refresh automatically at prayer time boundaries
- All widget text is localised (Arabic / English)
- `dart analyze` clean

---

## Widget inventory (MVP)

| Widget | Sizes | Data | Tap action |
|---|---|---|---|
| Next prayer countdown | Small (1×1) | Next prayer name + time remaining | Open prayer times screen |
| Prayer times today | Medium (2×2) | All 5 prayers + current highlighted | Open prayer times screen |
| Hijri date | Small (1×1) | Hijri day, month, year | Open app home |
| Daily athkar | Medium (2×2) | Random athkar title + first line | Open athkar category |

Lock screen widgets (iOS) and Dynamic Island — **post-MVP**.

---

## Architecture

```
packages/
  home_widget_provider/          # new package — isolates native widget glue
    android/                     # Glance AppWidget receivers
    ios/                         # WidgetKit extensions
    lib/
      home_widget_provider.dart  # public API: updatePrayerTimes(), updateHijriDate()
```

**Package**: `home_widget: ^4.x` (pub.dev) — handles the Flutter ↔ native
data bridge for both platforms via shared preferences / app group.

**Update trigger**: The existing `PrayerTimesNotificationService` already runs
after each prayer time calculation. Extend it to call
`HomeWidgetProvider.updatePrayerTimes(times)` after scheduling notifications.

**Hijri date**: Compute from `apps/tilawa/lib/features/prayer_times/` hijri
utilities already present; no new dependency needed.

**Background refresh**:
- Android: `HomeWidgetProvider` schedules a `WorkManager` periodic task (15 min)
- iOS: WidgetKit timeline reloads at next prayer time boundary

---

## Out of scope (MVP)

- Tasbih counter widget (needs interactive widget / WidgetKit intent — complex)
- Lock screen + Dynamic Island (iOS 16+) — post-MVP
- Apple Watch complications
- Android Glance interactive actions (toggle-counter style)

---

## Open questions

1. Do we put the widget provider in a new `packages/home_widget_provider/` or
   keep it in `apps/tilawa/` android/ios dirs directly?
2. How does the widget theme (light/dark) match the app theme — static tokens
   or OS-level dynamic color?

---

## References

- Athkar iOS: prayer times, countdown, tasbih counter, hijri date, monthly calendar widgets
- `missing_features.md` item 13: Home Screen Widget
- `home_widget` pub package: https://pub.dev/packages/home_widget
- Existing prayer time calculation: `apps/tilawa/lib/features/prayer_times/`
