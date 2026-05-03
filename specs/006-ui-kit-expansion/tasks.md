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

---

# Phase 2E Tasks

## Completed Tasks

- [x] Fix missing `TilawaPermissionBanner` export in `packages/ui_kit/lib/src/molecules/molecules.dart`
- [x] Add preview variants to `packages/ui_kit/lib/molecules_preview.dart`:
  - [x] `TilawaFeedbackStrip` (dark, RTL Arabic)
  - [x] `TilawaPermissionBanner` (default, dark)
  - [x] `LanguageSwitcher` (Arabic selected)
- [x] Add preview variant to `packages/ui_kit/lib/organisms_preview.dart`:
  - [x] `TilawaSettingsGroup` (dark)
- [x] Add golden groups to `packages/ui_kit/test/goldens/molecules_goldens_test.dart`:
  - [x] `TilawaFeedbackStrip` (Default, Dark, RTL Arabic)
  - [x] `TilawaPermissionBanner` (Default, Dark)
  - [x] `LanguageSwitcher` (English selected, Arabic selected)
- [x] Create `packages/ui_kit/test/goldens/organisms_goldens_test.dart`:
  - [x] `TilawaSettingsGroup` (Default, Dark)
- [x] Regenerate CI + macOS baseline PNGs (8 new files)
- [x] Run validation:
  - [x] `flutter analyze` → No issues found
  - [x] `flutter test test/goldens/` → 42/42 passed
  - [x] `flutter test` → 243/243 passed

## Phase 2F Completed Tasks

- [x] Cover static-only Phase 2F batch components:
  - [x] `MetadataChip`
  - [x] `SelectionPill`
  - [x] `TilawaIconToggle`
- [x] Add/update previews:
  - [x] `packages/ui_kit/lib/atoms_preview.dart` (`TilawaIconToggle`: off, on, dark on)
  - [x] `packages/ui_kit/lib/molecules_preview.dart` (`MetadataChip` dark, `SelectionPill` dark)
- [x] Add golden scenarios:
  - [x] `MetadataChip`: default icon + label, label only, dark
  - [x] `SelectionPill`: selected, unselected with icon, dark selected
  - [x] `TilawaIconToggle`: off, on, dark on
- [x] Validation:
  - [x] `flutter analyze` passed
  - [x] `flutter test test/goldens/` passed: 48/48
  - [x] `flutter test` passed: 249/249

## Deferred Beyond Phase 2F

- [ ] `TilawaLoadingIndicator`
- [ ] `TilawaCountProgressRing`
- [ ] `SeekBar`
- [ ] `ArabicAlphabetScrollbar`
- [ ] `TilawaAdaptiveShell`
- [ ] `TilawaMediaPlayerBar`
- [ ] `TilawaBackdropImageLayer`
- [ ] `ImmersiveComposerScaffold`
