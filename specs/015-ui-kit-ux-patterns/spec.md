# Feature Specification: UI Kit UX Patterns

**Feature Branch**: `feature/ui-kit-2` (or `015-ui-kit-ux-patterns`)
**Created**: 2026-05-20
**Status**: Draft
**Input**: Senior UX review of `packages/ui_kit/` — five high-impact improvements to make kit-built screens feel cohesive, trustworthy, and friendly on mobile. Builds on completed spec 014 (ergonomic reachability and 48 dp floor).

**Related specs**: [014-ergonomic-mobile-ux](../014-ergonomic-mobile-ux/spec.md) (complete), [008-skeleton-loading](../008-skeleton-loading/spec.md) (skeleton foundation — coordinate for async loading), [010-reciters-a11y](../010-reciters-a11y/spec.md) (semantics precedent).

## Intent

Spec 014 closed the mechanical gaps: hit targets, mini-player reachability, sheet handle dismiss. Users still experience inconsistency when screens mix bespoke loading UI, sheets with actions at the top, silent icon buttons, and chip styles that look equally tappable when only some are interactive.

This spec defines **five kit-level UX patterns** so feature teams ship screens that feel like one product:

1. **Sheet & modal pattern** — thumb-zone actions and predictable dismiss/scroll boundaries.
2. **Interaction feedback** — consistent press feel and optional haptics across interactive atoms.
3. **Async content states** — one screen-level loading / empty / error / content contract.
4. **Accessibility & large text** — semantics and 1.4× text-scale resilience as enforced kit contracts.
5. **Chip & filter clarity** — visual and behavioral distinction between metadata, selection, status, and action chips.

Each pillar is independently shippable; priority order is defined in [plan.md](plan.md).

## User scenarios

### User Story 1 — Confirm a sheet action without reaching up (Priority: P1)

As a user on a phone who opened a settings or picker sheet from the bottom of the screen, I want the primary action (Save, Done, Apply) in the lower third of the sheet so I can confirm with my thumb without stretching to the title row or relying only on the system back gesture.

**Why P1**: Prayer alerts, reciter filters, and player sheets are daily flows; mis-placed CTAs are the most common mobile UX failure after tiny tap targets.

**Independent test**: Open a kit demo sheet using `TilawaBottomSheetScaffold` with a sticky footer; primary button sits above safe area in thumb zone; dismiss via handle still works (spec 014).

**Acceptance scenarios**:

1. **Given** a form sheet with primary and secondary actions, **When** the sheet opens on a narrow phone, **Then** both actions are visible without scrolling and the primary action is in the bottom safe area.
2. **Given** a sheet with a scrollable list, **When** the user scrolls the list, **Then** the footer actions remain fixed and list scroll does not compete with handle drag-to-dismiss (spec 014 FR-005 edge case).

---

### User Story 2 — Feel when a control registered (Priority: P2)

As a listener tapping play, a toggle, or a segment control repeatedly, I want the same subtle press animation and (where appropriate) haptic cue so I trust the app responded even before content updates.

**Why P2**: Tilawa is interaction-heavy (player, prayer toggles, language switcher). Inconsistent motion/haptics makes the app feel unfinished.

**Independent test**: Press `TilawaButton`, `TilawaIconActionButton`, `TilawaIconToggle`, and `TilawaSwitch` in the gallery; all use tokenised duration; optional haptic fires on successful toggle (platform-gated).

**Acceptance scenarios**:

1. **Given** any kit primary button, **When** the user presses and releases, **Then** a tokenised scale or opacity animation completes within `durationMedium`.
2. **Given** haptics enabled on the device, **When** the user toggles `TilawaSwitch` or a segmented segment, **Then** a light selection haptic fires once per state change (not on every rebuild).

---

### User Story 3 — Know what happened during loading (Priority: P2)

As a user waiting for prayer times, reciters, or downloads, I want loading, empty, and error states to look and behave the same across screens so I always know whether to wait, retry, or change a setting.

**Why P2**: Async anxiety (“Did it work?”) drives support burden; spec 008 adds skeleton primitives — this spec wires them into a screen-level organism.

**Independent test**: `TilawaAsyncContent` demo cycles through loading → empty → error → content without feature-specific layout code.

**Acceptance scenarios**:

1. **Given** a screen wrapped in `TilawaAsyncContent` in loading state, **When** data arrives, **Then** content replaces loading without layout jump beyond tokenised cross-fade (or skeleton handoff per spec 008 when skeleton slot provided).
2. **Given** an error state with retry, **When** the user taps retry, **Then** loading state appears in the same region and retry button shows a brief loading affordance on the action (no duplicate spinners).

---

### User Story 4 — Use the app with larger text and a screen reader (Priority: P3)

As an older user or VoiceOver/TalkBack user, I want icon-only controls to have clear names and settings rows not to clip when I increase text size up to the app’s 1.4× clamp.

**Why P3**: DESIGN.md targets a wide age range; spec 014 fixed switch scaling — this extends the contract kit-wide.

**Independent test**: Contract test renders interactive molecules at text scale 1.4×; no `RenderFlex overflow`; every icon-only control has non-empty semantics label in widget tests.

**Acceptance scenarios**:

1. **Given** text scale 1.4×, **When** `TilawaSettingsSwitchTile` and `TilawaPrayerAlertRow` render, **Then** no overflow errors and hit targets remain ≥ 48 dp.
2. **Given** TalkBack focused on `TilawaIconToggle`, **When** the control is off, **Then** semantics report button + toggled false + caller-provided label.

---

### User Story 5 — Tell chips apart at a glance (Priority: P3)

As a user scanning reciter filters or prayer status rows, I want passive metadata to look quiet, selected filters to look active, and status hints not to look like buttons unless they are tappable.

**Why P3**: Four chip-family widgets overlap; wrong choice in feature code creates visual noise and mistaken taps.

**Independent test**: Gallery side-by-side demo of metadata vs selection vs status vs action chip; metadata never shows ink splash; selection shows selected elevation; status without `onTap` has no button semantics.

**Acceptance scenarios**:

1. **Given** a `TilawaMetadataChip`, **When** the user taps it, **Then** no ripple and no button semantics (unless explicitly made interactive in a future API — out of scope).
2. **Given** a horizontal row of `TilawaSelectionPill` widgets in `TilawaFilterBar`, **When** one is selected, **Then** selected pill uses tokenised elevation/shadow and `Semantics.selected`.

---

## Requirements

### Functional

#### Pillar A — Sheet & modal pattern

- **FR-A01**: `TilawaBottomSheetScaffold` gains an optional **`footer`** slot rendered below scrollable `children`, outside the scroll viewport, with tokenised padding and safe-area inset so primary actions sit in the thumb zone.
- **FR-A02**: `TilawaBottomSheetScaffold` gains an optional **`trailingClose`** on the title row (end edge under RTL) using `TilawaIconActionButton` or equivalent tokenised close control with semantic label supplied by caller.
- **FR-A03**: `showTilawaModalBottomSheet` documents three presets in kit docs: **form** (footer actions), **picker** (list + optional footer), **confirm** (footer primary + secondary). Presets are helper functions or named constructors, not app-specific copy.
- **FR-A04**: Scroll/dismiss boundary from spec 014 is preserved: drag-to-dismiss remains on `TilawaSheetHandle` only; list scroll inside `Flexible` must not trigger sheet dismiss.

#### Pillar B — Interaction feedback

- **FR-B01**: Introduce **`TilawaInteractionFeedback`** (foundation helper or mixin) exposing tokenised press scale/opacity curves and optional **`HapticFeedback.selectionClick`** / **`lightImpact`** tiers, gated by `MediaQuery.disableAnimations` and a kit-level `TilawaInteractionFeedback.enabled` override for tests.
- **FR-B02**: Wire press feedback into **`TilawaButton`**, **`TilawaIconActionButton`**, **`TilawaIconToggle`**, **`TilawaSwitch`**, **`TilawaCheckbox`**, and **`TilawaSegmentedControl`** segments using `durationMedium` / `durationFast` from `TilawaDesignTokens`.
- **FR-B03**: Toggle-state haptics fire on **`TilawaSwitch`**, **`TilawaCheckbox`**, **`TilawaIconToggle`**, and segmented control selection changes only (not on initial build).
- **FR-B04**: Remaining hardcoded 300 ms motion in **`tilawa_alphabet_scrollbar.dart`** and segmented-control **`transitionDuration`** token migrate to design tokens (closes spec 014 F-005).

#### Pillar C — Async content states

- **FR-C01**: Add organism **`TilawaAsyncContent`** with required **`state`** enum (`loading`, `empty`, `error`, `content`) and slots: `loadingBuilder`, `emptyBuilder`, `errorBuilder`, `builder` (content). Default builders delegate to `TilawaLoadingIndicator`, `TilawaEmptyState`, `TilawaErrorState`.
- **FR-C02**: **`TilawaAsyncContent`** accepts optional **`skeleton`** widget for loading; when present, prefer skeleton over spinner (coordinates with spec 008 when `TilawaSkeletonBlock` lands).
- **FR-C03**: Error slot requires **`onRetry`** callback; when retry is in flight, primary retry control shows inline loading (button loading state or disabled + indicator) without duplicating full-screen spinner.
- **FR-C04**: Non-blocking transient messages remain **`TilawaFeedbackStrip`** / app snackbars — `TilawaAsyncContent` is for full-region async, not toasts.

#### Pillar D — Accessibility & large text

- **FR-D01**: Add **`test/widgets/interaction_scale_contract_test.dart`** (or extend accessibility audit): pump representative interactive widgets at text scale **1.0** and **1.4**; assert no overflow; assert `kMeMuslimMinInteractiveDimension` on interactive atoms.
- **FR-D02**: **`TilawaCountProgressRing`**, **`TilawaSelectionPill`**, and **`TilawaMetadataChip`** document semantics rules in dartdoc; icon-only **`TilawaIconActionButton`** requires `tooltip` or `semanticLabel` (assert in debug mode or test).
- **FR-D03**: **`TilawaSettingsTile`** trailing chevron mirrors in RTL (`Directionality`); fix if current chevron is LTR-locked (inventory gap).
- **FR-D04**: No regression to Maestro **`Semantics.identifier`** values from spec 014 FR-008.

#### Pillar E — Chip & filter clarity

- **FR-E01**: **`TilawaMetadataChip`**: passive by default — no `InkWell`, no button semantics, no shadow (read-only appearance).
- **FR-E02**: **`TilawaStatusChip`**: button semantics and ripple only when **`onTap != null`**; quiet/icon-only mode unchanged.
- **FR-E03**: **`TilawaSelectionPill`**: always exposes **`Semantics.selected`** when `selected == true` (verify existing behavior; fix gaps).
- **FR-E04**: Add molecule **`TilawaFilterBar`**: horizontal scrollable row of `TilawaSelectionPill` with tokenised spacing, optional `padding`, semantics group label from caller.
- **FR-E05**: Add **`packages/ui_kit/doc/component_guide.md`** section “Chip family” with decision table (metadata / selection / status / action).

### Non-functional

- **NFR-001**: `dart analyze` and `flutter test` in `packages/ui_kit/` remain green; app smoke tests unaffected.
- **NFR-002**: New public APIs documented with dartdoc and gallery demos for sheet footer, async content, and filter bar.
- **NFR-003**: Goldens updated only where footer/ chip visual hierarchy changes; centre of existing elements unchanged where possible.
- **NFR-004**: Haptics respect platform (no haptic on web/desktop tests); tests disable haptics via injection or `enabled: false`.

## Edge cases

- **RTL**: Sheet close button and footer action order follow `Directionality`; primary action remains trailing in LTR and leading in RTL when using standard `Row` + `MainAxisAlignment.end` pattern documented in kit.
- **Large text (1.4×)**: Footer stacks vertically if horizontal button row would overflow; minimum 48 dp touch height preserved.
- **Reduced motion**: Press animations skip or instant-complete when `MediaQuery.disableAnimations` is true; haptics still optional (platform default).
- **Sheet + keyboard**: Footer stays above keyboard inset (`viewInsets.bottom`).
- **Empty vs error**: Empty state is “no data yet / nothing to show”; error state is “fetch failed” — `TilawaAsyncContent` must not conflate them.
- **Skeleton without spec 008**: If `TilawaSkeletonBlock` is not yet exported, `skeleton` slot accepts any widget; no hard dependency on 008 for FR-C02.

## Out of scope

- Replacing every app screen with `TilawaAsyncContent` in this spec (kit + one reference migration only).
- Full haptic parity on every list item or scroll snap.
- `DraggableScrollableSheet` migration for all app modals.
- Feature-specific sheet copy or l10n inside ui_kit.
- OLED / true-black theme changes.
- Replacing `TilawaAdaptiveShell` navigation model.

## Assumptions

- Spec 014 reachability work remains the baseline; this spec does not reopen FR-003–FR-005 except where sheet footer composes with handle dismiss.
- App text scaler clamp stays **1.0–1.4** (`tilawa_app.dart`).
- `TilawaDesignTokens.durationMedium` (400 ms) is the default interaction duration unless `durationFast` is explicitly better (segment highlight).
- Gallery app is the primary visual QA surface for new patterns.

## Success criteria

- **SC-001**: 100% of new modal sheets in kit gallery use footer slot for primary actions; manual QA confirms primary CTA in lower third on iPhone SE-class viewport.
- **SC-002**: Interactive atoms listed in FR-B02 share the same press animation duration token in code review checklist.
- **SC-003**: `TilawaAsyncContent` widget test covers all four states and retry loading affordance.
- **SC-004**: Zero overflow failures in interaction scale contract test at 1.4× for the audited widget set.
- **SC-005**: Chip family guide published; gallery shows four chip types with distinct visual/interaction behavior per FR-E01–E03.
