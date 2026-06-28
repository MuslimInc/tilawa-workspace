# Tilawa feature placement policy

Consolidated from `DESIGN.md` and product specs. When docs conflict on
*implementation*, trust **code** + `home-dashboard-patterns.md` +
`docs/design/home_screen_design_artifacts.md`; this file guides *UX placement*.

## Worship surfaces (restrictive)

Treat as **active worship / reading** — minimal interruption:

- Quran reader
- Athkar detail / counting flow
- Prayer times during salat-adjacent flows
- Tasbeeh counting session

**Forbidden on worship surfaces:**

- Support Tilawa / donation prompts
- Onboarding carousels
- Product tours / coach marks
- Cold-start promotional modals
- Account upsell

**Allowed:** inline controls needed for the act (counter, navigation, audio).

## Home dashboard

Treat Home as an **approved daily module stack**. Preserve the current layout
unless the user explicitly requests a Home redesign.

**Encouraged (current implementation):**

- Hero prayer/time context (`HomeDashboardHeroSliver`)
- Optional pinned tutor header when Quran Sessions is enabled
- Two primary tiles: Mushaf + Athkar (`HomePrimaryActionsSection`)
- Compact quick tools row: Reciters, Qibla, Tasbeeh
- Optional Today plan card
- Flat More list for library/setup destinations
- Conditional continue-listening row
- Daily ayah / dua inspiration + quiet closing mark

**Forbidden on Home:**

- Redesigning or reordering approved sections without explicit user approval
- Wiring stale widgets (`HomePrimaryActionZone`, `HomeDiscoverShortcuts`,
  `HomeDailyPracticeSection`, etc.)
- Tiles for Home, Prayer, or Settings/Profile
- Multi-column shortcut grids that mirror the bottom navigation bar
- Cold-start modals or support prompts on entry

**Reciters exception:** Reciters appears in **quick tools** and selects the
existing Reciters shell tab — intentional for daily listening. Do not move it
to More or remove it without product sign-off.

**More list rule:** History, Favorites, Downloads, Smart Khatma (when enabled),
Support Tilawa. Qibla and Tasbeeh belong in quick tools, not More.

## Catalog tabs (Reciters, Athkar categories, etc.)

**Encouraged:**

- Search, filter, favorites toggle
- FAB for create actions (e.g. tasbeeh)
- Illustrated empty/error states

**Allowed with care:**

- Product tours after tab mount (calm entry), not mid-flow

## Settings & About

**Encouraged:**

- Theme, language, prayer calculation, notifications
- Support Tilawa entry (per `specs/016-support-tilawa/spec.md`)
- Data management, legal, version

## Monetization (Support Tilawa)

| Allowed | Forbidden |
|---------|-----------|
| Settings, About, Profile | Reader, prayer, athkar, onboarding |
| Calm single CTA, transparent footer | Gold pay chrome, "benefits unlocked" |

See `packages/ui_kit/docs/support_visual_system.md`.
