# Tilawa UI Kit — Input System

**Status:** Adopted (2026-06-21)  
**ADR:** [`docs/adr/004-input-system-single-source-of-truth.md`](adr/004-input-system-single-source-of-truth.md)  
**Implementation:** `packages/ui_kit/lib/src/foundation/tilawa_input_style.dart`, `tilawa_field_shell.dart`

---

## Overview

All product form, search, dropdown, and read-only selector chrome is owned by
**ui_kit**. Feature packages and app screens compose kit atoms — they do not
define borders, radii, padding, or `InputDecoration` recipes.

```
ThemeData.inputDecorationTheme   → borderless fallback (raw Material only)
        ↓
TilawaInputStyle               → SSOT (radii, borders, padding, states)
        ↓
TilawaFieldShell               → single border owner (decorator | search)
        ↓
Kit atoms                      → behaviour only
```

---

## Core types

### `TilawaInputRole`

| Role | Radius | Use |
|------|--------|-----|
| `form` | `TilawaRadiusFamily.chrome` (12 dp) | Text fields, dropdowns, read-only selectors |
| `search` | `TilawaRadiusFamily.pill` (height / 2) | Catalog / list search bars |

Search keeps **pill** shape by design. The historical Reciters bug was **dual
border owners**, not pill radius.

### `TilawaInputStyle`

Access: `context.inputStyle(role: TilawaInputRole.form)`.

| API | Purpose |
|-----|---------|
| `decoration(...)` | Full `InputDecoration` with **every** border slot set explicitly |
| `borderlessDecoration(...)` | All borders `InputBorder.none` — child inside `TilawaFieldShell.search` |
| `searchShellDecoration(...)` | Outer `BoxDecoration` for search (sole border owner) |
| `borderRadius()` | Role-aware corner radius from tokens |

**Never** rely on `border: InputBorder.none` alone; `applyDefaults()` will
still inject `enabledBorder` from theme unless all slots are cleared.

### `TilawaFieldShell`

| Constructor | Border owner | Child |
|-------------|--------------|-------|
| `TilawaFieldShell.decorator` | `InputDecorator` + `TilawaInputStyle.decoration` | Value row or dropdown content |
| `TilawaFieldShell.search` | `BoxDecoration` via `searchShellDecoration` | `TextField` with `borderlessDecoration` |

---

## Kit atoms

| Widget | Layer | Notes |
|--------|-------|-------|
| `TilawaTextField` | Atom | `TextFormField` + `inputStyle.decoration()`; validation, password, clear |
| `TilawaSearchField` | Molecule | Default variant `catalog` (pill); uses `TilawaFieldShell.search` |
| `TilawaDropdownField` | Atom | `MenuAnchor` + `InputDecorator`; same closed-field chrome as text |
| `TilawaReadOnlyField` | Atom | Tappable date/time/value display; `TilawaFieldShell.decorator` |

Host search in catalog headers with `TilawaCatalogAppBar.bottomContent` +
`TilawaSearchField`. Use `TilawaSearchFieldSlot` only **outside** the app bar.

---

## Theme strategy (Strategy B)

`AppTheme` sets `inputDecorationTheme` to **fully borderless**:

- Kit widgets are the SSOT for input chrome.
- Raw `TextField` / `TextFormField` in unmigrated dialogs will look flat until
  wrapped in kit atoms — that is intentional pressure to migrate.

Compliance test:
`packages/ui_kit/test/theme/app_theme_spec_compliance_test.dart`.

---

## When raw `TextField` / `TextFormField` is allowed

| Context | Allowed? |
|---------|----------|
| Inside ui_kit atoms (`TilawaTextField`, `TilawaSearchField`) | Yes — must use `TilawaInputStyle` |
| ui_kit / widget tests exercising shell contract | Yes |
| ui_kit gallery / previews | Prefer kit atoms; raw only in isolated demos |
| Product features (apps, quran_sessions) | **No** — use kit atoms |
| Intentional custom controls (see ADR exceptions) | Yes, with documented reason |

---

## Forbidden patterns

Do **not**:

1. **Wrap `TextField` in a `Container` with its own border** — creates double
   borders when theme or `InputDecoration` also draws an outline.
2. **Copy `InputDecoration` in feature packages** — use `TilawaInputStyle` or
   kit atoms (removed: `QuranSessionsFormFieldShell`).
3. **Use multiple border owners** on the same control (shell + theme + partial
   `InputDecoration`).
4. **Hardcode radius or padding** in feature screens — use `theme.tokens` via
   `TilawaInputStyle`.
5. **Set only `border: InputBorder.none`** on an inner field without clearing
   `enabledBorder`, `focusedBorder`, etc.

---

## Radius hierarchy (inputs)

| Control | Radius family |
|---------|----------------|
| Form text, dropdown, read-only | `chrome` |
| Search fields | `pill` |
| Primary CTAs | `pill` (buttons — separate SSOT) |
| Chips / selection pills | `chip` / catalog tokens |

---

## Tests

| Test file | Guards |
|-----------|--------|
| `test/foundation/tilawa_input_style_test.dart` | Explicit borders, borderless slots |
| `test/foundation/tilawa_field_shell_test.dart` | **Reciters regression** — no nested `OutlineInputBorder` on catalog search |
| `test/atoms/tilawa_text_field_test.dart` | Text field behaviour |
| `test/atoms/tilawa_dropdown_field_test.dart` | Dropdown + menu placement |
| `test/atoms/tilawa_read_only_field_test.dart` | Read-only shell |
| `test/theme/app_theme_spec_compliance_test.dart` | Borderless theme |

---

## Raw input scan (2026-06-21)

See [§ Codebase scan](#codebase-scan-2026-06-21) in the ADR appendix or the
table below.

### Production app (`apps/tilawa`)

| File | Widget | Verdict |
|------|--------|---------|
| `features/color_picker/palette.dart` | `TextField` (hex) | **Intentionally custom** — dev color tool, dense hex entry |
| All other feature screens | Kit atoms only | Migrated |

### `packages/quran_sessions`

| File | Widget | Verdict |
|------|--------|---------|
| — | — | **No raw `TextField` / `TextFormField`** — uses `TilawaTextField`, `TilawaDropdownField`, `TilawaReadOnlyField` |

### `packages/ui_kit` (implementation)

| File | Widget | Verdict |
|------|--------|---------|
| `atoms/tilawa_text_field.dart` | `TextFormField` | Kit implementation |
| `molecules/tilawa_search_field.dart` | `TextField` | Kit implementation + `borderlessDecoration` |

### Other `InputDecoration` in app (not full fields)

| File | Verdict |
|------|---------|
| `share/.../share_audio_config_sheet.dart` | Custom slider/compact control — review when touched |
| `prayer_times/.../prayer_settings_sheet.dart` | Custom sheet control — review when touched |
| `frozen/share/...` | Frozen legacy — do not extend |

---

## Related docs

- [`packages/ui_kit/docs/design_system.md`](../packages/ui_kit/docs/design_system.md) — catalog chrome, tokens
- [`DESIGN.md`](../DESIGN.md) — product visual spec
- [`.cursor/rules/tilawa-dart.mdc`](../.cursor/rules/tilawa-dart.mdc) — agent rules
