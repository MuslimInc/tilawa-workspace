# Home dashboard UI patterns

> **Design / product intent:**
> [`docs/design/home_screen_design_artifacts.md`](../../../docs/design/home_screen_design_artifacts.md)

**Canonical technical Home reference** — sliver stack, body order, widget names,
pin policy, stale-widget list, and agent rules. Other docs must **link here**,
not copy this content.

**Source of truth:** `apps/tilawa/lib/features/home/presentation/` (entry:
`screens/home_screen.dart`).

---

## Agent rules

- **Product-approved layout** — preserve; do not redesign or reorder sections
  unless the user explicitly requests a Home redesign.
- **Allowed without redesign approval:** bug fixes, spacing rhythm, overflow at
  text scale 1.4, semantics/accessibility, token/theme consistency, RTL-safe
  layout — using approved widgets only.
- **Do not wire** stale widgets listed in [Building blocks not on Home](#building-blocks-not-on-home--do-not-implement-as-home-targets).

---

## Approved order (full stack)

Match this order everywhere (slivers + body):

| # | Layer | Widget / behavior |
|---|--------|-------------------|
| 1 | Sliver — Now | `HomeNextPrayerTime` |
| 2 | Sliver — tutor (flag) | `homeFeaturedTutorCardSliver` → scroll-away tutor promo when Quran Sessions enabled |
| 3 | Body | `HomePrimaryActionsSection` |
| 4 | Body | `HomeQuickToolsSection` |
| 5 | Body | `TodayPlanCard` (optional, deferred) |
| 6 | Body | `HomeMoreActionsGroup` (deferred) |
| 7 | Body | `HomeListeningResumeRow` (conditional, deferred) |
| 8 | Body | `HomeDailyInspirationSection` (deferred) |
| 9 | Body | `_HomeDashboardClosingMark` (deferred) |

Items 5–9 render inside `DeferredAfterFirstFrame` except primary actions and
quick tools, which load immediately under the sliver stack.

**Spacing rhythm** (do not change casually without cause): within a zone
`tokens.spaceLarge`; between unrelated zones `tokens.spaceExtraLarge`; More
uses `HomeDashboardSection(compact: true)`.

This is **not** a multi-tab launcher grid. Preserve the calm, polished,
RTL-first dashboard — two featured primary tiles, one compact tools row, flat
More list, conditional listening, inspiration, closing mark.

---

## Approved structure (current)

```text
Scaffold
├── HomeScreenBackground (canvas gradient)
└── RefreshIndicator
    └── CustomScrollView
        ├── HomeNextPrayerTime
        ├── [flag] homeFeaturedTutorCardSliver (SliverToBoxAdapter)
        └── HomeDashboardContentSliver
            └── HomeDashboardBody
                ├── HomePrimaryActionsSection
                ├── HomeQuickToolsSection
                ├── [deferred] TodayPlanCard
                ├── HomeMoreActionsGroup
                ├── [conditional] HomeListeningResumeRow
                ├── HomeDailyInspirationSection
                └── _HomeDashboardClosingMark
```

Deferred body content uses `DeferredAfterFirstFrame` for first-frame perf.
Above-deferred: primary actions + quick tools load immediately under the hero.

---

## Sliver scroll policy (Quran Sessions flag)

When `quranSessionsFeatureConfig().quranSessionsEnabled`:

- Hero and featured tutor slivers scroll away — no pinned headers on Home
- `homeFeaturedTutorCardSliver()` uses transparent canvas padding like
  `HomeNextPrayerTime` and `HomeDashboardContentSliver`

When the flag is off:

- Hero scrolls away (no pin)
- No tutor sliver

---

## Bottom navigation vs Home surfaces

Shell tabs (`app_shell_nav_destinations.dart`): **Home**, **Quran** (push),
**Reciters**, **Settings / Profile**.

| Home surface | Nav relationship | Approved? |
|--------------|------------------|-----------|
| Mushaf tile → `QuranIndexRoute` | Quran push (not a tab duplicate) | Yes |
| Athkar tile → `AthkarCategoriesRoute` | No Athkar tab | Yes |
| Reciters in quick tools | Selects Reciters tab | Yes — intentional daily-listening shortcut |
| Qibla / Tasbeeh in quick tools | Pushed routes, no shell tab | Yes |
| More list items | Library/setup routes | Yes |

**Do not add** Home, Settings/Profile, or Prayer tiles to the body.

**Do not** expand into a 4+ column shortcut grid that mirrors the bottom bar.

---

## Hero

File: `home_next_prayer_time.dart`

- Scrollable `SliverToBoxAdapter` with prayer-period photo/gradient tokens
- Expanded: context row + featured next-prayer card
- Hero text scale clamped 1.0–1.3 for extent math
- Prayer day strip removed — hero owns prayer context

---

## Primary actions section

File: `home_primary_actions_section.dart`

- `HomeDashboardSection` + two `HomePrimaryActionTile` in a row
- Mushaf tile: gold accent rail on start; `TilawaIcons.quran`
- Athkar tile: accent rail on end; morning icon
- Surface: `HomeDashboardElevatedSurface` + hero radius family
- Routes: `QuranIndexRoute`, `AthkarCategoriesRoute`

---

## Quick tools section

File: `home_quick_tools_section.dart`

- Three equal `_QuickToolTile` widgets in one row
- Lighter visual weight than primary tiles (decorative radius, icon box)
- Reciters: `openHomeRecitersTab(context)` — tab selection, not a new route
- Qibla: `QiblaRoute`; Tasbeeh: `TasbeehRoute`

---

## More list

Files: `home_more_actions_group.dart`, `home_grouped_list_row.dart`

- One flat `HomeDashboardCard` with hairline `TilawaDivider`s
- Row: outline icon box + title + optional subtitle + RTL chevron
- Min height: `tokens.minInteractiveDimension`
- Items: History, Favorites, Downloads, Smart Khatma (flag), Support Tilawa

Reciters, Qibla, and Tasbeeh belong in quick tools — not in More.

---

## Continue listening

File: `home_listening_resume_row.dart`

- Shown when `HomeListeningResumeCubit.state.isVisible`
- Placed after More in the approved order
- Resumes last audio queue position
- Neutral raised row — not the featured gold primary lane

Refresh on pull-to-refresh: `HomeListeningResumeCubit.load()` alongside
`HomeDashboardBloc` refresh (`home_screen.dart`).

---

## Daily inspiration

File: `home_daily_inspiration_section.dart`

- One raised `HomeDashboardCard`: ayah block, `TilawaDivider`, dua block
- Arabic line height when `context.isArabic`
- Reference labels: `bodySmall` w500 — not bold badges
- Entrance animation via `_EntranceAnimator`

---

## Closing mark

Private widget in `home_dashboard_body.dart`.

- Quiet Quran icon + app title at scroll bottom
- Does not compete with content; supports peak-end UX

---

## Composition root & refresh

File: `home_screen_scope.dart`

Provides: `HomeDashboardBloc`, `HomeListeningResumeCubit`, optional
`TodayPlanBloc`, optional `SmartKhatmaBloc`.

Pull-to-refresh reloads dashboard bloc + listening resume cubit.

---

## Building blocks **not** on Home — do not implement as Home targets

These names appear in older docs or unused files. They are **not** part of the
approved Home body. Do **not** wire, recommend, or substitute them on Home:

| Name | Status |
|------|--------|
| `HomePrimaryActionZone` | Unused on Home; not an implementation target |
| `HomeDiscoverShortcuts` | Does not exist on disk; superseded by `HomeQuickToolsSection` |
| `HomeDailyPracticeSection` | Does not exist on disk; athkar entry is `HomePrimaryActionsSection` |
| `HomeMorningAthkarSection` | Exists but not in approved Home body |
| `HomeQuickActionsSection` | Legacy; not in approved Home body |
| `HomeDashboardShortcutGrid` | Helper for legacy sections only |
| `PinnedAthkarHomeSection` | Athkar feature; not in approved Home body |

When improving Home, extend **approved widgets** in the order table — never
replace the body with patterns from superseded redesign docs.

---

## Patterns to reuse on Home

| Pattern | File |
|---------|------|
| Section rhythm | `home_dashboard_section.dart` |
| Primary pair tiles | `home_primary_action_tile.dart` |
| Compact tool tile | `home_quick_tools_section.dart` (`_QuickToolTile`) |
| Grouped list row | `home_grouped_list_row.dart` |
| More actions | `home_more_actions_group.dart` |
| Daily inspiration | `home_daily_inspiration_section.dart` |
| Content padding | `home_dashboard_content_sliver.dart` |
| Featured tutor pin | `home_featured_tutor_card.dart` |

---

## Feature flags

- `isTodayPlanEnabled()` → `TodayPlanCard`
- `isSmartKhatmaEnabled()` → Smart Khatma row in More
- `quranSessionsFeatureConfig().quranSessionsEnabled` → pinned tutor sliver + hero pin policy

---

## Adding a new Home section

1. Confirm placement with the **approved body order** table above.
2. Use `HomeDashboardSection` + existing card/tile patterns.
3. Match spacing rhythm (`spaceLarge` / `spaceExtraLarge`).
4. Add l10n (en + ar); no hard-coded chrome strings.
5. Update this file + `docs/design/home_screen_design_artifacts.md` together.
6. Add or update widget tests under `test/features/home/`.

---

## Verification

```sh
cd apps/tilawa && dart analyze
flutter test test/features/home/
```

Manual: light + dark, RTL Arabic, text scale 1.4, hero snap, tutor pin when
flag on.
