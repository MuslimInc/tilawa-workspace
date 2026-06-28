# Home Screen Design Artifacts

**Status:** Approved design / product reference  
**Last verified:** 2026-06-28  
**Technical reference (widgets, order, pin policy):**
[home-dashboard-patterns.md](../../.agents/skills/tilawa-apply-ui-principles/references/home-dashboard-patterns.md)  
**Code:** `apps/tilawa/lib/features/home/presentation/`

Do **not** duplicate stack order or widget names here — use the patterns file
for implementation. This document captures **design intent** and **UX direction**.

---

## Design intent

Home is a **calm daily dashboard**, not an app launcher. It should feel:

- **Polished** — intentional hierarchy, no visual noise or “dashboard of tiles”
- **Calm** — few choices per viewport; secondary surfaces recede (`compact`
  section titles for More)
- **Reverent** — worship context in the hero; gold accent used sparingly on
  primary Mushaf/Athkar tiles only
- **RTL-first** — directional layout, Arabic typography where content is Arabic
- **Professional** — token-driven spacing and surfaces; no ad-hoc hex or magic
  numbers

The approved layout is **fixed**. Agents and contributors preserve it unless
the user explicitly requests a Home redesign. Permitted improvements without
redesign approval: bugs, spacing, overflow, accessibility, token consistency,
RTL layout.

---

## Visual hierarchy (eye path)

1. **Now** — prayer/time context in the hero (and optional pinned tutor promo
   when Quran Sessions is enabled)
2. **Daily entry** — two featured primary tiles (Mushaf + Athkar), equal weight
3. **Supporting tools** — lighter compact row (Reciters, Qibla, Tasbeeh)
4. **Personal / library** — optional today plan, then flat More list
5. **Resume** — conditional continue-listening row (neutral, not gold)
6. **Reflection** — daily ayah + dua in one restrained card
7. **Closure** — quiet watermark at scroll end (peak-end rule)

Primary tiles use **hero radius** and elevated surfaces. Quick tools use
**decorative radius** and lighter treatment. More uses a **flat grouped list**
with hairline dividers.

---

## UX principles on Home

| Principle | On Home |
|-----------|---------|
| Content-first | Hero owns prayer context; no duplicate prayer strip in body |
| Calm density | No multi-column shortcut grid mirroring bottom nav |
| Progressive disclosure | Deferred sections after first frame for startup perf |
| One accent lane | Gold on primary pair only; listening/inspiration stay neutral |
| Respectful placement | No support prompts or cold-start modals on Home entry |

**Navigation:** Shell covers Home, Quran (push), Reciters, Settings. Mushaf and
Athkar tiles are worship entry points, not tab duplicates. Reciters in quick
tools is an approved exception (selects existing tab).

**Not on Home:** stale patterns from older docs (`HomePrimaryActionZone`,
`HomeDiscoverShortcuts`, `HomeDailyPracticeSection`, etc.) — see patterns file.

---

## Canvas & theming

- Background: gradient canvas (`HomeScreenBackground`) + neutral content sheet
  (`surfaceContainerLow`)
- Horizontal inset: `TilawaHomeScreenTokens.screenHorizontalPadding`
- Bottom inset: `TilawaShellPadding` (clears shell + mini-player)
- Tokens: `context.tokens`, `theme.componentTokens.homeScreen`
- Sections: `HomeDashboardSection` / `TilawaSectionTitle`
- Cards: `HomeDashboardCard`, `HomeDashboardElevatedSurface`
- Hero accent: `homePrayerHeroAccent` on primary/tool icon treatments

---

## Motion & interaction

- Hero snap at 35% collapse extent (`home_screen.dart`)
- Pull-to-refresh reloads dashboard + listening resume state
- Shell tab reselect: scroll to top or refresh
- Inspiration section: subtle entrance animation; must not dominate first screen

---

## Verification

Widget tests under `apps/tilawa/test/features/home/presentation/`. When Home
UI changes (with user approval), update **both** this file and
`home-dashboard-patterns.md`, plus affected tests.

---

## Superseded (historical only)

Do not implement from: `docs/product/home_screen_redesign.md`,
`docs/adr/ADR-home-screen-information-architecture.md`,
`docs/plans/home_screen_redesign_plan.md`,
`docs/migrations/home_screen_redesign_migration.md`,
`docs/specs/home_screen_acceptance_criteria.md`.
