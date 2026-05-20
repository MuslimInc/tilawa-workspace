# Plan: Ergonomic Mobile UX — Reachability Batch

**Feature Branch**: `feature/ui-kit-2`
**Created**: 2026-05-20
**Status**: In Progress
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

## Remaining work

**Decision needed**: drag-to-dismiss handle **or** trailing close slot.

Recommended: **drag-to-dismiss on `TilawaSheetHandle`** — handle is already
at the bottom; adding `onVerticalDragEnd` with velocity threshold keeps the
title row clean. Limit drag to the handle only (not scrollable content).

### FR-001 / FR-008 — self-sized 48 dp switch (F-004)

Introduce `TilawaSwitch` atom wrapping `Switch.adaptive` in a fixed 48×48
hit box (same `FittedBox` slot pattern as `TilawaSettingsSwitchTile`). Wire into
settings tile; verify Maestro identifiers unchanged.

## Verification gates

After each sub-task:

1. `dart analyze` in `packages/ui_kit`
2. `flutter test` in `packages/ui_kit`
3. Regenerate goldens only when pixel output changes; eyeball diffs.
