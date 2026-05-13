# Tasks: UX Audit Critical Fixes

**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## In Progress

- [ ] **T011-001**: Replace hardcoded error state in `QuranImageReaderScreen` with `TilawaIllustratedState` + localized strings + theme tokens.
- [ ] **T011-002**: Localize retry label in `ReciterDetailsLoader`.
- [ ] **T011-003**: Add visible overflow menu button to `SurahListTile`; remove hidden `onLongPress` dependency.
- [ ] **T011-004**: Fix Quran bottom-nav item navigation trap in `MainScreen`.
- [ ] **T011-005**: Add `Semantics` + `InkWell` to `QuranPlayerWidget` expanded secondary controls.
- [ ] **T011-006**: Audit and reduce artificial startup delays in `MainScreenCubit` and `RecitersScreen`.
- [ ] **T011-007**: Run `flutter analyze` on `apps/tilawa`.
