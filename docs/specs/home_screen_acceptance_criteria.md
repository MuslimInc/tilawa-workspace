# Home Screen Redesign — Acceptance Criteria

**Status:** Draft — awaiting implementation  
**Date:** 2026-06-20  
**Implementation Plan:** [Home Screen Redesign Plan](../plans/home_screen_redesign_plan.md)  
**ADR:** [ADR-002: Home Screen Information Architecture](../adr/ADR-home-screen-information-architecture.md)

---

## How to Use This Document

Each criterion is assigned to a phase. Criteria are testable — each has a clear pass/fail condition. Run these checks after the relevant phase is complete before merging.

An **automated** criterion should be covered by a widget or unit test.  
A **manual** criterion requires a device or simulator with a human tester.

---

## Phase 1 — Removal Criteria

### AC-1.1 — No duplicate bottom-nav shortcuts on Home
**Type:** Manual + automated  
**Pass:** The Home screen contains no shortcut, card, tile, or link whose sole purpose is to navigate to a screen already reachable via the bottom navigation bar without providing contextual value (progress, resume state, or personalisation) that the nav tab cannot provide.  
**Fail:** A "Browse Reciters" card, a "Find Qibla" card, or any equivalent static-label navigation shortcut appears on Home.

### AC-1.2 — Prayer Day Strip is absent
**Type:** Automated (widget test)  
**Pass:** `HomePrayerDayStrip` is not present in the Home widget tree.  
**Fail:** The widget is found in the tree, or a replacement widget renders more than two prayer time entries on the Home screen body (the hero is excluded from this check).

### AC-1.3 — Discover / Explore section is absent
**Type:** Automated (widget test)  
**Pass:** No widget with a section header labelled "Discover", "Explore", or equivalent is present on Home.  
**Fail:** A grid or list of feature shortcuts with a section header is present on Home.

### AC-1.4 — Layout toggle is absent
**Type:** Automated (widget test)  
**Pass:** No grid ↔ list toggle button or `HomeLayoutCubit` provider is present on Home.  
**Fail:** An `Icons.grid_view_rounded` or `Icons.view_list_rounded` toggle is visible on Home.

### AC-1.5 — Tasbeeh remains accessible from Home
**Type:** Manual  
**Pass:** The user can reach the Tasbeeh screen from Home in one tap.  
**Fail:** No Tasbeeh entry point exists on Home after the Discover section is removed.

### AC-1.6 — Static analysis passes
**Type:** Automated  
**Pass:** `dart analyze` from `apps/tilawa/` reports zero errors and zero warnings after Phase 1 changes.  
**Fail:** Any error or warning introduced by Phase 1 changes.

---

## Phase 2 — Daily Ayah Criteria

### AC-2.1 — Daily Ayah visible without scrolling on a standard device
**Type:** Manual (device / simulator)  
**Pass:** On a device with a screen height of 667 logical pixels or greater (iPhone SE 2nd gen and above; most Android phones), the Daily Ayah card is fully or partially visible below the hero without the user scrolling.  
**Fail:** The user must scroll to see any part of the Daily Ayah card on a 667px-height screen.  
**Note:** The hero in its collapsed state must not consume more vertical space than is needed for the next-prayer card and greeting. If the hero is too tall, revisit its minimum collapsed height before shipping Phase 2.

### AC-2.2 — Daily Ayah card appears before Quran Progress Card
**Type:** Automated (widget tree order)  
**Pass:** `HomeDailyAyahCard` (or equivalent) appears earlier in the widget tree than `HomeQuranResumeCard`.  
**Fail:** The Quran card appears above the Daily Ayah card.

### AC-2.3 — Daily Ayah card changes daily
**Type:** Automated (unit test)  
**Pass:** `homeDailyInspirationCatalogIndex(DateTime(2026, 6, 20))` returns a different value than `homeDailyInspirationCatalogIndex(DateTime(2026, 6, 21))`.  
**Fail:** The same catalog index is returned for consecutive days.

### AC-2.4 — Tapping Daily Ayah card opens a bottom sheet
**Type:** Automated (widget test)  
**Pass:** Tapping the Daily Ayah card causes a bottom sheet to appear containing the full Arabic text, full translation, verse reference, a bookmark button, and a share button.  
**Fail:** Tapping has no effect, or the bottom sheet is missing any of the required elements.

### AC-2.5 — Bookmark action is functional
**Type:** Manual  
**Pass:** Tapping the bookmark button in the Daily Ayah bottom sheet saves the verse to the user's bookmarks without error. The button updates its visual state to indicate the verse is bookmarked.  
**Fail:** The bookmark button is non-functional, shows an error, or does not update its visual state.

### AC-2.6 — Share action is functional
**Type:** Manual  
**Pass:** Tapping the share button in the Daily Ayah bottom sheet opens the platform share sheet with well-formatted text including the Arabic verse, translation, and reference.  
**Fail:** The share button is non-functional, or the share sheet contains malformed, truncated, or missing text.

---

## Phase 3 — Quran Progress Card Criteria

### AC-3.1 — Quran Progress Card is visible at or near the fold
**Type:** Manual (device / simulator)  
**Pass:** On a 667px-height screen, the top edge of the Quran Progress Card is visible when the hero is in its minimum collapsed height (as it appears after a user has scrolled down slightly). The user does not need to scroll more than one viewport height from launch to see the Quran card.  
**Fail:** The Quran card is below one full viewport height from the top of the screen even after the hero collapses.

### AC-3.2 — Streak is displayed for users with a reading streak
**Type:** Automated (widget test with mock cubit)  
**Pass:** When `HomeQuranResumeState.streakDays = 7`, the Quran card displays "Day 7" or "7-day streak" or equivalent.  
**Fail:** Streak is not visible, or an incorrect value is shown.

### AC-3.3 — Streak is absent when no streak exists
**Type:** Automated (widget test)  
**Pass:** When `HomeQuranResumeState.streakDays = 0` or `null`, no streak indicator is displayed on the Quran card.  
**Fail:** A "Day 0" or "0-day streak" indicator is shown.

### AC-3.4 — Goal progress bar is displayed when a daily goal is configured
**Type:** Automated (widget test with mock cubit)  
**Pass:** When `HomeQuranResumeState.goalProgress = 0.65`, a progress bar is visible on the Quran card and a label indicates approximately 65% completion.  
**Fail:** Progress bar is absent or shows incorrect value.

### AC-3.5 — Goal progress bar is absent when no goal is configured
**Type:** Automated (widget test)  
**Pass:** When `HomeQuranResumeState.goalProgress = null`, no progress bar appears on the Quran card.  
**Fail:** An empty or zero-value progress bar is shown.

### AC-3.6 — Khatma plan label is shown only when plan is active and feature flag is on
**Type:** Automated (widget test, two scenarios)  
**Pass (flag on, plan active):** Khatma plan label is visible on the Quran card.  
**Pass (flag off):** No Khatma label is visible.  
**Pass (flag on, no active plan):** No Khatma label is visible.  
**Fail:** Any scenario where the label visibility does not match the above conditions.

### AC-3.7 — New-user copy shown when no reading history exists
**Type:** Automated (widget test)  
**Pass:** When `HomeQuranResumeState` has no last-read position, the card displays a "Begin your Quran journey" CTA (or equivalent).  
**Fail:** An empty card, a null error, or resume copy that references a non-existent position is shown.

### AC-3.8 — Tapping Quran card navigates to last read position
**Type:** Manual  
**Pass:** Tapping the Quran card (when history exists) opens the Quran reader at the last read page and surah.  
**Fail:** Navigation leads to the Quran index page or the start of the Quran.

---

## Phase 4 — Listening Row Criteria

### AC-4.1 — Listening row is absent when no listening history exists
**Type:** Automated (widget test)  
**Pass:** When `HomeListeningResumeState.isVisible = false`, no listening row is present in the widget tree. There is no visible gap or empty placeholder in its expected position.  
**Fail:** An empty row, a placeholder, or a "Browse Reciters" fallback is shown.

### AC-4.2 — Listening row shows correct reciter and surah names
**Type:** Automated (widget test with mock cubit)  
**Pass:** When `HomeListeningResumeState` contains reciter name "Sheikh Mishary" and surah "Al-Baqarah", the row displays both values.  
**Fail:** Incorrect, missing, or placeholder values are shown.

### AC-4.3 — Listening row is positioned below Quran card
**Type:** Automated (widget tree order)  
**Pass:** `HomeListeningResumeRow` appears after `HomeQuranResumeCard` in the widget tree.  
**Fail:** The Listening row appears above the Quran card.

### AC-4.4 — Tapping Listening row resumes playback
**Type:** Manual  
**Pass:** Tapping the Listening row resumes audio playback from the last position. The mini-player becomes active. Navigation does not go to the Reciters screen.  
**Fail:** Tapping navigates to the Reciters search screen, or playback does not resume.

### AC-4.5 — Listening row does not flash on cold launch
**Type:** Manual  
**Pass:** On cold launch with listening history, the row either appears immediately (synchronous load) or appears after a brief delay without first appearing and then disappearing.  
**Fail:** The row is visible briefly, then hides, then reappears (flicker).

---

## Phase 5 — Athkar Compact Card Criteria

### AC-5.1 — Athkar Compact Card shows exactly three rows
**Type:** Automated (widget test)  
**Pass:** The Athkar Compact Card always shows exactly three rows: Morning Athkar, Evening Athkar, Sleep Athkar.  
**Fail:** Fewer than three rows, or additional rows beyond the three canonical categories, are shown.

### AC-5.2 — Each row shows a labelled category name and icon
**Type:** Automated (widget test)  
**Pass:** Each row contains a visible icon and a text label identifying the category (Morning, Evening, Sleep or their localised equivalents).  
**Fail:** Unlabelled rows, or missing icons.

### AC-5.3 — Completion state is accurate per category
**Type:** Automated (widget test with mock data)  
**Pass:**  
- When a category is fully complete: row shows "✓ Done" or equivalent.  
- When a category is partially complete (N dhikr remaining): row shows "N remaining".  
- When a category is untouched: row shows "Not started" or equivalent.  
**Fail:** Any mismatch between mock data and displayed state.

### AC-5.4 — Row ordering is time-contextual
**Type:** Automated (unit test with mocked prayer/time service)  
**Pass:**  
- At Fajr time: Morning Athkar row appears first.  
- At Maghrib time: Evening Athkar row appears first.  
- After Isha: Sleep Athkar row appears first.  
**Fail:** Rows are always in fixed alphabetical order regardless of time.

### AC-5.5 — Tapping a row navigates to the correct Athkar category
**Type:** Automated (widget test) + Manual  
**Pass:** Tapping the Morning row opens the Morning Athkar detail screen. Tapping Evening opens Evening. Tapping Sleep opens Sleep. Navigation does not go to the Athkar tab index screen.  
**Fail:** Any tap leads to the wrong category or the Athkar index screen.

### AC-5.6 — Completion state updates after returning from Athkar screen
**Type:** Manual  
**Pass:** User taps Evening Athkar row → completes all dhikr → returns to Home → Evening Athkar row now shows "✓ Done".  
**Fail:** The row still shows "N remaining" or "Not started" after completion and return to Home.

### AC-5.7 — PinnedAthkarHomeSection is no longer present on Home
**Type:** Automated (widget test)  
**Pass:** `PinnedAthkarHomeSection` widget is not present in the Home widget tree.  
**Fail:** The old pinned athkar grid or list is still visible.

### AC-5.8 — Contextual Athkar Hero card is no longer present on Home
**Type:** Automated (widget test)  
**Pass:** `HomeFeaturedRitualCard` and `_ContextualAthkarCard` are not present in the Home widget tree.  
**Fail:** The old contextual "Do this now" card is still visible as a separate element.

---

## Global Criteria (All Phases)

### AC-G.1 — Next prayer visible without scrolling on all standard devices
**Type:** Manual  
**Pass:** On any device with screen height ≥ 667 logical pixels, the next prayer name, time, and countdown are visible in the hero without any scrolling.  
**Fail:** The prayer card requires scrolling to see on any device in this size range.

### AC-G.2 — Home is valuable within 3 seconds of launch for a new user
**Type:** Manual (device, first-install or cleared-data scenario)  
**Pass:** Within 3 seconds of the Home screen loading, a user with no reading history, no listening history, and no completed Athkar can see: (1) the next prayer countdown in the hero, and (2) the Daily Ayah card.  
**Fail:** Both elements require scrolling, or either fails to load within 3 seconds on a standard connection.

### AC-G.3 — No navigation shortcut on Home duplicates a bottom-nav tab destination without contextual value
**Type:** Manual (final review across all phases)  
**Pass:** Every tappable element on Home either (a) provides contextual information not available from the bottom-nav tab (e.g., "Continue · Page 45" vs "Open Quran"), or (b) is a utility without a bottom-nav tab (Tasbeeh).  
**Fail:** Any tappable element on Home routes to the same screen as a bottom-nav tab without adding personalisation, progress, or resume context.

### AC-G.4 — Full test suite passes
**Type:** Automated  
**Pass:** `flutter test` from `apps/tilawa/` exits with zero failures.  
**Fail:** Any test failure.

### AC-G.5 — Static analysis clean
**Type:** Automated  
**Pass:** `dart analyze` from `apps/tilawa/` exits with zero errors and zero warnings.  
**Fail:** Any error or warning.
