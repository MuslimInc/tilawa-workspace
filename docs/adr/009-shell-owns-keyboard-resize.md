# ADR-009: Shell owns keyboard resize

**Status:** Accepted  
**Date:** 2026-07-14  
**Deciders:** Tilawa mobile architecture  

## Context

Feature routes under `AppShellScreen` → `TilawaAdaptiveShell` typically nest a
second Material `Scaffold` (app bar + body). The shell `Scaffold` already
resizes for the IME (`resizeToAvoidBottomInset: true`) and zeroes body
`MediaQuery.viewInsets`. Nested scaffolds that also resize (or widgets that
re-apply full keyboard height via `effectiveKeyboardInset` / `View.viewInsets`)
produce white gaps above the keyboard, crushed lists, or fields that appear
“overlaid.”

Screens that already opted out of nested resize: Bookmarks, Reciters search /
details, Smart Khatma. History still defaulted to nested `true` with a search
field.

## Decision

1. **`TilawaAdaptiveShell` is the sole owner** of IME geometry under the app
   navigation shell (`resizeToAvoidBottomInset: true`, set explicitly).
2. **Shell-hosted feature screens use [`TilawaShellChildScaffold`](../../packages/ui_kit/lib/src/foundation/tilawa_shell_child_scaffold.dart)** —
   a thin `Scaffold` wrapper defaulting to `resizeToAvoidBottomInset: false`.
3. **Outside the shell** (auth, immersive Athkar, Quran reader, `/player`,
   standalone package flows) keep Material `Scaffold` with default resize (or an
   intentional immersive override).
4. **Scroll / focus contract:** keep bodies scrollable; use light field
   `scrollPadding` based on MediaQuery `keyboardInset` (often `0` after shell
   consume) plus a small token buffer. Do not stack a second full keyboard pad
   with `effectiveKeyboardInset` when the parent already resized. Sticky form
   footers already use `TilawaComfortableReachPadding(..., keyboardAware: false)`.

5. **Lint:** `tilawa_shell_child_scaffold` in `packages/tilawa_lints` errors on
   Material `Scaffold` constructors in shell-hosted product paths (see
   `shellHostedScaffoldPathMarkers` in `rule_scope.dart`). Outside-shell routes
   are unaffected.    Reviewed exceptions use
   `// tilawa-ui-exception: <ID>` +
   `// ignore: tilawa_lints/tilawa_shell_child_scaffold`.

Bottom navigation visibility while the keyboard is open is **unchanged** by this
ADR (mini-player remains hidden when the IME is open).

## Alternatives considered

### A. Feature owns resize (shell `resize: false`)

**Rejected.** Shared chrome (nav + mini-player slot) must move with the IME as
one unit. Flipping ownership forces every shell child to own scroll/FAB/reach
padding and redesign chrome positioning — high regression risk.

### B. Per-screen `resizeToAvoidBottomInset: false` comments only

**Rejected as long-term.** Correct locally but easy to miss on new screens
(History was the leftover risk). Codify via `TilawaShellChildScaffold`.

## Consequences

### Positive

- One place to reason about IME under the shell
- New screens inherit the safe default through the API
- Aligns with existing Bookmarks / Reciters / Smart Khatma / form sticky-footer
  patterns

### Negative / costs

- Contributors must choose `TilawaShellChildScaffold` vs Material `Scaffold`
  based on route host (documented)
- Screens with forms must remain scrollable (already expected)

## References

- `packages/ui_kit/lib/src/organisms/tilawa_adaptive_shell.dart`
- `packages/ui_kit/lib/src/foundation/tilawa_shell_child_scaffold.dart`
- `packages/ui_kit/docs/design_system.md` §4.4
- `docs/architecture/navigation.md`
