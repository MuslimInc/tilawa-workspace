# Tilawa feature placement policy

Consolidated from `DESIGN.md` and product specs. When docs conflict on
*implementation*, trust code + `DESIGN.md`; this file guides *UX placement*.

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

Treat Home as a **daily module stack**, not an app launcher.

**Encouraged:**

- Hero prayer/time context
- Today modules (khatma, today plan, pinned athkar)
- Compact **More** row for non-nav destinations (Reciters, Qibla)
- Daily ayah / dua inspiration cards

**Forbidden on Home:**

- Tiles that duplicate bottom navigation (Home, Prayer, Quran, Athkar, Settings)
- Six-tile "Explore" launcher grids (legacy pattern — removed)
- Cold-start modals or support prompts

**More row rule:** only destinations **not** already in the phone bottom bar.

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
