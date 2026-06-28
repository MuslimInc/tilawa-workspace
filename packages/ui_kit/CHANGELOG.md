# Changelog

## Unreleased

### Breaking

- Removed `TilawaPressAnimation`, `TilawaInteractionFeedback.pressScaleEnd`, and `TilawaInteractiveSurface.enablePressAnimation`. Pressed feedback is soft Material ink plus state-layer washes (no press-scale).

### Deprecated

- `LanguageSwitcher` typedef (use `TilawaLanguageSwitcher`).
- `SelectionPill` typedef (use `TilawaSelectionPill`).
- `MetadataChip` typedef (use `TilawaMetadataChip`).

### Changed

- `TilawaInteractiveSurface` — soft Material ink (`inkSplashAlpha` / `inkHighlightAlpha`) plus stable state-layer washes (`stateLayerPressed` / `stateLayerHover` / `stateLayerFocused`). Optional `materialColor` / `materialShape` host ink on opaque fills (e.g. cards).
- `TilawaCard` / `TilawaButton` — cards use ink + state layers; buttons use Material overlay states.
- `TilawaIllustratedState` — primary action precedes secondary in reading order; default screen-reader label composed from title + subtitle when `semanticLabel` is omitted.
- `TilawaSelectionTile` — selected checkmark uses `primary` for clearer hierarchy; row enforces `minInteractiveDimension`.
- `TilawaSegmentedControl` — selected segment paints tokenized elevation shadow (visual feedback).
- `TilawaSettingsTile` / `TilawaSettingsSwitchTile` / `TilawaNavigationRow` — shared `TilawaSettingsListRow` routes list rows through `TilawaInteractiveSurface` (state-layer press, focus ring, haptics) instead of `ListTile` ink.
- `TilawaButton` — non–full-width labels now ellipsize in constrained parents via `Flexible(fit: FlexFit.loose)`; `isFullWidth` behavior unchanged.
- `TilawaSearchFieldTokens` — hint text uses a slightly higher alpha on `onSurfaceVariant` for readability.
- `TilawaMediaPlayerBarTokens` — compact density tightens padding, radii, and artwork while keeping transport controls at ≥48dp.

### Fixed

- `TilawaPermissionBanner` — Material 3 minimum touch target for the action control.
- `SeekBar` — tokenized ≥48dp touch strip for scrubbing affordance.
- `TilawaMediaPlayerBar` — ≥48dp transport control sizing from component tokens.
- `TilawaIconToggle` — enforced ≥48×48dp hit target independent of `iconSize`.
- `TilawaLanguageSwitcher` — segment `Semantics` (`button` + `selected`) co-located with taps.
- `TilawaSegmentedControl` — segment roles applied inside `InkWell` for stable semantics.
- `TilawaSelectionTile` — `Semantics(selected:)` on the row without fragile merge wrappers.
- `TilawaChip` — explicit labeled `Semantics(button:)` without `MergeSemantics` pitfalls.
- `TilawaIconActionButton` — explicit semantic name for icon-only actions.
- `TilawaFeedbackStrip` — structured `TilawaFeedbackVariant` default border colors.
- `TilawaFeedbackStrip` — `Semantics(liveRegion:)` for transient status messaging.
- `TilawaErrorState` — disabled retry + `CircularProgressIndicator` while `isRetrying`.
- `TilawaSearchField` — scroll inset from `TilawaSearchFieldTokens.scrollPadding`.
- `TilawaSettingsTile` — list/divider spacing aligned to the design-token 8dp grid.
- `TilawaModalBottomSheet` — barrier dismiss + optional sheet title semantics parity.
- `TilawaShareFooterBar` — ambient `Directionality` instead of hard-coded RTL layout.
- `TilawaShareFooterBar` — typography roles taken from `TextTheme` for hierarchy.
- `TilawaSeekBarTokens` — default `touchExtent` meets the ≥48dp interaction strip.
- Settings-style list tokens — `itemExtent` floor for ≥48dp row hit targets.
- `TilawaDesignTokens` — compact spacing/icon steps snapped to the 8dp rhythm.
- `TilawaFeedbackStripTokens` — padding values aligned to the 8dp grid.
- `TilawaPermissionBannerTokens` — spacing values aligned to the 8dp grid.
- Settings tiles tokens — tile gaps/padding expressed on the 8dp grid.
- `TilawaCardTokens` — compact card corner radius aligned to an 8dp grid multiple.
- `TilawaSettingsGroupTokens` — `groupHeaderPadding` and `tileDividerPadding` use directional insets so RTL mirrors LTR layout; settings rows enforce a 48dp minimum height where the list row allows it.
- `TilawaSettingsTile` — trailing chevron remains right-pointing; `ListTile` trailing alignment handles RTL.
- `TilawaSettingsGroup` — group panel spans full cross-axis width in narrow parents.
- `TilawaSectionHeader` — section title and subtitle use `TextAlign.start` for correct RTL alignment.
- `TilawaChip` / `TilawaSelectionPill` — optional `Semantics.selected` for pills via `semanticsSelected`.
- `TilawaErrorState` — retry progress indicator size follows design token `iconSizeLarge`.
- `TilawaSearchField` — optional `errorText` / `errorStyle` with error border and vertical growth for validation copy.
- `TilawaMediaPlayerBar` — `contentPadding` resolved with ambient `Directionality`; transport `IconButton`s expose tooltips for a11y.
