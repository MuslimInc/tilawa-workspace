# Tilawa Premium Visual System

This document defines the rules for keeping Tilawa visually calm, modern, and
premium while still allowing emotional and editorial moments where they earn
their place.

> Last revised 2026-05-15 alongside
> [`specs/012-visual-simplification/`](../../../specs/012-visual-simplification/spec.md).

## Principles

1. **Content > chrome.** Quran text, prayer time, athkar text, and reciter
   names are the focal elements. Surrounding chrome must recede.
2. **One accent per screen.** The user-selected brand primary is the only
   chromatic accent in product UI. Decorative parallel hues (Settings used to
   have eleven; gone now) compete with content and are forbidden.
3. **Calm by default.** Surfaces are solid colours with hairline outlines and
   at most a soft drop shadow. No double-stacked depth (gradient + tinted
   border + shadow).
4. **Decoration must justify itself.** No "decorative circles" or oversized
   background icons. Geometry belongs in empty states, onboarding, or
   product-distinct moments — not in routine list rows.
5. **Quran reading stays restrained.** No competing imagery, no patterned
   underlays. The Mushaf page is the only visual that earns attention.
6. **Derive from theme.** Colours come from `ColorScheme`, spacing from
   `TilawaDesignTokens`, component fills from `TilawaComponentTokens`. No
   hard-coded hex, radii, or shadows in reusable UI Kit widgets.

## Hit targets

The Tilawa hit-target floor is **44 dp**, exposed as
`TilawaDesignTokens.minInteractiveDimension` (and `context.minInteractiveDimension`).

Use this instead of Flutter's `kMinInteractiveDimension` (which is the Material
48 dp default) for *all* in-product hit targets: cards, list rows, icon
buttons, chips, settings tiles, search-field heights, player controls,
location pickers, etc.

| Floor | Source | Where used |
| ----- | ------ | ---------- |
| **44 dp** | `TilawaDesignTokens.minInteractiveDimension` | Tilawa default. Matches iOS HIG; denser, more premium than Material's 48 dp without dropping below iOS accessibility. |
| 48 dp | `kMinInteractiveDimension` (Flutter) | Do **not** use in product code. Material default; only acceptable in third-party widgets we can't override. |

## Cards and surfaces

`TilawaCard` exposes a `surface:` enum that captures the three legitimate
treatments:

| `TilawaCardSurface` | Fill | Outline | Shadow | When to use |
| ------------------- | ---- | ------- | ------ | ----------- |
| `raised` (default) | `surface` | hairline `outlineVariant` | soft drop | Top-level card on a scaffold background. |
| `flat` | `surface` | hairline `outlineVariant` | none | Cards nested inside an already-elevated container (e.g. settings group rows). |
| `outline` | transparent | hairline `outlineVariant` | none | Cards that should recede into the parent background. Use sparingly. |

The legacy `gradient:` and `flat:` parameters remain only as `@Deprecated`
migration helpers; do not use them in new code.

## Gradients

Gradients are *not* part of the product visual system. They are reserved for:

1. **The colour-picker tool** (`features/color_picker/`) — gradient *is* the
   tool.
2. **Share / reel composer output**
   (`features/share/presentation/widgets/page_passage_card_renderer.dart`,
   `share_audio_config_sheet.dart`) — generated poster artwork, not chrome.
3. **`CustomPainter` shaders** — e.g. the Qibla compass needle.
4. **Focused state badges in molecules** (`tilawa_count_progress_ring`) —
   narrow, indicator-only use.
5. **Preview dev tools** (`atoms_preview.dart`, `organisms_preview.dart`) —
   non-production.

Everywhere else, use solid surfaces.

## Illustrated states

Use this style for empty states, permission states, onboarding, and store
screenshots:

- Mature editorial vector artwork, not cartoons.
- Low detail, generous whitespace, soft contrast.
- Palette derived from active theme: primary, surface, surfaceContainer,
  outlineVariant. Optional muted gold accents for Quran / prayer emphasis.
- No stock photos inside the app shell.
- No decorative Quranic text unless reviewed and intentionally placed.
- No mascots, childish faces, exaggerated characters, or playful scenes.

## Where visuals belong

Good candidates:

- Downloads empty state.
- Reciters search empty, favourites empty, first-load states.
- Qibla permission, calibration, sensor error states.
- Prayer location-required state.
- Athkar category and tasbeeh history empty states.
- Onboarding pages.
- Google Play screenshots.

Avoid visuals:

- Inside the active Quran page.
- Inside dense prayer time cards.
- In every reciter list row.
- Inside Settings groups (except account / profile identity).
- Anywhere visuals compete with prayer accuracy, Quran readability, or adhan
  controls.

## UI Kit vs feature scope

Add to UI Kit when the visual contract is reusable:

- Generic illustrated-state layouts.
- Generic non-figurative state visuals.
- Decorative pattern layers.
- Shared skeleton / state layouts.
- Tokenised surface, spacing, motion, and sizing rules.

Keep feature-specific:

- Exact illustration asset choices.
- Screen-specific copy.
- Permission / request behaviour.
- Analytics, routing, repositories, and BLoC state.
- Any asset that only makes sense for one feature.

## Current foundation

`TilawaIllustratedState` is the baseline component for premium state moments.
It provides a token-backed layout with a custom visual slot, optional icon
fallback, title, subtitle, and up to two actions. Feature screens should
compose their own assets into this component instead of creating one-off
state layouts.

`TilawaStateVisual` is the default icon fallback for `TilawaIllustratedState`.
It uses a soft geometric field, centred symbolic icon, and theme-derived
colour roles. Use it when a state benefits from warmth but does not need a
bespoke asset.

Prefer the default visual for:

- Downloads empty and retry states.
- Reciters search / favourites empty states.
- Qibla service, permission, and sensor error states.
- Prayer location-required states.
- Athkar and tasbeeh empty states.

Use bespoke visual assets only when the state has enough product value to
justify a reviewed, feature-owned asset.
