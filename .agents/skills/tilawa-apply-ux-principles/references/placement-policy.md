# Tilawa feature placement policy

Consolidated from `DESIGN.md` and product specs. When docs conflict on
*implementation*, trust **code** and the Home canonical docs below.

**Home canonical references:**

- Technical: [home-dashboard-patterns.md](../../tilawa-apply-ui-principles/references/home-dashboard-patterns.md)
- Design: [home_screen_design_artifacts.md](../../../docs/design/home_screen_design_artifacts.md)

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

Preserve the **approved** layout (see Home canonical references above).

**Encouraged:** prayer hero, optional tutor pin, primary worship tiles, compact
tools row, today plan, More list, conditional listening resume, daily
inspiration, quiet closing mark.

**Forbidden:** unapproved redesign/reorder; stale widgets from superseded docs;
Home/Prayer/Settings tiles; launcher grids mirroring bottom nav; cold-start
modals on entry.

**Reciters exception:** quick-tools shortcut selects the existing Reciters tab.

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
