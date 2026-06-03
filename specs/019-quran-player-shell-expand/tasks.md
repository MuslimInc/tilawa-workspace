# Tasks: Quran Player Shell Expand

**Feature**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)  
**Release**: Next app release (MVP shipped in tree)

## Implementation Strategy

Ship the shell-overlay expand path with gesture fixes and Maestro parity, without waiting for Phase C legacy deletion. Post-release tasks consolidate presentation ownership and remove duplicate embed modes.

---

## Phase 1: Presentation shell host — **Done**

- [x] T001 Define `PlayerShellOverlayHost` in `player_shell_overlay_host.dart`
- [x] T002 Wire `PlayerPresentationController.expand/collapse` to shell host when bound
- [x] T003 Sync presentation progress/phases during shell overlay drag (`isDragging`, footer metrics)

## Phase 2: Gesture & overlay stability — **Done**

- [x] T004 `stop(canceled: false)` + drag flag lifecycle fix in `quran_player_widget.dart`
- [x] T005 Keep footer mini mounted (`Opacity(0)`) during active drag
- [x] T006 `IgnorePointer` on overlay sheet/morph during drag
- [x] T007 Shell `PointerRoute` for pointer retention above footer mini (optional attach/detach)
- [x] T008 Guard double `_finishExpandDrag` with end-handled flag

## Phase 3: YouTube Music–style interactive metrics — **Done**

- [x] T009 Update `_computeInteractiveDragMetrics` in `quran_player_expand_physics.dart`
- [x] T010 Unit tests for interactive drag thresholds and opacity curves
- [x] T011 Transition debug tooling (removed before release; use Maestro + optional dart-define logs)

## Phase 4: Tests & parity automation — **Done**

- [x] T012 `player_presentation_controller_test.dart` shell expand/collapse cases
- [x] T013 Maestro `quran_player_collapse_expand_parity.yaml` (coordinate swipe 92%→8% + conditional mini swipe)
- [x] T014 Reference README + YTM comparison flow under `.maestro/reference/`

## Phase 5: Release verification — **Done (agent / CI)**

- [x] T015 `dart analyze` on touched player files
- [x] T016 Targeted `flutter test` (physics + presentation controller)
- [x] T017 Maestro parity pass on `emulator-5554`

---

## Post-release refactor (future — not in this release)

- [x] T100 Delete `QuranPlayerExpandedHeroRoute` / hero bridge per [player-migration-roadmap.md](../../docs/architecture/player-migration-roadmap.md) Phase C
- [x] T101 Remove `embeddedInShellFooter: false` legacy overlay path after embed audit
- [x] T102 Single owner for `transitionProgress` vs `_expandController.value` (shell sync + reconcile)
- [ ] T103 iOS device Maestro + physical gesture QA matrix
- [ ] T104 Document final YTM visual deltas (queue handle, blur, typography) in design spec if needed
- [ ] T105 `011-ux-audit` expanded secondary controls semantics (volume/speed) — separate track

## Dependencies

- Phases 1–2 are prerequisites for Phase 3 metrics and Phase 4 Maestro.
- Phase C migration tasks (T100+) depend on product sign-off after release soak.
