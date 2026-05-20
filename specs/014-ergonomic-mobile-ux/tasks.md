# Tasks: Ergonomic Mobile UX — Mechanical Batch

**Feature Branch**: `feature/ui-kit-2`
**Created**: 2026-05-20
**Status**: Complete (mechanical batch)
**Scope**: FR-002, FR-006, FR-007. See [plan.md](plan.md).

## Doc-comment drift (FR-002)

- [X] **T-001**: In [molecules_tokens.dart:285-286](../../packages/ui_kit/lib/src/foundation/component_tokens/molecules_tokens.dart#L285-L286), change `// Size = Tilawa hit-target floor (44 dp). At the floor; do not shrink further.` to read `48 dp`. The value beneath (`kTilawaMinInteractiveDimension`) already resolves to 48; this is a comment-only fix.

## IconActionButton motion (FR-007)

- [X] **T-010**: In [tilawa_icon_action_button.dart](../../packages/ui_kit/lib/src/molecules/tilawa_icon_action_button.dart), set the press `AnimationController.duration` to `Theme.of(context).tokens.durationMedium` from `didChangeDependencies`. Keep `vsync: this`. Initialise the controller in `initState` with a placeholder so it's never null, then overwrite the duration once the theme is reachable.
- [X] **T-011**: If a unit/widget test exists for `TilawaIconActionButton`, verify it doesn't depend on the literal 300 ms timing. (Likely fine — the press animation isn't tested with a hard duration in the kit.)

## `HitTestBehavior.opaque` rule (FR-006)

- [X] **T-020**: Add a dartdoc paragraph to `kTilawaMinInteractiveDimension` in [design_tokens.dart:1-18](../../packages/ui_kit/lib/src/foundation/design_tokens.dart#L1-L18) codifying the rule: every `GestureDetector` in the kit that wraps a visible interactive surface declares `behavior: HitTestBehavior.opaque`; bare detectors are reserved for non-visible regions (pan handlers, pan-to-dismiss).
- [X] **T-021**: Add a contract test that greps `packages/ui_kit/lib/src/` for `GestureDetector(` call sites and asserts the allow-list is exactly: `tilawa_media_player_bar.dart`, `alphabet_scrollbar.dart` (two sites), `immersive_composer_scaffold.dart`. Test file: `test/foundation/kit_contracts_test.dart`. Failure message should point future contributors at this spec.

## Verification

- [X] **T-090**: `melos exec --scope=tilawa_ui_kit -- "dart analyze"` clean.
- [X] **T-091**: `melos exec --scope=tilawa_ui_kit -- "flutter test"` green. Baseline ≈ 494.
- [X] **T-092**: No golden diffs expected; if any appear, eyeball before regenerating with `--update-goldens`.

## Follow-ups (next plan against this spec)

- [ ] **F-001**: FR-003 — disambiguate `TilawaMediaPlayerBar.onTap` from inline transport taps.
- [ ] **F-002**: FR-004 — keep "next track" visible in compact mini-player layout.
- [ ] **F-003**: FR-005 — sheet drag-to-dismiss or trailing close slot.
- [ ] **F-004**: FR-001 / FR-008 — self-sized 48 dp `TilawaSwitch` atom; no Maestro identifier regressions.
- [ ] **F-005**: Adjacent motion drift in [alphabet_scrollbar.dart:109](../../packages/ui_kit/lib/src/molecules/alphabet_scrollbar.dart#L109) and the segmented-control 300 ms `transitionDuration` token. Out of scope here; mention if they get touched incidentally.
