# Feature Specification: Ergonomic Mobile UX

**Feature Branch**: `feature/ui-kit-2`
**Created**: 2026-05-20
**Status**: Draft
**Input**: Audit of `packages/ui_kit/` for thumb-zone reachability and tap-target / hit-slop compliance. Goal: close the remaining ergonomic gaps in the production kit before more screens migrate onto it.

## Intent

The kit is already disciplined on the 48 dp hit-target floor: `kTilawaMinInteractiveDimension` is wired into `TilawaButton`, `TilawaChip`, `TilawaSelectionPill`, `TilawaSettingsTile`, `TilawaSearchField`, `TilawaIconActionButton`, the media-player transport tokens, and the seek bar's touch strip. Most controls route through Material widgets (`IconButton`, `ListTile`, `InkWell`, `Tooltip`, `Switch.adaptive`) so they pick up Material's hit-slop, ripple, and accessibility scaffolding for free.

The remaining ergonomic gaps are subtler:

- A handful of components rely on their *parent* to provide the 48 dp floor and lose it when used out of context.
- A few interactive surfaces compete with each other (whole-bar tap wrappers around `IconButton`s, sheet handles that look draggable but don't dismiss).
- High-frequency actions (skip surah, dismiss sheet, reach "more options" on the player) are still pinned to the top corners or hidden behind compact-mode collapsing, forcing the user out of the thumb zone for routine taps.
- Doc-comment drift suggests "44 dp" in a couple of places while the kit actually targets 48 dp — small, but it confuses future contributors.

This spec captures the ergonomic floor we want every kit component to meet, then narrows in on the reachability gaps that affect daily use.

## User scenarios

### User Story 1 — Skip from the mini player on narrow phones

As a listener on a phone narrow enough for the mini player to enter compact layout (e.g. iPhone SE, foldable cover screen), I want at least a "next" affordance reachable from the dock so I can advance to the next surah without first opening the full player. Today on compact layout the dock collapses to play/pause only.

### User Story 2 — Dismiss a sheet with my thumb

As a user who just opened a modal sheet from a screen-bottom action, I want to dismiss it by either dragging its handle or tapping a visible close affordance inside the sheet, so I don't have to lift my hand to the system back gesture or stretch to the top scrim.

### User Story 3 — Open the player without poking the wrong button

As a listener pressing the play button on the floating mini-player bar, I want my tap to play/pause without also opening the full player route underneath. The bar's whole-surface tap target should not feel ambiguous when my finger lands near (but not on) an `IconButton`.

### User Story 4 — Trust the 48 dp floor everywhere

As an app team migrating a screen to the kit, I want every kit-provided interactive widget to guarantee 48 dp by itself — not "48 dp when wrapped in a `ListTile`" — so I don't have to remember which parent provides the floor.

### User Story 5 — Read accurate docs

As a future contributor reading the kit's token comments to decide what size to pick for a new component, I want the doc-comments to match the values they describe. Today one component says "44 dp" while resolving to `kTilawaMinInteractiveDimension` (48 dp).

## Requirements

### Functional

- **FR-001**: Every kit-provided interactive widget guarantees a hit area of `kTilawaMinInteractiveDimension` (48 dp) on both axes *on its own*, without relying on a parent (e.g. `ListTile`, `ConstrainedBox`) to provide it. This applies in particular to `Switch.adaptive` usage inside `TilawaSettingsSwitchTile` and to any new `TilawaSwitch` / `TilawaCheckbox` atoms added by this spec.
- **FR-002**: `TilawaIconActionButtonTokens.defaults` has its doc-comment updated so the documented size matches the resolved value. The constant `kTilawaMinInteractiveDimension` documents itself once as the single floor; per-component comments must not contradict it (no "44 dp" residue).
- **FR-003**: `TilawaMediaPlayerBar` separates the "tap-anywhere-to-open-player" target from the inline transport buttons. Acceptable resolutions: (a) the outer `GestureDetector` declares its hit region as the artwork + title strip only, leaving transport icons un-wrapped; (b) the `IconButton` taps consume the gesture and prevent the bar-level `onTap` from also firing; (c) the bar-level `onTap` is moved to an explicit affordance (artwork tap, swipe-up, or a chevron). Whichever path is chosen, a tap on a transport `IconButton` must never *also* fire `onTap`.
- **FR-004**: `TilawaMediaPlayerBar` exposes a "next" affordance in compact layout. When `useCompactControls == true`, the bar still renders the next-track `IconButton` (collapsing only previous + sleep timer). If artwork space must be saved, the bar may shrink the play-pause to its tokenised secondary size — but skip-forward must remain visible.
- **FR-005**: `showTilawaModalBottomSheet` + `TilawaBottomSheetScaffold` provide at least one dismiss affordance reachable from the bottom of the screen. The decorative `TilawaSheetHandle` is upgraded into a drag-to-dismiss surface (a `GestureDetector` with `behavior: HitTestBehavior.opaque` and `onVerticalDragEnd` calling `Navigator.maybePop`), *or* `TilawaBottomSheetScaffold` gains an optional `trailingClose` slot in its title row that renders a tokenised close button. The top scrim is no longer the only dismiss path.
- **FR-006**: Every `GestureDetector` in `packages/ui_kit/lib/src/` that wraps a visible interactive surface declares `behavior: HitTestBehavior.opaque`. Today this holds for the media player bar but the rule is unstated; the audit confirms `alphabet_scrollbar` (pan handlers) and `immersive_composer_scaffold` (pan-to-dismiss) use `GestureDetector` for non-visible regions and are out of scope.
- **FR-007**: `TilawaIconActionButton`'s built-in `AnimationController` runs at `Duration(milliseconds: 300)`. This is migrated to `TilawaDesignTokens.durationMedium` so the press animation shares the kit's motion budget. (Audit-discovered drift; closes the loop left by `specs/013-token-consistency-pass/`.)
- **FR-008**: No `Semantics` contract changes. Every interactive widget that gains a wrapper or drag affordance keeps its existing `label` / `tooltip` / `selected` / `toggled` / `enabled` reporting, and every `Semantics.identifier` consumed by Maestro stays stable. The integration test suite under `.maestro/` continues to find every control by its existing identifier.

### Non-functional

- **NFR-001**: No new failures in `dart analyze` or `melos run test` for `packages/ui_kit/` or `apps/tilawa/`.
- **NFR-002**: Golden snapshots regenerate where the dismiss affordance or transport additions change pixel output. Visual centre of every existing element stays unchanged — only added affordances grow the bounding box.
- **NFR-003**: No accessibility regression. Tooltips and semantic labels stay; new affordances (drag handle dismiss, close-X, compact-mode next) gain their own semantic labels using existing localisation slots (`context.l10n.*`) where applicable.
- **NFR-004**: No new dependency on `flutter/services` haptic APIs beyond the existing `HapticFeedback.selectionClick()` already in `TilawaAdaptiveShell`. Haptics on the new sheet drag-dismiss are optional and tracked separately.

## Edge cases

- **`TilawaMediaPlayerBar` whole-bar gesture vs `IconButton` taps**: Flutter's gesture arena resolves overlapping detectors by giving the inner widget priority once it claims, so the practical issue is *perceived* not *functional* — a tap that lands 1 dp outside the icon's circle fires `onTap`, not the icon. Acceptable fix is to shrink the outer detector to the metadata strip; "fixing" gesture arena ordering is out of scope.
- **Sheet drag-dismiss interaction with internal scrollables**: Sheets that contain a `ListView` inside `Flexible` must keep the new drag-to-dismiss limited to the handle / title strip so it doesn't compete with list scrolling. The handle is the only safe always-draggable region; full-content drag-dismiss requires `DraggableScrollableSheet` and is out of scope for this spec.
- **Compact mini-player real estate**: At very narrow widths (foldable cover ~280 dp), showing artwork + title + play-pause + next may push the bar above one row of metadata. Allowed: drop the subtitle line and keep the next button. Forbidden: drop the next button to keep the subtitle.
- **RTL**: A new close-X affordance in `TilawaBottomSheetScaffold`'s title row sits at the end edge under `Directionality.rtl`, matching the existing chevron behaviour of `TilawaSettingsTile`.
- **Large text scaling (≥1.5×)**: `TilawaSettingsSwitchTile` already wraps `Switch.adaptive` in a fixed 48×30 visual slot via `FittedBox`. If FR-001 introduces a standalone `TilawaSwitch` atom, it must apply the same `FittedBox` slot so the switch doesn't visually grow when system text scale grows — the *row* (or its replacement min-size box) absorbs the scale.

## Out of scope

- **Haptic feedback parity across all interactive widgets.** Today only the adaptive shell's bottom nav fires haptics. Extending haptics to toggles, sheet snaps, and transport is a separate spec.
- **Replacing `showModalBottomSheet` with `DraggableScrollableSheet` across the app.** This spec only adds a dismiss-from-bottom affordance to the kit's sheet helpers; app-level migration to fully draggable sheets is downstream.
- **Profile/settings entry points on the home header.** The audit notes that top-right avatar buttons live outside one-thumb reach on large phones, but the fix is a navigation decision (route Profile through the bottom tab bar) not a kit change.
- **`TilawaAdaptiveShell` thumb-zone rework.** The shell already uses Material's `BottomNavigationBar` with proper viewPadding handling and selection haptics; no further ergonomic gap was identified.
