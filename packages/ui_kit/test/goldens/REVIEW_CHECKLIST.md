# Golden PNG review checklist (`refactor/ui` / accessibility audit)

Human reviewers should open the updated images under
`test/goldens/goldens/macos/` (or your CI variant folder) and confirm the
deltas below are **intentional**—not accidental layout regressions.

## Atoms

- **TilawaCard** — spacing/radius may reflect 8dp token tweaks in compact density.
- **TilawaCard compact** — same as card; compact padding/radius on grid.
- **TilawaIconBox** / **TilawaIconBox compact** — minor size/spacing alignment if tokens changed.
- **TilawaIconToggle** — control bounding box wider/taller (48dp minimum hit target).
- **TilawaEmptyState** / **TilawaEmptyState compact** — scenario bounds + any action row with button may show label ellipsis behavior on `TilawaButton`.
- **TilawaLoadingIndicator** — unchanged expectation; confirm no accidental shift.
- **TilawaDivider** — confirm thickness/indent unchanged visually.
- **TilawaSectionTitle** — confirm title/subtitle layout unchanged.
- **TilawaSheetHandle** / **compact** — handle bar on 8dp-related tokens if touched.
- **TilawaErrorState** / **compact** — retry control loading state; spacing on grid.
- **TilawaButton** — non–full-width label now ellipsizes in tight constraints instead of overflowing (inner `Flexible`); **`isFullWidth`** goldens unchanged for row expansion.
- **TilawaTextField variants** / **env** — scroll padding / field chrome from tokens; no overflow.

## Molecules

- **TilawaGlassPanel** / **compact** — padding on 8dp grid if adjusted.
- **TilawaStatusChip** — chip metrics unchanged unless token-driven.
- **TilawaChip** / **compact** — semantics merge removed; tap target and label should still read clearly.
- **TilawaMetadataChip** — same chip family; deprecated typedef name only in code, visuals unchanged.
- **TilawaSelectionPill** / **compact** — pill selection visuals; deprecated typedef in code only.
- **TilawaCountProgressRing** — ring and caption spacing.
- **TilawaIconActionButton** — ≥48dp target and explicit a11y labeling path.
- **TilawaSearchField** / **compact** — scroll inset / padding from `scrollPadding` token.
- **TilawaSettingsTile** / **compact** — list row height / dividers on 8dp grid; **rows may be taller (48dp item extent)** where tokens apply.
- **TilawaFeedbackStrip** / **compact** — optional **variant border** (info/warning/error tint); message has **live region** semantics (no visual text change expected).
- **TilawaPermissionBanner** / **compact** — **trailing CTA** has standard Material tap padding (≥48dp hit height).
- **TilawaLanguageSwitcher** (golden file `tilawa_language_switcher`) — segment **Semantics** placement; segment min widths unchanged unless tokenized.
- **TilawaSegmentedControl** / **compact** — segment roles inside ink; touch areas unchanged unless adjusted.
- **TilawaSelectionTile** / **compact** — selected row semantics; selection background unchanged visually.

## Organisms

- **TilawaMediaPlayerBar** — **previous / next / play–pause** (and sleep if shown) have **more surrounding space** (≥48dp control sizes from tokens).
- **TilawaSettingsGroup** / **compact** — settings list density; row heights if list tokens apply.
- **TilawaShareFooterBar** / **compact** — RTL-aware layout and text theme roles; spacing should match design tokens.

## Audit-related but **not** covered by this golden suite

Use app previews, integration tests, or manual QA where these appear:

- **SeekBar** — **taller touch strip** (≥48dp `touchExtent` from tokens); no golden image in this folder.
- **ArabicAlphabetScrollbar** — **taller letter rows** when `itemExtent` / scrollbar tokens enforce 48dp; verify scroll and overlay still align.

## Global harness note

- Golden groups use **bounded `scenarioConstraints`** so Alchemist’s table layout stays stable; overall crop width/height of the table image may differ slightly from older unbounded runs.
