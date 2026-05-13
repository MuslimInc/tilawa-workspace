# Changelog

## Unreleased

### Breaking

- None.

### Deprecated

- `LanguageSwitcher` typedef (use `TilawaLanguageSwitcher`).
- `SelectionPill` typedef (use `TilawaSelectionPill`).
- `MetadataChip` typedef (use `TilawaMetadataChip`).

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
- `TilawaButton` — label row no longer uses `LayoutBuilder` so Alchemist intrinsics stay valid.
