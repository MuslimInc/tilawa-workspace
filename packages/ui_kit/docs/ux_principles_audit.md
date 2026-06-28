# UI Kit UX principles audit (Ramotion × Tilawa)

**Date:** 2026-06-24  
**Reference:** [Ramotion UX design principles](https://www.ramotion.com/blog/ux-design-principles/)  
**Product context:** Tilawa — calm worship app; UI kit serves daily rituals, catalog browsing, and settings.

---

## 1. Most relevant principles for Tilawa

| Ramotion principle | Tilawa relevance |
|--------------------|----------------|
| **User-centered design / users in control** | Worship surfaces stay uninterrupted; customization (pins, filters, language) must feel reversible and predictable. |
| **Consistency** | One interaction primitive (`TilawaInteractiveSurface`), one accent per screen, shared empty/error patterns. |
| **Hierarchy** | Title → body → metadata → actions on every card, row, and state layout. |
| **Contrast & balance** | Selected vs idle states must be scannable without rainbow chrome; calm neutral canvas. |
| **Comfort / simplicity** | Few choices per viewport; progressive disclosure via sheets; one primary CTA per state. |
| **Accessibility** | 48 dp targets, semantics for selection/toggles, live regions for transient feedback. |
| **Typography** | Token-backed `TextTheme`; no raw `fontSize` in kit widgets. |

Tilawa-specific tenets from `tilawa-apply-ux-principles` reinforce these: **content-first**, **calm density**, **gentle failure**, **respectful placement**.

---

## 2. Audit findings (pre-change)

### Strengths (already in kit)

- Shared soft ink + state-layer press + focus ring via `TilawaInteractiveSurface` (consistency, accessibility).
- `TilawaEmptyState` / `TilawaErrorState` share `TilawaIllustratedState` (comfort, hierarchy).
- Catalog filters use `TilawaSelectionPillStyle.catalog` (contrast without primary wash on chrome).
- 2026 accessibility audit closed touch-target and semantics gaps on chips, segments, feedback strips.

### Gaps addressed in this pass

| Component | Issue | UX principle |
|-----------|-------|--------------|
| `TilawaIllustratedState` | Secondary action rendered before primary in horizontal layouts | **Hierarchy** — primary CTA should lead |
| `TilawaIllustratedState` | No default screen-reader label when `semanticLabel` omitted | **Accessibility** |
| `TilawaSelectionTile` | Selected checkmark used muted `onSurfaceVariant` | **Hierarchy / contrast** |
| `TilawaSelectionTile` | Row could shrink below 48 dp on short labels | **Accessibility / comfort** |
| `TilawaSegmentedControl` | Selected segment shadow tokens existed but were not painted | **Feedback / hierarchy** |
| `TilawaQuickFilterBar` | Horizontal pill strip merged pill semantics with scroll parent | **Accessibility / user control** |

### Deferred (out of scope — larger refactors)

- Copy voice lives in app l10n, not the kit.

---

## 6. Follow-up (2026-06-24): list-row interaction parity

`TilawaSettingsTile`, `TilawaSettingsSwitchTile`, and `TilawaNavigationRow` now share
`TilawaSettingsListRow`, which routes through `TilawaInteractiveSurface` instead of
`ListTile` ink ripple.

| Principle | Benefit |
|-----------|---------|
| **Consistency** | Settings and hub rows press like cards, chips, and selection tiles. |
| **Accessibility** | Keyboard focus ring on every drill-down row. |
| **Feedback** | Shared haptic + soft ink + state-layer press on row activation. |

---

## 3. Planned changes

1. **Illustrated states** — primary-before-secondary action order; auto `semanticLabel` from title + subtitle.
2. **Selection tile** — primary checkmark; `minInteractiveDimension` row floor.
3. **Segmented control** — apply tokenized selected-segment shadow.
4. **Quick filter bar** — `explicitChildNodes` so each pill stays individually focusable in the scroll strip.

---

## 4. Affected files

| File | Change |
|------|--------|
| `lib/src/atoms/tilawa_illustrated_state.dart` | Action order, default semantics |
| `lib/src/molecules/tilawa_selection_tile.dart` | Check color, min height |
| `lib/src/molecules/tilawa_segmented_control.dart` | Selected shadow |
| `lib/src/molecules/tilawa_quick_filter_bar.dart` | Scroll semantics |
| `lib/src/molecules/tilawa_settings_list_row.dart` | **New** shared list-row primitive |
| `lib/src/molecules/tilawa_settings_tile.dart` | Migrate off `ListTile` ink |
| `lib/src/molecules/tilawa_navigation_row.dart` | Migrate off `ListTile` ink |
| `test/atoms/tilawa_illustrated_state_test.dart` | New behavior tests |
| `test/molecules/tilawa_selection_tile_test.dart` | New contract test |
| `docs/ux_principles_audit.md` | This document |
| `CHANGELOG.md` | Unreleased notes |

Golden targets (if visuals shift): `tilawa_segmented_control`, `tilawa_selection_pill`, `tilawa_chip_constrained` (unchanged in this pass unless segment goldens drift).

---

## 5. Verification

```sh
cd packages/ui_kit
dart analyze
flutter test test/atoms/tilawa_illustrated_state_test.dart
flutter test test/molecules/tilawa_selection_tile_test.dart
flutter test test/molecules/tilawa_segmented_control_test.dart
flutter test test/goldens/
```

Manual: light + dark theme, text scale 1.4, RTL Arabic on illustrated states and selection sheets.
