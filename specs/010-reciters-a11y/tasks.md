# Tasks: Reciters Screen Accessibility

**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Completed

- [x] **T010-001**: Add localization keys (`a11yOpenReciterDetails`, `a11yFavoriteRecitersOnlyFilter`, `a11yRecitersLetterIndex`, `a11yRecitersAlphabetScrollbarHint`, `a11yClearRecitersSearch`, `removeFromFavorites`) in EN/AR ARBs; run `flutter gen-l10n`.
- [x] **T010-002**: Extend `TilawaIconActionButton` with `enabled`, optional `toggled`; wire `Semantics` + disabled `InkWell`.
- [x] **T010-003**: Add `clearButtonTooltip` to `TilawaSearchField` / `_SearchFieldBody` `IconButton`.
- [x] **T010-004**: Add optional `scrollbarSemanticsLabel` / `scrollbarSemanticsHint` to `ArabicAlphabetScrollbar`; plumb from `ReciterAlphabetScrollbar`.
- [x] **T010-005**: Refactor `ReciterCard` — single `InkWell` on info; favorite ≥48dp; semantics label + `toggled`; preserve `ReciterSemanticsIds`.
- [x] **T010-006**: Update `RecitersScreen` — header icon semantics, `Semantics(header: true)`, loading `semanticsLabel`, favorites `enabled`, search clear tooltip, scrollbar semantics.
- [x] **T010-007**: Run `dart analyze` / `flutter analyze` on `apps/tilawa` and `packages/ui_kit`.

## Follow-up (optional)

- [ ] Widget test: `ReciterCard` semantics (open + favorite labels, no nested buttons).
- [ ] Add explicit keyboard-accessible “Refresh” for pull-to-refresh on Reciters.
