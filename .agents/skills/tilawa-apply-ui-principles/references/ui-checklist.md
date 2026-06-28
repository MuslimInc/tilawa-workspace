# Tilawa UI composition checklist

## Hierarchy

- [ ] Clear visual anchor (hero, title, or primary card)
- [ ] Primary content distinguishable from metadata (type role + color)
- [ ] ≤1 primary CTA per viewport
- [ ] Section titles use `TilawaSectionTitle` (not raw bold Text)
- [ ] Section edit actions use sibling `Row` + `TilawaIconActionButton` (not a fake trailing on title)

## Tokens & theme

- [ ] No raw hex / magic numbers for spacing (use `tokens.space*`)
- [ ] Colors from `colorScheme` / component tokens — not `AppColors` in features
- [ ] Typography from `textTheme` roles — no ad-hoc `fontSize`
- [ ] Radii via `resolveRadius` or established card patterns

## Surfaces & depth

- [ ] Cards use `TilawaCard` with appropriate `surface`
- [ ] No shadow arms-race on list tiles
- [ ] Floating chrome only on nav/player — not random sections
- [ ] Dividers: hairline or surface-tier change — not heavy borders

## Components

- [ ] Kit component used before custom duplicate
- [ ] Catalog screens use `TilawaCatalogAppBar` pattern
- [ ] Empty/error/loading use kit states
- [ ] `TilawaCard` sibling pattern for conflicting tap targets

## Layout

- [ ] `context.windowSize` or `LayoutBuilder` for adaptive columns
- [ ] Content capped with `TilawaContentBounds` where appropriate
- [ ] Lists use builder constructors for long data
- [ ] No overflow at text scale 1.4

## Brand alignment

- [ ] Feels reverent + calm (not marketing dashboard)
- [ ] One accent color lane per screen
- [ ] No gold/tertiary on interactive CTAs
- [ ] Arabic surfaces use loose line height where needed

## RTL & density

- [ ] Directional alignment/padding
- [ ] Touch targets ≥ 44 dp (`tokens.minInteractiveDimension`)
- [ ] Comfortable density — not compact VisualDensity

## Home-specific (if touching `features/home/`)

- [ ] Preserves approved full stack order (hero → tutor flag → primary actions →
  quick tools → today plan → more → listening → inspiration → closing mark)
- [ ] No Home redesign/reorder without explicit user request
- [ ] No stale widgets wired (`HomePrimaryActionZone`, `HomeDiscoverShortcuts`,
  `HomeDailyPracticeSection`)
- [ ] No Home / Prayer / Settings tiles; no launcher grid mirroring bottom nav
- [ ] Reciters in quick tools selects the existing Reciters tab
- [ ] More list only contains lower-frequency library/setup routes
- [ ] Uses approved section widgets before inventing new ones
- [ ] Spacing follows `spaceLarge` / `spaceExtraLarge` rhythm in body
- [ ] Changes limited to bugs, spacing, overflow, a11y, tokens, RTL unless
  user requested redesign

## FAB / shell chrome (if applicable)

- [ ] FAB `bottomOffset` accounts for `QuranPlayerWidget.fabBottomOffset`
- [ ] List bottom padding clears FAB + player + nav
