# Spec 028 — Athkar Swipe Flow (Misc Adhkar Mode)

**Created**: 2026-06-20
**Status**: Draft
**Priority**: P2 — calm, meditative UX; low engineering cost once content is in place

---

## Problem

Our athkar screen presents du'as as a scrollable list inside a category. This is
fine for reference but works against the act of recitation: the user is scrolling
and reading simultaneously, which breaks focus. Athkar iOS offers "Misc adhkar"
— 100+ du'as in a full-screen one-at-a-time swipe flow where tapping anywhere
advances to the next du'a. This mode is better suited to the mental state of
someone actually making dhikr.

---

## Goal

An alternate reading mode for any athkar category where du'as fill the screen
one at a time and the user advances by tapping. Available free for all categories.

**Success criteria**

- User can enter swipe-flow mode from any athkar category screen (one tap)
- Each screen shows one du'a: Arabic text, transliteration (if available),
  meaning/translation, and repeat count badge
- Tapping anywhere on the screen (or swiping left) advances to the next du'a
- A progress indicator shows position (e.g. "3 / 12")
- Reaching the last du'a shows a completion screen with a brief dua for
  acceptance (ثَبَّتَنَا اللهُ وَإِيَّاكُم)
- `dart analyze` clean

---

## UX design

- **Entry**: a toggle/button on the category list header — icon only
  (e.g. `FluentIcons.read_aloud_24_regular` or similar), tooltip "Recitation mode"
- **Layout**: full-bleed card, Arabic text large and centred, transliteration
  below in a muted style, meaning in a collapsed expandable, repeat count badge
  top-right
- **Navigation**: tap anywhere → next; swipe right → previous; top-right ✕ →
  exit back to list
- **Auto-advance**: optional setting (off by default) — advances after N seconds
- **Screen stays on** while in swipe-flow mode (use `WakelockPlus`)
- No bottom navigation bar in this mode (full immersion)

---

## Architecture

This is a presentation-layer addition — no new domain or data layer needed.

```
features/athkar/presentation/
  screens/
    athkar_swipe_flow_screen.dart    # new full-screen route
  widgets/
    athkar_swipe_card.dart           # single du'a display
    athkar_swipe_progress.dart       # "3 / 12" indicator
    athkar_completion_card.dart      # end-of-category screen
```

**Route**: `AthkarSwipeFlowRoute(categoryId: int)` via go_router_builder.
Receives the same `List<AthkarItem>` already loaded by the category cubit —
no extra repository calls.

**Dependencies to add**: `wakelock_plus` (keep screen on during recitation).

---

## Content dependency

The swipe flow is only compelling with rich content. This spec assumes the
Extended Athkar Categories work (`missing_features.md` item 7) is in progress
or done. With only 2 categories (morning/evening), the mode still works but
feels limited.

---

## Out of scope (MVP)

- Audio playback per du'a inside the flow (would require syncing audio + text)
- Custom ordering of du'as within the flow
- Auto-advance as default behaviour
- Haptic feedback on advance

---

## References

- Athkar iOS: "Misc adhkar — over a hundred du'as in a beautiful flow — tap
  the screen once to move to the next"
- Extended Athkar Categories: `docs/missing_features.md` item 7
- Existing athkar screens: `apps/tilawa/lib/features/athkar/presentation/screens/`
