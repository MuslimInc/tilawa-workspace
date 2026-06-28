---
name: tilawa-apply-ui-principles
description: >-
  Apply Tilawa visual UI composition principles when building or refactoring
  screens — hierarchy, section structure, elevation discipline, component
  selection, Arabic typography, and brand-aligned layout. Use when implementing
  home dashboard sections, cards, grids, sheets, catalog screens, or any
  widgets in apps/tilawa and packages/ui_kit. Pair with
  flutter-apply-tilawa-theming for tokens and tilawa-apply-ux-principles for
  flows.
---

# Tilawa UI Principles

Apply when **composing widgets on screen** — hierarchy, spacing rhythm, which
kit component to use, and how surfaces relate.

## Canonical references

1. [`DESIGN.md`](../../../DESIGN.md) — tokens, components, catalog chrome
2. [`docs/tilawa_brand.md`](../../../docs/tilawa_brand.md) — reverent / scholarly / welcoming
3. [`packages/ui_kit/docs/design_system.md`](../../../packages/ui_kit/docs/design_system.md) — agent contracts

**Tokens & colors:** use skill `flutter-apply-tilawa-theming` — this skill does
not duplicate token tables.

**Layout breakpoints:** use skill `flutter-build-responsive-layout`.

## How to use

**Build mode:** Pick components from the tables below; run
[UI checklist](references/ui-checklist.md) before handoff.

**Review mode:** Walk checklist; cite widget/file evidence.

## Visual hierarchy (top → bottom)

On a typical screen, eye path should be:

1. **Context** — where am I? (`TilawaCatalogAppBar`, hero, section title)
2. **Primary content** — the artifact (ayah, category grid, list)
3. **Supporting metadata** — `onSurfaceVariant`, `bodySmall`
4. **Actions** — one primary CTA; others secondary

On **Home:** preserve approved layout — see
[home-dashboard-patterns.md](references/home-dashboard-patterns.md).

## One accent per screen

- **One** `ColorScheme.primary` emphasis lane per viewport (CTA, active nav, key progress)
- Catalog chrome stays **neutral** — search/chips/app bar not primary-tinted
- **Gilding** (`tertiary`) — ceremonial only, never buttons (brand doc §3)
- **Scholar** (`secondary`) — metadata chips, not co-primary CTAs

## Elevation & surfaces

| Surface role | Treatment |
|--------------|-----------|
| Page / list background | `scaffoldCanvasColor` / `surface` |
| Raised card | `TilawaCard` + `TilawaCardSurface.raised` |
| Catalog list tile | flat + hairline (`outlineVariant`) — see ReciterCard pattern |
| Floating chrome | player bar, bottom nav — shadow tokens only here |
| Mushaf reader frame | **only** full layered shadow on content artifact |

**Do not** add box shadows to every Home shortcut tile — match existing
`_QuickActionTile` / `AthkarCategoryCard` patterns.

Radius: use `tokens.resolveRadius(family: ..., height: ...)` — see brand doc §5.

## Component selection

| Need | Prefer |
|------|--------|
| Tappable list row / shortcut | `TilawaCard` with `onTap` |
| Section header | `TilawaSectionTitle` — **title only** (`title`, `color`, `fontWeight`) |
| Section header + edit | `Row`: `Expanded(TilawaSectionTitle(...))` + `TilawaIconActionButton` |
| Primary action | `TilawaButton` |
| Icon action in app bar | `TilawaIconActionButton` |
| Catalog screen chrome | `TilawaCatalogAppBar` + `TilawaSearchField` (catalog variant) |
| Empty / error | `TilawaIllustratedState`, `TilawaEmptyState` |
| Loading | `TilawaLoadingIndicator` |
| Bottom sheet | `TilawaBottomSheetScaffold`, `showTilawaModalBottomSheet` |
| Filter chips | `TilawaSelectionPillStyle.catalog` |
| Category / catalog grid | `TilawaContentGrid` |
| FAB (create action) | `TilawaPrimaryFab` + `TilawaFabLocation.placement` |
| Horizontal shortcuts | `Wrap` or horizontal `ListView` with token gaps — cap visible items |

Before inventing a widget, grep `packages/ui_kit` and sibling features.

## Section composition pattern

`TilawaSectionTitle` does not accept a trailing action. Compose edit/customize
like `PinnedAthkarHomeSection`:

```dart
Row(
  children: [
    Expanded(
      child: TilawaSectionTitle(title: context.l10n.sectionTitle),
    ),
    TilawaIconActionButton(
      icon: Icons.edit_outlined,
      tooltip: context.l10n.sectionEdit,
      onPressed: onEdit,
    ),
  ],
)
```

Then content below with token spacing:

```dart
SizedBox(height: tokens.spaceSmall),
// grid, horizontal list, or card
SizedBox(height: tokens.spaceLarge),
```

Spacing: 8-point grid via `tokens.space*`; use Flex `spacing:` when all gaps
are equal (see `flutter-apply-tilawa-theming`).

## Grids & shortcuts

**Home:** Section surfaces and nav rules — see
[home-dashboard-patterns.md](references/home-dashboard-patterns.md).

**Pinned shortcuts** (athkar, favorites on other screens):

- Prefer **2-column compact grid** or **horizontal scroll** when ≤4 items
- Show category icon + localized title
- Optional progress badge only if data exists — no fake progress

**Catalog grids:** `TilawaContentGrid` on category screens (Athkar, etc.)

## FAB and player overlap

Screens with a FAB above the shell must offset for bottom nav + mini-player:

```dart
final fabBottomOffset =
    QuranPlayerWidget.fabBottomOffset(context) + tokens.spaceLarge;
// TilawaFabLocation.placement(..., bottomOffset: fabBottomOffset)
```

See `athkar_categories_screen.dart`. List padding must clear FAB height.

## Typography on screen

| Element | Role |
|---------|------|
| Screen title | `titleLarge` / `titleMedium`, w700 |
| Card title | `titleSmall`, w800 (Home quick tiles) |
| Body | `bodyMedium` / `titleMedium` for quoted Arabic |
| Metadata | `bodySmall`, `onSurfaceVariant` |
| Arabic names | `textHeightLoose` from tokens |

No raw `fontSize:` in features.

## TilawaCard interactive children

When a nested control has a **different** action than the card tap, use
**sibling `Row`** pattern (see `CLAUDE.md`):

- BookmarkCard, HistoryCard, PlaylistCard, Tasbeeh history delete

## Responsive layout

- Branch on `context.windowSize` / `TilawaWindowSize`, not raw phone/tablet flags
- Cap wide content: `TilawaContentBounds` + kind (`form`, `reader`, `settings`)
- Home content sheet: full width with horizontal padding `tokens.spaceMedium`

## Motion

- Toggles / snaps: `tokens.durationFast`, `Curves.easeOutCubic`
- Hero snap on Home: existing `home_screen.dart` pattern — do not add competing scroll physics

## Anti-patterns

- Rainbow category colors per athkar type
- Gradient backgrounds on every card
- `displayLarge` headlines on utility screens
- Magic pixel padding (`13`, `27`)
- Second primary button beside the main CTA
- Shadow on list tiles inside an already-raised sheet
- **Unapproved Home redesign** — see home-dashboard-patterns.md

## Verification

```sh
cd apps/tilawa && dart analyze
flutter test test/features/<feature>/
```

Visual: light + dark theme, text scale 1.4, RTL Arabic.

## Additional resources

- [references/ui-checklist.md](references/ui-checklist.md)
- [references/home-dashboard-patterns.md](references/home-dashboard-patterns.md)
