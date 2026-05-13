# Implementation Plan: UX Audit Critical Fixes

**Branch**: `011-ux-audit-critical-fixes` | **Date**: 2026-05-13 | **Spec**: [spec.md](./spec.md)

## Summary

Fix the highest-severity UX issues from the audit: hardcoded error states, hidden gestures, navigation traps, inaccessible player controls, and artificial startup delays.

## Technical Context

**Language**: Dart 3 / Flutter 3.x  
**Areas**: `apps/tilawa/lib/features/quran_reader/`, `apps/tilawa/lib/features/reciters/`, `apps/tilawa/lib/screens/`, `apps/tilawa/lib/shared/widgets/`  
**Localization**: `flutter gen-l10n` (`app_en.arb`, `app_ar.arb`)  
**Testing**: `flutter analyze` after each phase

## Constitution Check

- **UI Kit for shared controls**: PASS — changes go through existing `TilawaIllustratedState`, `TilawaIconActionButton`.
- **RTL**: PASS — no hard-coded LTR-only positioning.
- **Testing**: PASS — manual semantics verification.

## Phases

| Phase | Work |
|-------|------|
| 0 | `quran_image_reader_screen.dart`: replace hardcoded error state with `TilawaIllustratedState` + localized strings + theme tokens. |
| 1 | `reciter_details_loader.dart`: localize retry label. |
| 2 | `surah_list_tile.dart`: add visible overflow menu button; remove hidden `onLongPress`. |
| 3 | `main_screen.dart`: fix Quran nav item — make it a real tab or remove from bottom bar. |
| 4 | `quran_player_widget.dart`: wrap volume/speed in `Semantics` + `InkWell`. |
| 5 | `main_screen_cubit.dart` + `reciters_screen.dart`: audit and reduce artificial delays. |
| 6 | `flutter analyze` on `apps/tilawa`. |

## Risks

- Maestro flows rely on `Semantics.identifier` values — identifiers must remain stable.
- Removing artificial delays may expose race conditions in startup.
