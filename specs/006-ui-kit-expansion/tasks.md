# Tasks: UI Kit Expansion (Phase 2D)

## Completed Tasks

- [x] Define low-flakiness Phase 2D scope under `packages/ui_kit`
- [x] Update active preview files only:
  - [x] `packages/ui_kit/lib/atoms_preview.dart`
  - [x] `packages/ui_kit/lib/molecules_preview.dart`
- [x] Extend atom goldens:
  - [x] `TilawaSectionTitle`
  - [x] `TilawaSheetHandle`
- [x] Extend molecule goldens:
  - [x] `TilawaChip`
  - [x] `TilawaIconActionButton`
  - [x] `TilawaSearchField`
  - [x] `TilawaSettingsTile`
  - [x] `TilawaSettingsSwitchTile`
  - [x] `TilawaStatusChip` dark scenario
- [x] Regenerate CI + macOS baseline PNGs for new/updated scenarios
- [x] Verify no golden failure artifacts are tracked
- [x] Run validation:
  - [x] `flutter analyze`
  - [x] `flutter test test/goldens/`
  - [x] `flutter test`

## Deferred Tasks

- [ ] `TilawaLoadingIndicator` golden coverage (deferred)
- [ ] `ArabicAlphabetScrollbar` golden coverage (deferred)
- [ ] Organism golden expansion (deferred)
- [ ] App adoption tasks (deferred)
