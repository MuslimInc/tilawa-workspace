# Home Screen Redesign — Implementation Plan

> **Superseded (2026-06-28).** Do not execute this plan. Approved Home UI:
> `docs/design/home_screen_design_artifacts.md`.

> **⚠️ AI agents — historical archive only:** Phases below must **not** be
> executed. They reference widgets and orders not on the approved Home.

**Status:** Superseded (historical)  
**Date:** 2026-06-20  
**ADR:** [ADR-002: Home Screen Information Architecture](../adr/ADR-home-screen-information-architecture.md)  
**Product Decision Record:** [Home Screen Redesign](../product/home_screen_redesign.md)  
**Acceptance Criteria:** [Home Screen Acceptance Criteria](../specs/home_screen_acceptance_criteria.md)  
**Migration Notes:** [Home Screen Migration Notes](../migrations/home_screen_redesign_migration.md)

---

## Overview (historical)

The phases below were a **planned** Home redesign. The approved Home on disk
differs. Do not execute these phases unless the user explicitly requests that
historical redesign.

**Target architecture after all phases:**

```
HERO → TODAY (Daily Ayah) → YOURS (Quran Progress → Listening Row → Athkar Card) → FOOTER (Tasbeeh)
```

---

## Phase 1 — Remove Duplicate Navigation

**Goal:** Strip every element from Home that duplicates a bottom-nav destination without adding contextual value. Leave no empty spaces — the remaining elements reflow naturally. The screen should feel simpler, not broken.

### What changes

**Remove entirely:**
- `_DiscoverSection` widget and its instantiation in `home_dashboard_body.dart`
- `HomeShortcutGridView` widget
- `HomeMoreActionsGroup` widget
- `HomePrayerDayStrip` widget and its instantiation in `home_today_section.dart`
- `HomeLayoutCubit` (grid/list preference) and `HomeLayoutState`
- The "View All" link in the prayer strip
- `HomeShortcutItem` model / data class (if separate file)
- All callback props that existed solely to support the removed shortcuts: `onOpenReciters`, `onOpenQibla`

**Keep unchanged:**
- Hero sliver (all sub-components)
- Zone 1: Quran Resume Card (untouched in this phase)
- Zone 3: Contextual Athkar card + Pinned Athkar section (untouched in this phase)
- Daily Ayah + Daily Dua block (position unchanged in this phase)
- Tasbeeh shortcut item (kept, but now the only item in what was the Discover section — move it to a minimal single-link footer; see Migration Notes)

### Files expected to change

| File | Change |
|------|--------|
| `lib/features/home/presentation/widgets/home_dashboard_body.dart` | Remove `_DiscoverSection` block and `HomeLayoutCubit` provision |
| `lib/features/home/presentation/widgets/home_today_section.dart` | Remove `HomePrayerDayStrip` and its import |
| `lib/features/home/presentation/widgets/home_shortcut_grid_view.dart` | **Delete file** |
| `lib/features/home/presentation/widgets/home_more_actions_group.dart` | **Delete file** |
| `lib/features/home/presentation/widgets/home_prayer_day_strip.dart` | **Delete file** |
| `lib/features/home/presentation/cubit/home_layout_cubit.dart` | **Delete file** |
| `lib/features/home/presentation/cubit/home_layout_state.dart` | **Delete file** |
| `lib/features/home/presentation/screens/home_screen.dart` | Remove `HomeLayoutCubit` BlocProvider; remove `onOpenReciters`/`onOpenQibla` callbacks |
| `lib/screens/app_shell_screen.dart` | Remove `onOpenReciters`/`onOpenQibla` props passed to HomeScreen |

### Risks

- **Tasbeeh orphaned:** After removing `_DiscoverSection`, Tasbeeh has no home. It must be re-placed as a minimal footer link before this phase is considered complete. Do not leave Tasbeeh inaccessible from Home.
- **Callback prop removal cascades:** `onOpenReciters` and `onOpenQibla` may be passed from `AppShellScreen`. Trace the full call chain before deleting.
- **Test references to removed cubits:** `HomeLayoutCubit` may be instantiated in widget test helpers. All test files referencing it must be updated in this phase.

### Test requirements

- `dart analyze` passes with zero errors.
- `flutter test test/features/home/` passes.
- Verify that no test file still imports `HomeLayoutCubit`, `HomePrayerDayStrip`, `HomeShortcutGridView`, or `HomeMoreActionsGroup`.
- Manual smoke test: Home loads, hero is visible, Quran card is visible, Athkar section is visible, Tasbeeh is reachable.
- Verify Reciters bottom-nav tab still routes correctly (unaffected, but confirm no regression).
- Verify Qibla bottom-nav tab still routes correctly.

### Rollback strategy

Phase 1 is purely subtractive. Git revert to the commit before this phase restores all removed widgets. No data migration, no state schema change, no user-visible data is affected.

---

## Phase 2 — Promote Daily Ayah

**Goal:** Move the Daily Ayah from its buried position at the bottom of the screen to the first content zone below the hero (the "Today" layer). Add bookmark and share interactions so it is a daily action, not passive decoration.

### What changes

**Reposition:**
- Extract `HomeDailyInspirationSection` (currently at the bottom of `home_dashboard_body.dart`) into a new dedicated widget `HomeDailyAyahCard`.
- Insert `HomeDailyAyahCard` as the first child of the scrollable content area, immediately below the hero sliver — above the Quran card and Athkar section.

**Add interactions:**
- Tap on Daily Ayah card → opens a bottom sheet (`HomeDailyAyahSheet`) containing:
  - Full Arabic text (no line truncation)
  - Full translation
  - Surah name + verse reference
  - Bookmark action (saves to user's bookmarks)
  - Share action (triggers platform share sheet with formatted text)
- The card itself remains compact (2–3 lines Arabic, 1–2 lines translation, reference).

**Remove:**
- `HomeDailyDuaSection` from the bottom footer position. The Daily Dua can be included as a second tab or toggle within `HomeDailyAyahSheet`, or retained in a secondary position below the Athkar card. Do not remove it entirely without a conscious decision — it has value for users who seek it. Default: retain it below the Athkar card as a compact card with no interactions until a future phase enhances it.

**Rename:**
- `HomeDailyInspirationSection` → `HomeDailyAyahCard` (reflects its new singular focus and promoted position).

### Files expected to change

| File | Change |
|------|--------|
| `lib/features/home/presentation/widgets/home_daily_inspiration_section.dart` | Rename to `home_daily_ayah_card.dart`; extract from bottom position |
| `lib/features/home/presentation/widgets/home_dashboard_body.dart` | Re-order: insert `HomeDailyAyahCard` above Quran card; remove old bottom position |
| `lib/features/home/presentation/widgets/home_daily_ayah_sheet.dart` | **New file** — bottom sheet with full content + actions |
| Bookmark domain / repository | Add `saveAyahBookmark` or reuse existing bookmark mechanism |
| Localization (`app_en.arb`, `app_ar.arb`) | Add share text template if not present |

### Risks

- **Viewport constraint:** After promotion, the Daily Ayah + hero must together not push the Quran Progress Card below the fold on a standard 6-inch screen. Measure at implementation time. If the combined height exceeds the viewport, consider making the Daily Ayah card slightly more compact (e.g., 2-line Arabic instead of 3-line).
- **Bookmark backend:** If the bookmark feature does not yet support Quran verse bookmarks from Home context (only from the Quran reader), the bookmark action must either be deferred or connected to an existing mechanism. Do not ship a non-functional bookmark button.
- **Share formatting:** Share text must be well-formatted in both Arabic and English. Verify RTL rendering in the platform share sheet.

### Test requirements

- `dart analyze` passes.
- `flutter test test/features/home/` passes.
- Widget test: Daily Ayah card appears before the Quran card in the widget tree.
- Widget test: Tapping the Daily Ayah card opens the bottom sheet.
- Widget test: Bottom sheet contains Arabic text, translation, reference, bookmark button, share button.
- Manual: Quran Progress Card is visible at or near the fold on a device with a 6-inch screen.

### Rollback strategy

Phase 2 repositions and extends existing content. Revert restores the original position and removes the bottom sheet. No data is written to storage unless the user explicitly taps Bookmark, so no storage rollback is needed.

---

## Phase 3 — Quran Progress Card Enhancements

**Goal:** Upgrade the existing Quran Resume Card to communicate streak, today's reading goal progress, and active Khatma plan — transforming it from a navigation shortcut into a progress dashboard for Quran practice.

### What changes

**Extend `HomeQuranResumeCubit`:**
- Add query for reading streak (consecutive days with at least one Quran session).
- Add query for today's reading goal progress (pages read today / daily goal).
- Add query for active Khatma plan label (plan name + current week/juz if Smart Khatma feature is enabled).

**Extend `HomeQuranResumeState`:**
- Add fields: `int? streakDays`, `double? goalProgress`, `String? khatmaPlanLabel`.

**Redesign `HomeQuranResumeCard` layout:**

Returning user with streak and goal:
```
[Progress Ring]  Al-Baqarah · Page 45
                 Day 12 streak  ●●●●○  65% of today's goal
                 [Ramadan Khatma · Week 3]   (if plan active)
                                                           →
```

New user:
```
[Book Icon]  Begin your Quran journey
             Start reading today                           →
```

Loading state: existing skeleton (unchanged).  
Failure state: falls back to new-user copy (unchanged behaviour).

**Streak indicator:** Use a simple pip row (filled/empty circles, max 5 visible) or a flame icon + day count. Do not build a complex streak calendar — that belongs on a dedicated stats screen. One line, scannable in under one second.

**Goal progress:** A thin linear progress bar below the subtitle line. Labelled with percentage ("65%") or page count ("3 of 5 pages"). If no daily goal is configured, omit the bar entirely — do not show an empty or zero-state bar.

**Khatma label:** Single line of secondary text below the progress bar. Only visible when Smart Khatma feature flag is enabled and a plan is active. Do not show the label when no plan is active — do not prompt the user to create a plan from this card.

### Files expected to change

| File | Change |
|------|--------|
| `lib/features/home/presentation/cubit/home_quran_resume_cubit.dart` | Add streak, goal, and plan queries |
| `lib/features/home/presentation/cubit/home_quran_resume_state.dart` | Add `streakDays`, `goalProgress`, `khatmaPlanLabel` fields |
| `lib/features/home/presentation/widgets/home_quran_resume_card.dart` | Redesign layout to show streak + goal + plan |
| Quran reading domain / repository | Add `getReadingStreak()` and `getTodayGoalProgress()` if not present |
| Smart Khatma domain | Add `getActivePlanLabel()` query if not present |

### Risks

- **Streak calculation correctness:** Streaks must use the user's local timezone, not UTC. An incorrect timezone calculation breaks the streak on day boundaries. Verify at implementation time.
- **Goal configuration:** If the user has not configured a daily reading goal, the goal progress bar must be absent, not zero. A zero-state progress bar is demoralising and confusing.
- **Performance:** Three additional domain queries on Home startup. All must be read from local storage (Hive / SQLite), not from a network call. Do not add network dependencies to the Home cubit.
- **Feature flag for Khatma:** Guard all Khatma-related code behind the existing `isSmartKhatmaEnabled()` flag. The card must render correctly when the flag is off.

### Test requirements

- `dart analyze` passes.
- `flutter test test/features/home/` passes.
- Unit test `HomeQuranResumeCubit`: streak field populated correctly from mock repository.
- Unit test `HomeQuranResumeCubit`: goal progress field absent when no goal configured.
- Widget test: Streak indicator visible when `streakDays > 0`.
- Widget test: Progress bar absent when `goalProgress == null`.
- Widget test: Khatma label absent when feature flag is off.
- Widget test: New-user copy shown when `HomeQuranResumeState` has no last-read position.

### Rollback strategy

Phase 3 extends an existing cubit and card. Reverting removes the new fields and restores the original card layout. No new storage schema is introduced if streak and goal are read from existing read-history storage. If a new storage key is required, document it in migration notes and ensure the rollback path does not corrupt existing data.

---

## Phase 4 — Continue Listening Row

**Goal:** Add a conditional "Continue Listening" row to the Yours layer, immediately below the Quran Progress Card. The row is invisible when no listening history exists — it never shows an empty state or a "Browse Reciters" fallback.

### What changes

**New widget `HomeListeningResumeRow`:**
```
[Headphones icon]  Continue · Sheikh Mishary Rashid  ·  Al-Baqarah    →
```
- Avatar or reciter icon on left.
- "Continue" label + reciter name + surah name.
- Tap: resumes playback from last position via the existing player pipeline.
- Hidden (`SizedBox.shrink()` or `Visibility`) when no listening history exists.

**New cubit or extension `HomeListeningResumeCubit`** (or extend `HomeDashboardBloc`):
- Query: last played reciter name, last played surah name, last played position.
- Source: player's existing last-played state (already persisted for mini-player resume).
- Emits: `HomeListeningResumeState` with `reciterName`, `surahName`, `isVisible`.

**Placement:** Insert `HomeListeningResumeRow` in `home_dashboard_body.dart` between `HomeQuranResumeCard` and the Athkar section.

### Files expected to change

| File | Change |
|------|--------|
| `lib/features/home/presentation/widgets/home_listening_resume_row.dart` | **New file** |
| `lib/features/home/presentation/cubit/home_listening_resume_cubit.dart` | **New file** (or extend existing bloc) |
| `lib/features/home/presentation/widgets/home_dashboard_body.dart` | Insert `HomeListeningResumeRow` between Quran card and Athkar section |
| `lib/features/home/presentation/screens/home_screen.dart` | Provide `HomeListeningResumeCubit` if separate |
| Player domain / last-played repository | Expose `getLastPlayedSession()` if not already public |

### Risks

- **State source:** The mini-player already reads last-played state. Ensure `HomeListeningResumeCubit` reads from the same source — do not duplicate storage writes. If the player state source is not injectable, refactor it to be injectable before this phase.
- **Row visibility on cold launch:** If last-played state loads asynchronously, the row must not flash visible and then disappear. Use a loading state that keeps the row invisible until data is confirmed present or absent.
- **Navigation on tap:** Tapping the row should resume playback, not navigate to the Reciters screen. Use the existing player entry pipeline. See [player-entry-pipeline.md](../architecture/player-entry-pipeline.md).

### Test requirements

- `dart analyze` passes.
- `flutter test test/features/home/` passes.
- Widget test: Row is absent when `HomeListeningResumeState` has no history.
- Widget test: Row is visible and shows correct reciter/surah names when history exists.
- Widget test: Tapping row invokes the correct player resume action (not navigation to Reciters).
- Widget test: Row is positioned below Quran card and above Athkar card in widget tree.

### Rollback strategy

Phase 4 adds a new widget and cubit. Reverting removes both. No storage schema is modified — the cubit reads from existing player storage. Clean rollback.

---

## Phase 5 — Athkar Compact Card

**Goal:** Replace the current Pinned Athkar section (pinned grid/list with no completion state) and the Contextual Athkar Hero card with a single, unified Athkar Compact Card showing three rows — Morning, Evening, Sleep — each with live completion state and time-contextual ordering.

### What changes

**Remove:**
- `PinnedAthkarHomeSection` from Home (the athkar feature widget).
- `_ContextualAthkarCard` / `HomeFeaturedRitualCard` widget from `home_today_section.dart`.
- The "Your Rituals / Daily Practice" section header and its trailing edit button.
- The pinned athkar picker modal trigger (the edit icon button that allowed pinning/unpinning categories).

**Add:**
- New widget `HomeAthkarCompactCard` in `lib/features/home/presentation/widgets/home_athkar_compact_card.dart`.

**Card structure:**
```
┌─────────────────────────────────────────────────────┐
│  ☀  Morning Athkar      ✓ Done             →        │
│  ─────────────────────────────────────────────────  │
│  🌙  Evening Athkar     34 remaining       →        │
│  ─────────────────────────────────────────────────  │
│  ★   Sleep Athkar       Not started        →        │
└─────────────────────────────────────────────────────┘
```

Row ordering: time-contextual, most urgent first. Reuse the `contextualAthkarCategory()` logic already present in the athkar cubit to determine ordering. Do not implement a new ordering algorithm.

Status text states:
- `✓ Done` — user has completed all dhikr in this category today.
- `N remaining` — user has started but not completed (e.g., "34 remaining").
- `Not started` — no dhikr read from this category today.

Tap on any row → `AthkarDetailsRoute` for that category (same navigation as before).

**New cubit `HomeAthkarCompactCubit`** (or extend `HomeDashboardBloc`):
- Queries completion state for Morning, Evening, Sleep categories.
- Determines row ordering via prayer time / current time.
- Emits `HomeAthkarCompactState` with three `AthkarRowState` entries.

**Note on pinned categories:** The previous design allowed users to pin arbitrary athkar categories. This redesign replaces pinning with a fixed set of three canonical daily categories (Morning, Evening, Sleep). This is a deliberate product simplification — the pinning feature added configuration overhead for minimal user benefit, and the three canonical categories cover the daily practice of the vast majority of users. If the pinning feature has significant adoption data suggesting otherwise, revisit before removing.

### Files expected to change

| File | Change |
|------|--------|
| `lib/features/home/presentation/widgets/home_athkar_compact_card.dart` | **New file** |
| `lib/features/home/presentation/cubit/home_athkar_compact_cubit.dart` | **New file** |
| `lib/features/home/presentation/widgets/home_today_section.dart` | Remove `_ContextualAthkarCard`; remove `HomeFeaturedRitualCard` |
| `lib/features/home/presentation/widgets/home_dashboard_body.dart` | Replace `PinnedAthkarHomeSection` with `HomeAthkarCompactCard` |
| `lib/features/home/presentation/screens/home_screen.dart` | Provide `HomeAthkarCompactCubit`; remove `PinnedAthkarCubit` provision |
| `lib/features/home/presentation/cubit/home_pinned_athkar_cubit.dart` | **Delete file** (if only used on Home) |
| Athkar domain | Expose completion state queries for the three canonical categories |

### Risks

- **Completion state freshness:** If a user completes Athkar in the Athkar sub-screen and returns to Home, the compact card must reflect the update. Ensure `HomeAthkarCompactCubit` either listens to a stream from the athkar repository or is refreshed on `HomeScreen` resume.
- **Pinning feature removal:** If the pinning feature has been promoted to users as a customisation feature, removing it is a breaking change in UX terms. Verify adoption before removal. If adoption is significant, consider keeping pinning in the Athkar tab rather than removing it entirely.
- **Three fixed categories assumption:** The canonical three (Morning, Evening, Sleep) map to specific athkar category IDs. Verify the IDs are stable and not user-configurable before hardcoding.
- **Midnight reset:** Completion state must reset at midnight in the user's local timezone, consistent with the existing athkar completion logic.

### Test requirements

- `dart analyze` passes.
- `flutter test test/features/home/` passes.
- Widget test: Three rows visible with correct labels (Morning, Evening, Sleep).
- Widget test: Row order matches time-contextual expectation (mock prayer time service).
- Widget test: "✓ Done" state shown correctly when all dhikr in a category are complete.
- Widget test: "N remaining" state shown with correct count.
- Widget test: "Not started" state shown for untouched categories.
- Widget test: Tapping any row navigates to `AthkarDetailsRoute` for that category.
- Unit test `HomeAthkarCompactCubit`: completion state updates when repository emits new data.
- Unit test `HomeAthkarCompactCubit`: row ordering is correct for Fajr time (Morning first).
- Unit test `HomeAthkarCompactCubit`: row ordering is correct for Maghrib time (Evening first).

### Rollback strategy

Phase 5 is the most significant behaviour change — it removes the pinning feature from Home. Rollback requires restoring `PinnedAthkarCubit`, `PinnedAthkarHomeSection`, and `_ContextualAthkarCard`. These should be preserved (not deleted) until Phase 5 is confirmed stable in production. Mark them `// LEGACY: preserved for Phase 5 rollback` rather than deleting immediately.

---

## Post-Implementation Checklist

After all five phases are complete and stable:

- [ ] Run full test suite: `flutter test` from `apps/tilawa/`.
- [ ] Run `dart analyze` with zero errors or warnings.
- [ ] Delete all `// LEGACY` rollback-preservation comments and their associated dead code.
- [ ] Update `test/features/home/` test helpers to remove references to deleted cubits and widgets.
- [ ] Verify acceptance criteria: [Home Screen Acceptance Criteria](../specs/home_screen_acceptance_criteria.md).
- [ ] Update screenshot assets if used in any CI screenshot tests.
- [ ] Review analytics events — if any events were tied to removed shortcuts (Reciters tap, Qibla tap from Home), remove those event calls or replace with equivalent events on the new elements.
