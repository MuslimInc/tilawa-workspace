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
- Phase 2D implementation: committed (73ccebf)
- Spec folder renamed from 002 to 006: committed (bfc8e2c)
- Phase 2E implementation: complete, pending commit approval
- Analyze: passed
- Golden tests: 42/42
- Full UI Kit tests: 243/243
- Scope compliance: passed
- Commit status: not committed yet

---

# Phase 2E Scope

## Overview

Phase 2E completes golden coverage for the remaining static, zero-risk molecules and organisms deferred from Phase 2D. All components are fully stateless with no animation, no overlay, no gesture complexity, and no MediaQuery dependency.

## Export Fix

`packages/ui_kit/lib/src/molecules/molecules.dart`: Added missing `export 'tilawa_permission_banner.dart';`. `TilawaPermissionBanner` already existed in the codebase but was not exported from the public molecule barrel. Pre-existing gap fix only — not a production logic change.

## Components Covered in Phase 2E

1. `TilawaFeedbackStrip` — stateless, icon + text message, theme-driven colors
2. `TilawaPermissionBanner` — stateless inline banner, no permission system dependency
3. `TilawaSettingsGroup` — stateless organism wrapper around known-covered tiles
4. `LanguageSwitcher` — stateless segmented control; verified fully static (Row hardcodes `TextDirection.ltr` — RTL scenario intentionally excluded)

## Golden Matrix

| Component | Scenarios | File |
|---|---|---|
| TilawaFeedbackStrip | Default, Dark, RTL Arabic | tilawa_feedback_strip.png |
| TilawaPermissionBanner | Default, Dark | tilawa_permission_banner.png |
| LanguageSwitcher | English selected, Arabic selected | tilawa_language_switcher.png |
| TilawaSettingsGroup | Default (2 tiles), Dark | tilawa_settings_group.png |

## New Baseline PNGs (8 files)

- ci/tilawa_feedback_strip.png, macos/tilawa_feedback_strip.png
- ci/tilawa_permission_banner.png, macos/tilawa_permission_banner.png
- ci/tilawa_language_switcher.png, macos/tilawa_language_switcher.png
- ci/tilawa_settings_group.png, macos/tilawa_settings_group.png

No existing baselines were modified.

## New File

`packages/ui_kit/test/goldens/organisms_goldens_test.dart` — first organism-level golden test file.

## Verification Evidence

- `flutter analyze`: No issues found
- `flutter test test/goldens/`: 42/42 passed (+8 new)
- `flutter test`: 243/243 passed (+8 new)

## Not Changed in Phase 2E

AppTheme, AppColors, design tokens, production component logic, app screens, TilawaLoadingIndicator, ArabicAlphabetScrollbar, TilawaAdaptiveShell, TilawaMediaPlayerBar, SeekBar, TilawaCountProgressRing.

## Deferred to Phase 2F

TilawaLoadingIndicator, TilawaCountProgressRing, SeekBar, MetadataChip, SelectionPill, TilawaIconToggle (preview needed first), TilawaAdaptiveShell (3-viewport strategy), TilawaMediaPlayerBar (viewport + MediaQuery setup), ArabicAlphabetScrollbar (behavior tests sufficient), TilawaBackdropImageLayer (async image + blur churn), ImmersiveComposerScaffold (AnimationController + blur).
