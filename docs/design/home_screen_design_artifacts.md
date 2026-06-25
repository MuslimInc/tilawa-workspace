# Home Screen Design Artifacts

**Status:** Current implementation reference
**Last verified:** 2026-06-25
**Implementation:** `apps/tilawa/lib/features/home/presentation/`
**Related tests:** `apps/tilawa/test/features/home/presentation/`

This document describes the Home UI/UX currently implemented in Flutter. Older
concept wireframes were removed from this file because the implementation has
settled on a more compact daily-dashboard model.

---

## 1. Current Structure

Source of truth:

- `screens/home_screen.dart`
- `widgets/home_dashboard_hero_sliver.dart`
- `widgets/home_dashboard_hero_variant_b.dart`
- `widgets/home_dashboard_content_sliver.dart`
- `widgets/home_dashboard_body.dart`

```text
Scaffold
└── RefreshIndicator
    └── CustomScrollView
        ├── HomeDashboardHeroSliver
        │   └── HomeDashboardHeroVariantB
        └── HomeDashboardContentSliver
            └── HomeDashboardBody
                ├── HomePrimaryActionZone
                ├── [flag] TodayPlanCard
                ├── HomeDailyPracticeSection
                ├── HomeDailyInspirationSection
                ├── HomeDiscoverShortcuts
                ├── HomeMoreActionsGroup
                └── [conditional] HomeListeningResumeRow
```

The content sheet is flat on `surfaceContainerLow`, with horizontal
`tokens.spaceMedium` padding and bottom padding from `TilawaShellPadding` so
content clears the shell and mini-player.

---

## 2. UX Order

Home uses a daily ritual hierarchy:

1. **Now:** prayer context, greeting, date, location, and refresh/retry state in
   the pinned hero.
2. **Primary action:** one prominent resume action directly under the hero.
   `HomePrimaryActionCubit` chooses Quran, listening, or urgent athkar from the
   supporting cubits.
3. **Practice:** optional Today Plan, contextual athkar, and pinned athkar edit.
4. **Inspiration:** daily ayah and dua grouped in one card.
5. **Discover:** supporting shortcuts in a compact grid, visually quieter than
   the daily ritual surfaces.
6. **More:** lower-frequency library and setup destinations.
7. **Listening row:** shown only when listening is available and not already the
   primary action.

This order keeps the first screen useful without rebuilding Home as a tab
launcher.

---

## 3. Hero

`HomeDashboardHeroVariantB` is the current hero. It is a pinned
`SliverPersistentHeader` with:

- prayer-period photo/gradient tokens from `HomeHeroGradientResolver` and
  `HomeHeroPhotoTheme`
- compact context row
- next-prayer featured card
- location refresh and dashboard retry actions
- collapsed toolbar that preserves prayer context while scrolling

Hero behavior:

- `sheetOverlap`: 8 dp
- snap threshold: 35% of `HomeDashboardHeroSliver.collapseScrollExtent`
- snap motion: `tokens.durationFast` with `Curves.easeOutCubic`
- text scale is clamped for hero body height calculations between 1.0 and 1.3

The old Home prayer-day strip is removed. Prayer context belongs in the hero;
the full prayer experience belongs outside Home.

---

## 4. Primary Action

`HomePrimaryActionZone` renders `HomePrimaryActionCard`.

| State | Widget | UX |
|---|---|---|
| Quran | `HomeQuranResumeCard(featured: true)` | Gold featured card; starts or resumes Quran; shows progress, streak, goal, and active Khatma context when available. |
| Listening | `_HomePrimaryListeningCard` | Neutral raised resume card; resumes the last audio queue position. |
| Athkar | `_HomePrimaryAthkarCard` | Neutral raised urgent-athkar card; opens the relevant athkar detail screen. |

Only the Quran state uses the featured gold gradient. Listening and athkar stay
neutral so the screen keeps one ceremonial emphasis lane.

---

## 5. Discover

`HomeDiscoverShortcuts` is the supporting shortcut block below daily ritual
content.

Current items:

- Reciters: selects `kAppShellRecitersTabIndex`
- Qibla: pushes `QiblaRoute`
- Tasbeeh: pushes `TasbeehRoute`
- Bookmarks: pushes `BookmarksRoute`
- Quran Sessions: shown only when
  `quranSessionsFeatureConfig().quranSessionsEnabled`

Layout:

- 2 columns on narrow screens
- 4 columns on medium and wider screens
- stable tile height from icon + two-line label math
- neutral section treatment; no gradient shell

Rule: do not add Home, Quran, Prayer, Athkar, or Settings/Profile tiles here.
Reciters is the current exception because listening is a core daily behavior and
the shortcut reuses the existing tab.

---

## 6. Daily Practice

`HomeDailyPracticeSection` owns quick athkar:

- title from `homeAthkarRitualsTitle`
- trailing edit `TilawaIconActionButton`
- `_ContextualAthkarCard` when a time-relevant pinned category exists
- `PinnedAthkarHomeSection` with its own header hidden

The picker remains a modal bottom sheet via `showPinnedAthkarPicker(context)`.
Pinned athkar stay user-customizable; this implementation does not remove the
pinning feature.

---

## 7. Inspiration

`HomeDailyInspirationSection` groups daily ayah and daily dua in a single raised
`HomeDashboardCard`:

- one row for ayah
- `TilawaDivider`
- one row for dua
- tertiary vertical accent rail
- reference labels in `bodySmall` weight 500
- Arabic typography uses `tokens.textHeightLoose`

Rows are intentionally compact and capped to three body lines so inspiration
supports the dashboard instead of dominating the first screen.

---

## 8. More

`HomeMoreActionsGroup` is a flat grouped list for lower-frequency destinations.

Current items:

- History
- Favorites
- Downloads
- Smart Khatma when `isSmartKhatmaEnabled()`
- Support Tilawa

The More list uses one flat `HomeDashboardCard`, `HomeGroupedListRow`, and
hairline dividers. Reciters, Qibla, Tasbeeh, and Bookmarks do not belong here in
the current design because they are surfaced earlier in Discover.

---

## 9. States And Verification

Implemented state coverage:

- Pull-to-refresh reloads dashboard, Quran resume, listening resume, athkar
  compact state, then recomputes the primary action.
- Primary action updates through `HomePrimaryActionSyncListener`.
- Listening resume row hides when listening is already primary.
- Discover sits below daily practice and inspiration, avoids the old layout
  toggle, and avoids Prayer/Quran/Athkar/Settings shortcut duplicates.

Current tests covering this contract:

- `home_screen_test.dart`
- `home_dashboard_body_test.dart`
- `home_dashboard_hero_variant_b_test.dart`
- `home_dashboard_content_sliver_test.dart`
- `home_dashboard_shortcut_grid_test.dart`

Before changing Home UI, update this document, the home pattern reference in
`.agents/skills/tilawa-apply-ui-principles/references/home-dashboard-patterns.md`,
and any affected widget tests together.
