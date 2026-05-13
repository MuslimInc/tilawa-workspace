# Implementation Plan: Reciters Screen Accessibility

**Branch**: `010-reciters-a11y` | **Date**: 2026-05-13 | **Spec**: [spec.md](./spec.md)

## Summary

Implement WCAG-aligned fixes for the Reciters list: split card tap targets to remove nested `InkWell`s, enlarge and label the favorite control, extend `TilawaIconActionButton` and `TilawaSearchField` for semantics/disabled/toggled behavior, wrap the alphabet scrollbar with optional semantics from the app, add localized strings, and expose a screen heading on the Reciters header.

## Technical Context

**Language**: Dart 3 / Flutter 3.x  
**Areas**: `apps/tilawa/lib/features/reciters/`, `packages/ui_kit/lib/src/molecules/`  
**Localization**: `flutter gen-l10n` (`app_en.arb`, `app_ar.arb`)  
**Testing**: `flutter test` (widget/semantics smoke for `ReciterCard` optional)

## Constitution Check

- **UI Kit for shared controls**: PASS — changes go through `TilawaIconActionButton`, `TilawaSearchField`, `ArabicAlphabetScrollbar`.
- **RTL**: PASS — no hard-coded LTR-only positioning in changed layout.
- **Testing**: PASS — manual semantics verification; optional widget test for card semantics.

## Phases

| Phase | Work |
|-------|------|
| 0 | Add ARB keys; run code generation. |
| 1 | UI kit: `TilawaIconActionButton` (`enabled`, `toggled`); `TilawaSearchField` (`clearButtonTooltip`); `ArabicAlphabetScrollbar` (optional semantics). |
| 2 | `reciter_card.dart`: layout split, `Semantics`, 48dp favorite. |
| 3 | `reciters_screen.dart`: header labels, heading, loading label, scrollbar hints, favorites disabled gate, search clear tooltip. |
| 4 | `dart analyze` on touched packages. |

## Risks

- Maestro flows rely on `Semantics.identifier` values — identifiers must remain stable (only moved/reparented as needed).
