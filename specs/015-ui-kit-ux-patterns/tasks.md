# Tasks: UI Kit UX Patterns

**Feature Branch**: `feature/ui-kit-2`
**Created**: 2026-05-20
**Status**: Not started
**Spec**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md)

## Batch 1 — Sheet & modal pattern (FR-A01–A04)

### Tokens & scaffold

- [x] **T-A01**: Add `footerPadding`, `footerGap`, and `footerBackgroundColor` (or reuse surface token) to `TilawaBottomSheetScaffoldTokens` in `molecules_tokens.dart` / `component_tokens_theme.dart`.
- [x] **T-A02**: Add optional `footer` parameter to `TilawaBottomSheetScaffold`; render below `children`, wrapped in `SafeArea(top: false)` and tokenised padding; apply `MediaQuery.viewInsets.bottom` for keyboard.
- [x] **T-A03**: Add `TilawaBottomSheetTitleRow` molecule (title + optional `trailingClose` using tokenised icon button) OR document pattern for `topBar` composition — pick one approach in implementation.
- [x] **T-A04**: Add `TilawaBottomSheetActions` molecule (primary + optional secondary, full-width on narrow, side-by-side when width allows).

### Helpers & docs

- [x] **T-A05**: Add sheet preset helpers on `showTilawaModalBottomSheet` or sibling file: `showTilawaFormSheet`, `showTilawaPickerSheet`, `showTilawaConfirmSheet` (thin wrappers).
- [x] **T-A06**: Widget tests: footer stays fixed while list scrolls; handle dismiss still works; RTL close button on end edge.
- [x] **T-A07**: Gallery demos: form sheet with footer actions; picker sheet with list + Done footer.

### Verification

- [x] **T-A90**: `flutter test` green for `tilawa_bottom_sheet_scaffold_test.dart` + new tests.
- [ ] **T-A91**: Manual thumb-zone check on SE viewport (gallery).

---

## Batch 2 — Interaction feedback + async content (FR-B01–B04, FR-C01–C04)

### Interaction feedback

- [x] **T-B01**: Create `lib/src/foundation/tilawa_interaction_feedback.dart` with haptic tiers and global `enabled` flag for tests.
- [x] **T-B02**: Create `TilawaPressAnimation` (or integrate into existing button internals) using `durationFast` / `durationMedium`.
- [x] **T-B03**: Wire press animation into `TilawaButton` and `TilawaIconActionButton`.
- [x] **T-B04**: Wire toggle haptics into `TilawaSwitch`, `TilawaCheckbox`, `TilawaIconToggle`, `TilawaSegmentedControl`.
- [x] **T-B05**: Migrate alphabet scrollbar overlay fade duration to `TilawaDesignTokens` (closes 014 F-005).
- [x] **T-B06**: Migrate `TilawaImmersiveComposerTokens.transitionDuration` to design token default (closes 014 F-005).
- [x] **T-B07**: Widget tests with `TilawaInteractionFeedback.enabled = false`; verify animation uses token duration via theme override.

### Async content

- [x] **T-C01**: Create `TilawaAsyncContentState` enum and `TilawaAsyncContent` organism with four slots + defaults.
- [x] **T-C02**: Implement retry-in-flight on error primary action (loading affordance on button).
- [x] **T-C03**: Widget tests: all state transitions; empty vs error distinct; skeleton slot renders when provided.
- [x] **T-C04**: Gallery demo: state switcher (loading / empty / error / content).

### Verification

- [x] **T-B90**: `dart analyze` + full ui_kit test suite green.

---

## Batch 3 — Accessibility + chip clarity (FR-D01–D04, FR-E01–E05)

### Accessibility contracts

- [ ] **T-D01**: Add `test/widgets/interaction_scale_contract_test.dart` — pump widget set at 1.0× and 1.4×; assert no overflow.
- [ ] **T-D02**: Assert `kMeMuslimMinInteractiveDimension` on audited interactive widgets in same test file.
- [ ] **T-D03**: Fix `TilawaSettingsTile` chevron mirroring for RTL if contract test or manual QA fails.
- [ ] **T-D04**: Extend `accessibility_audit_contracts_test.dart` for `TilawaIconActionButton` label requirement and chip semantics rules.
- [ ] **T-D05**: Grep `.maestro/` and document no identifier changes in PR notes.

### Chip family

- [ ] **T-E01**: Audit `TilawaMetadataChip` — ensure passive (no ripple, no button semantics).
- [ ] **T-E02**: Audit `TilawaStatusChip` — button semantics only when `onTap != null`; add test if missing.
- [ ] **T-E03**: Verify `TilawaSelectionPill` exposes `Semantics.selected`; fix if gap.
- [ ] **T-E04**: Implement `TilawaFilterBar` molecule + export + test.
- [ ] **T-E05**: Write `packages/ui_kit/doc/component_guide.md` chip section; link from `DESIGN.md` §6.
- [ ] **T-E06**: Gallery: chip family comparison demo + filter bar demo.

### Verification

- [ ] **T-D90**: Full test suite + regenerate goldens only if chip visuals changed (eyeball diff).
- [ ] **T-D91**: Update `specs/006-ui-kit-expansion/ui-kit-inventory.md` gaps section for closed items.

---

## Optional app migration (not blocking spec close)

- [ ] **T-M01**: Migrate one production sheet (e.g. prayer notification settings) to footer pattern — separate PR if desired.
