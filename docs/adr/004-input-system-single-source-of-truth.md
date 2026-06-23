# ADR-004: Input System Single Source of Truth

**Status:** Accepted  
**Date:** 2026-06-21  
**Deciders:** Tilawa mobile / design system  
**Supersedes:** Feature-level `QuranSessionsFormFieldShell`, theme-owned input chrome

## Context

Catalog search (Reciters) showed a **double border**: an outer pill `Container`
and an inner `OutlineInputBorder` from `ThemeData.inputDecorationTheme` leaking
through `InputDecoration.applyDefaults()` because only `border: none` was set.

The same period revealed **five parallel decoration sources**:

1. `AppTheme.inputDecorationTheme`
2. `TilawaTextField` partial decorations
3. `TilawaSearchField` outer `Container` + inner `TextField`
4. `TilawaDropdownField._fieldDecoration`
5. `QuranSessionsFormFieldShell` in a feature package

No single layer owned “what does an input look like,” violating DRY and making
regressions inevitable.

## Problem

- Duplicate border owners on one control
- Feature packages owning design-system chrome
- Inconsistent radius (pill search vs chrome forms) without documented roles
- Theme defaults fighting kit widgets

## Decision

Adopt a **kit-owned input stack**:

| Layer | Responsibility |
|-------|----------------|
| `ThemeData.inputDecorationTheme` | **Borderless** — fallback for unmigrated raw Material only (Strategy B) |
| `TilawaInputStyle` | SSOT for radii, padding, borders, fill, error/focus/disabled |
| `TilawaFieldShell` | Exactly **one** border owner per control (`decorator` or `search`) |
| Kit atoms | Behaviour (validation, menus, pickers) — no local decoration recipes |

### Semantic roles

- **`TilawaInputRole.form`** — chrome radius (12 dp): text, dropdown, read-only
- **`TilawaInputRole.search`** — pill radius: catalog search (unchanged product intent)

### Atoms

- `TilawaTextField`, `TilawaDropdownField`, `TilawaReadOnlyField`, `TilawaSearchField`

### Removed

- `QuranSessionsFormFieldShell` — deleted; call sites use kit atoms

## Consequences

### Positive

- Reciters (and all search) double-border fixed at architecture level
- One place to change form chrome
- Feature packages no longer import decoration logic
- Regression tests lock borderless inner search + no nested `OutlineInputBorder`

### Negative / tradeoffs

- Raw `TextField` in unmigrated dialogs looks flat until wrapped in kit atoms
- `TilawaTextField` now uses filled surface (aligned with dropdown) — minor visual shift
- Golden snapshots for text fields may need refresh on CI

### Neutral

- Search remains pill-shaped; only ownership changed

## Migration rules

1. **New inputs** — kit atom only; never new feature-level `InputDecoration` helpers
2. **Read-only pickers** — `TilawaReadOnlyField` + platform dialog in `onTap`
3. **Search** — `TilawaSearchField`; never `Container` border + `TextField`
4. **Theme** — do not reintroduce outlined `inputDecorationTheme` without ADR revision
5. **Tests** — add widget tests when touching input chrome; run `tilawa_field_shell_test` for search

## Remaining exception

| File | Reason |
|------|--------|
| `apps/tilawa/lib/features/color_picker/palette.dart` | Dev/QA hex entry — dense, non-form, intentionally custom `TextField` + minimal `InputDecoration`. **Do not use as a pattern for product forms.** |

## Verification

- `dart analyze` — `packages/ui_kit`, `packages/quran_sessions`: clean
- Input-focused tests: `tilawa_input_style_test`, `tilawa_field_shell_test`, atom tests
- `QuranSessionsFormFieldShell` — **fully removed** (grep clean)

## References

- [`docs/UI_KIT_INPUT_SYSTEM.md`](../UI_KIT_INPUT_SYSTEM.md)
- `packages/ui_kit/lib/src/foundation/tilawa_input_style.dart`
- `packages/ui_kit/lib/src/foundation/tilawa_field_shell.dart`
