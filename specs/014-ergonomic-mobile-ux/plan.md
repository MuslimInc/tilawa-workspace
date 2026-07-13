# Plan: Ergonomic Mobile UX — Mechanical Batch

**Feature Branch**: `feature/ui-kit-2`
**Created**: 2026-05-20
**Status**: Complete (mechanical batch)
**Scope of this plan**: FR-002 (doc-comment drift), FR-006 (`HitTestBehavior.opaque` rule), FR-007 (`IconActionButton` motion token). The reachability batch (FR-003, FR-004, FR-005) and the floor-enforcement work (FR-001, FR-008) are deferred to a follow-up plan in the same spec.

## Why this batch first

These three FRs are the mechanical, no-API-change subset of the spec:

- **No new widgets, no removed widgets.**
- **No golden churn expected.** FR-002 and FR-006 only touch dartdoc comments. FR-007 changes a press-animation duration from 300 ms to 400 ms, which is invisible in a static golden frame.
- **No `Semantics` changes**, so the Maestro identifier surface and the `accessibility_audit_contracts_test.dart` contract test continue to pass.
- They unblock confidence for the larger reachability batch — once we know the test suite stays green on the easy ones, the bigger refactors run against a known-good baseline.

## Diagnosis (snapshot from audit)

| Finding | File | Notes |
| ------- | ---- | ----- |
| Doc-comment says "44 dp" but value is `kMeMuslimMinInteractiveDimension` (48 dp) | [molecules_tokens.dart:285-286](../../packages/ui_kit/lib/src/foundation/component_tokens/molecules_tokens.dart#L285-L286) | One comment line; cosmetic drift left over from before the 44→48 floor decision. |
| `HitTestBehavior.opaque` rule for visible-surface `GestureDetector`s is implicit | [tilawa_media_player_bar.dart:147](../../packages/ui_kit/lib/src/organisms/tilawa_media_player_bar.dart#L147) | The behaviour is set correctly in the only place it currently matters; the spec asks us to *codify* the rule so future contributors don't drift. |
| `AnimationController(duration: 300 ms)` in `initState` | [tilawa_icon_action_button.dart:59-62](../../packages/ui_kit/lib/src/molecules/tilawa_icon_action_button.dart#L59-L62) | Press animation. Should consume `tokens.durationMedium` (400 ms) for kit-wide motion consistency. |

Adjacent (out of scope for this plan, flagged for follow-up):

- [alphabet_scrollbar.dart:109](../../packages/ui_kit/lib/src/molecules/alphabet_scrollbar.dart#L109) — `Duration(milliseconds: 300)` fade. Same pattern, not in this spec but worth a `// fix: motion token` note if the FR-007 work makes it tempting to migrate.
- [organisms_tokens.dart:1501](../../packages/ui_kit/lib/src/foundation/component_tokens/organisms_tokens.dart#L1501) — `transitionDuration: 300 ms` segmented-control token. Bound by component-token tests; touching it grows the diff. Left alone.

## Execution order

Three sub-tasks, each independently committable. I'll run `dart analyze` between them and `flutter test` at the end.

### 1. FR-002 — doc-comment drift

Update the `// Size = Tilawa hit-target floor (44 dp).` comment to read 48 dp, matching the actual value `kMeMuslimMinInteractiveDimension`. Single-line edit. No code path changes.

### 2. FR-007 — IconActionButton press motion → tokens.durationMedium

Move the `AnimationController` instantiation so it can read `Theme.of(context)`:

- Drop `late AnimationController _animationController;` initialisation from `initState` (or initialise with a zero placeholder).
- Set `_animationController.duration` in `didChangeDependencies`, reading `Theme.of(context).tokens.durationMedium`. Guard so reassignment is idempotent on rebuild.
- Keep `vsync: this` from the `SingleTickerProviderStateMixin`.

The press animation is a forward/reverse scale (1.0 ↔ 0.92). Going 300 → 400 ms slightly extends the touch ripple feel. Test plan: the existing `tilawa_icon_action_button` test (if any) plus a manual press should look subtly slower but no longer than the kit's other tokenised animations.

### 3. FR-006 — codify the `HitTestBehavior.opaque` rule

Two parts:

- **Doc**: add a paragraph to the dartdoc of `kMeMuslimMinInteractiveDimension` in [design_tokens.dart:1-18](../../packages/ui_kit/lib/src/foundation/design_tokens.dart#L1-L18) stating the rule: "Every `GestureDetector` in the kit that wraps a visible interactive surface must declare `behavior: HitTestBehavior.opaque` so transparent padding still registers taps. Bare detectors are reserved for non-visible regions (pan handlers, pan-to-dismiss layers)."
- **Lint-equivalent check**: extend the existing `accessibility_audit_contracts_test.dart` (or a new lightweight contract test) to grep the kit source for `GestureDetector(` and assert the only call sites are in: `tilawa_media_player_bar.dart`, `alphabet_scrollbar.dart`, `immersive_composer_scaffold.dart`. Future contributors adding a new detector trigger the test until they justify it.

The text-based contract test is the cheap way to keep the rule honest without writing a custom analyzer plugin. If the audit-contracts test isn't a good fit (it might be widget-tree-based), add a new file `test/foundation/kit_contracts_test.dart` instead.

## Risks

- **`didChangeDependencies` fires on every InheritedWidget change**, including locale/text-scaler switches. The guard prevents reassignment, but if `tokens.durationMedium` itself changes mid-flight (theme switch dark→light) we'd want the new duration. Set unconditionally — it's a cheap setter on `AnimationController`, no resource leak.
- **Contract test as gatekeeper**: a grep-based test couples the source layout to the test. If someone moves `tilawa_media_player_bar.dart` to a subfolder, the test breaks. Document the workaround inline ("update the allow-list when relocating these files").
- **Golden churn**: not expected, but if a snapshot was captured mid-press-animation it could drift. The kit's goldens are static (no animation pumping unless explicit), so this should be a non-issue.

## Verification gates

After each sub-task, in order:

1. `melos exec --scope=tilawa_ui_kit -- "dart analyze"`
2. `melos exec --scope=tilawa_ui_kit -- "flutter test"` (494 expected baseline per spec 013)
3. If any golden diffs, regenerate with `--update-goldens` and eyeball the PNG diff before committing.

## Follow-ups (deferred to later plans against the same spec)

- **FR-003** — `TilawaMediaPlayerBar.onTap` vs inline transport taps. Needs a decision: shrink the outer gesture region to the metadata strip, or move bar-open into an explicit affordance (artwork chevron, swipe). Design call.
- **FR-004** — Compact mini-player keeps "next track" visible. Token + layout change in `_TransportControls`.
- **FR-005** — `TilawaSheetHandle` becomes drag-to-dismiss, *or* `TilawaBottomSheetScaffold` gains a `trailingClose` slot. Pick one; both is overkill.
- **FR-001 / FR-008** — `Switch.adaptive` self-sized 48 dp atom (probably `TilawaSwitch`), no Maestro identifier regressions.
