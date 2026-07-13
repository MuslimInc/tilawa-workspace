# Plan: Ergonomic Mobile UX — Reachability Batch

**Feature Branch**: `feature/ui-kit-2`
**Created**: 2026-05-20
**Status**: Complete
**Scope**: FR-003, FR-004, FR-005, FR-001. See [spec.md](spec.md).

## Completed in this batch

### FR-004 — compact mini-player keeps "next" (F-002)

`_TransportControls` now always renders the next-track button. Compact layout
collapses only previous and sleep timer; play/pause and next remain visible.
Goldens updated for the narrow compact scenario.

### FR-003 — bar tap limited to artwork + metadata (F-001)

The open-player `GestureDetector` now wraps only the artwork + title strip via
`_OpenPlayerTapTarget`. Transport controls sit outside the detector so
play/pause/next taps never also fire `onTap`. Widget tests cover both paths.

### FR-005 — sheet drag-to-dismiss (F-003)

`TilawaSheetHandle` expands to a 48 dp-tall hit strip and dismisses the modal
route on a downward fling (`playerDismissVelocityThreshold`). Used by default
from `TilawaBottomSheetScaffold`. Optional `onDismiss` override for tests.

### FR-001 — self-sized 48 dp switch (F-004)

New `TilawaSwitch` atom guarantees `kMeMuslimMinInteractiveDimension` on both
axes. `TilawaSettingsSwitchTile` now composes it; Maestro identifier surface
unchanged (no new semantics identifiers on the tile).

## Verification gates

All passed:

1. `dart analyze` in `packages/ui_kit`
2. `flutter test` in `packages/ui_kit` (359 tests)
3. Goldens updated for sheet handle hit strip and compact mini-player

## Optional follow-up (F-005)

Adjacent motion drift in `alphabet_scrollbar.dart` and segmented-control
`transitionDuration` token — out of scope for this spec batch.
