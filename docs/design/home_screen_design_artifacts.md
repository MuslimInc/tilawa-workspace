# Home Screen Design Artifacts

**Status:** Approved implementation reference  
**Last verified:** 2026-06-28  
**Implementation:** `apps/tilawa/lib/features/home/presentation/`  
**Pattern reference:**
`.agents/skills/tilawa-apply-ui-principles/references/home-dashboard-patterns.md`  
**Related tests:** `apps/tilawa/test/features/home/presentation/`

This document describes the **current, product-approved** Home UI/UX. Older
redesign plans (ADR-002, product PDR, migration notes) are historical context
only — **trust this file and the code** when implementing or reviewing Home.

**For AI agents:** Do not redesign Home from scratch. Preserve the approved
order below. Improve only: bugs, spacing, overflow, accessibility, token
consistency, RTL layout — using existing approved widgets. Do not reorder
sections or wire stale widgets (`HomePrimaryActionZone`, `HomeDiscoverShortcuts`,
`HomeDailyPracticeSection`, etc.) unless explicitly requested.

---

## 1. Approved order (full stack)

| # | Layer | Widget / behavior |
|---|--------|-------------------|
| 1 | Sliver | `HomeDashboardHeroSliver` (Variant B) |
| 2 | Sliver (flag) | `homeFeaturedTutorCardSliver` — pinned tutor promo; hero unpins when enabled |
| 3 | Body | `HomePrimaryActionsSection` |
| 4 | Body | `HomeQuickToolsSection` |
| 5 | Body | `TodayPlanCard` (optional, deferred) |
| 6 | Body | `HomeMoreActionsGroup` (deferred) |
| 7 | Body | `HomeListeningResumeRow` (conditional, deferred) |
| 8 | Body | `HomeDailyInspirationSection` (deferred) |
| 9 | Body | `_HomeDashboardClosingMark` (deferred) |

---

## 2. Screen structure

```text
HomeScreenScope
└── HomeScreen
    └── Scaffold
        ├── HomeScreenBackground
        └── RefreshIndicator
            └── CustomScrollView
                ├── HomeDashboardHeroSliver → Variant B
                ├── [flag] homeFeaturedTutorCardSliver
                └── HomeDashboardContentSliver
                    └── HomeDashboardBody
```

Content sheet: flat on `surfaceContainerLow`, horizontal padding from
`TilawaHomeScreenTokens.screenHorizontalPadding`, bottom padding from
`TilawaShellPadding` (clears shell + mini-player).

---

## 3. Body detail (matches stack above)

From `home_dashboard_body.dart`. Sliver layers #1–2 sit above this column.

Items 5–9 use `DeferredAfterFirstFrame`. Primary actions + quick tools load
immediately.

---

## 4. Hero

`HomeDashboardHeroVariantB` — pinned `SliverPersistentHeader`:

- Prayer-period photo/gradient via `HomeHeroGradientResolver` /
  `HomeHeroPhotoTheme`
- Context row, next-prayer featured card, location refresh, retry
- Collapsed toolbar keeps prayer context while scrolling
- `sheetOverlap`: 8 dp
- Snap: 35% of collapse extent; `durationFast` + `easeOutCubic`
- Text scale clamp 1.0–1.3 for hero height math

When Quran Sessions is enabled, the hero **unpins** and the tutor header
**pins** instead (`homeDashboardHeroShouldPin()`).

---

## 4. Primary actions

Two equal `HomePrimaryActionTile` widgets:

| Tile | Destination | Visual |
|------|-------------|--------|
| Mushaf | `QuranIndexRoute` | Gold accent rail (start) |
| Athkar | `AthkarCategoriesRoute` | Gold accent rail (end) |

Elevated surface + hero radius. Section title from `homeMainActionsTitle`.

This pair is intentional daily worship entry — not a bottom-nav duplicate grid.

---

## 5. Quick tools

Compact three-tile row (`_QuickToolTile`):

| Tool | Action |
|------|--------|
| Reciters | `openHomeRecitersTab` — selects existing shell tab |
| Qibla | `QiblaRoute` |
| Tasbeeh | `TasbeehRoute` |

Visually lighter than primary tiles. Reciters on Home is an approved exception
for daily listening; do not move it to More or remove it without product sign-off.

---

## 6. More

Flat grouped list (`HomeMoreActionsGroup`, `compact: true`):

- History, Favorites, Downloads
- Smart Khatma when `isSmartKhatmaEnabled()`
- Support Tilawa

One flat card, hairline dividers, `HomeGroupedListRow` rows.

---

## 7. Continue listening

`HomeListeningResumeRow` when `HomeListeningResumeCubit.state.isVisible`.

- Appears **after** More in the approved order
- Neutral surface; resumes last playback
- Hidden entirely when no listening history

---

## 8. Inspiration

`HomeDailyInspirationSection` — single raised card:

- Daily ayah row + divider + daily dua row
- Catalog rotation via `homeDailyInspirationCatalogIndex`
- Arabic typography uses `tokens.textHeightLoose`
- Compact body lines (capped) so inspiration supports rather than dominates

---

## 9. Featured tutor (Quran Sessions flag)

When enabled:

- Pinned `HomeFeaturedTutorCardHeaderDelegate` between hero and body
- Status-bar `topInset`, scroll-linked bottom elevation when pinned
- Hero unpins to keep the pinned stack compact

Standalone `HomeFeaturedTutorCard` exists for tests; production Home uses the
pinned header sliver API.

---

## 10. States & refresh

- Pull-to-refresh: `HomeDashboardRefreshRequested` + `HomeListeningResumeCubit.load()`
- Shell tab reselect: scroll to top or refresh (`ShellTabReselectListener`)
- Hero snap on partial collapse (see `home_screen.dart`)
- Listening row collapses to zero height when not visible

---

## 11. Design system usage

- Tokens: `context.tokens`, `theme.componentTokens.homeScreen`
- Sections: `HomeDashboardSection` / `TilawaSectionTitle`
- Cards: `HomeDashboardCard`, `HomeDashboardElevatedSurface`
- Icons: `TilawaIcons`, hero accent from `homePrayerHeroAccent`
- RTL: directional padding/alignment throughout
- No raw hex or magic spacing in feature widgets

---

## 12. Tests covering the contract

- `home_dashboard_body_test.dart` — section presence and vertical order
- `home_screen_test.dart`
- `home_dashboard_hero_variant_b_test.dart`
- `home_dashboard_content_sliver_test.dart`
- `home_featured_tutor_card_test.dart`

Before changing Home UI, update this document, `home-dashboard-patterns.md`,
and affected tests together — **only when the user approves the change**.

---

## 13. Superseded references

Do not implement from these without explicit user request:

- `docs/product/home_screen_redesign.md`
- `docs/adr/ADR-home-screen-information-architecture.md`
- `docs/plans/home_screen_redesign_plan.md`
- `docs/migrations/home_screen_redesign_migration.md`
- `docs/specs/home_screen_acceptance_criteria.md`

Those describe an earlier redesign trajectory that **does not match** the
approved Home on disk.
