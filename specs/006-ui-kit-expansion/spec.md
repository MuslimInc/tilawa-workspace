# Feature Specification: UI Kit Expansion

**Feature Branch**: `002-ui-kit-expansion`
**Created**: 2026-05-03
**Status**: In Progress

## Phase 2D Scope

Phase 2D is strictly a golden coverage expansion effort.

- Scope location: `packages/ui_kit` only
- Components: existing components only
- Allowed changes: previews + goldens
- Not included: app adoption
- Not included: `AppTheme` / `AppColors` / design token changes
- Not included: production component logic changes
- Not included: new components

## Components Covered In Phase 2D

Approved and implemented batch:

1. `TilawaSectionTitle`
2. `TilawaSheetHandle`
3. `TilawaChip`
4. `TilawaIconActionButton`
5. `TilawaSearchField`
6. `TilawaSettingsTile`
7. `TilawaSettingsSwitchTile`
8. `TilawaStatusChip` dark coverage completion

## Preview Source Of Truth

Phase 2D updated active preview files:

- `packages/ui_kit/lib/atoms_preview.dart`
- `packages/ui_kit/lib/molecules_preview.dart`

Phase 2D intentionally did not update duplicate/legacy preview files under `packages/ui_kit/lib/previews/` to avoid preview churn.

## Golden Baseline Changes

- Added new representative golden scenarios for selected components above.
- Added new baseline PNGs for both CI and macOS variants:
  - `tilawa_section_title.png`
  - `tilawa_sheet_handle.png`
  - `tilawa_chip.png`
  - `tilawa_icon_action_button.png`
  - `tilawa_search_field.png`
  - `tilawa_settings_tile.png`
- Updated existing baseline:
  - `tilawa_status_chip.png` (CI + macOS)

Golden failure artifacts are generated outputs and must not be committed.

## Verification Evidence

Commands executed from `packages/ui_kit`:

1. `flutter analyze`
2. `flutter test test/goldens/`
3. `flutter test`

Results:

- Analyze: passed
- Golden tests: passed
- Full UI Kit tests: passed
- Pub advisory decode warnings occurred during dependency resolution and were non-fatal.

## Deferred Items

Deferred from Phase 2D by design:

- `TilawaLoadingIndicator` (animation stability risk)
- `ArabicAlphabetScrollbar` (interactive/layout churn)
- Organism coverage (`TilawaAdaptiveShell`, `TilawaMediaPlayerBar`, and similar)
- App adoption tasks
- New components
- Token/theme refactors

## Final Status

- Phase 2D implementation: completed pending review
- Analyze: passed
- Golden tests: passed
- Full UI Kit tests: passed
- Scope compliance: passed
- Commit status: not committed yet
