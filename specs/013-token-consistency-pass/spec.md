# Feature Specification: Token Consistency Pass

**Feature Branch**: `013-token-consistency-pass`
**Created**: 2026-05-15
**Status**: In Progress
**Input**: Audit follow-up to [`specs/012-visual-simplification/`](../012-visual-simplification/spec.md). Goal: collapse the remaining "magic literals" in product code so the calm visual system reads consistently — same animation speeds, same type ramp, same feedback style, same icon-button affordance.

## Intent

After the visual-simplification pass, several smaller violations remain. Each individually is cosmetic, but together they erode the *premium* feel: an icon button with no ripple, a snackbar that pops on top of a toast, an animation that fades in at 350 ms when every neighbour fades at 200 ms. None of these need design input — they're mechanical migrations to the existing token system.

## User scenarios

### User Story 1 — Coherent motion
As a user moving between screens and toggling controls, I want every transition to share the same rhythm so the app feels like one product, not five.

### User Story 2 — Respect my text-scale settings
As a user with low vision who has bumped my system text scale to 1.5×, I want every label in the app to scale with it. Hard-coded `fontSize:` violates that.

### User Story 3 — Single feedback style
As a user completing an action (delete bookmark, save settings, copy text), I want feedback to come from a single visual channel, not sometimes a snackbar and sometimes a toast.

### User Story 4 — Discoverable icon-only controls
As a screen-reader user, I want every icon-only button to announce what it does. Today some `IconButton`s have no `tooltip:`/`semanticLabel`.

### User Story 5 — Touch feedback
As a user tapping a row, I want a ripple so I know the tap registered. Rows wrapped in bare `GestureDetector`s give no visual feedback.

## Requirements

### Functional

- **FR-001**: No `Duration(milliseconds: N)` literals in `apps/tilawa/lib/features/`. All motion durations come from `TilawaDesignTokens.durationFast` / `durationMedium` / `durationSlow`, or from local `static const` declarations that explain *why* they diverge (e.g. video-playback timing). Test code, animation curves, and bootstrap scheduling stay literal.
- **FR-002**: No `fontSize:` literals inside `TextStyle(...)` in `apps/tilawa/lib/features/` except inside the Quran reader's documented feature palette ([`quran_reader_theme.dart`](apps/tilawa/lib/features/quran_reader/presentation/theme/quran_reader_theme.dart) — tracked separately as an explicit exception). All other type comes from `theme.textTheme.*`.
- **FR-003**: One feedback channel. `ScaffoldMessenger.of(context).showSnackBar(...)` is removed from product code in favour of `ToastUtils.show*Toast(...)`. Snack-bar use is allowed only for actions that require an in-context *undo* affordance (none currently in the codebase).
- **FR-004**: Every `IconButton` in `apps/tilawa/lib/features/` and `apps/tilawa/lib/shared/widgets/` either (a) has both a `tooltip:` and an explicit `Semantics` parent, or (b) is replaced by `TilawaIconActionButton`. Bare icon buttons with no a11y affordance are forbidden.
- **FR-005**: Any `GestureDetector(onTap: …)` wrapping visible UI in product code is replaced by `InkWell` (or `TilawaCard(onTap:)` / `TilawaButton`). Bare gesture detectors are reserved for non-visible hit regions (e.g. pan-to-dismiss layers).
- **FR-006**: Quran-reader screen system-bar colours come from `colorScheme.surface` / `colorScheme.surfaceContainer`, not raw `Color(0x00000000)`. The transparent default leaks the home-screen wallpaper on Android in some launchers.

### Non-functional

- **NFR-001**: No new failures in `dart analyze` or `flutter test`.
- **NFR-002**: No accessibility regression. Every change that touches Semantics keeps existing semantic IDs (`*SemanticsIds.*`) intact so the integration test suite continues to find controls.
- **NFR-003**: No visual regression in goldens. Where a golden changes by < 1 px because of token rounding, regenerate it and note the affected snapshot in `tasks.md`.

## Edge cases

- **`AnimationController.duration` initial value** — `AnimationController` constructors take a `Duration`, but the call site usually has `Theme.of(context)` available; pull tokens at construction time inside `didChangeDependencies` (or use a `late` field). Where the controller is initialised in `initState` and the theme isn't reachable, leave the literal but add a `// fix: motion-token deferred — initState scope` comment.
- **`Future.delayed` outside UI code** — services, BLoCs, and bootstrap code have legitimate non-UI delays (debounce, retry back-off). These are out of scope; only product widget animations are migrated.
- **Quran reader theme** — explicitly out of scope per the audit recommendation: it's a *Mushaf-only* feature palette, not chrome. To be tracked as a separate exception in `docs/design/colors.md`.

## Out of scope

- Quran reader feature palette refactor (separate decision: keep as Mushaf exception vs migrate to ColorScheme).
- Custom `AlertDialog` standardisation (needs design — should we add a `TilawaDialog` molecule? Decision deferred to a later spec).
- Share-flow consolidation (needs UX design).
- Quran-reader gesture discoverability tutorial.
- Dynamic-type golden coverage (deserves its own spec).
