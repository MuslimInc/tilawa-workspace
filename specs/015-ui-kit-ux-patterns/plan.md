# Plan: UI Kit UX Patterns

**Feature Branch**: `feature/ui-kit-2`
**Created**: 2026-05-20
**Status**: Draft
**Spec**: [spec.md](spec.md)

## Summary

Five pillars, shipped in **three batches** to limit review size and golden churn. Each batch is independently mergeable and testable.

| Batch | Pillars | FRs | Risk |
|-------|---------|-----|------|
| **1 — Sheets** | A | FR-A01–A04 | Medium — layout API on `TilawaBottomSheetScaffold` |
| **2 — Feel & states** | B + C | FR-B01–B04, FR-C01–C04 | Medium — haptics need test doubles |
| **3 — Trust & clarity** | D + E | FR-D01–D04, FR-E01–E05 | Low–medium — semantics + chip visual tweaks |

## Batch 1 — Sheet & modal pattern (P1)

### Diagnosis

- `TilawaBottomSheetScaffold` today: handle + optional `topBar` + scroll `children`. No sticky footer.
- Spec 014 added handle drag-to-dismiss; actions still often live in `topBar` or bottom of scroll content (thumb-unfriendly).
- `trailingClose` was listed as an alternative in 014 FR-005 but not implemented if handle-only path was chosen.

### Design

```
Column
├── TilawaSheetHandle          (drag dismiss — unchanged)
├── topBar (+ optional trailingClose)
├── betweenTopBarAndBody
├── Flexible → scroll body
└── footer (NEW, sticky, SafeArea bottom)
```

**API sketch** (implementation detail for tasks, not binding on spec):

```dart
TilawaBottomSheetScaffold(
  topBar: TilawaBottomSheetTitleRow(
    title: '…',
    trailingClose: true,
    onClose: () => Navigator.pop(context),
  ),
  footer: TilawaBottomSheetActions(
    primary: …,
    secondary: …,
  ),
  children: [ Flexible(child: ListView(…)) ],
)
```

**Tokens**: extend `TilawaBottomSheetScaffoldTokens` with `footerPadding`, `footerGap`, optional `footerElevation` / surface color.

### Verification

- Widget test: footer visible when list scrolls; handle dismiss still pops route.
- Gallery demo: form + picker presets.
- Manual: iPhone SE viewport — primary button in thumb zone.

---

## Batch 2 — Interaction feedback + async content (P2)

### Interaction feedback

- Add `lib/src/foundation/tilawa_interaction_feedback.dart`:
  - `TilawaPressAnimation` widget wrapper (scale 1.0 → 0.96, `durationFast`)
  - `TilawaHaptic` enum: `none`, `selection`, `lightImpact`
  - `TilawaInteractionFeedback.trigger(TilawaHaptic)` — no-op when disabled
- Migrate existing `AnimationController` sites to shared helper where duplicate.
- Close 014 **F-005**: alphabet scrollbar fade + segmented control `transitionDuration` → tokens.

### Async content

- New file: `lib/src/organisms/tilawa_async_content.dart`
- State machine:

```
loading  → content (on success)
loading  → empty   (on success, zero items)
loading  → error   (on failure)
error    → loading (on retry)
```

- Default builders reuse existing atoms; no new visual language.
- Optional `skeleton` parameter — placeholder `SizedBox` in tests until spec 008 ships.

### Verification

- Unit/widget tests for state transitions and retry loading on button.
- Gallery demo with toggle buttons to switch states.
- Press feedback: test that animation duration reads from tokens (mock theme).

---

## Batch 3 — Accessibility contracts + chip clarity (P3)

### Accessibility

- New contract test file pumping at 1.0× and 1.4× text scale.
- Widget set (minimum): `TilawaSettingsSwitchTile`, `TilawaSettingsTile`, `TilawaPrayerAlertRow`, `TilawaButton`, `TilawaSegmentedControl`, `TilawaSelectionPill`.
- Fix RTL chevron on `TilawaSettingsTile` if test proves regression.

### Chip family

- **`TilawaMetadataChip`**: remove implicit tap if any; ensure no `Material` ripple.
- **`TilawaStatusChip`**: audit `onTap` null → no button semantics (likely exists; verify tests).
- **`TilawaFilterBar`**: thin wrapper — `SingleChildScrollView` + `Row` + token spacing.
- **`doc/component_guide.md`**: chip decision table + link from `DESIGN.md` §6.

### Verification

- Extend `accessibility_audit_contracts_test.dart` for new rules.
- Golden update for chip hierarchy if shadows/borders change.
- No Maestro identifier changes (grep `.maestro/` before merge).

---

## Dependencies

| Dependency | Notes |
|------------|-------|
| Spec 014 complete | Handle dismiss, 48 dp floor |
| Spec 008 optional | Skeleton slot in `TilawaAsyncContent` |
| Spec 013 motion tokens | `durationMedium` / `durationFast` source of truth |

## Risks

| Risk | Mitigation |
|------|------------|
| Footer + keyboard overlap | `Padding(padding: viewInsets)` on footer |
| Haptic flakiness in CI | `TilawaInteractionFeedback.enabled = false` in tests |
| Chip visual change breaks app | Prefer semantics/ripple fixes first; shadow changes behind token flag if needed |
| Scope creep into app migrations | One reference screen per pillar in gallery only |

## Follow-ups (post-spec)

- Migrate `prayer_notification_settings_sheet.dart` to sheet footer + `TilawaPrayerAlertRow`.
- App-wide adoption tracker in `ui-kit-inventory.md`.
- Haptic on sheet snap / successful save (product decision).
