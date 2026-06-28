# Home Screen Redesign — Migration Notes

> **Superseded (2026-06-28).** Current Home is documented in
> `docs/design/home_screen_design_artifacts.md`. Do not follow removal/rename
> steps here unless explicitly requested.

> **⚠️ AI agents — historical archive only:** Everything below describes a
> **superseded** Home redesign. Do **not** execute steps, removals, or renames.
> Approved Home:
> [`home-dashboard-patterns.md`](../../.agents/skills/tilawa-apply-ui-principles/references/home-dashboard-patterns.md)
> and [`home_screen_design_artifacts.md`](../design/home_screen_design_artifacts.md).

**Status:** Superseded (historical)  
**Date:** 2026-06-20  
**Implementation Plan:** [Home Screen Redesign Plan](../plans/home_screen_redesign_plan.md)  
**Acceptance Criteria:** [Home Screen Acceptance Criteria](../specs/home_screen_acceptance_criteria.md)

---

## Purpose (historical)

This archived inventory described a **planned** Home redesign that does **not**
match the approved Home on disk. It is kept for historical reference only. AI
agents must use `home-dashboard-patterns.md` instead — not this file.

---

## Components to Remove

These files and classes are deleted entirely. They have no role in the redesigned Home screen.

### Phase 1 removals

| Type | File / Class | Reason |
|------|-------------|--------|
| Widget | `lib/features/home/presentation/widgets/home_shortcut_grid_view.dart` | Discover grid — navigation menu, removed |
| Widget | `lib/features/home/presentation/widgets/home_more_actions_group.dart` | Discover list — navigation menu, removed |
| Widget | `lib/features/home/presentation/widgets/home_prayer_day_strip.dart` | Duplicates hero prayer context |
| Cubit | `lib/features/home/presentation/cubit/home_layout_cubit.dart` | Grid/list preference — removed |
| State | `lib/features/home/presentation/cubit/home_layout_state.dart` | Paired with removed cubit |
| Shortcut item | Any `HomeShortcutItem` model file if extracted separately | No shortcuts in redesign |
| Callback props | `onOpenReciters`, `onOpenQibla` in `HomeScreen` and `AppShellScreen` | Reciters and Qibla shortcuts removed |

### Phase 5 removals

| Type | File / Class | Reason |
|------|-------------|--------|
| Widget | `PinnedAthkarHomeSection` (from athkar feature, used on Home) | Replaced by `HomeAthkarCompactCard` |
| Widget | `_ContextualAthkarCard` in `home_today_section.dart` | Merged into `HomeAthkarCompactCard` |
| Widget | `HomeFeaturedRitualCard` (if only used as contextual Athkar card on Home) | Merged into `HomeAthkarCompactCard` |
| Cubit | `lib/features/home/presentation/cubit/home_pinned_athkar_cubit.dart` | Replaced by `HomeAthkarCompactCubit` |
| State | Paired state class for `HomePinnedAthkarCubit` | Same |
| Section header | "Your Rituals / Daily Practice" section header widget | Section concept removed |
| Edit button | Pinned athkar picker modal trigger (edit icon in section header) | Pinning feature removed from Home |

**Caution for Phase 5:** Do not delete `PinnedAthkarHomeSection`, `_ContextualAthkarCard`, and `HomeFeaturedRitualCard` until Phase 5 is confirmed stable in production. Mark them with `// LEGACY: preserved for Phase 5 rollback` during the transition window.

---

## Components to Keep (Unchanged)

These files and classes continue to exist and function without modification.

| Type | File / Class | Notes |
|------|-------------|-------|
| Screen | `lib/features/home/presentation/screens/home_screen.dart` | Modified (cubit providers change), not replaced |
| Widget | `lib/features/home/presentation/widgets/home_dashboard_hero_sliver.dart` | Unchanged |
| Widget | `lib/features/home/presentation/widgets/home_dashboard_body.dart` | Modified (section order changes), not replaced |
| Widget | `lib/features/home/presentation/widgets/home_dashboard_content_sliver.dart` | Unchanged |
| Bloc | `HomeDashboardBloc` | Unchanged; prayer + location + user data |
| Cubit | `HomeQuranResumeCubit` | Extended in Phase 3 (new fields), not replaced |
| Widget | `HomeQuranResumeCard` | Modified in Phase 3 (layout), not replaced |
| Widget | Hero background, gradient, photo theme widgets | Unchanged |
| Route | `HomeRoute` in `app_router_config.dart` | Unchanged |
| Bottom nav | All bottom-nav tab definitions and routing | Unchanged; Reciters, Qibla, Athkar tabs unaffected |
| Athkar feature | All athkar domain, data, and presentation layers | Unchanged; `HomeAthkarCompactCard` is a new Home-layer consumer |
| Player feature | All player domain, data, and presentation layers | Unchanged; `HomeListeningResumeRow` is a new Home-layer consumer |

---

## Components to Rename

| Current Name | New Name | Phase | Reason |
|-------------|----------|-------|--------|
| `HomeDailyInspirationSection` | `HomeDailyAyahCard` | 2 | Reflects promoted status and singular focus on Ayah |
| `home_daily_inspiration_section.dart` | `home_daily_ayah_card.dart` | 2 | Paired file rename |

No other renames are required. The separation between `HomeDailyAyahCard` (compact card on screen) and `HomeDailyAyahSheet` (new bottom sheet) is an addition, not a rename.

---

## New Components Added

| Type | File | Phase | Purpose |
|------|------|-------|---------|
| Widget | `lib/features/home/presentation/widgets/home_daily_ayah_card.dart` | 2 | Promoted Daily Ayah (renamed from `HomeDailyInspirationSection`) |
| Widget | `lib/features/home/presentation/widgets/home_daily_ayah_sheet.dart` | 2 | Bottom sheet: full ayah + bookmark + share |
| Widget | `lib/features/home/presentation/widgets/home_listening_resume_row.dart` | 4 | Conditional "Continue Listening" row |
| Cubit | `lib/features/home/presentation/cubit/home_listening_resume_cubit.dart` | 4 | Last-played state for Listening row |
| State | Paired state class | 4 | |
| Widget | `lib/features/home/presentation/widgets/home_athkar_compact_card.dart` | 5 | Replaces pinned athkar + contextual card |
| Cubit | `lib/features/home/presentation/cubit/home_athkar_compact_cubit.dart` | 5 | Completion state + row ordering |
| State | Paired state class | 5 | |

---

## State Management Changes

### Removed cubits and state classes

| Cubit | State | Phase | Impact |
|-------|-------|-------|--------|
| `HomeLayoutCubit` | `HomeLayoutState` | 1 | No user-visible preference is lost (layout was a display preference) |
| `HomePinnedAthkarCubit` | Paired state | 5 | Pinning feature removed from Home (see risk note in Phase 5) |

### Extended cubits

| Cubit | New Fields | Phase |
|-------|-----------|-------|
| `HomeQuranResumeCubit` / `HomeQuranResumeState` | `streakDays: int?`, `goalProgress: double?`, `khatmaPlanLabel: String?` | 3 |

### New cubits

| Cubit | Source of Truth | Phase |
|-------|----------------|-------|
| `HomeListeningResumeCubit` | Player's existing last-played storage | 4 |
| `HomeAthkarCompactCubit` | Athkar repository completion state + prayer time service | 5 |

### BlocProvider changes in `home_screen.dart`

| Phase | Action |
|-------|--------|
| 1 | Remove `BlocProvider<HomeLayoutCubit>` |
| 4 | Add `BlocProvider<HomeListeningResumeCubit>` |
| 5 | Remove `BlocProvider<HomePinnedAthkarCubit>` |
| 5 | Add `BlocProvider<HomeAthkarCompactCubit>` |

---

## Test Files Affected

### Phase 1

| File | Change |
|------|--------|
| `test/features/home/presentation/widgets/home_shortcut_grid_view_test.dart` | **Delete** (if exists) |
| `test/features/home/presentation/widgets/home_prayer_day_strip_test.dart` | **Delete** (if exists) |
| `test/features/home/presentation/cubit/home_layout_cubit_test.dart` | **Delete** (if exists) |
| Any home widget test that provides `HomeLayoutCubit` | Remove cubit provision |
| Any home widget test that renders `_DiscoverSection` | Remove section reference |

### Phase 2

| File | Change |
|------|--------|
| `test/features/home/presentation/widgets/home_daily_inspiration_section_test.dart` | Rename to `home_daily_ayah_card_test.dart` |
| All references to `HomeDailyInspirationSection` in tests | Update to `HomeDailyAyahCard` |
| New: `test/features/home/presentation/widgets/home_daily_ayah_sheet_test.dart` | Add: tests for bottom sheet content and actions |

### Phase 3

| File | Change |
|------|--------|
| `test/features/home/presentation/widgets/home_quran_resume_card_test.dart` | Add test cases for streak, goal progress, khatma label |
| `test/features/home/presentation/cubit/home_quran_resume_cubit_test.dart` | Add test cases for new state fields |

### Phase 4

| File | Change |
|------|--------|
| New: `test/features/home/presentation/widgets/home_listening_resume_row_test.dart` | Add: all AC-4.x test cases |
| New: `test/features/home/presentation/cubit/home_listening_resume_cubit_test.dart` | Add: unit tests for last-played state |

### Phase 5

| File | Change |
|------|--------|
| New: `test/features/home/presentation/widgets/home_athkar_compact_card_test.dart` | Add: all AC-5.x test cases |
| New: `test/features/home/presentation/cubit/home_athkar_compact_cubit_test.dart` | Add: unit tests for completion state and ordering |
| `test/features/home/presentation/widgets/home_today_section_test.dart` | Remove contextual Athkar card references |
| Any test that provides or references `HomePinnedAthkarCubit` | Update to `HomeAthkarCompactCubit` |

---

## Localisation Changes

### Strings to add

| Key | Usage | Phase |
|-----|-------|-------|
| `homeListeningResumeContinue` | "Continue" label in Listening row | 4 |
| `homeAthkarStatusDone` | "✓ Done" status in Athkar card | 5 |
| `homeAthkarStatusRemaining` | "{count} remaining" status | 5 |
| `homeAthkarStatusNotStarted` | "Not started" status | 5 |
| `homeDailyAyahShareTemplate` | Share text template for Daily Ayah | 2 |

### Strings to remove or deprecate

| Key | Reason | Phase |
|-----|--------|-------|
| Any strings exclusively used in `HomePrayerDayStrip` | Widget removed | 1 |
| Any strings exclusively used in `HomeShortcutGridView` / `HomeMoreActionsGroup` | Widgets removed | 1 |
| Any strings for the "Your Rituals / Daily Practice" section header | Section removed | 5 |

Verify all removed string keys are not referenced elsewhere in the codebase before deleting from `.arb` files. Use `grep -r '<key>' apps/tilawa/lib` to confirm zero remaining usages.

---

## Analytics Events

If analytics events are tracked for Home interactions, the following events become invalid after the redesign and should be removed or replaced:

| Event | Element | Phase | Action |
|-------|---------|-------|--------|
| Home Reciters shortcut tap | Reciters shortcut card | 1 | Remove event |
| Home Qibla shortcut tap | Qibla shortcut card | 1 | Remove event |
| Prayer Strip pill tap | Prayer Day Strip | 1 | Remove event |
| Athkar category pinned | Pinned athkar picker | 5 | Remove event (pinning removed from Home) |

New events to add:

| Event | Element | Phase |
|-------|---------|-------|
| Daily Ayah bookmarked from Home | Bookmark button in `HomeDailyAyahSheet` | 2 |
| Daily Ayah shared from Home | Share button in `HomeDailyAyahSheet` | 2 |
| Continue Listening tapped | `HomeListeningResumeRow` | 4 |
| Athkar category opened from Home compact card | Row tap in `HomeAthkarCompactCard` | 5 |

---

## No Storage Schema Changes

This redesign does not introduce new local storage schemas (Hive boxes, SQLite tables, or SharedPreferences keys). All new cubits (`HomeListeningResumeCubit`, `HomeAthkarCompactCubit`) read from existing storage owned by the player and athkar features respectively.

The one exception: if reading streak data in Phase 3 requires a new `readingStreak` field in the Quran reading history storage, document that schema change in the Quran feature's own migration notes, not here. The Home layer is a consumer, not an owner, of that data.
